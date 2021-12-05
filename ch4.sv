

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

parameter clk_period = 10;
int fd,fout,cmd;
bit waiting;
bit eof;
string line;
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

/*typedef struct {
  longint unsigned r_time;
  int operation;
    logic [32:0] addr;
    int time_in_q = 100;
    int dram_op_time;
  } request; */
  
  typedef struct {
	bit CurrentState;
	// bit OngoingRequest;
	 logic [14:0] OpenRow;
	 bit [3:0] cmd_issued;
	 bit [7:0] TimeSinceLast [4];
	 
} bankstate;

bankstate BS [4][4];

typedef struct {
  longint unsigned r_time;
  int operation;
    logic [32:0] addr;
	logic [14:0] row;
	logic [7:0] col;
	
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
fd = $fopen("trace1.txt","r");
fout = $fopen("dramout.txt","w");
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
function void RD (longint unsigned t,bit[1:0] bank_group, bit [1:0] bank, bit [7:0] col );
	$fdisplay(fout,"%0d\tRD\t%0h\t%0h\t%0h",t, bank_group,bank,col);
endfunction
function void WR (longint unsigned t,bit[1:0] bank_group, bit [1:0] bank, bit [7:0] col );
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
		$display("stalled");
		end
else
$display("could not open file");
end
end

/*always @(posedge clk)
begin
  
  for(int i=0; i< mem_queue.size(); i++)
  begin
		mem_queue[i].time_in_q = mem_queue[i].time_in_q -1;
		
  end
end */

/*always @(posedge clk)
begin
	if(mem_queue.size()!=0)
		begin
			if(mem_queue[0].time_in_q == 0)
			begin
				$display("element popped - current time: %0d, request time: %0d, operation: %s and mem address is %h ",simulation_time, mem_queue[0].r_time, op[mem_queue[0].operation],mem_queue[0].addr);
				mem_queue.pop_front();
			end
			simulation_time <= simulation_time + 1;
			
		end

end */

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
	$display("the input line is missing some parameters");
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
				r1.col = add_t[17:10];
				r1.bank = add_t[9:8];
				r1.bg =  add_t[7:6];
				mem_queue.push_back(r1);
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
		else $display("input values are not valid , val of addr %h",add_t);
	end
		end
else
	$display("processor is stalled");
	


end

	always @(posedge clk)
	begin
		if(mem_queue.size() != 0 && fout)
		begin
			
			BS[mem_queue[0].bg][mem_queue[0].bank].CurrentState = 1;
			cmd = 0; // 0 is precharge
			PRE(simulation_time,mem_queue[0].bg,mem_queue[0].bank);
			BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
			repeat (`tRP*2) @(posedge clk);
			cmd = 1; // 1 is for act
			ACT(simulation_time,mem_queue[0].bg,mem_queue[0].bank,mem_queue[0].row);
			BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
			repeat(`tRCD*2) @(posedge clk);
			cmd = 2; // 2 is for a read
			RD(simulation_time,mem_queue[0].bg,mem_queue[0].bank,mem_queue[0].col);
			BS[mem_queue[0].bg][mem_queue[0].bank].cmd_issued[cmd] = 1;
			repeat((`tCAS + `tBURST)*2) @(posedge clk);
			mem_queue.pop_front();
			//POP(simulation_time);
		end
	end
	
	always @(posedge clk)
	begin
	for(int i=0; i<4; i++)
	begin
		for(int j=0; j<4; j++)
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
#40000 $stop;
endmodule


// queue processing logic
/*




*/

// we are reading one line ahead
// if we put a check read line only when the simulation time is equal to time in line
// not going to work
// if queue is not empty , increment time by one and hold the value of line until simulation time is equal to time in line
// then only change it 
// so don't take values at every posedge but only after simulation time is equal to time in line.

/*

always @(posedge clk)
begin

	)
bit [3:0] cmd;
bit [3:0] bank_active_bit [4][2]; // first four bits for active and other for ongoing request.


    //bank state
	bit [7:0] bank_state [2][2][4];
	for(int i=0; i<2; i++)
	begin
		for(int j=0; j<2; j++)
		begin
			if(bank_active_bit[i][j]) 
			begin1
			for(int k=0; k<4; k++)
			begin 
			
				if(cmd[k] == 1)  // if this command has been issued in this bank and bank group
				begin
				if(bank_state[i][j] != 255)
					bank_state[i][j] = bank_state[i][j] + 1;
				end
				else
				continue;
				
			end
			end
		end
	end
end
*/ 

/*
 function print_queue(request q[$:15])
		$display("queue elements are: \n");
		for(int j=0; j<q.size(); j++)
		begin
			$displaly("request time : %0d, operation : %s, address: %h \n", q[i].r_time, op[q[i].operation],q[i].addr);
		end
 endfunction
*/

/*
task read 
if its a hit just tcl + tburst
if its a empty  trcd + tcl + tburst
miss pre act read 
// in case of read


always @(posedge clk)
begin
for(i=0; i<4; i++)
case(i)
0: pre : cmd[0] 
1: act
2: read 
3: write 

end
// mem read
always @(posedge clk)
begin
if(!hold & mem read)
	if ( BS[mem_queue[0].bg][mem_queue[0].bank].CurrentState ) // active
	begin
	// && !BS[mem_queue[0].bg][mem_queue[0].bank].OngoingRequest put this condition for bank parallelism
		
		if( mem_queue[0].row == BS[mem_queue[0].bg][mem_queue[0].bank].OpenRow) // only read required 
			begin
				mem_queue.dram_op_time = 2*28; // tcl + tburst call read
				// delay tccd_ l
				// BS[mem_queue[0].bg][mem_queue[0].bank].TimeSinceLast[2] >= Tccd_L; // service bit wiill be high
				then only issue a read cmd.
			end
			
		else if (mem_queue[0].row != BS[mem_queue[0].bg][mem_queue[0].bank].OpenRow)
		  begin
				// trtp; if(BS[mem_queue[0].bg][mem_queue[0].bank].TimeSinceLast[2] >= Trtp && this has not been serviced before;)
				 inside if cmd[0] = 1 and hold = 1 && dram_op_time = trp;
				 cmd[1] = 1 and hold = 1 && dram_op_time = trcd;
				 
					pre // trp
				act // trcd
				
				
				read // tcl + tburst
		  end
	end
	else
	
	begin
			1 act
			2 read
	end
    pop element after read.
end
*/
/*
typddef struct {
	bit CurrentState;
	// bit OngoingRequest;
	 logic [14:0] OpenRow;
	 bit [3:0] cmd_issued;
	 bit [7:0] TimeSinceLast [4];
	 
} bankstate;

bankstate BS [4][4];

typedef struct {
  longint unsigned r_time;
  int operation;
    logic [32:0] addr;
	logic [14:0] row = addr[32:18];
	logic [7:0] col = addr[17:10];
	
	logic [1:0] bank = addr[9:8];
	logic [1:0] bg = addr[7:6];
	// lower col and byte select remaining (0 to 5)
    int time_in_q = 100;
    int dram_op_time;
  } request;
  




// prech act read write 








always @(posedge clk)
begin
	for(int i=0; i<4; i++)
	begin
		for(j=0; j<4; j++)
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

add_t[2:0]==0
*/


