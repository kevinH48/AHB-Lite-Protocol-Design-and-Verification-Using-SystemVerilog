module ahb_slave(HCLK,HRSTn,HWRITE,HSIZE,HBURST,HTRANS,HWDATA,HADDR,HSEL,HREADY,HRESP,HRDATA);

	input HCLK,HRSTn,HWRITE,HSEL;
	input [2:0]HSIZE,HBURST;
	input [1:0]HTRANS;
	input [31:0]HADDR,HWDATA;
	
	output reg HRESP;
	output reg HREADY;
	output reg [31:0]HRDATA;
	
	reg [31:0]ram_mem[0:9];
	
	reg [1:0]wait_cnt;
	
 
	initial
	begin
		ram_mem[0] = 32'd7;
		ram_mem[1] = 32'd0;
		ram_mem[2] = 32'd4;
		ram_mem[3] = 32'd9;
		ram_mem[4] = 32'd14;
		ram_mem[5] = 32'd9;
		ram_mem[6] = 32'd18;
		ram_mem[7] = 32'd23;
		ram_mem[8] = 32'd1;
		ram_mem[9] = 32'd74;
		wait_cnt = 2'b00;
	end 
	
	reg [31:0]addr;
	reg [2:0]size;
	reg write_en;
	reg [1:0]trans_type;

	wire slow_mem;
	assign slow_mem = (HREADY)?(HADDR == 32'd7):(1'b1);
	// inserting wait state for accessing this location

	
	
	always @(posedge HCLK)
	begin
		if(HREADY)
		begin 
			addr <= HADDR;
			size <= HSIZE;
			write_en <= HWRITE;
			trans_type <= HTRANS;
		end 
	end 
	
	

	
	always @(posedge HCLK)
	begin
		if(!HRSTn | !HSEL)
		begin
			HRESP <= 1'b0;
		end 
		else
		begin 
			if(trans_type[1] && HREADY)
			begin 
				HRESP <= 1'b0;
				if(write_en)
				begin
					case(size)
						3'b000 : ram_mem[addr][7:0] <= HWDATA[7:0];
						3'b001 :ram_mem[addr][15:0] <= HWDATA[15:0];
						3'b010 : ram_mem[addr] <= HWDATA;
						default : ram_mem[addr] <= HWDATA;
					endcase 
				end 
			end 
		end 
	end 
	
	always @(*)//combinational read
	begin
		if(!HRSTn | !HSEL)
		begin
			HRDATA = 32'd0;
		end 
		else
		begin
			if(trans_type[1] && HREADY && !write_en)
			begin
				case(size)
						3'b000 : HRDATA = {24'd0,ram_mem[addr][7:0]};
						3'b001 : HRDATA = {16'd0,ram_mem[addr][15:0]};
						3'b010 : HRDATA = ram_mem[addr];
						default : HRDATA = ram_mem[addr];
				endcase 
			end 
			else
			begin
				HRDATA = 32'd0;
			end 
		end 
	end 
	
	
	always @(posedge HCLK)
	begin
		 if(!HRSTn | !HSEL) 
		 begin
			HREADY   <= 1'b1;
			wait_cnt <= 0;
		end
		
		else 
		begin
        if(trans_type[1] && slow_mem && wait_cnt < 2) 
		  begin
            HREADY   <= 1'b0;   
            wait_cnt <= wait_cnt + 1'b1;
        end
        else 
		  begin
            HREADY   <= 1'b1;
            wait_cnt <= 0;
        end
		end
	end 
	




endmodule 