package transaction_pkg;
`timescale 1ns / 1ps

class transaction;
  
    bit [31:0] addr;
    bit [31:0] data;
    bit write;
    bit [2:0] size;

endclass 
endpackage 