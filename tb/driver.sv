`timescale 1ns / 1ps
package driver_pkg;
import packet_pkg::*;
class driver;

    virtual interface ahb_if.tb d_if;
    mailbox gen2drv;
    
    function new(virtual ahb_if.tb t_if,mailbox g2d);
        this.d_if = t_if; 
        this.gen2drv = g2d;
    endfunction 
    

    task run();

        packet curr_pkt;
        packet next_pkt;
    
        bit curr_valid = 0;
        bit next_valid = 0;
    
        d_if.cb.HBURST <= 3'b000;
    
       
        // Preload first transaction
        gen2drv.get(curr_pkt);
        curr_valid = 1;
    
        @(d_if.cb);
    
        // First address phase
        d_if.cb.HADDR  <= curr_pkt.HADDR;
        d_if.cb.HWRITE <= curr_pkt.HWRITE;
        d_if.cb.HTRANS <= 2'b10; // NONSEQ
        d_if.cb.HSIZE  <= curr_pkt.HSIZE;
    
        forever begin
    
           
            // Fetch next packet EARLY
            if(!next_valid) begin
                gen2drv.get(next_pkt);   
                next_valid = 1;
            end
    
 
            // DATA PHASE
            @(d_if.cb);
    
            if(curr_valid && curr_pkt.HWRITE)
                d_if.cb.HWDATA <= curr_pkt.HWDATA;
    
            
            // ADDRESS PHASE (next_pkt)
            if(d_if.cb.HREADY) begin
    
                if(next_valid) begin
                    d_if.cb.HADDR  <= next_pkt.HADDR;
                    d_if.cb.HWRITE <= next_pkt.HWRITE;
                    d_if.cb.HTRANS <= 2'b11; // SEQ
                    d_if.cb.HSIZE  <= next_pkt.HSIZE;
    
                    // Move pipeline
                    curr_pkt   = next_pkt;
                    curr_valid = 1;
                    next_valid = 0;
    
                end else begin
                    // No more packets - IDLE
                    d_if.cb.HTRANS <= 2'b00;
                    curr_valid = 0;
                end
    
            end
            // else: HOLD automatically
    
        end
    endtask 

endclass 
endpackage 
