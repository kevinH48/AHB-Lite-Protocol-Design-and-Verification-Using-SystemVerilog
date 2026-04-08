package scoreboard_pkg;

`timescale 1ns/1ps
import transaction_pkg::*;

class scoreboard;

    mailbox mon2sb;

    bit [31:0] ref_mem [0:9];

    int pass_count = 0;
    int fail_count = 0;

    int txn_count  = 0;   // TOTAL processed transactions

    function new(mailbox m2s);
        this.mon2sb = m2s;

        // Initial memory
        ref_mem[0] = 32'd7;
        ref_mem[1] = 32'd0;
        ref_mem[2] = 32'd4;
        ref_mem[3] = 32'd9;
        ref_mem[4] = 32'd14;
        ref_mem[5] = 32'd9;
        ref_mem[6] = 32'd18;
        ref_mem[7] = 32'd23;
        ref_mem[8] = 32'd1;
        ref_mem[9] = 32'd74;
    endfunction


    task run();

        transaction tr;
        bit [31:0] expected;

        forever begin
            mon2sb.get(tr);

            txn_count++;   // COUNT EVERYTHING


            // ---------------- WRITE ----------------
            if(tr.write) begin

                case(tr.size)
                    3'b000: ref_mem[tr.addr][7:0]   = tr.data[7:0];
                    3'b001: ref_mem[tr.addr][15:0]  = tr.data[15:0];
                    default: ref_mem[tr.addr]       = tr.data;
                endcase
                pass_count++;
                $display("[SB][WRITE] addr=%0d size=%0b data=%h mem=%h time=%0t",
                          tr.addr, tr.size, tr.data, ref_mem[tr.addr], $time);
            end


            // ---------------- READ ----------------
            else begin

                case(tr.size)
                    3'b000: expected = {24'd0, ref_mem[tr.addr][7:0]};
                    3'b001: expected = {16'd0, ref_mem[tr.addr][15:0]};
                    default: expected = ref_mem[tr.addr];
                endcase

                if(tr.data === expected) begin
                    pass_count++;
                    $display("[SB][PASS] addr=%0d size=%0b exp=%h got=%h time=%0t",
                              tr.addr, tr.size, expected, tr.data, $time);
                end
                else begin
                    fail_count++;
                    $display("[SB][FAIL] addr=%0d size=%0b exp=%h got=%h time=%0t",
                              tr.addr, tr.size, expected, tr.data, $time);
                end
            end

        end
    endtask


    function void report();
        $display("=================================");
        $display("        SCOREBOARD REPORT        ");
        $display(" TOTAL = %0d", txn_count);
        $display(" PASS  = %0d", pass_count);
        $display(" FAIL  = %0d", fail_count);
        $display("=================================");
    endfunction

endclass

endpackage