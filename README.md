# AHB-Lite-Protocol-Design-and-Verification-Using-SystemVerilog

> A complete, class-based SystemVerilog implementation and verification of the AMBA 3 AHB-Lite bus protocol; featuring a synthesizable slave subsystem and a structured Generator → Driver → Monitor → Scoreboard testbench environment.

## Overview
 
The **Advanced High-performance Bus Lite (AHB-Lite)** protocol is a simplified subset of ARM's AMBA 3 specification. It is the de-facto interconnect standard in ARM Cortex-M series processors (M0, M3, M4) for SoC integration.
 
This project implements:
 
- A **synthesizable AHB-Lite slave subsystem** (DUT) — includes a `1024×32-bit` pipelined slave memory, address decoder, and top-level response multiplexer with default slave error handling.
- A **complete class-based verification environment** — Generator, Driver, Monitor, and Scoreboard with a reference memory model for automated self-checking.
- **71 constrained-random transactions** verified at 100% PASS rate.

## Protocol Background
 
### AMBA Protocol Generations

<img width="835" height="402" alt="7d4105f09496b6e2b21cdae7186109b722d15dba" src="https://github.com/user-attachments/assets/0fcb62a3-fca4-4791-a26d-b07b7c3d40c2" />

```
AMBA 2 ──► APB2, AHB
AMBA 3 ──► APB3, AHB-Lite  ◄── (This Project)
AMBA 4 ──► AXI3/4, AHB5+Lite
AMBA 5 ──► AXI5, ACE5, CHI
```

### AHB-Lite Key Features
 
| Feature | Description |
|---|---|
| **Single Master** | No arbitration logic (no HBUSREQ / HGRANT / HMASTER) |
| **Pipelined Operation** | Address phase of transfer N+1 overlaps data phase of transfer N |
| **Burst Support** | Single, 4-beat, 8-beat, 16-beat INCR and WRAP bursts |
| **Wait States** | Slave can stall master by deasserting `HREADY` |
| **Error Response** | Slave asserts `HRESP=1` to signal illegal access |

 
### AHB-Lite Signal Summary
 
| Signal | Width | Dir | Description |
|---|---|---|---|
| `HCLK` | 1 | In | System clock (100 MHz) |
| `HRESETn` | 1 | In | Active-low synchronous reset |
| `HADDR[31:0]` | 32 | In | Transfer address |
| `HTRANS[1:0]` | 2 | In | Transfer type (IDLE/BUSY/NONSEQ/SEQ) |
| `HWRITE` | 1 | In | Transfer direction — `1`=Write, `0`=Read |
| `HSIZE[2:0]` | 3 | In | Transfer size (byte / halfword / word) |
| `HBURST[2:0]` | 3 | In | Burst type |
| `HPROT[3:0]` | 4 | In | Protection control |
| `HWDATA[31:0]` | 32 | In | Write data |
| `HSEL` | 1 | In | Slave select |
| `HREADYin` | 1 | In | Previous slave ready (pipeline) |
| `HRDATA[31:0]` | 32 | Out | Read data |
| `HRESP` | 1 | Out | Transfer response (`0`=OKAY, `1`=ERROR) |
| `HREADYout` | 1 | Out | Slave ready (`0`=insert wait state) |

### AHB-Lite Pipeline Timing
 
<img width="743" height="213" alt="image" src="https://github.com/user-attachments/assets/612663b8-31f4-4ba1-99b9-085a456e0280" />

### HTRANS Encodings

Transfer types can be classified using `HTANS[1:0]`.
 
| Code | Name | Meaning |
|---|---|---|
| `2'b00` | IDLE | No transfer requested |
| `2'b01` | BUSY | Idle cycle within a burst |
| `2'b10` | NONSEQ | Start of a new transaction |
| `2'b11` | SEQ | Continuation of a burst |

### HSIZE Encodings
 
`HSIZE[2:0]` indicates the width of each data transfer. The full protocol supports up to 1024-bit transfers, but **this project implements and verifies only the three encodings listed below** — matching the byte-lane logic in the DUT and the `valid_size` constraint in the testbench.

| Code | Size | Description | Project Status |
|---|---|---|---|
| `3'b000` | 8-bit | Byte | ✅ Implemented & Verified |
| `3'b001` | 16-bit | Halfword | ✅ Implemented & Verified |
| `3'b010` | 32-bit | Word | ✅ Implemented & Verified |
| `3'b011` | 64-bit | Doubleword | ❌ Not implemented |
| `3'b100` | 128-bit | 4-word line | ❌ Not implemented |
| `3'b101` | 256-bit | 8-word line | ❌ Not implemented |
| `3'b110` | 512-bit | — | ❌ Not implemented |
| `3'b111` | 1024-bit | — | ❌ Not implemented |

### HBURST Encodings
 
`HBURST[2:0]` defines the burst type and length. **This project exercises only `SINGLE` and `INCR` burst types.** The generator's `burst_test` task increments addresses manually over 4 beats using `INCR`; full wrapping and fixed-length burst verification is left as future work.
 
| Code | Type | Description | Project Status |
|---|---|---|---|
| `3'b000` | SINGLE | Single transfer | ✅ Exercised (main random test) |
| `3'b001` | INCR | Incrementing burst, undefined length | ✅ Exercised (burst test) |

> All the other burst types are not implemented.

## Architecture
 
### DUT (Design Under Test)
 
```
┌─────────────────────────────────────────────────┐
│                  ahb_slave_top                  │
│                                                 │
│  ┌──────────────┐    ┌──────────────────────┐   │
│  │ Address      │    │   ahb_slave          │   │
│  │ Decoder      │───►│  (Pipeline + Memory) │   │
│  └──────────────┘    └──────────────────────┘   │
│         │                      │                │
│         └── Default Slave ─────┘                │
│              (ERROR on OOB)                     │
└─────────────────────────────────────────────────┘
```
 
The slave includes:
- **Pipeline register stage**: latches `HADDR`, `HWRITE`, `HSIZE`, `HTRANS` on rising edge when `HREADY=1`
- **Byte-lane write logic**: supports byte (`HSIZE=000`), halfword (`001`), and word (`010`) writes
- **Combinational read path**: zero-wait-state reads
- **Wait-state injection**: automatically inserts 2 wait states for a specific slow-memory address (`HADDR=7`)
- **Error response**: `HRESP=1` for out-of-range accesses

### Testbench Architecture

<img width="624" height="324" alt="image" src="https://github.com/user-attachments/assets/e9d03bd2-0ead-4466-917e-b53ec174e6cc" />

#### Component Responsibilities
 
| Component | Role |
|---|---|
| `packet` | Randomized transaction object with constraints (valid addr range, size) |
| `generator` | Produces write-read pairs, burst sequences, and random transactions |
| `driver` | Converts packet objects into cycle-accurate AHB-Lite pin activity |
| `monitor` | Passively observes bus, reconstructs transactions from pin-level signals |
| `scoreboard` | Maintains `ref_mem[]`, auto-compares every read against expected value |
| `environment` | Orchestrates all components; coordinates fork/join completion |
 
## Simulation Results
 
### Test Configuration
 
| Parameter | Value |
|---|---|
| Simulator | Xilinx Vivado Behavioral Simulation |
| Clock Frequency | 100 MHz (10 ns period) |
| Number of Slaves | 1 |
| Memory per Slave | 1024 × 32-bit words |
| Total Transactions | 71 (constrained random) |
| Write / Read Ratio | 60% / 40% |
| Transfer Type | Single (NONSEQ) |
| Data Width | 32-bit |

### Simulation Waveform 
![376f42eb508d8a7dbffe1ba2cf4552600ae7e1a2](https://github.com/user-attachments/assets/685d71a2-7509-4648-b8e1-142d303f2f7d)


### Scoreboard Final Report
 
```
=============================================================
              AHB-LITE VERIFICATION TEST STARTING
=============================================================
[15]  DRIVER : Reset complete
[25]  GEN [0]  | WRITE | ADDR=0x00000020 | DATA=0xA5B6C7D8
[55]  MON      | WRITE | ADDR=0x00000020 | DATA=0xA5B6C7D8
[55]  SCB [1]  PASS  - WRITE  addr=0x00000020  stored
...
[185] SCB [8]  PASS  - READ   addr=0x00000020  data=0xA5B6C7D8 matches
=============================================================
                   SCOREBOARD FINAL REPORT
=============================================================
  Total Transactions : 71
  PASS               : 71
  FAIL               : 0
=============================================================
                    *** TEST PASSED ***
=============================================================
```
 
### Verified Protocol Behaviours
 
| Behaviour | Observation |
|---|---|
| **Pipelined operation** | Address phase of N+1 overlaps data phase of N — 1 cycle latency |
| **Zero-wait-state reads** | `HREADY=1` always asserted for normal addresses |
| **Wait-state injection** | `HREADY=0` for 2 cycles on slow-memory address (`HADDR=7`) |
| **ERROR response** | `HRESP=1` returned for `HADDR ≥ 0x800` (out-of-range) |
| **IDLE handling** | `HTRANS=IDLE` produces no memory access, `HRESP=OKAY` |
 
---

 
## Test Scenarios
 
| Scenario | Expected Behaviour | Status |
|---|---|---|
| Single Write to slave memory | Data stored; `HRESP=OKAY` | ✅ Verified |
| Single Read from slave memory | Correct data returned | ✅ Verified |
| Write → Read same address | Read returns exactly what was written | ✅ Verified |
| Burst (INCR4) write sequence | 4 consecutive addresses written correctly | ✅ Verified |
| Slow-memory address (`HADDR=7`) | 2 wait states inserted (`HREADY=0`) | ✅ Verified |
| Out-of-range address (`≥ 0x800`) | Default slave returns `HRESP=ERROR` | ✅ Verified |
| IDLE transfer | No memory access; no error | ✅ Verified |
| Random constrained transactions (×30) | All pass scoreboard check | ✅ Verified |
 
 
## Future Work
 
- **Functional Coverage** — Add `covergroup`/`coverpoint` blocks for address, data value, and transfer type coverage closure.
- **Assertion-Based Verification (ABV)** — Add SystemVerilog Assertions (SVA) for protocol-level rules: address alignment, burst sequence integrity, `HREADY` timing.
- **Multi-Slave Topology** — Extend address decoder for 2+ slaves; add interconnect fabric.
- **UVM Migration** — Migrate the testbench to UVM for standardized reuse, phasing, and reporting.
- **Formal Verification** — Verify protocol properties using property-checking tools (JasperGold, SymbiYosys).
