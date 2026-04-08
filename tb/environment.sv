`timescale 1ns / 1ps
package environment_pkg;
import driver_pkg::*;
import generator_pkg::*;
import monitor_pkg::*;
import scoreboard_pkg::*;

class environment;
    
    virtual interface ahb_if.tb e_if;
    mailbox gen2drv,gen2sb,mon2sb;
    driver d;
    generator g;
    monitor m;
    scoreboard s;
    
    function new(virtual ahb_if.tb t_if);
        this.e_if = t_if;
    endfunction

    function void build();
        gen2drv = new();
        gen2sb = new();
        mon2sb = new();
        d = new(e_if,gen2drv);
        g = new(gen2drv,gen2sb);
        m = new(e_if,mon2sb);
        s = new(mon2sb);
    endfunction 
    
   task run();

        // Start background components
        fork
            d.run();
            m.run();
            s.run();
        join_none

        // Generate all transactions
        g.run();

        $display("===== GENERATION DONE =====");


        // 1. Driver consumed all packets
        wait(gen2drv.num() == 0);

        // 2. Scoreboard processed all transactions
        wait(s.txn_count == g.total_pkts);

        // 3. Flush pipeline (last data phase)
        repeat(2) @(e_if.cb);

        $display("===== ENV RUN COMPLETE =====");

    endtask


    // REPORT
    function void report();
        s.report();
    endfunction


endclass
endpackage