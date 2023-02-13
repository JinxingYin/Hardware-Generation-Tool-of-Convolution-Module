// ESE 507 Project 3 Handout Code
// You may not redistribute this code

// Getting started:
// The main() function contains the code to read the parameters. 
// For Parts 1 and 2, your code should be in the genFCLayer() function. Please
// also look at this function to see an example for how to create the ROMs.
//
// For Part 3, your code should be in the genNetwork() function.



#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <cstdlib>
#include <cstring>
#include <assert.h>
#include <math.h>
using namespace std;

// Function prototypes
void printUsage();
void genFCLayer(int M, int N, int T, int R, int P, vector<int>& constvector, string modName, ofstream &os);
void genNetwork(int N, int M1, int M2, int M3, int T, int R, int B, vector<int>& constVector, string modName, ofstream &os);
void readConstants(ifstream &constStream, vector<int>& constvector);
void genROM(vector<int>& constVector, int bits, string modName, ofstream &os, int P, int N);

int main(int argc, char* argv[]) {

   // If the user runs the program without enough parameters, print a helpful message
   // and quit.
   if (argc < 7) {
      printUsage();
      return 1;
   }

   int mode = atoi(argv[1]);

   ifstream const_file;
   ofstream os;
   vector<int> constVector;

   //----------------------------------------------------------------------
   // Look here for Part 1 and 2
   if (((mode == 1) && (argc == 7)) || ((mode == 2) && (argc == 8))) {

      // Mode 1/2: Generate one layer with given dimensions and one testbench

      // --------------- read parameters, etc. ---------------
      int M = atoi(argv[2]);
      int N = atoi(argv[3]);
      int T = atoi(argv[4]);
      int R = atoi(argv[5]);

      int P;

      // If mode == 1, then set P to 1. If mode==2, set P to the value
      // given at the command line.
      if (mode == 1) {
         P=1;
         const_file.open(argv[6]);         
      }
      else {
         P = atoi(argv[6]);
         const_file.open(argv[7]);
      }

      if (const_file.is_open() != true) {
         cout << "ERROR reading constant file " << argv[6] << endl;
         return 1;
      }

      // Read the constants out of the provided file and place them in the constVector vector
      readConstants(const_file, constVector);

      string out_file = "fc_" + to_string(M) + "_" + to_string(N) + "_" + to_string(T) + "_" + to_string(R) + "_" + to_string(P) + ".sv";

      os.open(out_file);
      if (os.is_open() != true) {
         cout << "ERROR opening " << out_file << " for write." << endl;
         return 1;
      }
      // -------------------------------------------------------------

      // call the genFCLayer function you will write to generate this layer
      string modName = "fc_" + to_string(M) + "_" + to_string(N) + "_" + to_string(T) + "_" + to_string(R) + "_" + to_string(P);
      genFCLayer(M, N, T, R, P, constVector, modName, os); 

   }
   //--------------------------------------------------------------------


   // ----------------------------------------------------------------
   // Look here for Part 3
   else if ((mode == 3) && (argc == 10)) {
      // Mode 3: Generate three layers interconnected

      // --------------- read parameters, etc. ---------------
      int N  = atoi(argv[2]);
      int M1 = atoi(argv[3]);
      int M2 = atoi(argv[4]);
      int M3 = atoi(argv[5]);
      int T  = atoi(argv[6]);
      int R  = atoi(argv[7]);
      int B  = atoi(argv[8]);

      const_file.open(argv[9]);
      if (const_file.is_open() != true) {
         cout << "ERROR reading constant file " << argv[8] << endl;
         return 1;
      }
      readConstants(const_file, constVector);

      string out_file = "net_" + to_string(N) + "_" + to_string(M1) + "_" + to_string(M2) + "_" + to_string(M3) + "_" + to_string(T) + "_" + to_string(R) + "_" + to_string(B)+ ".sv";


      os.open(out_file);
      if (os.is_open() != true) {
         cout << "ERROR opening " << out_file << " for write." << endl;
         return 1;
      }
      // -------------------------------------------------------------

      string mod_name = "net_" + to_string(N) + "_" + to_string(M1) + "_" + to_string(M2) + "_" + to_string(M3) + "_" + to_string(T) + "_" + to_string(R) + "_" + to_string(B);

      // generate the design
      genNetwork(N, M1, M2, M3, T, R, B, constVector, mod_name, os);

   }
   //-------------------------------------------------------

   else {
      printUsage();
      return 1;
   }

   // close the output stream
   os.close();

}

// Read values from the constant file into the vector
void readConstants(ifstream &constStream, vector<int>& constvector) {
   string constLineString;
   while(getline(constStream, constLineString)) {
      int val = atoi(constLineString.c_str());
      constvector.push_back(val);
   }
}

// Generate a ROM based on values constVector.
// Values should each be "bits" number of bits.
void genROM(vector<int>& constVector, int bits, string modName, ofstream &os, int P, int N) {

      int numWords = constVector.size()/P;
      int addrBits = ceil(log2(numWords));
      //hardcode the ROM module and split the ROM when P > 1
      for(int i = 0; i < P ;  i++){
      os << "module " << modName << i << "(clk, addr, z);" << endl;
      os << "   input clk;" << endl;
      os << "   input [" << addrBits-1 << ":0] addr;" << endl;
      os << "   output logic signed [" << bits-1 << ":0] z;" << endl;
      os << "   always_ff @(posedge clk) begin" << endl;
      os << "      case(addr)" << endl;
      int index = i * N;
      for (int j = 0; j< numWords; j++) {
         if (constVector[index] < 0)
            os << "        " << j << ": z <= signed'(-" << bits << "'d" << abs(constVector[index]) << ");" << endl;
         else
            os << "        " << j << ": z <= signed'("  << bits << "'d" << constVector[index] << ");" << endl;
            index = index + 1;
            if(index%N==0 && index != 0)
            index = index+(P-1)*N;
      }
      os << "      endcase" << endl << "   end" << endl << "endmodule" << endl << endl;
      }
}

// Parts 1 and 2
// Here is where you add your code to produce a neural network layer.
void genFCLayer(int M, int N, int T, int R, int P, vector<int>& constVector, string modName, ofstream &os) {

   // Check there are enough values in the constant file.
   if (M*N != constVector.size()) {
      cout << "ERROR: constVector does not contain correct amount of data for the requested design" << endl;
      cout << "The design parameters requested require " << M*N+M << " numbers, but the provided data only have " << constVector.size() << " constants" << endl;
      assert(false);
   }

   // Generate a ROM (for W) with constants 0 through M*N-1, with T bits
   string romModName = modName + "_W_rom";
   
    // no major change from part1, changes is done in getROM function
   os << "`include \"system.sv\" " << endl << endl;
   os << "module " << modName << "(clk, reset, input_valid, input_ready, input_data, output_valid, output_ready, output_data);" << endl;
   os << "   // your stuff here!" << endl;
   os << "parameter DATA_LENGTH = " << T << " ;" << endl;
   os << "parameter MATRIX_ROW_LENGTH = " << M << " ;"  << endl;
   os << "parameter PIPELINE_LENGTH = " << P << " ;"  << endl;
   os << "parameter MATRIX_COL_LENGTH = " << N << " ;"  << endl;
   os << "localparam MATRIX_SIZE = MATRIX_ROW_LENGTH * MATRIX_COL_LENGTH/PIPELINE_LENGTH;" << endl;
   os << "localparam VECTOR_SIZE = MATRIX_COL_LENGTH;" << endl;
   os << "input clk, reset, input_valid, output_ready;" << endl;
   os << "input signed [DATA_LENGTH-1:0] input_data;" << endl;
   os << "output signed [DATA_LENGTH-1:0] output_data;" << endl;
   os << "output output_valid, input_ready;" << endl;
   os << "wire [$clog2(VECTOR_SIZE)-1:0]wire_addr_x;" << endl;
   os << "wire wire_wr_en_x;" << endl;
   os << "wire [$clog2(MATRIX_SIZE)-1:0]wire_addr_w;" << endl;
   os << "wire wire_clear_acc;" << endl;
   os << "wire wire_en_acc;" <<endl;
   os << "wire wire_en_pipe;" << endl;
   os << "wire wire_done_out;" << endl;
   os << "logic wire_relu;" << endl;
   os << "wire signed [PIPELINE_LENGTH-1:0][DATA_LENGTH-1:0] wire_demux_data; " << endl;
   os << "wire wire_output_valid;" << endl;
   os << "wire wire_done_P;" << endl;
   for(int i =0 ; i < P; i++){
   os << "wire signed [DATA_LENGTH-1:0] wire_mem_w_data_out" <<  i << ";" << endl;
}
   os << "always_ff @(posedge clk)begin" << endl;
   os << "if(reset)begin" << endl;
   os <<  "wire_relu <= " << R << " ;" << endl;
   os << "end " << endl;
   os << "end " << endl;
   os << "control #(MATRIX_ROW_LENGTH,MATRIX_COL_LENGTH,PIPELINE_LENGTH) control_inst(.clk(clk), .reset(reset), .done_out(wire_done_out), .done_P(wire_done_P), .input_valid(input_valid), .addr_x(wire_addr_x), .wr_en_x(wire_wr_en_x), .addr_w(wire_addr_w), .clear_acc(wire_clear_acc), .en_acc(wire_en_acc), .en_pipe(wire_en_pipe), .input_ready(input_ready), .output_valid(wire_output_valid), .output_ready(output_ready));" << endl;
   for(int i =0; i< P ; i++){
   os <<  romModName << i <<" ROMWInst" << i  << "(.clk(clk), .z(wire_mem_w_data_out" << i << "), .addr(wire_addr_w));" <<endl;
   os << "datapath #(DATA_LENGTH,MATRIX_ROW_LENGTH,MATRIX_COL_LENGTH,PIPELINE_LENGTH) datapath_inst" << i << "(.clk(clk), .reset(reset), .input_data(input_data), .addr_x(wire_addr_x), .wr_en_x(wire_wr_en_x), .value_w(wire_mem_w_data_out" << i << "), .clear_acc(wire_clear_acc), .en_pipe(wire_en_pipe), .en_acc(wire_en_acc), .output_data(wire_demux_data[" << i <<  "]), .relu(wire_relu));" << endl;
}  
// added demux module
   os << "demux #(DATA_LENGTH,MATRIX_ROW_LENGTH,PIPELINE_LENGTH) demux_inst(.clk(clk), .reset(reset), .out_ready(output_ready),.local_valid(wire_output_valid), .data(wire_demux_data), .valid_out(output_valid), .out_data(output_data), .done_out(wire_done_out) , .done_P(wire_done_P));" << endl;
   os << "endmodule" << endl << endl;


   // You will need to generate ROM(s) with values from the pre-stored constant values.
   // Here is code that demonstrates how to do this for the simple case where you want to put all of
   // the matrix values W in one ROM. This is probably what you will need for P=1, but you will want 
   // to change this for P>1. Please also see some examples of splitting these vectors in the Part 3
   // code.
   // one more parameter is passed here P
   genROM(constVector, T, romModName, os, P, N);

   

}

// Part 3: Generate a hardware system with three layers interconnected.
// Layer 1: Input length: N, output length: M1
// Layer 2: Input length: M1, output length: M2
// Layer 3: Input length: M2, output length: M3
// B is the number of multipliers your overall design may use.
// Your goal is to build the fastest design that uses B or fewer multipliers
// constVector holds all the constants for your system (all three layers, in order)
void genNetwork(int N, int M1, int M2, int M3, int T, int R, int B, vector<int>& constVector, string modName, ofstream &os) {

   // Here you will write code to figure out the best values to use for P1, P2, and P3, given
   // B. 
   int P1 = 1; // replace this with your optimized value
   int P2 = 1; // replace this with your optimized value
   int P3 = 1; // replace this with your optimized value

   // output top-level module
   os << "module " << modName << "();" << endl;
   os << "   // this module should instantiate three layers and wire them together" << endl;
   os << "endmodule" << endl;
   
   // -------------------------------------------------------------------------
   // Split up constVector for the three layers
   // layer 1's W matrix is M1 x N
   int start = 0;
   int stop = M1*N;
   vector<int> constVector1(&constVector[start], &constVector[stop]);

   // layer 2's W matrix is M2 x M1
   start = stop;
   stop = start+M2*M1;
   vector<int> constVector2(&constVector[start], &constVector[stop]);

   // layer 3's W matrix is M3 x M2
   start = stop;
   stop = start+M3*M2;
   vector<int> constVector3(&constVector[start], &constVector[stop]);

   if (stop > constVector.size()) {
      os << "ERROR: constVector does not contain enough data for the requested design" << endl;
      os << "The design parameters requested require " << stop << " numbers, but the provided data only have " << constVector.size() << " constants" << endl;
      assert(false);
   }
   // --------------------------------------------------------------------------


   // generate the three layer modules
   string subModName1 = "l1_fc_" + to_string(M1) + "_" + to_string(N) + "_" + to_string(T) + "_" + to_string(R) + "_" + to_string(P1);
   genFCLayer(M1, N, T, R, P1, constVector1, subModName1, os);

   string subModName2 = "l2_fc_" + to_string(M2) + "_" + to_string(M1) + "_" + to_string(T) + "_" + to_string(R) + "_" + to_string(P2);
   genFCLayer(M2, M1, T, R, P2, constVector2, subModName2, os);

   string subModName3 = "l3_fc3_" + to_string(M3) + "_" + to_string(M2) + "_" + to_string(T) + "_" + to_string(R) + "_" + to_string(P3);
   genFCLayer(M3, M2, T, R, P3, constVector3, subModName3, os);

}


void printUsage() {
  cout << "Usage: ./gen MODE ARGS" << endl << endl;

  cout << "   Mode 1 (Part 1): Produce one neural network layer (unparallelized)" << endl;
  cout << "      ./gen 1 M N T R const_file" << endl << endl;

  cout << "   Mode 2 (Part 2): Produce one neural network layer (parallelized)" << endl;
  cout << "      ./gen 2 M N T R P const_file" << endl << endl;

  cout << "   Mode 3 (Part 3): Produce a system with three interconnected layers" << endl;
  cout << "      ./gen 3 N M1 M2 M3 T R B const_file" << endl;
}
