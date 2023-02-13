# Hardware-Generation-Tool-of-Convolution-Module


This Project totally contains 3 phases.

Phase1 folder contains all files related to phase 1. Phase 1 is just building up a multiply-accumulate unit with pipeline technique in RTL. In addition, this unit is overflow free in accumulate which means it will saturate when overflow occurs in addition. By doing pipeline, the latency is increased, however the throughput is also increased. The input/output files are data to verify the correctness of the unit. The output.txt is the synthesis report which contains the power, area, critical path analysis.


Phase2 folder contains files for phase 2. In phase 2, the system upgrades to holding multiple multiply-accumulate unit parallel to each other. Thus, a control module and a data path module is created for handshaking and acknowledge purpose.
The design is aim to maximize the throughput with given input data rate. I accomplished this by combining parallellism and pipeline technique for the system. This two greatly improve the throughput of the system. Furthermore, by overlapping the outputting old output values and storing new input data, the system also gains some relative small improvement.

Lastly, phase3 was the final wrap up of the whole system. The multiply-accumulate unit can be seen as a convolution nerual network. In phase 3, a piece of code written in c was used. The purpose of that code was helping us automatically generate the hardware system verilog code as much as possible. In addition to that, an optimization method was written in that program which will give the best hyper-parameters for the convolution neural network such as numbers of layers, numbers of parallelism and numbers of input training set for each parallel line. The result of my program although is not the best optimal based on the difference between my hyppthesis and the real optimization algorithm, it was still about 80-90 percent close as the optimal one created by my professor. I attached my report to just in case if anyone is interested about some analysis of the whole system. Thank you for reading the code, Have fun!
