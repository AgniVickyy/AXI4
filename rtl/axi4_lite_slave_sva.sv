// ============================================================================
// axi4_lite_slave_sva.sv — AXI4-Lite Protocol Compliance Assertions
//
// Covers ARM AMBA AXI4-Lite specification rules.
// Bind to axi4_lite_slave in testbench:
//   bind axi4_lite_slave axi4_lite_slave_sva #(...) u_sva (.*);
// ============================================================================
module axi4_lite_slave_sva #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
)(
  input logic                    aclk,
  input logic                    aresetn,

  // Write Address
  input logic [ADDR_WIDTH-1:0]   s_axi_awaddr,
  input logic [2:0]              s_axi_awprot,
  input logic                    s_axi_awvalid,
  input logic                    s_axi_awready,

  // Write Data
  input logic [DATA_WIDTH-1:0]   s_axi_wdata,
  input logic [DATA_WIDTH/8-1:0] s_axi_wstrb,
  input logic                    s_axi_wvalid,
  input logic                    s_axi_wready,

  // Write Response
  input logic [1:0]              s_axi_bresp,
  input logic                    s_axi_bvalid,
  input logic                    s_axi_bready,

  // Read Address
  input logic [ADDR_WIDTH-1:0]   s_axi_araddr,
  input logic [2:0]              s_axi_arprot,
  input logic                    s_axi_arvalid,
  input logic                    s_axi_arready,

  // Read Data
  input logic [DATA_WIDTH-1:0]   s_axi_rdata,
  input logic [1:0]              s_axi_rresp,
  input logic                    s_axi_rvalid,
  input logic                    s_axi_rready,

  // Sideband
  input logic                    irq_out
);

  // =========================================================================
  // AXI4-LITE HANDSHAKE RULES (ARM spec A3.3.1)
  // "VALID must not depend on READY. READY may depend on VALID."
  // =========================================================================

  // ---- AW channel: AWVALID stable until AWREADY ----
  property p_awvalid_stable;
    @(posedge aclk) disable iff (!aresetn)
    s_axi_awvalid && !s_axi_awready |=> s_axi_awvalid;
  endproperty
  a_awvalid_stable: assert property (p_awvalid_stable)
    else $error("SVA: AWVALID deasserted before AWREADY");

  property p_awaddr_stable;
    @(posedge aclk) disable iff (!aresetn)
    s_axi_awvalid && !s_axi_awready |=> $stable(s_axi_awaddr);
  endproperty
  a_awaddr_stable: assert property (p_awaddr_stable)
    else $error("SVA: AWADDR changed while AWVALID waiting for AWREADY");

  property p_awprot_stable;
    @(posedge aclk) disable iff (!aresetn)
    s_axi_awvalid && !s_axi_awready |=> $stable(s_axi_awprot);
  endproperty
  a_awprot_stable: assert property (p_awprot_stable)
    else $error("SVA: AWPROT changed while AWVALID waiting for AWREADY");

  // ---- W channel: WVALID stable until WREADY ----
  property p_wvalid_stable;
    @(posedge aclk) disable iff (!aresetn)
    s_axi_wvalid && !s_axi_wready |=> s_axi_wvalid;
  endproperty
  a_wvalid_stable: assert property (p_wvalid_stable)
    else $error("SVA: WVALID deasserted before WREADY");

  property p_wdata_stable;
    @(posedge aclk) disable iff (!aresetn)
    s_axi_wvalid && !s_axi_wready |=> $stable(s_axi_wdata);
  endproperty
  a_wdata_stable: assert property (p_wdata_stable)
    else $error("SVA: WDATA changed while WVALID waiting for WREADY");

  property p_wstrb_stable;
    @(posedge aclk) disable iff (!aresetn)
    s_axi_wvalid && !s_axi_wready |=> $stable(s_axi_wstrb);
  endproperty
  a_wstrb_stable: assert property (p_wstrb_stable)
    else $error("SVA: WSTRB changed while WVALID waiting for WREADY");

  // ---- B channel: BVALID stable until BREADY ----
  property p_bvalid_stable;
    @(posedge aclk) disable iff (!aresetn)
    s_axi_bvalid && !s_axi_bready |=> s_axi_bvalid;
  endproperty
  a_bvalid_stable: assert property (p_bvalid_stable)
    else $error("SVA: BVALID deasserted before BREADY");

  property p_bresp_stable;
    @(posedge aclk) disable iff (!aresetn)
    s_axi_bvalid && !s_axi_bready |=> $stable(s_axi_bresp);
  endproperty
  a_bresp_stable: assert property (p_bresp_stable)
    else $error("SVA: BRESP changed while BVALID waiting for BREADY");

  // ---- AR channel: ARVALID stable until ARREADY ----
  property p_arvalid_stable;
    @(posedge aclk) disable iff (!aresetn)
    s_axi_arvalid && !s_axi_arready |=> s_axi_arvalid;
  endproperty
  a_arvalid_stable: assert property (p_arvalid_stable)
    else $error("SVA: ARVALID deasserted before ARREADY");

  property p_araddr_stable;
    @(posedge aclk) disable iff (!aresetn)
    s_axi_arvalid && !s_axi_arready |=> $stable(s_axi_araddr);
  endproperty
  a_araddr_stable: assert property (p_araddr_stable)
    else $error("SVA: ARADDR changed while ARVALID waiting for ARREADY");

  // ---- R channel: RVALID stable until RREADY ----
  property p_rvalid_stable;
    @(posedge aclk) disable iff (!aresetn)
    s_axi_rvalid && !s_axi_rready |=> s_axi_rvalid;
  endproperty
  a_rvalid_stable: assert property (p_rvalid_stable)
    else $error("SVA: RVALID deasserted before RREADY");

  property p_rdata_stable;
    @(posedge aclk) disable iff (!aresetn)
    s_axi_rvalid && !s_axi_rready |=> $stable(s_axi_rdata);
  endproperty
  a_rdata_stable: assert property (p_rdata_stable)
    else $error("SVA: RDATA changed while RVALID waiting for RREADY");

  property p_rresp_stable;
    @(posedge aclk) disable iff (!aresetn)
    s_axi_rvalid && !s_axi_rready |=> $stable(s_axi_rresp);
  endproperty
  a_rresp_stable: assert property (p_rresp_stable)
    else $error("SVA: RRESP changed while RVALID waiting for RREADY");

  // =========================================================================
  // RESET ASSERTIONS (ARM spec A3.1.2)
  // =========================================================================

  property p_reset_awready;
    @(posedge aclk) !aresetn |-> ##1 (!s_axi_bvalid && !s_axi_rvalid);
  endproperty
  a_reset_outputs: assert property (p_reset_awready)
    else $error("SVA: BVALID or RVALID asserted after reset");

  // =========================================================================
  // RESPONSE RULES
  // =========================================================================

  // Write response must follow a complete write transaction
  property p_bresp_after_write;
    @(posedge aclk) disable iff (!aresetn)
    $rose(s_axi_bvalid) |-> (s_axi_bresp inside {2'b00, 2'b10});
  endproperty
  a_bresp_valid: assert property (p_bresp_after_write)
    else $error("SVA: BRESP has invalid value (EXOKAY/DECERR not supported in this slave)");

  // Read response code validity
  property p_rresp_valid;
    @(posedge aclk) disable iff (!aresetn)
    s_axi_rvalid |-> (s_axi_rresp inside {2'b00, 2'b10});
  endproperty
  a_rresp_valid: assert property (p_rresp_valid)
    else $error("SVA: RRESP has invalid value");

  // =========================================================================
  // LIVENESS — transactions must complete
  // =========================================================================

  property p_write_completes;
    @(posedge aclk) disable iff (!aresetn)
    (s_axi_awvalid && s_axi_awready) |-> ##[1:16] (s_axi_bvalid && s_axi_bready);
  endproperty
  a_write_completes: assert property (p_write_completes)
    else $error("SVA: Write transaction did not complete within 16 cycles");

  property p_read_completes;
    @(posedge aclk) disable iff (!aresetn)
    (s_axi_arvalid && s_axi_arready) |-> ##[1:16] (s_axi_rvalid && s_axi_rready);
  endproperty
  a_read_completes: assert property (p_read_completes)
    else $error("SVA: Read transaction did not complete within 16 cycles");

  // =========================================================================
  // ADDRESS ALIGNMENT (AXI4-Lite requires word-aligned addresses)
  // =========================================================================

  property p_awaddr_aligned;
    @(posedge aclk) disable iff (!aresetn)
    s_axi_awvalid |-> (s_axi_awaddr[1:0] == 2'b00);
  endproperty
  a_awaddr_aligned: assert property (p_awaddr_aligned)
    else $error("SVA: AWADDR not word-aligned");

  property p_araddr_aligned;
    @(posedge aclk) disable iff (!aresetn)
    s_axi_arvalid |-> (s_axi_araddr[1:0] == 2'b00);
  endproperty
  a_araddr_aligned: assert property (p_araddr_aligned)
    else $error("SVA: ARADDR not word-aligned");

  // =========================================================================
  // COVER PROPERTIES
  // =========================================================================

  c_write_okay:   cover property (@(posedge aclk) s_axi_bvalid && s_axi_bresp == 2'b00);
  c_write_slverr: cover property (@(posedge aclk) s_axi_bvalid && s_axi_bresp == 2'b10);
  c_read_okay:    cover property (@(posedge aclk) s_axi_rvalid && s_axi_rresp == 2'b00);
  c_read_slverr:  cover property (@(posedge aclk) s_axi_rvalid && s_axi_rresp == 2'b10);

  c_aw_w_simultaneous: cover property (
    @(posedge aclk) s_axi_awvalid && s_axi_wvalid && s_axi_awready && s_axi_wready
  );

  c_aw_before_w: cover property (
    @(posedge aclk) (s_axi_awvalid && s_axi_awready && !s_axi_wvalid)
    ##[1:$] (s_axi_wvalid && s_axi_wready)
  );

  c_w_before_aw: cover property (
    @(posedge aclk) (s_axi_wvalid && s_axi_wready && !s_axi_awvalid)
    ##[1:$] (s_axi_awvalid && s_axi_awready)
  );

  c_back2back_reads: cover property (
    @(posedge aclk) (s_axi_rvalid && s_axi_rready) ##[1:3] (s_axi_arvalid && s_axi_arready)
  );

  c_irq_asserted: cover property (@(posedge aclk) $rose(irq_out));

endmodule
