`timescale 1ns / 1ps
import environment_pkg::*;

module top;

    logic HCLK;
    ahb_if aif(HCLK);
   ahb_slave dut(
    .HCLK   (HCLK),
    .HRSTn  (aif.HRSTn),
    .HWRITE (aif.HWRITE),
    .HSIZE  (aif.HSIZE),
    .HBURST (aif.HBURST),
    .HTRANS (aif.HTRANS),
    .HWDATA (aif.HWDATA),
    .HADDR  (aif.HADDR),
    .HSEL   (aif.HSEL),
    .HREADY (aif.HREADY),
    .HRESP  (aif.HRESP),
    .HRDATA (aif.HRDATA)
);
    
   initial 
   begin
    HCLK = 0;
   end

    always 
    begin
    #5 HCLK = ~HCLK;
    end
    
    environment e;
    
    initial
    begin
        e = new(aif);
        e.build();
        aif.HRSTn = 0;
        #10;
        aif.HSEL = 1;
        aif.HRSTn = 1;
  
        e.run();
        e.report();
        #100;
        $finish;
    end 


endmodule
