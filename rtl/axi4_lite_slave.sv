// ============================================================================
// axi4_lite_slave.sv — Top-level AXI4-Lite Slave
//
// Implements the 5-channel AXI4-Lite protocol:
//   AW (Write Address), W (Write Data), B (Write Response)
//   AR (Read Address),  R (Read Data)
//
// Features:
//   - Parameterized data/address widths
//   - WSTRB support for byte-lane writes
//   - SLVERR on invalid address decode
//   - Independent read/write channels (no blocking)
//   - Registered outputs for timing closure
// ============================================================================
module axi4_lite_slave
  import axi4_lite_slave_pkg::*;
#(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
)(
  input  logic                    aclk,
  input  logic                    aresetn,

  // ---- Write Address Channel ----
  input  logic [ADDR_WIDTH-1:0]   s_axi_awaddr,
  input  logic [2:0]              s_axi_awprot,
  input  logic                    s_axi_awvalid,
  output logic                    s_axi_awready,

  // ---- Write Data Channel ----
  input  logic [DATA_WIDTH-1:0]   s_axi_wdata,
  input  logic [DATA_WIDTH/8-1:0] s_axi_wstrb,
  input  logic                    s_axi_wvalid,
  output logic                    s_axi_wready,

  // ---- Write Response Channel ----
  output logic [1:0]              s_axi_bresp,
  output logic                    s_axi_bvalid,
  input  logic                    s_axi_bready,

  // ---- Read Address Channel ----
  input  logic [ADDR_WIDTH-1:0]   s_axi_araddr,
  input  logic [2:0]              s_axi_arprot,
  input  logic                    s_axi_arvalid,
  output logic                    s_axi_arready,

  // ---- Read Data Channel ----
  output logic [DATA_WIDTH-1:0]   s_axi_rdata,
  output logic [1:0]              s_axi_rresp,
  output logic                    s_axi_rvalid,
  input  logic                    s_axi_rready,

  // ---- Side-band outputs ----
  output logic                    irq_out
);

  // ==========================================================================
  // Internal signals
  // ==========================================================================
  logic                    reg_wr_en;
  logic [ADDR_WIDTH-1:0]   reg_wr_addr;
  logic [DATA_WIDTH-1:0]   reg_wr_data;
  logic [DATA_WIDTH/8-1:0] reg_wr_strb;

  logic                    reg_rd_en;
  logic [ADDR_WIDTH-1:0]   reg_rd_addr;
  logic [DATA_WIDTH-1:0]   reg_rd_data;
  logic                    reg_rd_valid;
  logic                    reg_error;

  logic                    ctrl_enable;
  logic [1:0]              ctrl_mode;
  logic                    ctrl_irq_en;

  // ==========================================================================
  // Write Channel State Machine
  // ==========================================================================
  typedef enum logic [1:0] {
    WR_IDLE,
    WR_ADDR_WAIT,    // Have data, waiting for address
    WR_DATA_WAIT,    // Have address, waiting for data
    WR_RESP
  } wr_state_e;

  wr_state_e wr_state, wr_state_next;

  logic [ADDR_WIDTH-1:0]   wr_addr_lat;
  logic [DATA_WIDTH-1:0]   wr_data_lat;
  logic [DATA_WIDTH/8-1:0] wr_strb_lat;

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn)
      wr_state <= WR_IDLE;
    else
      wr_state <= wr_state_next;
  end

  always_comb begin
    wr_state_next = wr_state;
    case (wr_state)
      WR_IDLE: begin
        if (s_axi_awvalid && s_axi_wvalid)
          wr_state_next = WR_RESP;
        else if (s_axi_awvalid)
          wr_state_next = WR_DATA_WAIT;
        else if (s_axi_wvalid)
          wr_state_next = WR_ADDR_WAIT;
      end
      WR_ADDR_WAIT:
        if (s_axi_awvalid)
          wr_state_next = WR_RESP;
      WR_DATA_WAIT:
        if (s_axi_wvalid)
          wr_state_next = WR_RESP;
      WR_RESP:
        if (s_axi_bready)
          wr_state_next = WR_IDLE;
    endcase
  end

  // Latch address/data as they arrive
  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      wr_addr_lat <= '0;
      wr_data_lat <= '0;
      wr_strb_lat <= '0;
    end else begin
      if (s_axi_awvalid && s_axi_awready)
        wr_addr_lat <= s_axi_awaddr;
      if (s_axi_wvalid && s_axi_wready) begin
        wr_data_lat <= s_axi_wdata;
        wr_strb_lat <= s_axi_wstrb;
      end
    end
  end

  // AW/W channel ready signals
  assign s_axi_awready = (wr_state == WR_IDLE) || (wr_state == WR_ADDR_WAIT);
  assign s_axi_wready  = (wr_state == WR_IDLE) || (wr_state == WR_DATA_WAIT);

  // Write to register block
  logic wr_both_valid;
  assign wr_both_valid = (wr_state == WR_IDLE) && s_axi_awvalid && s_axi_wvalid;

  assign reg_wr_en   = (wr_state_next == WR_RESP) && (wr_state != WR_RESP);
  assign reg_wr_addr = wr_both_valid ? s_axi_awaddr : wr_addr_lat;
  assign reg_wr_data = wr_both_valid ? s_axi_wdata  : wr_data_lat;
  assign reg_wr_strb = wr_both_valid ? s_axi_wstrb  : wr_strb_lat;

  // Write response
  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      s_axi_bvalid <= 1'b0;
      s_axi_bresp  <= 2'b00;
    end else begin
      if (wr_state_next == WR_RESP && wr_state != WR_RESP) begin
        s_axi_bvalid <= 1'b1;
        s_axi_bresp  <= reg_error ? AXI_RESP_SLVERR : AXI_RESP_OKAY;
      end else if (s_axi_bready && s_axi_bvalid) begin
        s_axi_bvalid <= 1'b0;
      end
    end
  end

  // ==========================================================================
  // Read Channel State Machine
  // ==========================================================================
  typedef enum logic [1:0] {
    RD_IDLE,
    RD_READ,
    RD_RESP
  } rd_state_e;

  rd_state_e rd_state, rd_state_next;

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn)
      rd_state <= RD_IDLE;
    else
      rd_state <= rd_state_next;
  end

  always_comb begin
    rd_state_next = rd_state;
    case (rd_state)
      RD_IDLE:
        if (s_axi_arvalid)
          rd_state_next = RD_READ;
      RD_READ:
        rd_state_next = RD_RESP;  // 1 cycle for registered read
      RD_RESP:
        if (s_axi_rready)
          rd_state_next = RD_IDLE;
    endcase
  end

  assign s_axi_arready = (rd_state == RD_IDLE);

  // Register read
  logic [ADDR_WIDTH-1:0] rd_addr_lat;

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn)
      rd_addr_lat <= '0;
    else if (s_axi_arvalid && s_axi_arready)
      rd_addr_lat <= s_axi_araddr;
  end

  assign reg_rd_en   = (rd_state == RD_IDLE) && s_axi_arvalid;
  assign reg_rd_addr = (rd_state == RD_IDLE) ? s_axi_araddr : rd_addr_lat;

  // Read response
  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      s_axi_rvalid <= 1'b0;
      s_axi_rdata  <= '0;
      s_axi_rresp  <= 2'b00;
    end else begin
      if (rd_state == RD_READ) begin
        s_axi_rvalid <= 1'b1;
        s_axi_rdata  <= reg_rd_data;
        s_axi_rresp  <= reg_error ? AXI_RESP_SLVERR : AXI_RESP_OKAY;
      end else if (s_axi_rready && s_axi_rvalid) begin
        s_axi_rvalid <= 1'b0;
      end
    end
  end

  // ==========================================================================
  // Register Block Instance
  // ==========================================================================
  axi4_lite_reg_block #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH)
  ) u_reg_block (
    .clk          (aclk),
    .rst_n        (aresetn),
    .reg_wr_en    (reg_wr_en),
    .reg_wr_addr  (reg_wr_addr),
    .reg_wr_data  (reg_wr_data),
    .reg_wr_strb  (reg_wr_strb),
    .reg_rd_en    (reg_rd_en),
    .reg_rd_addr  (reg_rd_addr),
    .reg_rd_data  (reg_rd_data),
    .reg_rd_valid (reg_rd_valid),
    .reg_error    (reg_error),
    .ctrl_enable  (ctrl_enable),
    .ctrl_mode    (ctrl_mode),
    .ctrl_irq_en  (ctrl_irq_en),
    .irq_out      (irq_out)
  );

endmodule
