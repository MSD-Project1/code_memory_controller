# code_memory_controller
*/ Introduction
In this project, we have simulated a DDR4 Memory controller with an open page policy. 
The controller will accept request from CPU and turn them into commands. 
The commands are taken from trace file and output is generated in other text file.
A request will be triggered for every DIMM tick. 
For the implementation of the open page policy, if the request is made to the same bank,
bank group, and same row, there is no need for precharge and directly read/write command is issued. 
Each bank maintains the structure of the bank state to check if it has been previously accessed 
or not.Every subsequent access to the same bank will result in a precharge command unless it is 
to the same row which was accessed most recently.
/*


*/
Software used:
Questa Sim v 10.7
/*

*/
Language used:
System Verilog
/*

## Execution in Windows OS

1. Make sure all the files are in same directory:
	-final.sv
	-trace.txt (has all the inputs)
2. Enter the commands in command line of Questasim:
3.	i.vlib work (which contains the files final.sv,trace.txt and dramout.txt was generated).
4.	ii.vlog final.sv
5.	iii.vsim -c tb_test +DEBUG=0 +inputfile=trace.txt +outputfile=dramout.txt
6.	iv.run -all
