package generator_pkg;

import packet_pkg::*;

class generator;

    mailbox gen2drv;
    mailbox gen2sb;

    int total_pkts;   //  total transactions generated

    function new(mailbox g2d, mailbox g2s);
        this.gen2drv = g2d;
        this.gen2sb  = g2s;
        total_pkts = 0;
    endfunction 


    // -----------------------------
    // 1. WRITE - READ SAME ADDRESS
    // -----------------------------
    task write_read_test(input int num);
        packet p_wr, p_rd;

        repeat(num) 
        begin
            p_wr = new();
            if(!p_wr.randomize()) 
                continue;

            p_wr.HWRITE = 1;

            p_rd = new();
            p_rd.HADDR  = p_wr.HADDR;
            p_rd.HWRITE = 0;
            p_rd.HSIZE  = p_wr.HSIZE;

            gen2drv.put(p_wr); 
            gen2sb.put(p_wr); 
            total_pkts++;
            gen2drv.put(p_rd); 
            gen2sb.put(p_rd); 
            total_pkts++;
        end
    endtask


    // -----------------------------
    // 2. BURST(INCR4)
    // -----------------------------
    task burst_test(input int num);
        packet p;

        repeat(num) begin
            int base = $urandom_range(0,5);

            for(int i=0; i<4; i++) begin
                p = new();
                if(!p.randomize()) continue;

                p.HADDR  = base + i;
                p.HWRITE = 1;
                p.HSIZE  = 3'b010;

                gen2drv.put(p);
                gen2sb.put(p);
                total_pkts++;
            end
        end
    endtask


    // -----------------------------
    // 3. RANDOM
    // -----------------------------
    task random_test(input int num);
        packet p;

        repeat(num) begin
            p = new();
            if(!p.randomize()) continue;

            gen2drv.put(p);
            gen2sb.put(p);
            total_pkts++;
        end
    endtask


    // -----------------------------
    // MAIN RUN
    // -----------------------------
    task run();

        write_read_test(10);
        burst_test(5);
        random_test(30);

        $display("===== GENERATION DONE =====");
        $display("[GEN] TOTAL PACKETS = %0d", total_pkts);

    endtask

endclass

endpackage