// ============================================================================
// axi4_lite_ral_model.sv — UVM RAL Register Model
//
// This is the key Tier-1 differentiator. Models every register, field,
// and access policy. Enables:
//   - Frontdoor read/write via AXI4-Lite bus
//   - Backdoor read/write via DPI/hierarchical path
//   - Built-in sequences (reset, hw_reset, bit_bash, reg_access)
//   - Auto-prediction and mirror checking
// ============================================================================

// ---- CTRL Register (RW) ----
class reg_ctrl extends uvm_reg;
  `uvm_object_utils(reg_ctrl)

  rand uvm_reg_field enable;
  rand uvm_reg_field mode;
  rand uvm_reg_field irq_en;
  rand uvm_reg_field reserved;

  function new(string name = "reg_ctrl");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    enable   = uvm_reg_field::type_id::create("enable");
    mode     = uvm_reg_field::type_id::create("mode");
    irq_en   = uvm_reg_field::type_id::create("irq_en");
    reserved = uvm_reg_field::type_id::create("reserved");

    //              parent, size, lsb, access,  volatile, reset, has_reset, is_rand
    enable.configure  (this, 1,  0,  "RW",    0,       0,     1,         1);
    mode.configure    (this, 2,  1,  "RW",    0,       0,     1,         1);
    irq_en.configure  (this, 1,  3,  "RW",    0,       0,     1,         1);
    reserved.configure(this, 28, 4,  "RO",    0,       0,     1,         0);
  endfunction
endclass

// ---- STATUS Register (RO) ----
class reg_status extends uvm_reg;
  `uvm_object_utils(reg_status)

  rand uvm_reg_field busy;
  rand uvm_reg_field done;
  rand uvm_reg_field error;
  rand uvm_reg_field fifo_level;
  rand uvm_reg_field reserved;

  function new(string name = "reg_status");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    busy       = uvm_reg_field::type_id::create("busy");
    done       = uvm_reg_field::type_id::create("done");
    error      = uvm_reg_field::type_id::create("error");
    fifo_level = uvm_reg_field::type_id::create("fifo_level");
    reserved   = uvm_reg_field::type_id::create("reserved");

    busy.configure      (this, 1,  0,  "RO", 1, 0, 1, 0);
    done.configure      (this, 1,  1,  "RO", 1, 0, 1, 0);
    error.configure     (this, 1,  2,  "RO", 1, 0, 1, 0);
    fifo_level.configure(this, 5,  3,  "RO", 1, 0, 1, 0);
    reserved.configure  (this, 24, 8,  "RO", 0, 0, 1, 0);
  endfunction
endclass

// ---- DATA_IN Register (RW) ----
class reg_data_in extends uvm_reg;
  `uvm_object_utils(reg_data_in)

  rand uvm_reg_field data;

  function new(string name = "reg_data_in");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    data = uvm_reg_field::type_id::create("data");
    data.configure(this, 32, 0, "RW", 0, 0, 1, 1);
  endfunction
endclass

// ---- DATA_OUT Register (RO) ----
class reg_data_out extends uvm_reg;
  `uvm_object_utils(reg_data_out)

  rand uvm_reg_field data;

  function new(string name = "reg_data_out");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    data = uvm_reg_field::type_id::create("data");
    data.configure(this, 32, 0, "RO", 1, 0, 1, 0);
  endfunction
endclass

// ---- IRQ_STATUS Register (W1C) ----
class reg_irq_status extends uvm_reg;
  `uvm_object_utils(reg_irq_status)

  rand uvm_reg_field done_irq;
  rand uvm_reg_field error_irq;
  rand uvm_reg_field overflow_irq;
  rand uvm_reg_field reserved;

  function new(string name = "reg_irq_status");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    done_irq     = uvm_reg_field::type_id::create("done_irq");
    error_irq    = uvm_reg_field::type_id::create("error_irq");
    overflow_irq = uvm_reg_field::type_id::create("overflow_irq");
    reserved     = uvm_reg_field::type_id::create("reserved");

    done_irq.configure    (this, 1,  0, "W1C", 1, 0, 1, 1);
    error_irq.configure   (this, 1,  1, "W1C", 1, 0, 1, 1);
    overflow_irq.configure(this, 1,  2, "W1C", 1, 0, 1, 1);
    reserved.configure    (this, 29, 3, "RO",  0, 0, 1, 0);
  endfunction
endclass

// ---- IRQ_MASK Register (RW) ----
class reg_irq_mask extends uvm_reg;
  `uvm_object_utils(reg_irq_mask)

  rand uvm_reg_field done_mask;
  rand uvm_reg_field error_mask;
  rand uvm_reg_field overflow_mask;
  rand uvm_reg_field reserved;

  function new(string name = "reg_irq_mask");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    done_mask     = uvm_reg_field::type_id::create("done_mask");
    error_mask    = uvm_reg_field::type_id::create("error_mask");
    overflow_mask = uvm_reg_field::type_id::create("overflow_mask");
    reserved      = uvm_reg_field::type_id::create("reserved");

    done_mask.configure    (this, 1,  0, "RW", 0, 0, 1, 1);
    error_mask.configure   (this, 1,  1, "RW", 0, 0, 1, 1);
    overflow_mask.configure(this, 1,  2, "RW", 0, 0, 1, 1);
    reserved.configure     (this, 29, 3, "RO", 0, 0, 1, 0);
  endfunction
endclass

// ---- SCRATCH Register (RW) ----
class reg_scratch extends uvm_reg;
  `uvm_object_utils(reg_scratch)

  rand uvm_reg_field data;

  function new(string name = "reg_scratch");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    data = uvm_reg_field::type_id::create("data");
    data.configure(this, 32, 0, "RW", 0, 0, 1, 1);
  endfunction
endclass

// ---- VERSION Register (RO) ----
class reg_version extends uvm_reg;
  `uvm_object_utils(reg_version)

  rand uvm_reg_field version;

  function new(string name = "reg_version");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    version = uvm_reg_field::type_id::create("version");
    version.configure(this, 32, 0, "RO", 0, 32'h0001_0000, 1, 0);
  endfunction
endclass

// ============================================================================
// Top-level Register Block
// ============================================================================
class axi4_lite_reg_model extends uvm_reg_block;
  `uvm_object_utils(axi4_lite_reg_model)

  rand reg_ctrl       ctrl;
  rand reg_status     status;
  rand reg_data_in    data_in;
  rand reg_data_out   data_out;
  rand reg_irq_status irq_status;
  rand reg_irq_mask   irq_mask;
  rand reg_scratch    scratch;
  rand reg_version    version;

  uvm_reg_map default_map;

  function new(string name = "axi4_lite_reg_model");
    super.new(name, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    // Create registers
    ctrl       = reg_ctrl::type_id::create("ctrl");
    status     = reg_status::type_id::create("status");
    data_in    = reg_data_in::type_id::create("data_in");
    data_out   = reg_data_out::type_id::create("data_out");
    irq_status = reg_irq_status::type_id::create("irq_status");
    irq_mask   = reg_irq_mask::type_id::create("irq_mask");
    scratch    = reg_scratch::type_id::create("scratch");
    version    = reg_version::type_id::create("version");

    // Build each register (configures fields)
    ctrl.configure(this);       ctrl.build();
    status.configure(this);     status.build();
    data_in.configure(this);    data_in.build();
    data_out.configure(this);   data_out.build();
    irq_status.configure(this); irq_status.build();
    irq_mask.configure(this);   irq_mask.build();
    scratch.configure(this);    scratch.build();
    version.configure(this);    version.build();

    // Create address map
    default_map = create_map("default_map",
      .base_addr(0),
      .n_bytes(4),           // 32-bit data bus
      .endian(UVM_LITTLE_ENDIAN)
    );

    // Add registers to map
    default_map.add_reg(ctrl,       'h00, "RW");
    default_map.add_reg(status,     'h04, "RO");
    default_map.add_reg(data_in,    'h08, "RW");
    default_map.add_reg(data_out,   'h0C, "RO");
    default_map.add_reg(irq_status, 'h10, "RW");  // W1C at field level
    default_map.add_reg(irq_mask,   'h14, "RW");
    default_map.add_reg(scratch,    'h18, "RW");
    default_map.add_reg(version,    'h1C, "RO");

    lock_model();
  endfunction

endclass
