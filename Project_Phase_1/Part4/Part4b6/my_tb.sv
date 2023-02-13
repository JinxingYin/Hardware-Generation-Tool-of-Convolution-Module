//This is the testbench module to test totally 4000 test input
//which is 1000 set of the combination of reset a b valid_in
// targeting MAC with six stage pipeline multiplier

module my_testbench();

logic valid_in;
logic reset;
logic signed [13:0] a;
logic signed [13:0] b;
logic signed [27:0] f;
logic valid_out;
logic clk;
initial clk = 0;
always #5 clk = ~clk;
initial reset = 1;            //reset at the beginning

//text simulation
//initial $monitor($time,, "clk=%b, valid_in =%d, a=%d, b=%d, reset=%d, f=%d, valid_out = %d", clk,valid_in, a, b, reset, f, valid_out);
part4b6_mac dut(.clk(clk), .reset(reset), .a(a), .b(b), .valid_in(valid_in), .f(f), .valid_out(valid_out));

parameter INPUTSIZE = 4000;  // # of input
logic [27:0] testData[INPUTSIZE-1:0];

//reading the input 
initial $readmemb("inputData",testData);

//assign input to corresponding signals
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

//output output data to a txt file

integer filehandle = $fopen("outValues");
always @(posedge clk)
	$fdisplay(filehandle, "%d\t%d" , valid_out,f);
	
endmodule

