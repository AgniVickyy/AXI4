// ============================================================================
// axi4_lite_slave_pkg.sv — Register map definitions and shared types
// ============================================================================
package axi4_lite_slave_pkg;

  // ---- Register address offsets ----
  localparam logic [7:0] ADDR_CTRL       = 8'h00;  // RW   Control
  localparam logic [7:0] ADDR_STATUS     = 8'h04;  // RO   Status
  localparam logic [7:0] ADDR_DATA_IN    = 8'h08;  // RW   Data input
  localparam logic [7:0] ADDR_DATA_OUT   = 8'h0C;  // RO   Data output
  localparam logic [7:0] ADDR_IRQ_STATUS = 8'h10;  // W1C  Interrupt status
  localparam logic [7:0] ADDR_IRQ_MASK   = 8'h14;  // RW   Interrupt mask
  localparam logic [7:0] ADDR_SCRATCH    = 8'h18;  // RW   Scratch pad
  localparam logic [7:0] ADDR_VERSION    = 8'h1C;  // RO   IP version

  // ---- CTRL register bit fields ----
  // [0]    enable    — block enable
  // [2:1]  mode      — operating mode (00=idle, 01=loopback, 10=process, 11=rsvd)
  // [3]    irq_en    — global interrupt enable
  // [31:4] reserved

  // ---- STATUS register bit fields ----
  // [0]    busy
  // [1]    done
  // [2]    error
  // [7:3]  fifo_level (0-31)
  // [31:8] reserved

  // ---- IRQ_STATUS / IRQ_MASK bit fields ----
  // [0]    done_irq
  // [1]    error_irq
  // [2]    overflow_irq
  // [31:3] reserved

  // ---- Version ----
  localparam logic [31:0] IP_VERSION = 32'h0001_0000;  // v1.0.0

  // ---- AXI response codes ----
  typedef enum logic [1:0] {
    AXI_RESP_OKAY   = 2'b00,
    AXI_RESP_EXOKAY = 2'b01,
    AXI_RESP_SLVERR = 2'b10,
    AXI_RESP_DECERR = 2'b11
  } axi_resp_e;

endpackage
