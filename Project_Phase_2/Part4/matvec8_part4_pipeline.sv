module matvec8_part4(clk, reset, input_valid, input_ready, input_data, new_matrix, output_valid, output_ready, output_data);

parameter INPUT_LENGTH = 14;
parameter OUTPUT_LENGTH = 28;
parameter MATRIX_LENGTH = 8;
parameter VECTOR_SIZE = MATRIX_LENGTH;
parameter MATRIX_SIZE = MATRIX_LENGTH * MATRIX_LENGTH;

input clk, reset, input_valid, output_ready,new_matrix;
input signed [INPUT_LENGTH-1:0] input_data;
output signed [OUTPUT_LENGTH-1:0] output_data;
output output_valid, input_ready;

wire [$clog2(VECTOR_SIZE)-1:0]wire_addr_x;
wire wire_wr_en_x;
wire [$clog2(MATRIX_SIZE)-1:0]wire_addr_w;
wire wire_wr_en_w;
wire wire_clear_acc;
wire wire_en_acc;
wire wire_en_pipe;

control control_inst(.clk(clk), .reset(reset), .new_matrix(new_matrix), .input_valid(input_valid), .addr_x(wire_addr_x), .wr_en_x(wire_wr_en_x), .addr_w(wire_addr_w), .wr_en_w(wire_wr_en_w), .clear_acc(wire_clear_acc), .en_acc(wire_en_acc), .en_pipe(wire_en_pipe), .input_ready(input_ready), .output_valid(output_valid), .output_ready(output_ready));
datapath datapath_inst(.clk(clk), .input_data(input_data), .addr_x(wire_addr_x), .wr_en_x(wire_wr_en_x), .addr_w(wire_addr_w), .wr_en_w(wire_wr_en_w), .clear_acc(wire_clear_acc), .en_pipe(wire_en_pipe), .en_acc(wire_en_acc), .output_data(output_data));
// data path does not need reset for our specific design  

endmodule


// datapath design does not have any pipeline register only deal with the saturation 
module datapath(clk, input_data, addr_x, wr_en_x, addr_w, wr_en_w, en_pipe, clear_acc, en_acc, output_data);

parameter INPUT_LENGTH = 14;
parameter OUTPUT_LENGTH = 28;
parameter MATRIX_LENGTH = 8;
parameter MATRIX_SIZE = MATRIX_LENGTH * MATRIX_LENGTH;
parameter VECTOR_SIZE = MATRIX_LENGTH;

input clk, wr_en_x, wr_en_w, clear_acc, en_acc,en_pipe;
input signed [INPUT_LENGTH-1:0] input_data;
input [$clog2(VECTOR_SIZE)-1:0] addr_x ;
input [$clog2(MATRIX_SIZE)-1:0] addr_w;
output logic signed [OUTPUT_LENGTH-1:0] output_data;
   logic [INPUT_LENGTH-1: 0]input_data_holder;                                      // not a single bit
wire [INPUT_LENGTH-1:0] wire_mem_x_data_out;
wire [INPUT_LENGTH-1:0] wire_mem_w_data_out;
wire [OUTPUT_LENGTH-1:0] wire_mult_to_pipe;
wire [OUTPUT_LENGTH-1:0] wire_pipe_to_add;
wire [OUTPUT_LENGTH-1:0] wire_add_to_reg28b;


// input_data need to be delayed one clock cycle to sync with the control signals generated from control module
always_ff @(posedge clk)begin
   input_data_holder <= input_data ;
end

// matrix instantiation
memory #(INPUT_LENGTH,MATRIX_SIZE) memoryWInst(.clk(clk), .data_in(input_data_holder), .data_out(wire_mem_w_data_out), .addr(addr_w), .wr_en(wr_en_w));
// vector instantiation
memory #(INPUT_LENGTH,VECTOR_SIZE) memoryXInst(.clk(clk), .data_in(input_data_holder), .data_out(wire_mem_x_data_out), .addr(addr_x), .wr_en(wr_en_x));
multiplier multiplier_inst(.a_in(wire_mem_x_data_out), .b_in(wire_mem_w_data_out), .mult_out(wire_mult_to_pipe), .clk(clk));
register28b pipelineReg_inst(.data(wire_mult_to_pipe), .en(en_pipe), .clk(clk), .reset(reset), .out(wire_pipe_to_add));
adder adder_inst(.productAB(wire_pipe_to_add), .preSum(output_data), .out(wire_add_to_reg28b));
register28b reg28b_add_to_out_inst(.clk(clk), .reset(clear_acc), .en(en_acc), .data(wire_add_to_reg28b), .out(output_data));


endmodule

//control module
module control(clk, reset,new_matrix, input_valid, input_ready, output_valid, output_ready, addr_x, wr_en_x, addr_w, wr_en_w, clear_acc, en_acc,en_pipe);

parameter MATRIX_LENGTH = 8;
parameter MATRIX_SIZE = MATRIX_LENGTH * MATRIX_LENGTH;
parameter VECTOR_SIZE = MATRIX_LENGTH;
parameter DATA_SIZE = MATRIX_SIZE + VECTOR_SIZE;

input clk, reset, input_valid, output_ready,new_matrix;
output logic [$clog2(VECTOR_SIZE)-1:0] addr_x;
output logic [$clog2(MATRIX_SIZE)-1:0] addr_w;
output logic wr_en_x, wr_en_w, clear_acc, en_acc, input_ready, output_valid,en_pipe;


// these are the local parameters as  copies of the output signals since we can't read output signals
// temp signals are signals to perform propagated signal values
// start computing is status signal to determine when should start computation and when is the whole computation finish
// the number of inputs into the system determines when should start to load values to each memory (w and x)
// continue next  == continue next three matrix vector computation eg  x11y1 + x12y2+ x13y3
// came3 is a status signal stands for just coming from loading the last 3rd computation
// reset_x_addr status signal means at that time should not increment memoryinstX addr from 0 -> 1
// from loading status signal means last cycle was  count_input_data == 12 (count_input_data == 12 cycle is when we pass the 12th input into the memory)

logic local_valid, temp_valid, temp_valid2, temp_valid3, local_ready,local_wr_en_x, local_wr_en_w; 
logic start_computing,temp_en_acc,temp_clear_acc,continue_next,reset_x_addr,from_loading;          
logic temp_en_accp,temp_en_acc2,came3,temp_en_pipe,temp_clear_acc2;
logic temp3_en_acc;
logic t_p1,t_p2,t_p3,t_p4,t_p5;
logic t_acc1,t_acc2,t_acc3,t_acc4,t_acc5;
logic t_c_acc1,t_c_acc2,t_c_acc3,t_c_acc4,t_c_acc5;
logic t_valid1,t_valid2,t_valid3,t_valid4,t_valid5;
logic unsigned [$clog2(VECTOR_SIZE):0]count_pipe_acc_valid;
logic unsigned [$clog2(DATA_SIZE)-1:0]count_input_data;                                     
logic unsigned [$clog2(MATRIX_SIZE):0]count_w_addr;
logic unsigned [$clog2(VECTOR_SIZE):0]count_x_addr;
logic unsigned [$clog2(MATRIX_SIZE):0]count_compute;
logic unsigned [$clog2(MATRIX_SIZE):0] counter;

always_ff @(posedge clk) begin 
    if(reset)begin                                                                         // reset initialize most of the signals
        local_ready <= 1;                                                                   
        input_ready <= 1;
        local_valid <= 0;
        output_valid <= 0;
        count_input_data <= 0;
        count_w_addr <= 0;
        count_x_addr <= 0;
        count_compute <= 0;
        count_pipe_acc_valid <= 0;
        addr_x <=0;
        addr_w <=0 ;
        local_wr_en_w <= 0;
        local_wr_en_x <= 0;
        wr_en_w <= 0;
        wr_en_x <= 0;
        en_acc <= 0;
	en_pipe <= 0;
        clear_acc <= 1;
        start_computing <= 0;    
   end 

    else begin
        if(count_input_data != DATA_SIZE &&(!input_valid && !start_computing))begin                // need to deal with the condition where no input data is valid, should remove the wr_en signals
            if(local_wr_en_w == 1)begin 
                local_wr_en_w <= 0;
                wr_en_w <= 0;
            end
            else if (local_wr_en_x == 1) begin
                local_wr_en_x <= 0;
                wr_en_x <= 0;
            end
        end
        else if((input_valid && local_ready)||count_input_data == DATA_SIZE) begin                 // when both handshaking signals are avaliable  or we have all 12 input data
            if(count_input_data < MATRIX_SIZE) begin                                         //loads matrix until all 9 indexes have been loaded, then enables memory write for vector
                if(count_input_data == 0)begin
                    if(new_matrix == 1)begin
                        local_wr_en_w <= 1;
                        local_wr_en_x <= 0;
                        wr_en_w <= 1;                                                                 
                        wr_en_x <= 0;
                        count_input_data <= count_input_data +1;
                    end
                    else begin
                        count_input_data <= MATRIX_SIZE+1;
                        local_wr_en_w <= 0;
                        local_wr_en_x <= 1;
                        wr_en_w <= 0;
                        wr_en_x <= 1;
                    end
                end
                else begin
                    local_wr_en_w <= 1;
                    local_wr_en_x <= 0;
                    wr_en_w <= 1;                                                                 
                    wr_en_x <= 0;
                    count_input_data <= count_input_data +1;
                    if(count_input_data != 0 )begin
                        count_w_addr <= count_w_addr +1;
                        addr_w <= count_w_addr +1 ;
                    end
                end
            end
        else if(count_input_data >= MATRIX_SIZE && count_input_data < DATA_SIZE) begin            // load vector elements 
            local_wr_en_w <= 0;
            local_wr_en_x <= 1;
            wr_en_w <= 0;
            wr_en_x <= 1;
            count_input_data <= count_input_data +1;                                               //counts the number of numbers from matrix and vectors that have been loaded 
            if(count_input_data != MATRIX_SIZE)begin                                                                  
                count_x_addr <= count_x_addr +1;
                addr_x <= count_x_addr +1 ;
                end
        end                                                                          
	    else if(count_input_data == DATA_SIZE) begin                                                       // at this condition the 12th data and wr_en is ready at the input of the memory 
            start_computing <= 1;                                                                   //next cycle should start to compute the first entry of matrix and vector
            count_w_addr <= 0;                                                                      // cleaning up input count and disabling wr_en, reset addresses
            addr_w <=  0 ;                                                                          // prepare control signals for accumulator along with first computation
            addr_x <= 0;
            count_x_addr <= 0;
            count_input_data <= 0;
            local_wr_en_x <= 0;
            wr_en_x <= 0;
	    temp_en_pipe <= 1;
            temp_clear_acc <= 0;
            temp_valid <= 0;
            count_compute <= count_compute+1;
        end   
	    if(count_input_data +1 == DATA_SIZE)begin                                                 // changes here so the ready will be deasserted once getting 12 data instead of after that
	    local_ready <= 0 ;                                                                          // to prevent any data being erased by the testbench
            input_ready <= 0;
        end
        end

        else if(start_computing) begin                                                                  // for computing five categories: regular computation x11*y1;
            if( count_compute%MATRIX_LENGTH != 0)begin                                             // three above computations are finished: output is ready to take or not 		                                                                     // nine of aboe computation are finished: output is ready to take or not
           	count_w_addr <= count_w_addr +1;
                addr_w <= count_w_addr +1 ;                                       
                count_x_addr <= count_x_addr +1;
                addr_x <= count_x_addr +1 ;    
                count_compute <= count_compute +1;
		t_p1 <= temp_en_pipe;
		t_p2 <= t_p1;
		t_p3 <= t_p2;
		t_p4 <= t_p3;
		t_p5 <= t_p4;
		en_pipe <= t_p5;
                en_acc <= en_pipe;

                t_c_acc1 <= temp_clear_acc;
		t_c_acc2 <= t_c_acc1;
		t_c_acc3 <= t_c_acc2;
		t_c_acc4 <= t_c_acc3;
		t_c_acc5 <= t_c_acc4;
		temp_clear_acc2 <= t_c_acc5;
                clear_acc <= temp_clear_acc2 ;
                if((count_compute +1)%MATRIX_LENGTH == 0)begin                                       // if next cycle 3 computations will be counted in control module, then propagate the valid out
                    temp_valid <= 1;                                                                        // propagate the en_acc and assert just come from 3 computation counted
                    temp_valid2 <= temp_valid;
		    temp_valid3 <= temp_valid2;
		    
                    local_valid <= temp_valid3;
                    output_valid <= temp_valid3;
                    count_pipe_acc_valid <= count_pipe_acc_valid +1;
                end
                else begin                                                                                      // if not just indicate output is not valid yet
                    temp_valid2 <= temp_valid;
		    temp_valid3 <= temp_valid2;
                    local_valid <= temp_valid3;
                    output_valid <= temp_valid3;
                end
            end
            else if(count_compute%MATRIX_LENGTH == 0) begin                                                                     // deal with 3,6,9 computation is finished 
                if(count_compute != MATRIX_SIZE) begin 
                    if(output_ready && local_valid)begin                                                              // just 3,6 computation is finished and output is ready for tb to take
                    t_p1 <= 0;
		            t_p2 <= 0;
		            t_p3 <= 0;
		            t_p4 <= 0;
		            t_p5 <= 0;
                    t_c_acc1 <= 0;
		            t_c_acc2 <= 0;
		            t_c_acc3 <= 0;
		            t_c_acc4 <= 0;
		            t_c_acc5 <= 0;            
                        clear_acc <= 1;                                                                               // cleaning up and assert not valid, reset x address, 
                        output_valid <= 0;
                        local_valid <= 0;
		        temp_valid <= 0;
		        temp_valid2 <= 0;
			temp_valid3 <= 0;
		        temp_en_acc <= 0;
			temp3_en_acc <= 0;
                        count_x_addr <= 0;
			count_w_addr <= count_w_addr +1;
                	addr_w <= count_w_addr +1 ;  
		        addr_x <= 0 ;
		        en_acc <= 0;
			en_pipe <= 0;
			temp_en_pipe <= 1;    
            		temp_clear_acc <= 0;
            		temp_clear_acc2 <= 0 ;
            		count_compute <= count_compute+1;
                    count_pipe_acc_valid <= 0;

                    end
                    else if(!output_ready && local_valid )begin                                                     //not ready to take so disable accumulator
                        en_acc <= 0;
                        en_pipe <= 0;
                    end 
                    else if(!local_valid)begin                                                                      // if valid is not ready and just come from 3rd computation 
		               if(count_pipe_acc_valid == 7)begin 
                            en_pipe <= 0;
                       end
                       else if (count_pipe_acc_valid >=8)begin
                                en_acc <= 0;
                                local_valid <= 1;
                                output_valid <= 1;
                       end
                       else if( count_pipe_acc_valid <7 )begin
                            en_pipe <= 1;
                            en_acc <= 1;
                            local_valid <= 0;
                            output_valid <= 0;
                       end
                        count_pipe_acc_valid <= count_pipe_acc_valid +1;
                    end
                end
                else begin                                                                                              // 9 computation is finished
                    if(output_ready && local_valid)begin                                                                // cleaning up as above and then re start loading  cleaning up and assert not valid, reset x address, 
            		t_p1 <= 0;
		            t_p2 <= 0;
		            t_p3 <= 0;
		            t_p4 <= 0;
		            t_p5 <= 0;
                    t_c_acc1 <= 0;
		            t_c_acc2 <= 0;
		            t_c_acc3 <= 0;
		            t_c_acc4 <= 0;
		            t_c_acc5 <= 0;  
                    temp_clear_acc <= 0;
            		temp_clear_acc2 <= 0 ;
			start_computing <= 0;
                        en_acc <= 0;
			en_pipe <= 0;
                        clear_acc <= 1;
                        local_valid <= 0;
                        output_valid <= 0;
			 temp_valid <= 0;
                        temp_valid2 <= 0;
			temp_valid3 <= 0;
			temp_en_pipe <= 0;
                        temp_en_acc <= 0;
			temp3_en_acc <= 0;
                        count_compute <= 0;
                        count_w_addr <= 0;
                        count_x_addr <= 0;
                        addr_w <= 0;
                        addr_x <= 0;
                        local_ready <= 1;
                        input_ready<=1;   
                        count_pipe_acc_valid <= 0;
                    end
                    else if(!output_ready && local_valid )begin                                                         // same as above
                        en_acc <= 0;
                        en_pipe <=0;
                    end 
                    else if(!local_valid)begin                                                                          // same as above 
		                if(count_pipe_acc_valid == 7)begin 
                            en_pipe <= 0;
                       end
                       else if (count_pipe_acc_valid >=8)begin
                                en_acc <= 0;
                                local_valid <= 1;
                                output_valid <= 1;
                       end
                       else if(count_pipe_acc_valid <7)begin
                            en_pipe <= 1;
                            en_acc <= 1;
                            local_valid <= 0;
                            output_valid <= 0;
                           
                       end
                        count_pipe_acc_valid <= count_pipe_acc_valid +1;
                    end
                end
            end
        end
    end
end //ends always_ff

endmodule


// memory module as specified at each positive clock edge output data old value at that address, if wr_en asserted, writing new value to that location
module memory(clk, data_in, data_out, addr, wr_en);

parameter WIDTH = 16, SIZE = 64;
localparam LOGSIZE = $clog2(SIZE);
input [WIDTH-1:0] data_in;
output logic [WIDTH-1:0] data_out;
input [LOGSIZE-1:0] addr;
input clk, wr_en;
logic [SIZE-1:0][WIDTH-1:0] mem;

always_ff @(posedge clk) begin
    data_out <= mem[addr];
if (wr_en)
    mem[addr] <= data_in;
end

endmodule

//adder module with saturation
module adder(preSum, productAB, out);
parameter WIDTH = 28;
input signed[WIDTH-1:0] preSum, productAB;
output logic signed[WIDTH-1:0] out;

//here is the logic of taking care of the overflow situation
// when output does not make sense with the given inputs
// the output will be ouverwritten/saturated

always_comb begin
    out = productAB + preSum;
    if(preSum>0 && productAB >0 && out<0) begin
        out = signed'(28'b0111111111111111111111111111);
    end
    else if(preSum <0 && productAB <0 && out>0) begin
        out = signed'(28'b1000000000000000000000000000);
    end
end
endmodule


// multiplier module no changes from project1
module multiplier(a_in, b_in, mult_out,clk);

parameter WIDTH = 14;
parameter WIDTH2 = 28;
input clk;
input signed [WIDTH-1:0] a_in, b_in;
output logic signed [WIDTH2-1:0] mult_out;

/*always_comb begin
    mult_out = a_in * b_in;
end   
*/
DW02_mult_6_stage #(14,14)multinstance(a_in,b_in,1'b1,clk,mult_out); 
endmodule


// accumulator / output register 
module register28b(data, en, clk, reset, out);

parameter WIDTH = 28;

input logic signed [WIDTH-1:0] data;
input en, reset, clk ;
output logic signed [WIDTH-1:0] out;

always_ff @(posedge clk) begin
    if (reset) begin
        out <= 0;
    end
    else if (en) begin
        out <= data;
    end
end

endmodule
