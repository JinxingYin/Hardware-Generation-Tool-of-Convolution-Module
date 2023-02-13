module datapath(clk, reset, input_data, addr_x, wr_en_x, value_w, en_pipe, clear_acc, en_acc, output_data,relu);

parameter DATA_LENGTH = 14;
parameter MATRIX_ROW_LENGTH = 8;
parameter MATRIX_COL_LENGTH = 8;
parameter PIPELINE_LENGTH = 8;
localparam MATRIX_SIZE = MATRIX_ROW_LENGTH * MATRIX_COL_LENGTH/PIPELINE_LENGTH;
localparam VECTOR_SIZE = MATRIX_COL_LENGTH;

input clk, reset, wr_en_x, clear_acc, en_acc, en_pipe, relu;
input signed [DATA_LENGTH-1:0] input_data;
input [$clog2(VECTOR_SIZE)-1:0] addr_x ;
input signed [DATA_LENGTH-1:0] value_w;
output logic signed [DATA_LENGTH-1:0] output_data;

logic signed [DATA_LENGTH-1: 0]input_data_holder;                                      
wire [DATA_LENGTH-1:0] wire_mem_x_data_out;
wire [DATA_LENGTH-1:0] wire_mult_to_pipe;
wire [DATA_LENGTH-1:0] wire_pipe_to_add;
wire [DATA_LENGTH-1:0] wire_add_to_reg28b;
wire [DATA_LENGTH-1:0] wire_reg28b_to_Relu;

// input_data need to be delayed one clock cycle to sync with the control signals generated from control module
always_ff @(posedge clk)begin
   input_data_holder <= input_data ;
end

// vector instantiation
memory #(DATA_LENGTH,VECTOR_SIZE) memoryXInst(.clk(clk), .data_in(input_data_holder), .data_out(wire_mem_x_data_out), .addr(addr_x), .wr_en(wr_en_x));
multiplier #(DATA_LENGTH) multiplier_inst(.a_in(wire_mem_x_data_out), .b_in(value_w), .mult_out(wire_mult_to_pipe));
register28b #(DATA_LENGTH) pipelineReg_inst(.data(wire_mult_to_pipe), .en(en_pipe), .clk(clk), .reset(reset), .out(wire_pipe_to_add));
adder #(DATA_LENGTH) adder_inst(.productAB(wire_pipe_to_add), .preSum(wire_reg28b_to_Relu), .out(wire_add_to_reg28b));
register28b #(DATA_LENGTH) reg28b_add_to_out_inst(.clk(clk), .reset(clear_acc), .en(en_acc), .data(wire_add_to_reg28b), .out(wire_reg28b_to_Relu));
relumod #(DATA_LENGTH) relu_inst(.relu(relu), .d_in(wire_reg28b_to_Relu), .d_out(output_data));
endmodule


module control(clk, reset, done_out, done_P, input_valid, input_ready, output_valid, output_ready, addr_x, wr_en_x, addr_w, clear_acc, en_acc,en_pipe);

parameter unsigned MATRIX_ROW_LENGTH = 8;
parameter unsigned MATRIX_COL_LENGTH = 8;
parameter unsigned PIPELINE_LENGTH = 8;
localparam unsigned MATRIX_SIZE = MATRIX_ROW_LENGTH * MATRIX_COL_LENGTH/PIPELINE_LENGTH;
localparam unsigned VECTOR_SIZE = MATRIX_COL_LENGTH;
localparam unsigned DATA_SIZE = VECTOR_SIZE;

input clk, reset, input_valid, output_ready,done_out,done_P;
output logic [$clog2(VECTOR_SIZE)-1:0] addr_x;
output logic [$clog2(MATRIX_SIZE)-1:0] addr_w;
output logic wr_en_x, clear_acc, en_acc, input_ready, output_valid,en_pipe;

logic local_valid, local_ready,local_wr_en_x; 
logic start_computing;          
logic unsigned [$clog2(DATA_SIZE):0]count_input_data;                                     
logic unsigned [$clog2(MATRIX_SIZE):0]count_w_addr;
logic unsigned [$clog2(VECTOR_SIZE):0]count_x_addr;
logic unsigned [$clog2(MATRIX_SIZE):0]count_compute;
logic unsigned [$clog2(3+DATA_SIZE):0]counter;

always_ff @(posedge clk) begin 
    if(reset)begin                                                                                // reset initialize most of the signals
        local_ready <= 1;                                                                   
        input_ready <= 1;
        local_valid <= 0;
        output_valid <= 0;
        count_input_data <= 0;
        count_w_addr <= 0;
        count_x_addr <= 0;
        count_compute <= 0;
        counter <= 0;
        addr_x <=0;
        addr_w <=0 ;
        local_wr_en_x <= 0;
        wr_en_x <= 0;
        en_acc <= 0;
	    en_pipe <= 0;
        clear_acc <= 1;
        start_computing <= 0;    
   end 

    else begin
        if(count_input_data != DATA_SIZE &&(!input_valid && !start_computing))begin                // disable wr_en when not needed
            if (local_wr_en_x == 1) begin
                local_wr_en_x <= 0;
                wr_en_x <= 0;
            end
        end
        else if((input_valid && local_ready)||count_input_data == DATA_SIZE) begin                 // when both handshaking signals are avaliable  or we have all  input data  
            if(count_input_data < DATA_SIZE) begin                                                 
                local_wr_en_x <= 1;
                wr_en_x <= 1;
                count_input_data <= count_input_data +1;                                               // counts the number of numbers from matrix and vectors that have been loaded 
                if(count_input_data != 0)begin                                                                  
                    count_x_addr <= count_x_addr +1;
                    addr_x <= count_x_addr +1 ;
                end
            end                                                                          
            else if(count_input_data == DATA_SIZE) begin                                                
                start_computing <= 1;                                                                   // next cycle should start to compute the first entry of matrix and vector
                count_w_addr <= 0;                                                                      // cleaning up input count and disabling wr_en, reset addresses
                addr_w <=  0 ;                                                                          // prepare control signals for accumulator along with first computation
                addr_x <= 0;
                count_x_addr <= 0;
                count_input_data <= 0;
                local_wr_en_x <= 0;
                wr_en_x <= 0;
                count_compute <= count_compute+1;
                counter <= 1;
            end   
            if(count_input_data +1 == DATA_SIZE)begin                                                   // changes here so the ready will be deasserted once getting all data instead of after that
                local_ready <= 0 ;                                                                      // to prevent any data being erased by the testbench
                input_ready <= 0;
            end
        end

        else if(start_computing) begin                                                                  // for computing five categories: regular computation x11*y1;
                
            if( count_compute%MATRIX_COL_LENGTH != 0)begin                                              // row computations are finished: output is ready to take or not
                counter <= counter +1;
                count_w_addr <= count_w_addr +1;
                addr_w <= count_w_addr +1 ;                                       
                count_x_addr <= count_x_addr +1;
                addr_x <= count_x_addr +1 ;    
                count_compute <= count_compute +1;
                if(counter+1 == 2)begin
                    en_pipe <= 1;
                end
                else if(counter +1 == 3)begin
                    en_acc <= 1;
                    clear_acc <= 0;
                end
            end
            else if(count_compute%MATRIX_COL_LENGTH == 0) begin                                         // deal with row computation is finished 
                if(count_compute != MATRIX_SIZE) begin 
                    if(local_valid && done_P)begin                                                // deals row computation is finished and output is ready for tb to take
                        clear_acc <= 1;
                        output_valid <= 0;
                        local_valid <= 0;
                        count_x_addr <= 0;
                        count_w_addr <= count_w_addr +1;
                        addr_w <= count_w_addr +1 ;  
                        addr_x <= 0 ;
                        en_acc <= 0;
                        en_pipe <= 0;
                        counter <= 1;
                        count_compute <= count_compute+1;

                    end
                    else if(!output_ready && local_valid )begin                                         // output_ready is clear, disable accumulator until output_ready is set
                        en_acc <= 0;
                    end 
                    else if(local_valid !=1)begin   
                        counter <= counter +1;

                        if(counter + 1 == 3)begin
                            en_acc <= 1;
                            clear_acc <= 0;
                        end                                                                               
                        else if(counter + 1 == unsigned'(VECTOR_SIZE + 3))begin                                  // enalbe the output valid
                            local_valid <= 1;
                            output_valid <= 1;
                            en_acc <= 0;
                        end
                    end
                end
                else begin                                                                              // one set computations is finished
                    if(local_valid && done_out)begin                                                // assert not valid, reset x address, 
                        start_computing <= 0;
                        en_acc <= 0;
                        en_pipe <= 0;
                        clear_acc <= 1;
                        local_valid <= 0;
                        output_valid <= 0;
                        counter <= 0;
                        count_compute <= 0;
                        count_w_addr <= 0;
                        count_x_addr <= 0;
                        addr_w <= 0;
                        addr_x <= 0;
                        local_ready <= 1;
                        input_ready<=1;   
                    end
                    else if(!output_ready && local_valid )begin                                         // if output_ready is cleared and local_valid is set (ready to send data from MAC), disable accumulater until output_ready is set
                        en_acc <= 0;
                    end 
                    else if(local_valid !=1)begin                                                       
                        counter <= counter +1;
                        if(counter +1 == 3)begin
                            en_acc <= 1;
                            clear_acc <= 0;
                        end
                        else if(counter + 1 == unsigned'(VECTOR_SIZE + 3))begin
                            local_valid <= 1;
                            output_valid <= 1;
                            en_acc <= 0;
                        end
                    end
                end
            end
        end
    end
end //ends always_ff

endmodule



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
logic signed[WIDTH-1:0] local_value;

//here is the logic of taking care of the overflow situation
// when output does not make sense with the given inputs
// the output will be ouverwritten/saturated
always_comb begin
    local_value = productAB + preSum;
    if(preSum>0 && productAB >0 && local_value<0) begin
        local_value[WIDTH-1]=0;
            for(int i =0; i<WIDTH-1; i++)begin
                local_value[i] = 1;
            end
    end
    else if(preSum <0 && productAB <0 && local_value>=0) begin
        local_value[WIDTH-1]=1;
            for(int i =0; i<WIDTH-1; i++)begin
                local_value[i] = 0;
            end
    end
    out = local_value;
end
endmodule


// multiplier saturation logic
module multiplier(a_in, b_in, mult_out);

parameter WIDTH = 14;
localparam WIDTH2 = WIDTH +WIDTH ;     // twice width for overflow

input logic signed [WIDTH-1:0] a_in, b_in;
output logic signed [WIDTH-1:0] mult_out;
logic signed [WIDTH2-1:0] local_value;
logic signed [WIDTH-1:0] smallest_value;
logic signed [WIDTH-1:0] biggest_value;

always_comb begin
    smallest_value[WIDTH-1] = 1;
    biggest_value [WIDTH-1] = 0;
    for(int i =0; i < WIDTH-1; i++)begin
        smallest_value[i] = 0;
        biggest_value [i] = 1;
    end

    local_value = a_in * b_in;
    mult_out = 0;
    if(local_value > biggest_value || local_value < smallest_value)begin 
        if((a_in >0 && b_in >0) || (a_in <0 && b_in <0))begin 
                mult_out = biggest_value;
        end
        else if((a_in >0 && b_in <0) || (a_in <0 && b_in >0))begin 
                mult_out = smallest_value;
        end
    end
    else begin
        mult_out = local_value;
    end
    
end   

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

// output value >= 0
module relumod(relu, d_in, d_out);
    parameter WIDTH = 14;
    input logic relu;
    input logic signed[WIDTH-1:0] d_in;
    output logic signed[WIDTH-1:0] d_out;

    always_comb begin
    if(relu == 1)
        if(d_in <= 0)
            d_out = 0; 
        else 
            d_out = d_in;
    else 
        d_out = d_in;
    end
endmodule

// added demux module to output the MAC value in order
module demux(clk,reset,out_ready,local_valid,data,valid_out, out_data, done_out, done_P);

parameter DATA_LENGTH = 14;
parameter MATRIX_ROW_LENGTH = 8;
parameter PIPELINE_LENGTH = 8;

input clk,reset,out_ready,local_valid;
input logic signed [PIPELINE_LENGTH-1:0][DATA_LENGTH-1:0] data;
output logic signed [DATA_LENGTH-1:0] out_data;
output logic valid_out, done_out, done_P;

logic unsigned [$clog2(MATRIX_ROW_LENGTH):0] counter;
logic unsigned [$clog2(PIPELINE_LENGTH):0] counterP;
logic wait_one;

always_ff @(posedge clk) begin
    if (reset) begin
        out_data <= 0;
        counter <= 0;
        counterP <= 0;
        done_out <= 0;
        done_P <= 0;
        valid_out <= 0;
    end
    else if(out_ready && local_valid)begin
        if(counterP == PIPELINE_LENGTH)begin
            if(counter == MATRIX_ROW_LENGTH)begin             // finish one round
            valid_out <= 0;
            out_data <= 0;
            done_out <= 1;
            counter <= 0;
            end
            else begin
            valid_out <= 0;
            out_data <= 0;
            done_P <= 1;
            end
            counterP <= 0 ;
            wait_one <= 1;
        end
        else begin
        if(!wait_one)begin                                // finish one set of input
        done_out <= 0;
        done_P <= 0;
        valid_out <= 1;
        out_data <= data[counterP];
        counter <= counter+1;
        counterP <= counterP+1;
        end
        end
    end
    else if(!local_valid)begin 
        done_out <= 0;
        done_P <= 0;
        wait_one <= 0;
    //    counterP <= 0;
    //    counter <= 0;
    end 
end

endmodule