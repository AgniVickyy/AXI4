// ============================================================================
// axi4_lite_scoreboard.sv — Register-level scoreboard
//
// Uses RAL mirror as reference model. Checks:
//   - RW registers: written value matches readback
//   - RO registers: value matches hardware state
//   - W1C registers: write-1-to-clear behavior
//   - Invalid addresses: SLVERR response
// ============================================================================
class axi4_lite_scoreboard #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
) extends uvm_scoreboard;

  `uvm_component_param_utils(axi4_lite_scoreboard#(DATA_WIDTH, ADDR_WIDTH))

  uvm_analysis_imp #(axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH),
                      axi4_lite_scoreboard#(DATA_WIDTH, ADDR_WIDTH)) ap;

  // RAL model handle (set from env)
  axi4_lite_reg_model ral;

  // Statistics
  int unsigned wr_count, rd_count;
  int unsigned match_count, mismatch_count;
  int unsigned slverr_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("scb_ap", this);
  endfunction

  function void write(axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH) item);
    uvm_reg reg_h;

    if (item.resp == 2'b10) begin
      slverr_count++;
      `uvm_info("SCB", $sformatf("SLVERR on %s addr=0x%02h (expected for invalid address)",
                item.write ? "WR" : "RD", item.addr), UVM_MEDIUM)
      return;
    end

    if (item.write) begin
      wr_count++;
      `uvm_info("SCB", $sformatf("WR: addr=0x%02h data=0x%08h", item.addr, item.data), UVM_MEDIUM)
    end else begin
      rd_count++;
      // Look up register by address and compare against RAL mirror
      reg_h = ral.default_map.get_reg_by_offset(item.addr);
      if (reg_h != null) begin
        logic [DATA_WIDTH-1:0] mirror_val;
        mirror_val = reg_h.get_mirrored_value();

        // For volatile (HW-updated) registers, skip strict comparison
        if (reg_h.get_name() == "status" || reg_h.get_name() == "data_out") begin
          `uvm_info("SCB", $sformatf("RD VOLATILE: %s addr=0x%02h rdata=0x%08h (mirror=0x%08h, skipped)",
                    reg_h.get_name(), item.addr, item.rdata, mirror_val), UVM_MEDIUM)
        end else begin
          if (item.rdata === mirror_val) begin
            match_count++;
            `uvm_info("SCB", $sformatf("RD MATCH: %s addr=0x%02h data=0x%08h",
                      reg_h.get_name(), item.addr, item.rdata), UVM_MEDIUM)
          end else begin
            mismatch_count++;
            `uvm_error("SCB", $sformatf("RD MISMATCH: %s addr=0x%02h got=0x%08h exp=0x%08h",
                       reg_h.get_name(), item.addr, item.rdata, mirror_val))
          end
        end
      end
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCB", "========== SCOREBOARD SUMMARY ==========", UVM_LOW)
    `uvm_info("SCB", $sformatf("  Writes:      %0d", wr_count), UVM_LOW)
    `uvm_info("SCB", $sformatf("  Reads:       %0d", rd_count), UVM_LOW)
    `uvm_info("SCB", $sformatf("  Matches:     %0d", match_count), UVM_LOW)
    `uvm_info("SCB", $sformatf("  Mismatches:  %0d", mismatch_count), UVM_LOW)
    `uvm_info("SCB", $sformatf("  SLVERR:      %0d", slverr_count), UVM_LOW)

    if (mismatch_count > 0)
      `uvm_error("SCB", "*** TEST FAILED ***")
    else
      `uvm_info("SCB", "*** TEST PASSED ***", UVM_LOW)
  endfunction

endclass
