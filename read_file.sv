module read_file;
int fd = 0;
bit DEBUG;
int line_num = 0;
string line, FILENAME;
int signed time_t, op_t,prev_t = 0;
logic [32:0] add_t;

initial begin
if($value$plusargs("FILENAME=%s",FILENAME))
if($value$plusargs("DEBUG=%b",DEBUG))
fd = $fopen(FILENAME,"r");

if(fd)
begin
if(DEBUG)
begin
	$display("debugging mode enabled");
	while(!$feof(fd))
	begin
	
		time_t = -1;
		op_t = -1;
		add_t = -1;
		line_num++;
		$fgets(line,fd);
		$sscanf(line,"%d %d %h",time_t,op_t,add_t);
		if(time_t == -1 || op_t == -1 || add_t == -1)
			$display("input string at line %0d not valid",line_num);
		else
		begin
			if(op_t > 2 || op_t < 0)
				$display("enter correct operation value");
			if(time_t < prev_t)
				$display("time");
			if(add_t[2:0] != 3'b000)
				$display("The address is not 8-byte aligned");
			if(time_t > prev_t && (op_t >=0 && op_t <=2 && add_t[2:0] == 3'b000))
				begin
				$display("time in cpu clock cycles is %0d, op is %0d and addr is %h",time_t,op_t,add_t);
 				
				prev_t = time_t;
				//$display("previous time is %d",prev_t);
				end
			
		end
		
	end
	
end
else
$display("debugging mode not enabled"); 

$fclose();
end

else
$display("filename could not be found");
end

endmodule