module tb_test;

`define tRC 76
`define tRAS 52
`define tRRD_L 6
`define tRRD_S 4
`define tRP 24
`define tRFC 350ns
`define CWL  20
`define tCAS  24
`define tRCD 24
`define tWR 20
`define tRTP 12
`define tCCD_L 8
`define tCCD_S 4
`define tBURST 4
`define tWTR_L 12
`define tWTR_S 4

bit DEBUG;
parameter clk_period = 10;
int fd,fout,cmd;
bit waiting;
bit eof;
bit first_access = 1;
string line,inputfile,outputfile;
 bit clk = 0;
longint unsigned simulation_time = 0;
logic stall;
longint unsigned prev_time = 0;
int val;
string op[0:2] = {"read", "write", "instruction fetch" };

always 
begin
#(5) clk = ~clk;
end
  
  typedef struct {
	bit CurrentState;
	// bit OngoingRequest;
	 logic [14:0] OpenRow;
	 bit [3:0] cmd_issued;
	 bit [7:0] TimeSinceLast [4];
	 
} bankstate;

bankstate BS [4][4];

bit [1:0] last_bg;
//if bg accessed
//last bank accesses
// last accessed op in bank bank group
typedef struct {
	bit accessed;
	bit [1:0] last_bank;
	bit last_op; // 0 for read and 1 for write in a bank group.
} bg_info;

bg_info bg1[4];

typedef struct {
  longint unsigned r_time;
  int operation;
    logic [32:0] addr;
	logic [14:0] row;
	logic [10:0] col;
	 
	logic [1:0] bank;
	logic [1:0] bg;
	// lower col and byte select remaining (0 to 5)
    int time_in_q = 100;
    int dram_op_time;
  } request;
  request r1;

request mem_queue [$:15];
 function print_queue(request q[$:15]);
		$display("queue elements are: ");
		for(int j=0; j<q.size(); j++)
		begin
			$display("request time : %0d, operation : %s, address: %h , time in queue is : %0d", q[j].r_time, op[q[j].operation],q[j].addr,q[j].time_in_q);
		end
 endfunction

initial 
begin
if($value$plusargs("inputfile=%s",inputfile))
if($value$plusargs("outputfile=%s",outputfile))
fd = $fopen(inputfile,"r");
fout = $fopen(outputfile,"w");
if($value$plusargs("DEBUG=%b",DEBUG))
if(fd)
$display("file opened successfully");
else
$display("file could not be opened");

if(fout)
$display("output file opened successfully");
else 
$display("output file could not be opened");
end


function void ACT (longint unsigned t, bit[1:0] bank_group, bit [1:0] bank, bit [14:0] row );
	$fdisplay(fout,"%0d\tACT\t%0h\t%0h\t%0h",t, bank_group,bank,row);
endfunction
function void PRE(longint unsigned t, bit[1:0] bank_group, bit [1:0] bank );
	$fdisplay(fout,"%0d\tPRE\t%0h\t%0h",t, bank_group,bank);
endfunction
function void RD (longint unsigned t,bit[1:0] bank_group, bit [1:0] bank, bit [10:0] col );
	$fdisplay(fout,"%0d\tRD\t%0h\t%0h\t%0h",t, bank_group,bank,col);
endfunction
function void WR (longint unsigned t,bit[1:0] bank_group, bit [1:0] bank, bit [10:0] col );
	$fdisplay(fout,"%0d\tWR\t%0h\t%0h\t%0h",t, bank_group,bank,col);
endfunction
function void POP (longint unsigned t);
	$fdisplay(fout, "request satisfied at time: %0d",t);
endfunction

always @(posedge clk)
begin
   //line = "";
if(fd && !stall) 
begin
   if(!$feof(fd) && !waiting)
	$fgets(line,fd);
   else
	begin
	if(waiting)
	begin
		// $displaly("processor is waiting");
	end
	else if(!eof) // not waiting case
	begin
	line = " ";
	if(DEBUG)
		$display("reached end of file");
	$fclose();
	eof = 1;
	end
	end
end
else
begin
if(stall == 1)
		begin
		if(DEBUG)
			$display("stalled");
		end
else
begin
	if(DEBUG)
		$display("could not open file");
end
end
end

always @(posedge clk)
begin
if(mem_queue.size() != 0)
begin
	simulation_time <= simulation_time + 1;
end
end

assign stall = (mem_queue.size() == 16) ? 1: 0;

always @(posedge clk)
begin
/*if(mem_queue.size() >= 16)
begin
    stall <= 1;
end
else 
begin */
	if(!stall)
	begin
	longint unsigned time_t;
	int signed op_t;
	logic [32:0] add_t;
	val = $sscanf(line,"%d %d %h",time_t,op_t,add_t);
	//$display("current time is %0d and val is %0d",simulation_time, val);
	if(val != 3)
	begin
		if(DEBUG)
		$display("the input line is missing some parameters");
	end
	else 
	begin
		
		if(time_t >= 0 && time_t >= prev_time && op_t >=0 && op_t <=2)
		begin
			// $display("Im here");
			if(mem_queue.size() == 0)
				simulation_time = time_t;
			//request r1;
			
			if(time_t <= simulation_time)
			begin
				waiting = 0;
				r1.r_time = time_t;
				r1.operation = op_t;
				r1.addr = add_t;
				r1.row = add_t[32:18];
				r1.col = {add_t[17:10],add_t[5:3]};
				r1.bank = add_t[9:8];
				r1.bg =  add_t[7:6];
				mem_queue.push_back(r1);
				if(DEBUG)
					$display("element inserted: current time: %0d, request time: %0d, operation: %s and mem address is %h ",simulation_time, time_t, op[op_t],add_t);
				prev_time = time_t;

			end
			else
			begin
				waiting = 1;
		
			end
			//print_queue(mem_queue);
			//$display("the queue len is %0d and the queue elements are %p",mem_queue.size(),mem_queue);
		end
		else 
		begin
		if(DEBUG)
			$display("input values are not valid , val of addr %h",add_t);
		end
	end
		end
else
	begin
		if(DEBUG)
			$display("processor is stalled");
	end
	


end



always @(posedge clk)
	begin
		if(mem_queue.size() != 0 && fout)
		begin
		
			if(mem_queue[0].operation == 0 || mem_queue[0].operation == 2) // read or if
			begin
				if(BS[mem_queue[0].bg][mem_queue[0].bank].CurrentState) // bank gp bank active
				begin
					if(mem_queue[0].row == BS[mem_queue[0].bg][mem_queue[0].bank].OpenRow)
					begin
						// just read 
						if(bg1[mem_queue[0].bg].last_op == 0) // last read
						begin
							if(BS[mem_queue[0].bg][mem_queue[0].bank].TimeSinceLast[2] >= (`tCCD_L*2))
							begin
								// issue read
								
								cmd = 2; // 2 is for a read
								RD(simulation_time,mem_queue[0].bg,mem_queue[0].bank,mem_queue[0].col);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat((`tCAS + `tBURST)*2) @(posedge clk);
								bg1[mem_queue[0].bg].accessed = 1;
								bg1[mem_queue[0].bg].last_bank = mem_queue[0].bank;
								bg1[mem_queue[0].bg].last_op = 0;
								last_bg = mem_queue[0].bg;
								if(DEBUG)
								$display("request served: current time: %0d, operation: %s and mem address is %h ",simulation_time, op[mem_queue[0].operation],mem_queue[0].addr);
								mem_queue.pop_front();
							end
						
						end
						// if last op was write
						else 
						begin
							if(BS[mem_queue[0].bg][mem_queue[0].bank].TimeSinceLast[3] >= (`tWTR_L*2))
							begin
								// issue read
								cmd = 2; // 2 is for a read
								RD(simulation_time,mem_queue[0].bg,mem_queue[0].bank,mem_queue[0].col);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat((`tCAS + `tBURST)*2) @(posedge clk);
								bg1[mem_queue[0].bg].accessed = 1;
								bg1[mem_queue[0].bg].last_bank = mem_queue[0].bank;
								bg1[mem_queue[0].bg].last_op = 0;
								last_bg = mem_queue[0].bg;
								if(DEBUG)
								$display("request served: current time: %0d, operation: %s and mem address is %h ",simulation_time, op[mem_queue[0].operation],mem_queue[0].addr);
								mem_queue.pop_front();
							end
						end
					
					end
					else
					begin
					// diff row - then pre act and read
						// read to precharge or write to precharge 
						if(bg1[mem_queue[0].bg].last_op == 0)
						begin//
							//if(BS[mem_queue[0].bg][mem_queue[0].bank].TimeSinceLast[2] >= (`tRTP*2))
							//begin//
								cmd = 0; // 0 is for a pre
								PRE(simulation_time,mem_queue[0].bg,mem_queue[0].bank);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat(`tRP*2) @(posedge clk);
								cmd = 1; // 1 is for act
								ACT(simulation_time,mem_queue[0].bg,mem_queue[0].bank,mem_queue[0].row);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat(`tRCD*2) @(posedge clk);
								cmd = 2; // 2 is for a read
								RD(simulation_time,mem_queue[0].bg,mem_queue[0].bank,mem_queue[0].col);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat((`tCAS + `tBURST)*2) @(posedge clk);
								bg1[mem_queue[0].bg].accessed = 1;
								bg1[mem_queue[0].bg].last_bank = mem_queue[0].bank;
								bg1[mem_queue[0].bg].last_op = 0;
								BS[mem_queue[0].bg][mem_queue[0].bank].OpenRow = mem_queue[0].row;
								last_bg = mem_queue[0].bg;
								if(DEBUG)
								$display("request served: current time: %0d, operation: %s and mem address is %h ",simulation_time, op[mem_queue[0].operation],mem_queue[0].addr);
								mem_queue.pop_front();
						end
						else
						begin
						// if last op was write
							//if(BS[mem_queue[0].bg][mem_queue[0].bank].TimeSinceLast[3] >= (`tWR*2))
							//begin
								cmd = 0; // 0 is for a pre
								PRE(simulation_time,mem_queue[0].bg,mem_queue[0].bank);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat(`tRP*2) @(posedge clk);
								cmd = 1; // 1 is for act
								ACT(simulation_time,mem_queue[0].bg,mem_queue[0].bank,mem_queue[0].row);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat(`tRCD*2) @(posedge clk);
								cmd = 2; // 2 is for a read
								RD(simulation_time,mem_queue[0].bg,mem_queue[0].bank,mem_queue[0].col);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat((`tCAS + `tBURST)*2) @(posedge clk);
								bg1[mem_queue[0].bg].accessed = 1;
								bg1[mem_queue[0].bg].last_bank = mem_queue[0].bank;
								bg1[mem_queue[0].bg].last_op = 0;
								BS[mem_queue[0].bg][mem_queue[0].bank].OpenRow = mem_queue[0].row;
								last_bg = mem_queue[0].bg;
								if(DEBUG)
								$display("request served: current time: %0d, operation: %s and mem address is %h ",simulation_time, op[mem_queue[0].operation],mem_queue[0].addr);
								mem_queue.pop_front();
							
						end
					end
				end
				else
				begin
					// bank bg never accessed then act and read 
					// cases bg accessed or not accessed if accesses long delays else short.
					if(bg1[mem_queue[0].bg].accessed)
					begin
								cmd = 1; // 1 is for act
								ACT(simulation_time,mem_queue[0].bg,mem_queue[0].bank,mem_queue[0].row);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat(`tRCD*2) @(posedge clk);
								cmd = 2; // 2 is for a read
								RD(simulation_time,mem_queue[0].bg,mem_queue[0].bank,mem_queue[0].col);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat((`tCAS + `tBURST)*2) @(posedge clk);
								bg1[mem_queue[0].bg].accessed = 1;
								bg1[mem_queue[0].bg].last_bank = mem_queue[0].bank;
								bg1[mem_queue[0].bg].last_op = 0;
								BS[mem_queue[0].bg][mem_queue[0].bank].CurrentState = 1;
								BS[mem_queue[0].bg][mem_queue[0].bank].OpenRow = mem_queue[0].row;
								last_bg = mem_queue[0].bg;
								if(DEBUG)
								$display("request served: current time: %0d, operation: %s and mem address is %h ",simulation_time, op[mem_queue[0].operation],mem_queue[0].addr);
								mem_queue.pop_front();
					
					end
					else
					begin
						//if(BS[last_bg][bg1[last_bg].last_bank].TimeSinceLast[1] >= (`tRRD_S*2)|| first_access)
						
								cmd = 1; // 1 is for act
								ACT(simulation_time,mem_queue[0].bg,mem_queue[0].bank,mem_queue[0].row);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat(`tRCD*2 + first_access) @(posedge clk);
								cmd = 2; // 2 is for a read
								RD(simulation_time,mem_queue[0].bg,mem_queue[0].bank,mem_queue[0].col);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat((`tCAS + `tBURST)*2) @(posedge clk);
								bg1[mem_queue[0].bg].accessed = 1;
								bg1[mem_queue[0].bg].last_bank = mem_queue[0].bank;
								bg1[mem_queue[0].bg].last_op = 0;
								BS[mem_queue[0].bg][mem_queue[0].bank].CurrentState = 1;
								BS[mem_queue[0].bg][mem_queue[0].bank].OpenRow = mem_queue[0].row;
								last_bg = mem_queue[0].bg;
								first_access = 0;
								if(DEBUG)
								$display("request served: current time: %0d, operation: %s and mem address is %h ",simulation_time, op[mem_queue[0].operation],mem_queue[0].addr);
								mem_queue.pop_front();
					end
				end
			end
			// in case of write
			else 
				begin
				if(BS[mem_queue[0].bg][mem_queue[0].bank].CurrentState) // bank gp bank active
				begin
					if(mem_queue[0].row == BS[mem_queue[0].bg][mem_queue[0].bank].OpenRow)
					begin
						// just write
						if(bg1[mem_queue[0].bg].last_op == 0)
						begin
							if(BS[mem_queue[0].bg][mem_queue[0].bank].TimeSinceLast[2] >= ((`tCAS + `tBURST + 1 - `CWL)*2))
							begin
								// issue write
								cmd = 3; // 3 is for a write
								WR(simulation_time,mem_queue[0].bg,mem_queue[0].bank,mem_queue[0].col);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat((`CWL + `tBURST)*2) @(posedge clk);
								bg1[mem_queue[0].bg].accessed = 1;
								bg1[mem_queue[0].bg].last_bank = mem_queue[0].bank;
								bg1[mem_queue[0].bg].last_op = 1;
								last_bg = mem_queue[0].bg;
								if(DEBUG)
								$display("request served: current time: %0d, operation: %s and mem address is %h ",simulation_time, op[mem_queue[0].operation],mem_queue[0].addr);
								mem_queue.pop_front();
							end
						
						end
						// if last op was write
						else 
						begin
							if(BS[mem_queue[0].bg][mem_queue[0].bank].TimeSinceLast[3] >= (`tCCD_L*2)) // not given
							begin
								// issue write
								cmd = 3; // 3 is for a wr
								WR(simulation_time,mem_queue[0].bg,mem_queue[0].bank,mem_queue[0].col);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat((`CWL + `tBURST)*2) @(posedge clk);
								bg1[mem_queue[0].bg].accessed = 1;
								bg1[mem_queue[0].bg].last_bank = mem_queue[0].bank;
								bg1[mem_queue[0].bg].last_op = 1;
								last_bg = mem_queue[0].bg;
								if(DEBUG)
								$display("request served: current time: %0d, operation: %s and mem address is %h ",simulation_time, op[mem_queue[0].operation],mem_queue[0].addr);
								mem_queue.pop_front();
							end
						end
					
					end
					else
					begin
					// diff row - then pre act and read
						// read to precharge or write to precharge 
						if(bg1[mem_queue[0].bg].last_op == 0)
						begin
							//if(BS[mem_queue[0].bg][mem_queue[0].bank].TimeSinceLast[2] >= (`tRTP*2))
								cmd = 0; // 0 is for a pre
								PRE(simulation_time,mem_queue[0].bg,mem_queue[0].bank);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat(`tRP*2) @(posedge clk);
								cmd = 1; // 1 is for act
								ACT(simulation_time,mem_queue[0].bg,mem_queue[0].bank,mem_queue[0].row);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat(`tRCD*2) @(posedge clk);
								cmd = 3; // 3 is for a wr
								WR(simulation_time,mem_queue[0].bg,mem_queue[0].bank,mem_queue[0].col);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat((`CWL + `tBURST)*2) @(posedge clk);
								bg1[mem_queue[0].bg].accessed = 1;
								bg1[mem_queue[0].bg].last_bank = mem_queue[0].bank;
								bg1[mem_queue[0].bg].last_op = 1;
								BS[mem_queue[0].bg][mem_queue[0].bank].OpenRow = mem_queue[0].row;
								last_bg = mem_queue[0].bg;
								if(DEBUG)
								$display("request served: current time: %0d, operation: %s and mem address is %h ",simulation_time, op[mem_queue[0].operation],mem_queue[0].addr);
								mem_queue.pop_front();			
						end
						else
						begin
						// if last op was write
							//if(BS[mem_queue[0].bg][mem_queue[0].bank].TimeSinceLast[3] >= (`tWR*2))
								cmd = 0; // 0 is for a pre
								PRE(simulation_time,mem_queue[0].bg,mem_queue[0].bank);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat(`tRP*2) @(posedge clk);
								cmd = 1; // 1 is for act
								ACT(simulation_time,mem_queue[0].bg,mem_queue[0].bank,mem_queue[0].row);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat(`tRCD*2) @(posedge clk);
								cmd = 3; // 3 is for a wr
								WR(simulation_time,mem_queue[0].bg,mem_queue[0].bank,mem_queue[0].col);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat((`CWL + `tBURST)*2) @(posedge clk);
								bg1[mem_queue[0].bg].accessed = 1;
								bg1[mem_queue[0].bg].last_bank = mem_queue[0].bank;
								bg1[mem_queue[0].bg].last_op = 1;
								BS[mem_queue[0].bg][mem_queue[0].bank].OpenRow = mem_queue[0].row;
								last_bg = mem_queue[0].bg;
								if(DEBUG)
								$display("request served: current time: %0d, operation: %s and mem address is %h ",simulation_time, op[mem_queue[0].operation],mem_queue[0].addr);
								mem_queue.pop_front();
						end
					end
				end
				else
				begin
					// bank bg never accessed then act and write
					// cases bg accessed or not accessed if accesses long delays else short.
					if(bg1[mem_queue[0].bg].accessed)
					begin
						//if(BS[mem_queue[0].bg][bg1[mem_queue[0].bg].last_bank].TimeSinceLast[1] >= (`tRRD_L*2))
								cmd = 1; // 1 is for act
								ACT(simulation_time,mem_queue[0].bg,mem_queue[0].bank,mem_queue[0].row);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat(`tRCD*2) @(posedge clk);
								cmd = 3; // 3 is for a wr
								WR(simulation_time,mem_queue[0].bg,mem_queue[0].bank,mem_queue[0].col);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat((`CWL + `tBURST)*2) @(posedge clk);
								bg1[mem_queue[0].bg].accessed = 1;
								bg1[mem_queue[0].bg].last_bank = mem_queue[0].bank;
								bg1[mem_queue[0].bg].last_op = 1;
								BS[mem_queue[0].bg][mem_queue[0].bank].CurrentState = 1;
								BS[mem_queue[0].bg][mem_queue[0].bank].OpenRow = mem_queue[0].row;
								last_bg = mem_queue[0].bg;
								if(DEBUG)
								$display("request served: current time: %0d, operation: %s and mem address is %h ",simulation_time, op[mem_queue[0].operation],mem_queue[0].addr);
								mem_queue.pop_front();
					end
					else
					begin
						//if(BS[last_bg][bg1[last_bg].last_bank].TimeSinceLast[1] >= (`tRRD_S*2) || first_access)
								cmd = 1; // 1 is for act
								ACT(simulation_time,mem_queue[0].bg,mem_queue[0].bank,mem_queue[0].row);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat(`tRCD*2 + first_access) @(posedge clk);
								cmd = 3; // 3 is for a wr
								WR(simulation_time,mem_queue[0].bg,mem_queue[0].bank,mem_queue[0].col);
								BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
								repeat((`CWL + `tBURST)*2) @(posedge clk);
								bg1[mem_queue[0].bg].accessed = 1;
								bg1[mem_queue[0].bg].last_bank = mem_queue[0].bank;
								bg1[mem_queue[0].bg].last_op = 1;
								BS[mem_queue[0].bg][mem_queue[0].bank].CurrentState = 1;
								BS[mem_queue[0].bg][mem_queue[0].bank].OpenRow = mem_queue[0].row;
								last_bg = mem_queue[0].bg;
								first_access = 0;
								if(DEBUG)
								$display("request served: current time: %0d, operation: %s and mem address is %h ",simulation_time, op[mem_queue[0].operation],mem_queue[0].addr);
								mem_queue.pop_front();	
					end
				end	
		end
	end
end
	
always @(posedge clk)
begin
	for(int i=0; i<4; i++)
	begin
		for( int j=0; j<4; j++)
		begin
			if(BS[i][j].CurrentState == 1)
			begin
				for(int k=0; k<4; k++)
				begin
					if(BS[i][j].cmd_issued[k] && BS[i][j].TimeSinceLast[k] != 255)
							BS[i][j].TimeSinceLast[k]++;
				end
			end
		end
	end
end
	
initial
#70000 $stop;
endmodule
