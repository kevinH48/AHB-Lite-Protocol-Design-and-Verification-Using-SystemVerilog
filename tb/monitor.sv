package monitor_pkg;

import transaction_pkg::*;
`timescale 1ns/1ps

class monitor;

    virtual interface ahb_if.tb m_if;
    mailbox mon2sb;

    transaction pipe_tr;

    function new(virtual ahb_if.tb t_if, mailbox m2s);
        this.m_if   = t_if;
        this.mon2sb = m2s;
    endfunction 


    task run();
        transaction new_tr;

        forever begin
            @(m_if.cb);

            // -------------------------------
            // DATA PHASE
            // -------------------------------
            if(m_if.HREADY && pipe_tr != null) begin

                if(pipe_tr.write)
                    pipe_tr.data = m_if.HWDATA;
                else
                    pipe_tr.data = m_if.HRDATA;

                mon2sb.put(pipe_tr);

                $display("[MON][DATA] addr=%0d wr=%0d size=%0b data=%h time=%0t",
                          pipe_tr.addr,
                          pipe_tr.write,
                          pipe_tr.size,
                          pipe_tr.data,
                          $time);

                pipe_tr = null;
            end


            // -------------------------------
            // ADDRESS PHASE
            // -------------------------------
            if(m_if.HREADY && m_if.HTRANS[1]) begin

                new_tr = new();

                new_tr.addr  = m_if.HADDR;
                new_tr.write = m_if.HWRITE;
                new_tr.size  = m_if.HSIZE;

                pipe_tr = new_tr;

                $display("[MON][ADDR] addr=%0d wr=%0d size=%0b time=%0t",
                          new_tr.addr,
                          new_tr.write,
                          new_tr.size,
                          $time);
            end

        end
    endtask

endclass


endpackage