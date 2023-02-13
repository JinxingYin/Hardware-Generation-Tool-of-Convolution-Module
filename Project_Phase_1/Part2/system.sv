//Part2 top level module
//control module controls the datapath enable and validates the output 
module control(clk, reset, valid_in, valid_out, enable_f, enable_ab);
input clk, valid_in, reset;
output logic valid_out, enable_f, enable_ab;

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
	enable_f <= 0;
	valid_out <= 0;
	end
	else begin
    	enable_f <= valid_in;
    	valid_out <= enable_f ;
	end
    
end
endmodule

//adder module add previous result with current result
module adder(preSum, productAB, out);
parameter WIDTH =28;
input signed[WIDTH-1:0] preSum, productAB;
output logic signed[WIDTH-1:0] out;

always_comb begin
	out = productAB + preSum;
end
endmodule

//multiplier module multiply two input
module multiplier(a_in, b_in, mult_out);
	parameter WIDTH = 14;
	parameter WIDTH2 = 28;
   input signed [WIDTH-1:0] a_in, b_in;
   output logic signed [WIDTH2-1:0] mult_out;
   always_comb begin
      mult_out = a_in * b_in;
   end   
endmodule

// register to hold a,b values
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

//register that holds the output value
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

// top level module which instantiate all previous modules into one system
module part2_mac(clk,reset,a,b,valid_in,f,valid_out);
input clk,reset,valid_in;
input signed[13:0] a,b;
output logic signed [27:0] f;
output logic valid_out;
wire controlToReg28b;
wire controlToReg14b;
wire [13:0] regAtoMult;
wire [13:0] regBtoMult;
wire [27:0] multToAdd;
wire [27:0] addToReg28b;
control control_inst(.clk(clk), .reset(reset), .valid_in(valid_in), .valid_out(valid_out), .enable_f(controlToReg28b), .enable_ab(controlToReg14b));
register14b register14b_ainst(.data(a), .en(controlToReg14b), .clk(clk), .reset(reset), .out(regAtoMult));
register14b register14b_binst(.data(b), .en(controlToReg14b), .clk(clk), .reset(reset), .out(regBtoMult));
multiplier multiplier_inst(.a_in(regAtoMult), .b_in(regBtoMult), .mult_out(multToAdd));
adder adder_inst(.preSum(f), .productAB(multToAdd), .out(addToReg28b));
register28b register28b_inst(.data(addToReg28b), .en(controlToReg28b), .clk(clk), .reset(reset), .out(f));
endmodule


//the testbench was originally combined with the system
//but moved to a separated file later

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

initial $monitor($time,, "clk=%b, valid_in =%d, a=%d, b=%d, reset=%d, f=%d, valid_out = %d", clk,valid_in, a, b, reset, f, valid_out);
part2_mac dut(.clk(clk), .reset(reset), .a(a), .b(b), .valid_in(valid_in), .f(f), .valid_out(valid_out));

parameter INPUTSIZE = 40;
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

