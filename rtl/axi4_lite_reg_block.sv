// ============================================================================
// axi4_lite_reg_block.sv — Internal register file
//
// Register Map:
//   0x00  CTRL        RW    Control (enable, mode, irq_en)
//   0x04  STATUS      RO    Status (busy, done, error, fifo_level)
//   0x08  DATA_IN     RW    Data input
//   0x0C  DATA_OUT    RO    Data output (loopback of DATA_IN when mode=01)
//   0x10  IRQ_STATUS  W1C   Interrupt status
//   0x14  IRQ_MASK    RW    Interrupt mask
//   0x18  SCRATCH     RW    Scratch pad
//   0x1C  VERSION     RO    Hardcoded IP version
// ============================================================================
module axi4_lite_reg_block
  import axi4_lite_slave_pkg::*;
#(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
)(
  input  logic                    clk,
  input  logic                    rst_n,

  // Register write interface (from AXI slave)
  input  logic                    reg_wr_en,
  input  logic [ADDR_WIDTH-1:0]   reg_wr_addr,
  input  logic [DATA_WIDTH-1:0]   reg_wr_data,
  input  logic [DATA_WIDTH/8-1:0] reg_wr_strb,

  // Register read interface
  input  logic                    reg_rd_en,
  input  logic [ADDR_WIDTH-1:0]   reg_rd_addr,
  output logic [DATA_WIDTH-1:0]   reg_rd_data,
  output logic                    reg_rd_valid,

  // Decode error (invalid address)
  output logic                    reg_error,

  // Hardware-facing signals
  output logic                    ctrl_enable,
  output logic [1:0]              ctrl_mode,
  output logic                    ctrl_irq_en,
  output logic                    irq_out      // Interrupt output
);

  // ---- Register storage ----
  logic [DATA_WIDTH-1:0] reg_ctrl;
  logic [DATA_WIDTH-1:0] reg_status;
  logic [DATA_WIDTH-1:0] reg_data_in;
  logic [DATA_WIDTH-1:0] reg_data_out;
  logic [DATA_WIDTH-1:0] reg_irq_status;
  logic [DATA_WIDTH-1:0] reg_irq_mask;
  logic [DATA_WIDTH-1:0] reg_scratch;

  // ---- Write logic ----
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reg_ctrl       <= '0;
      reg_data_in    <= '0;
      reg_irq_status <= '0;
      reg_irq_mask   <= '0;
      reg_scratch    <= '0;
    end else if (reg_wr_en) begin
      case (reg_wr_addr)
        ADDR_CTRL: begin
          for (int i = 0; i < DATA_WIDTH/8; i++)
            if (reg_wr_strb[i])
              reg_ctrl[i*8 +: 8] <= reg_wr_data[i*8 +: 8];
        end

        ADDR_DATA_IN: begin
          for (int i = 0; i < DATA_WIDTH/8; i++)
            if (reg_wr_strb[i])
              reg_data_in[i*8 +: 8] <= reg_wr_data[i*8 +: 8];
        end

        ADDR_IRQ_STATUS: begin
          // W1C: write-1-to-clear — clear bits where data has 1s
          for (int i = 0; i < DATA_WIDTH/8; i++)
            if (reg_wr_strb[i])
              reg_irq_status[i*8 +: 8] <= reg_irq_status[i*8 +: 8] & ~reg_wr_data[i*8 +: 8];
        end

        ADDR_IRQ_MASK: begin
          for (int i = 0; i < DATA_WIDTH/8; i++)
            if (reg_wr_strb[i])
              reg_irq_mask[i*8 +: 8] <= reg_wr_data[i*8 +: 8];
        end

        ADDR_SCRATCH: begin
          for (int i = 0; i < DATA_WIDTH/8; i++)
            if (reg_wr_strb[i])
              reg_scratch[i*8 +: 8] <= reg_wr_data[i*8 +: 8];
        end

        default: ;  // Writes to RO or invalid addresses are ignored
      endcase
    end
  end

  // ---- Hardware status generation (simplified model) ----
  // In a real design, these come from datapath logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reg_status <= '0;
    end else begin
      reg_status[0]   <= reg_ctrl[0] && (reg_ctrl[2:1] == 2'b10);  // busy when enabled + process mode
      reg_status[1]   <= 1'b0;                                      // done (set by HW event)
      reg_status[2]   <= 1'b0;                                      // error
      reg_status[7:3] <= 5'd0;                                      // fifo_level
    end
  end

  // ---- DATA_OUT: loopback DATA_IN when mode == 01 ----
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      reg_data_out <= '0;
    else if (reg_ctrl[0] && reg_ctrl[2:1] == 2'b01)  // enable + loopback
      reg_data_out <= reg_data_in;
  end

  // ---- Address decode functions (shared by read and write paths) ----
  function automatic logic is_valid_addr(input logic [ADDR_WIDTH-1:0] addr);
    case (addr)
      ADDR_CTRL, ADDR_STATUS, ADDR_DATA_IN, ADDR_DATA_OUT,
      ADDR_IRQ_STATUS, ADDR_IRQ_MASK, ADDR_SCRATCH, ADDR_VERSION:
        return 1'b1;
      default:
        return 1'b0;
    endcase
  endfunction

  // ---- Read data mux (combinational) ----
  logic [DATA_WIDTH-1:0] rd_data_mux;

  always_comb begin
    rd_data_mux = '0;
    case (reg_rd_addr)
      ADDR_CTRL:       rd_data_mux = reg_ctrl;
      ADDR_STATUS:     rd_data_mux = reg_status;
      ADDR_DATA_IN:    rd_data_mux = reg_data_in;
      ADDR_DATA_OUT:   rd_data_mux = reg_data_out;
      ADDR_IRQ_STATUS: rd_data_mux = reg_irq_status;
      ADDR_IRQ_MASK:   rd_data_mux = reg_irq_mask;
      ADDR_SCRATCH:    rd_data_mux = reg_scratch;
      ADDR_VERSION:    rd_data_mux = IP_VERSION;
      default:         rd_data_mux = '0;
    endcase
  end

  // ---- Registered read output + error flag ----
  // Error uses the CORRECT address per operation: wr_addr for writes, rd_addr for reads
  logic rd_addr_invalid, wr_addr_invalid;
  assign rd_addr_invalid = reg_rd_en && !is_valid_addr(reg_rd_addr);
  assign wr_addr_invalid = reg_wr_en && !is_valid_addr(reg_wr_addr);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reg_rd_data  <= '0;
      reg_rd_valid <= 1'b0;
      reg_error    <= 1'b0;
    end else begin
      reg_rd_data  <= rd_data_mux;
      reg_rd_valid <= reg_rd_en;
      reg_error    <= rd_addr_invalid || wr_addr_invalid;
    end
  end

  // ---- Output assignments ----
  assign ctrl_enable = reg_ctrl[0];
  assign ctrl_mode   = reg_ctrl[2:1];
  assign ctrl_irq_en = reg_ctrl[3];

  // IRQ: masked interrupt status, gated by global enable
  assign irq_out = ctrl_irq_en && |(reg_irq_status & reg_irq_mask);

endmodule
