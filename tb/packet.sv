`timescale 1ns / 1ps

package packet_pkg;
class packet;

    rand bit [31:0]HADDR;
    rand bit [31:0]HWDATA;
    rand bit HWRITE;
    rand bit [2:0]HSIZE;
    
    constraint valid_addr 
    {
    HADDR inside {[0:9]}; // for now,10 location memory
    }

    constraint valid_size 
    {
    HSIZE inside {3'b000, 3'b001, 3'b010};
    }
endclass 
endpackage