# AXI4-Lite Slave with UVM RAL Verification

Production-quality AXI4-Lite slave IP with a full UVM testbench featuring the Register Abstraction Layer (RAL). Demonstrates bus protocol handling, register modeling, and industry-standard verification methodology used at Apple, NVIDIA, Intel, and Qualcomm SoC teams.

## Architecture

```
                          AXI4-Lite Bus (5 channels)
                 ┌─────────────────────────────────────────┐
                 │           axi4_lite_slave               │
                 │                                         │
   AW ──────────►│  ┌────────────┐    ┌─────────────────┐  │
   W  ──────────►│  │  Write FSM │───►│                 │  │
   B  ◄──────────│  │ (IDLE/ADDR/│    │  axi4_lite      │  │──► ctrl_enable
                 │  │  DATA/RESP)│    │  _reg_block     │  │──► ctrl_mode
   AR ──────────►│  └────────────┘    │                 │  │──► ctrl_irq_en
   R  ◄──────────│  ┌────────────┐    │  CTRL    (RW)   │  │
                 │  │  Read FSM  │───►│  STATUS  (RO)   │  │──► irq_out
                 │  │ (IDLE/READ/│◄───│  DATA_IN (RW)   │  │
                 │  │  RESP)     │    │  DATA_OUT(RO)   │  │
                 │  └────────────┘    │  IRQ_STAT(W1C)  │  │
                 │                    │  IRQ_MASK(RW)   │  │
                 │                    │  SCRATCH (RW)   │  │
                 │                    │  VERSION (RO)   │  │
                 │                    └─────────────────┘  │
                 └─────────────────────────────────────────┘
```

## Register Map

| Offset | Name | Access | Reset | Description |
|--------|------|--------|-------|-------------|
| 0x00 | CTRL | RW | 0x0 | `[0]` enable, `[2:1]` mode, `[3]` irq_en |
| 0x04 | STATUS | RO | 0x0 | `[0]` busy, `[1]` done, `[2]` error, `[7:3]` fifo_level |
| 0x08 | DATA_IN | RW | 0x0 | Write data register |
| 0x0C | DATA_OUT | RO | 0x0 | Read data (loopback of DATA_IN when mode=01) |
| 0x10 | IRQ_STATUS | W1C | 0x0 | `[0]` done, `[1]` error, `[2]` overflow |
| 0x14 | IRQ_MASK | RW | 0x0 | Interrupt mask (1=enabled) |
| 0x18 | SCRATCH | RW | 0x0 | Scratch pad register |
| 0x1C | VERSION | RO | 0x00010000 | IP version (v1.0.0) |

## Directory Structure

```
axi4_lite_slave/
├── rtl/
│   ├── axi4_lite_slave_pkg.sv      # Register addresses, types
│   ├── axi4_lite_reg_block.sv      # Internal register file (RW/RO/W1C)
│   ├── axi4_lite_slave.sv          # Top: AXI4-Lite protocol FSMs
│   └── axi4_lite_slave_sva.sv      # Protocol compliance assertions
├── tb/
│   ├── axi4_lite_if.sv             # Virtual interface
│   ├── axi4_lite_tb_pkg.sv         # Package (include order)
│   ├── axi4_lite_seq_item.sv       # Transaction
│   ├── axi4_lite_driver.sv         # AXI4-Lite master driver
│   ├── axi4_lite_monitor.sv        # Bus monitor (R+W)
│   ├── axi4_lite_agent.sv          # UVM agent
│   ├── axi4_lite_ral_model.sv      # *** UVM RAL register model ***
│   ├── axi4_lite_ral_adapter.sv    # RAL ↔ AXI4-Lite adapter
│   ├── axi4_lite_scoreboard.sv     # RAL-mirror-based checker
│   ├── axi4_lite_coverage.sv       # Covergroups
│   ├── axi4_lite_env.sv            # Env (agent + RAL + predictor)
│   ├── axi4_lite_sequences.sv      # 7 sequences
│   ├── axi4_lite_base_test.sv      # Base + 6 tests
│   └── tb_top.sv                   # Top harness, clock, reset, bind
└── sim/
    ├── Makefile                    # VCS / Xcelium / Questa
    └── filelist.f                  # Compilation order
```

## UVM Testbench Architecture

```
┌───────────────────────────────────────────────────────────────────┐
│                        uvm_test                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                     axi4_lite_env                           │  │
│  │                                                             │  │
│  │  ┌──────────────┐     ┌─────────────────────────────────┐   │  │
│  │  │  axi4_lite   │     │        UVM RAL                  │   │  │
│  │  │  _agent      │     │  ┌───────────────────────────┐  │   │  │
│  │  │ ┌──────────┐ │     │  │  axi4_lite_reg_model      │  │   │  │
│  │  │ │sequencer │◄┼─────┼──│  (CTRL, STATUS, DATA_IN,  │  │   │  │
│  │  │ │ driver   │ │     │  │   DATA_OUT, IRQ_STATUS,   │  │   │  │
│  │  │ │ monitor──┼─┼──┐  │  │   IRQ_MASK, SCRATCH, VER) │  │   │  │
│  │  │ └──────────┘ │  │  │  └───────────────────────────┘  │   │  │
│  │  └──────────────┘  │  │  ┌───────────┐  ┌───────────┐   │   │  │
│  │                    ├──┼─►│predictor  │  │  adapter  │   │   │  │
│  │                    │  │  │(auto-     │  │ (reg2bus/ │   │   │  │
│  │                    │  │  │ mirror)   │  │  bus2reg) │   │   │  │
│  │                    │  │  └───────────┘  └───────────┘   │   │  │
│  │                    │  └─────────────────────────────────┘   │  │
│  │                    │                                        │  │
│  │                    ├───► scoreboard (RAL mirror check)      │  │
│  │                    └───► coverage (addr × R/W × resp)       │  │
│  └─────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘
```

## SVA Assertions (22 properties)

**Handshake stability** (ARM spec A3.3.1): VALID must not deassert before READY. All payload signals (ADDR, DATA, STRB, RESP) must remain stable while VALID is high and READY is low. Covered for all 5 channels.

**Reset**: BVALID and RVALID must be low after reset.

**Response codes**: Only OKAY (00) and SLVERR (10) are valid for this slave.

**Liveness**: Write and read transactions must complete within 16 cycles.

**Alignment**: AXI4-Lite requires word-aligned addresses.

**9 cover properties**: OKAY/SLVERR for both R/W, AW+W simultaneous, AW-before-W, W-before-AW, back-to-back reads, IRQ assertion.

## Tests

| Test | What it exercises |
|------|-------------------|
| `axi4_lite_ral_frontdoor_test` | RAL write + readback all registers via bus |
| `axi4_lite_ral_field_test` | Field-level set/update/read, loopback verification |
| `axi4_lite_walking_ones_test` | Walking-1s and walking-0s on SCRATCH (bit integrity) |
| `axi4_lite_invalid_addr_test` | SLVERR on 5 invalid addresses |
| `axi4_lite_strobe_test` | WSTRB byte-lane writes |
| `axi4_lite_reset_test` | RAL reset value verification for all registers |


