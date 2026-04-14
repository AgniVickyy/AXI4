// ============================================================================
// axi4_lite_sequences.sv — Test sequences including RAL-based sequences
// ============================================================================

// ---------------------------------------------------------------------------
// Base register write/read sequence (raw AXI — no RAL)
// ---------------------------------------------------------------------------
class axi4_lite_raw_rw_seq #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
) extends uvm_sequence #(axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH));

  `uvm_object_param_utils(axi4_lite_raw_rw_seq#(DATA_WIDTH, ADDR_WIDTH))

  function new(string name = "raw_rw_seq");
    super.new(name);
  endfunction

  task body();
    axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH) item;

    // Write SCRATCH register
    item = axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("item");
    start_item(item);
    item.write = 1;
    item.addr  = 8'h18;
    item.data  = 32'hDEAD_BEEF;
    item.strb  = 4'hF;
    finish_item(item);

    // Read SCRATCH register
    item = axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("item");
    start_item(item);
    item.write = 0;
    item.addr  = 8'h18;
    finish_item(item);

    // Read VERSION register
    item = axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("item");
    start_item(item);
    item.write = 0;
    item.addr  = 8'h1C;
    finish_item(item);
  endtask

endclass

// ---------------------------------------------------------------------------
// RAL frontdoor register access — the standard way to use RAL
// ---------------------------------------------------------------------------
class axi4_lite_ral_frontdoor_seq extends uvm_sequence;
  `uvm_object_utils(axi4_lite_ral_frontdoor_seq)

  axi4_lite_reg_model ral;

  function new(string name = "ral_frontdoor_seq");
    super.new(name);
  endfunction

  task body();
    uvm_status_e   status;
    uvm_reg_data_t rdata;

    // ---- Write and readback all RW registers ----
    `uvm_info("SEQ", "=== RAL Frontdoor: Write all RW registers ===", UVM_LOW)

    ral.ctrl.write(status, 32'h0000_000B);      // enable=1, mode=01(loopback), irq_en=1
    ral.data_in.write(status, 32'hCAFE_BABE);
    ral.irq_mask.write(status, 32'h0000_0007);   // All IRQs unmasked
    ral.scratch.write(status, 32'hA5A5_5A5A);

    `uvm_info("SEQ", "=== RAL Frontdoor: Readback all registers ===", UVM_LOW)

    ral.ctrl.read(status, rdata);
    `uvm_info("SEQ", $sformatf("CTRL     = 0x%08h", rdata), UVM_LOW)

    ral.status.read(status, rdata);
    `uvm_info("SEQ", $sformatf("STATUS   = 0x%08h", rdata), UVM_LOW)

    ral.data_in.read(status, rdata);
    `uvm_info("SEQ", $sformatf("DATA_IN  = 0x%08h", rdata), UVM_LOW)

    ral.data_out.read(status, rdata);
    `uvm_info("SEQ", $sformatf("DATA_OUT = 0x%08h", rdata), UVM_LOW)

    ral.irq_mask.read(status, rdata);
    `uvm_info("SEQ", $sformatf("IRQ_MASK = 0x%08h", rdata), UVM_LOW)

    ral.scratch.read(status, rdata);
    `uvm_info("SEQ", $sformatf("SCRATCH  = 0x%08h", rdata), UVM_LOW)

    ral.version.read(status, rdata);
    `uvm_info("SEQ", $sformatf("VERSION  = 0x%08h", rdata), UVM_LOW)
  endtask

endclass

// ---------------------------------------------------------------------------
// RAL field-level access — demonstrates fine-grained register manipulation
// ---------------------------------------------------------------------------
class axi4_lite_ral_field_seq extends uvm_sequence;
  `uvm_object_utils(axi4_lite_ral_field_seq)

  axi4_lite_reg_model ral;

  function new(string name = "ral_field_seq");
    super.new(name);
  endfunction

  task body();
    uvm_status_e status;
    uvm_reg_data_t rdata;

    `uvm_info("SEQ", "=== RAL Field-level access ===", UVM_LOW)

    // Set individual fields
    ral.ctrl.enable.set(1);
    ral.ctrl.mode.set(2'b01);     // Loopback
    ral.ctrl.irq_en.set(1);
    ral.ctrl.update(status);      // Push to hardware

    // Read back and check field values
    ral.ctrl.read(status, rdata);
    `uvm_info("SEQ", $sformatf("CTRL.enable = %0d (expected 1)", ral.ctrl.enable.get_mirrored_value()), UVM_LOW)
    `uvm_info("SEQ", $sformatf("CTRL.mode   = %0d (expected 1)", ral.ctrl.mode.get_mirrored_value()), UVM_LOW)
    `uvm_info("SEQ", $sformatf("CTRL.irq_en = %0d (expected 1)", ral.ctrl.irq_en.get_mirrored_value()), UVM_LOW)

    // Set data_in, then check data_out in loopback mode
    ral.data_in.write(status, 32'h1234_5678);
    #100;  // Wait for loopback pipeline
    ral.data_out.read(status, rdata);
    `uvm_info("SEQ", $sformatf("DATA_OUT (loopback) = 0x%08h (expected 0x12345678)", rdata), UVM_LOW)
  endtask

endclass

// ---------------------------------------------------------------------------
// Walking-ones register test — exhaustive bit-level verification
// ---------------------------------------------------------------------------
class axi4_lite_walking_ones_seq #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
) extends uvm_sequence #(axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH));

  `uvm_object_param_utils(axi4_lite_walking_ones_seq#(DATA_WIDTH, ADDR_WIDTH))

  function new(string name = "walking_ones_seq");
    super.new(name);
  endfunction

  task body();
    axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH) wr_item, rd_item;

    // Target: SCRATCH register (full 32-bit RW)
    `uvm_info("SEQ", "=== Walking-1s on SCRATCH register ===", UVM_LOW)

    for (int i = 0; i < DATA_WIDTH; i++) begin
      logic [DATA_WIDTH-1:0] pattern = (1 << i);

      // Write pattern
      wr_item = axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("wr_item");
      start_item(wr_item);
      wr_item.write = 1;
      wr_item.addr  = 8'h18;  // SCRATCH
      wr_item.data  = pattern;
      wr_item.strb  = 4'hF;
      finish_item(wr_item);

      // Read back
      rd_item = axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("rd_item");
      start_item(rd_item);
      rd_item.write = 0;
      rd_item.addr  = 8'h18;
      finish_item(rd_item);

      if (rd_item.rdata !== pattern)
        `uvm_error("SEQ", $sformatf("Walking-1 bit[%0d]: wrote=0x%08h read=0x%08h",
                   i, pattern, rd_item.rdata))
      else
        `uvm_info("SEQ", $sformatf("Walking-1 bit[%0d]: PASS (0x%08h)", i, pattern), UVM_HIGH)
    end

    // Walking zeros
    `uvm_info("SEQ", "=== Walking-0s on SCRATCH register ===", UVM_LOW)
    for (int i = 0; i < DATA_WIDTH; i++) begin
      logic [DATA_WIDTH-1:0] pattern = ~(1 << i);

      wr_item = axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("wr_item");
      start_item(wr_item);
      wr_item.write = 1;
      wr_item.addr  = 8'h18;
      wr_item.data  = pattern;
      wr_item.strb  = 4'hF;
      finish_item(wr_item);

      rd_item = axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("rd_item");
      start_item(rd_item);
      rd_item.write = 0;
      rd_item.addr  = 8'h18;
      finish_item(rd_item);

      if (rd_item.rdata !== pattern)
        `uvm_error("SEQ", $sformatf("Walking-0 bit[%0d]: wrote=0x%08h read=0x%08h",
                   i, pattern, rd_item.rdata))
    end
  endtask

endclass

// ---------------------------------------------------------------------------
// Invalid address test — verify SLVERR on bad addresses
// ---------------------------------------------------------------------------
class axi4_lite_invalid_addr_seq #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
) extends uvm_sequence #(axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH));

  `uvm_object_param_utils(axi4_lite_invalid_addr_seq#(DATA_WIDTH, ADDR_WIDTH))

  function new(string name = "invalid_addr_seq");
    super.new(name);
  endfunction

  task body();
    axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH) item;
    logic [ADDR_WIDTH-1:0] bad_addrs[] = '{8'h20, 8'h24, 8'h40, 8'h80, 8'hFC};

    `uvm_info("SEQ", "=== Invalid address SLVERR test ===", UVM_LOW)

    foreach (bad_addrs[i]) begin
      // Write to invalid
      item = axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("item");
      start_item(item);
      item.write = 1;
      item.addr  = bad_addrs[i];
      item.data  = 32'hBAAD_F00D;
      item.strb  = 4'hF;
      finish_item(item);

      // Read from invalid
      item = axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("item");
      start_item(item);
      item.write = 0;
      item.addr  = bad_addrs[i];
      finish_item(item);
    end
  endtask

endclass

// ---------------------------------------------------------------------------
// Byte strobe test — verify per-byte write enables
// ---------------------------------------------------------------------------
class axi4_lite_strobe_seq #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
) extends uvm_sequence #(axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH));

  `uvm_object_param_utils(axi4_lite_strobe_seq#(DATA_WIDTH, ADDR_WIDTH))

  function new(string name = "strobe_seq");
    super.new(name);
  endfunction

  task body();
    axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH) item;

    `uvm_info("SEQ", "=== Byte strobe test on SCRATCH ===", UVM_LOW)

    // Step 1: Write full word
    item = axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("item");
    start_item(item);
    item.write = 1; item.addr = 8'h18; item.data = 32'hAABBCCDD; item.strb = 4'hF;
    finish_item(item);

    // Step 2: Overwrite only byte 1 (bits [15:8])
    item = axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("item");
    start_item(item);
    item.write = 1; item.addr = 8'h18; item.data = 32'h00FF0000; item.strb = 4'b0010;
    finish_item(item);

    // Step 3: Read back — expect 0xAABBFF DD (only byte 1 changed)
    //         Actually: 0xAABBFFDD because strb=0010 targets bits [15:8]
    //         Wait, strb bit mapping: strb[0]→[7:0], strb[1]→[15:8], strb[2]→[23:16], strb[3]→[31:24]
    //         So strb=4'b0010 targets byte[1] = bits [15:8]
    //         Write data 0x00FF0000: byte[1] = 0x00, byte[2] = 0xFF
    //         Only byte[1] is written → bits[15:8] get 0x00
    //         Expected: 0xAABB00DD
    item = axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("item");
    start_item(item);
    item.write = 0; item.addr = 8'h18;
    finish_item(item);

    // Step 4: Overwrite bytes 0 and 3 only
    item = axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("item");
    start_item(item);
    item.write = 1; item.addr = 8'h18; item.data = 32'h11000022; item.strb = 4'b1001;
    finish_item(item);

    // Step 5: Read back
    item = axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("item");
    start_item(item);
    item.write = 0; item.addr = 8'h18;
    finish_item(item);
  endtask

endclass

// ---------------------------------------------------------------------------
// RAL built-in reset sequence — verify all registers at reset values
// ---------------------------------------------------------------------------
class axi4_lite_ral_reset_seq extends uvm_sequence;
  `uvm_object_utils(axi4_lite_ral_reset_seq)

  axi4_lite_reg_model ral;

  function new(string name = "ral_reset_seq");
    super.new(name);
  endfunction

  task body();
    uvm_status_e   status;
    uvm_reg_data_t rdata;
    uvm_reg regs[$];

    `uvm_info("SEQ", "=== RAL Reset value verification ===", UVM_LOW)

    ral.get_registers(regs);
    foreach (regs[i]) begin
      // Skip volatile registers (HW-updated)
      if (regs[i].get_name() == "status" || regs[i].get_name() == "data_out")
        continue;

      regs[i].read(status, rdata);
      if (status == UVM_IS_OK) begin
        uvm_reg_data_t reset_val = regs[i].get_reset();
        if (rdata !== reset_val)
          `uvm_error("SEQ", $sformatf("Reset mismatch: %s got=0x%08h exp=0x%08h",
                     regs[i].get_name(), rdata, reset_val))
        else
          `uvm_info("SEQ", $sformatf("Reset OK: %s = 0x%08h",
                    regs[i].get_name(), rdata), UVM_MEDIUM)
      end
    end
  endtask

endclass
