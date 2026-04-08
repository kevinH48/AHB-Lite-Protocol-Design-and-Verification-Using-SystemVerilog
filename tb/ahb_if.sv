interface ahb_if(input logic HCLK);

    logic HRSTn,HWRITE,HSEL;
    logic [2:0]HSIZE,HBURST;
    logic [1:0]HTRANS;
    logic [31:0]HADDR,HWDATA;
    
    logic HRESP;
    logic HREADY;
    logic [31:0]HRDATA;
    
    clocking cb @(posedge HCLK);
        default input #1ns output #1ns;
    
        output HADDR, HWRITE, HTRANS, HSIZE, HWDATA, HBURST;
        input  HREADY, HRESP, HRDATA;
    endclocking
    
    modport tb(clocking cb, input HCLK, output HWRITE, HBURST, HSIZE, HTRANS, HADDR, HWDATA, HRSTn,input HREADY, HRESP, HRDATA);
    
    
endinterface 
