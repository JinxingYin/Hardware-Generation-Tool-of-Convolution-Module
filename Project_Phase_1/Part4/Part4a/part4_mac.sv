//this is the top level design for part 4 with a pipeline register
//in between multiplier and adder

//changes are needed for contrl module
module control(clk, reset, valid_in, valid_out, enable_f, enable_ab,enable_inter);
input clk, valid_in, reset;
output logic valid_out, enable_f, enable_ab,enable_inter; // enable_inter is used to enable the pipeline register

//enable sequence  a,b reg -> pipeline reg -> f reg
// a,b reg get instantaneous enalbing, the following 
//reg will get the delayed version of enable in signal
// this is accomplished by using always ff block
always_comb begin 
	if(reset)begin
	enable_ab = 0;
	end
	else begin
    	enable_ab = valid_in;
	end
end
always_ff @( posedge clk ) begin 
	if(reset) begin 
	enable_inter <=0;
	enable_f <= 0;
	valid_out <= 0;
	end
	else begin
    	enable_inter <= valid_in;
	enable_f <= enable_inter;
    	valid_out <= enable_f ;
	end
    
end
endmodule


//no change has made from part3 
module adder(preSum, productAB, out);
parameter WIDTH =28;       //parameterize the register size
input signed[WIDTH-1:0] preSum, productAB;
output logic signed[WIDTH-1:0] out;

always_comb begin
	out = productAB + preSum;
	if(preSum > 0 && productAB > 0 && out < 0)begin
	out = signed'(28'b0111111111111111111111111111);  // saturated most positive value
	end
	else if(preSum < 0 && productAB < 0 && out > 0)begin
	out = signed'(28'b1000000000000000000000000000);  //saturated most negative value
	end
end
endmodule

//no change has made from part2
module multiplier(a_in, b_in, mult_out);
parameter WIDTH = 14;         
parameter WIDTH2 = 28;
input signed [WIDTH-1:0] a_in, b_in;
output logic signed [WIDTH2-1:0] mult_out;

always_comb begin
      mult_out = a_in * b_in;
   end   
endmodule

//no change has made from part2
module register14b(data, en, clk, reset, out);
parameter WIDTH = 14;
input logic signed [WIDTH-1:0] data;
input en;
input clk;
input reset;
output logic signed [WIDTH-1:0] out;
  
 always_ff @(posedge clk) begin
      if (reset)
         out <= 0;
      else if (en)
         out <= data;
   end
endmodule

// no change has made from part2
module register28b(data, en, clk, reset, out);
parameter WIDTH = 28;
input logic signed [WIDTH-1:0] data;
input en;
input clk;
input reset;
output logic signed [WIDTH-1:0] out;

always_ff @(posedge clk) begin
      if (reset)
         out <= 0;
      else if (en)
         out <= data;
   end
endmodule


// system module  additional control signals had
// made and few interconnection had been added
module part4_mac(clk,reset,a,b,valid_in,f,valid_out);
input clk,reset,valid_in;
input signed[13:0] a,b;
output logic signed [27:0] f;
output logic valid_out;
wire controlToReg28b;   //enable_f
wire controlToReg14b;   //enable_a enable_b
wire controlToReg28bInter;   // enable_pipeline
wire [13:0] regAtoMult;       // regA to multiplier
wire [13:0] regBtoMult;	     // regB to multiplier
wire [27:0] multTo28bInter;	// multiplication result to pipeline reg
wire [27:0] addToReg28b;	//adder to output reg
wire [27:0] interToAdd;		//pipeline to adder

//instantiation of each module
control control_inst(.clk(clk), .reset(reset), .valid_in(valid_in), .valid_out(valid_out), .enable_f(controlToReg28b), .enable_ab(controlToReg14b), .enable_inter(controlToReg28bInter));
register14b register14b_ainst(.data(a), .en(controlToReg14b), .clk(clk), .reset(reset), .out(regAtoMult));
register14b register14b_binst(.data(b), .en(controlToReg14b), .clk(clk), .reset(reset), .out(regBtoMult));
multiplier multiplier_inst(.a_in(regAtoMult), .b_in(regBtoMult), .mult_out(multTo28bInter));
register28b register28bInter_inst(.data(multTo28bInter), .en(controlToReg28bInter), .clk(clk), .reset(reset), .out(interToAdd));
adder adder_inst(.preSum(f), .productAB(interToAdd), .out(addToReg28b));
register28b register28b_inst(.data(addToReg28b), .en(controlToReg28b), .clk(clk), .reset(reset), .out(f));
endmodule


// previously the testbench was in the same file
/*module my_testbench();

logic valid_in;
logic reset;
logic signed [13:0] a;
logic signed [13:0] b;
logic signed [27:0] f;
logic valid_out;
logic clk;
initial clk = 0;
always #5 clk = ~clk;
initial reset = 1;  //reset at the beginning

initial $monitor($time,, "clk=%b, valid_in =%d, a=%d, b=%d, reset=%d, f=%d, valid_out = %d", clk,valid_in, a, b, reset, f, valid_out);
part4_mac dut(.clk(clk), .reset(reset), .a(a), .b(b), .valid_in(valid_in), .f(f), .valid_out(valid_out));


parameter INPUTSIZE = 4000;
logic [27:0] testData[INPUTSIZE-1:0];
initial $readmemb("inputData",testData);

integer i;
initial begin 
	for(i = 0; i< (INPUTSIZE)/4; i=i+1) begin 
	@(posedge clk);
	#1;
	reset = testData[4*i];
	a = testData[4*i+1][13:0];
	b = testData[4*i+2][13:0];
	valid_in =testData[4*i+3];
	end

@(posedge clk);
@(posedge clk);
@(posedge clk);

$fclose(filehandle);
$finish;
end

integer filehandle = $fopen("outValues");
always @(posedge clk)
	$fdisplay(filehandle, "%d\t%d" , valid_out,f);
endmodule
*/

