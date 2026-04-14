// ============================================================================
// axi4_lite_if.sv — AXI4-Lite Virtual Interface
// ============================================================================
interface axi4_lite_if #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
)(
  input logic aclk,
  input logic aresetn
);

  // Write Address Channel
  logic [ADDR_WIDTH-1:0]   awaddr;
  logic [2:0]              awprot;
  logic                    awvalid;
  logic                    awready;

  // Write Data Channel
  logic [DATA_WIDTH-1:0]   wdata;
  logic [DATA_WIDTH/8-1:0] wstrb;
  logic                    wvalid;
  logic                    wready;

  // Write Response Channel
  logic [1:0]              bresp;
  logic                    bvalid;
  logic                    bready;

  // Read Address Channel
  logic [ADDR_WIDTH-1:0]   araddr;
  logic [2:0]              arprot;
  logic                    arvalid;
  logic                    arready;

  // Read Data Channel
  logic [DATA_WIDTH-1:0]   rdata;
  logic [1:0]              rresp;
  logic                    rvalid;
  logic                    rready;

  // Sideband
  logic                    irq_out;

  // ---- Clocking blocks ----

  clocking master_cb @(posedge aclk);
    default input #1 output #1;
    output awaddr, awprot, awvalid;
    input  awready;
    output wdata, wstrb, wvalid;
    input  wready;
    input  bresp, bvalid;
    output bready;
    output araddr, arprot, arvalid;
    input  arready;
    input  rdata, rresp, rvalid;
    output rready;
  endclocking

  clocking monitor_cb @(posedge aclk);
    default input #1;
    input awaddr, awprot, awvalid, awready;
    input wdata, wstrb, wvalid, wready;
    input bresp, bvalid, bready;
    input araddr, arprot, arvalid, arready;
    input rdata, rresp, rvalid, rready;
    input irq_out;
  endclocking

  modport MASTER  (clocking master_cb, input aresetn);
  modport MONITOR (clocking monitor_cb, input aresetn);

endinterface
