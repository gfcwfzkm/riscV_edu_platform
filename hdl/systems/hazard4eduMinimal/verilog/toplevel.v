// Minimal Hazard3 system for the GECKO5Education (ECP5 LFE5U-85):
// Hazard3 (Wishbone ports) + JTAG debug + 64 KiB SRAM + 16550 UART on a shared Wishbone bus.
//
// Memory map (see wishBone.xml):
//   0x0000_0000 - 0x0000_ffff  sramSlave, 64 KiB block RAM (reset vector and mtvec at 0x0)
//   0x0001_0000 - 0x0001_0007  uartBus, 16550 compatible, byte registers
//
// Bus masters in arbiter index order (priorityScheme = 0: round robin): debugIf (debug module system bus access),
// cpuData (load/store port), cpuInstr (instruction fetch port).
//
// The RAM is not initialised: software is loaded through the JTAG debug port
// (OpenOCD, see openocd/gecko5-hazard3.cfg).
module hazard4eduMinimal
  (  input wire  clock,   // 50 MHz
     input wire  n_reset,
     input wire  RxD,
     output wire TxD);

  localparam AddrBits = 32;
  localparam DataBits = 32;
  localparam priorityScheme = 0;

  wire s_debugIf_CLK_I;
  wire s_debugIf_RST_I;
  wire [DataBits-1:0] s_debugIf_DAT_I;
  wire [DataBits-1:0] s_debugIf_DAT_O;
  wire s_debugIf_ACK_I;
  wire [AddrBits-1:0] s_debugIf_ADDR_O;
  wire s_debugIf_CYC_O;
  wire s_debugIf_ERR_I;
  wire s_debugIf_LOCK_O;
  wire [(DataBits/8)-1:0] s_debugIf_SEL_O;
  wire s_debugIf_STB_O;
  wire s_debugIf_WE_O;
  wire [2:0] s_debugIf_CTI_O;
  wire [1:0] s_debugIf_BTE_O;
  wire s_cpuData_CLK_I;
  wire s_cpuData_RST_I;
  wire [DataBits-1:0] s_cpuData_DAT_I;
  wire [DataBits-1:0] s_cpuData_DAT_O;
  wire s_cpuData_ACK_I;
  wire [AddrBits-1:0] s_cpuData_ADDR_O;
  wire s_cpuData_CYC_O;
  wire s_cpuData_ERR_I;
  wire s_cpuData_LOCK_O;
  wire [(DataBits/8)-1:0] s_cpuData_SEL_O;
  wire s_cpuData_STB_O;
  wire s_cpuData_WE_O;
  wire [2:0] s_cpuData_CTI_O;
  wire [1:0] s_cpuData_BTE_O;
  wire s_cpuInstr_CLK_I;
  wire s_cpuInstr_RST_I;
  wire [DataBits-1:0] s_cpuInstr_DAT_I;
  wire [DataBits-1:0] s_cpuInstr_DAT_O;
  wire s_cpuInstr_ACK_I;
  wire [AddrBits-1:0] s_cpuInstr_ADDR_O;
  wire s_cpuInstr_CYC_O;
  wire s_cpuInstr_ERR_I;
  wire s_cpuInstr_LOCK_O;
  wire [(DataBits/8)-1:0] s_cpuInstr_SEL_O;
  wire s_cpuInstr_STB_O;
  wire s_cpuInstr_WE_O;
  wire [2:0] s_cpuInstr_CTI_O;
  wire [1:0] s_cpuInstr_BTE_O;
  wire s_sramSlave_CLK_I;
  wire s_sramSlave_RST_I;
  wire [DataBits-1:0] s_sramSlave_DAT_I;
  wire [DataBits-1:0] s_sramSlave_DAT_O;
  wire s_sramSlave_ACK_O;
  wire [AddrBits-1:0] s_sramSlave_ADDR_I;
  wire s_sramSlave_CYC_I;
  wire s_sramSlave_ERR_O;
  wire s_sramSlave_LOCK_I;
  wire [(DataBits/8)-1:0] s_sramSlave_SEL_I;
  wire s_sramSlave_STB_I;
  wire s_sramSlave_WE_I;
  wire [2:0] s_sramSlave_CTI_I;
  wire [1:0] s_sramSlave_BTE_I;
  wire s_uartBus_CLK_I;
  wire s_uartBus_RST_I;
  wire [DataBits-1:0] s_uartBus_DAT_I;
  wire [DataBits-1:0] s_uartBus_DAT_O;
  wire s_uartBus_ACK_O;
  wire [AddrBits-1:0] s_uartBus_ADDR_I;
  wire s_uartBus_CYC_I;
  wire s_uartBus_ERR_O;
  wire s_uartBus_LOCK_I;
  wire [(DataBits/8)-1:0] s_uartBus_SEL_I;
  wire s_uartBus_STB_I;
  wire s_uartBus_WE_I;
  wire [2:0] s_uartBus_CTI_I;
  wire [1:0] s_uartBus_BTE_I;
  wire s_SYSCON_CLK_O;
  wire s_SYSCON_RST_O;

  // SYSCON: clock and a short power-on / button reset
  assign s_SYSCON_CLK_O = clock;
  reg [3:0] s_resetReg;
  always @(posedge clock or negedge n_reset)
    if (n_reset == 1'b0) s_resetReg <= 4'b1111;
    else s_resetReg <= (s_resetReg[3] == 1'b1) ? s_resetReg - 4'd1 : s_resetReg;
  assign s_SYSCON_RST_O = s_resetReg[3];

  // CPU reset: bus reset, or a system/hart reset requested by the debugger
  wire s_sys_reset_req, s_hart_reset_req;
  reg  s_cpuResetReg;
  always @(posedge clock)
    s_cpuResetReg <= s_SYSCON_RST_O | s_sys_reset_req | s_hart_reset_req;

  // Debug module <-> hart
  wire        s_hart_req_halt, s_hart_req_halt_on_reset, s_hart_req_resume;
  wire        s_hart_halted, s_hart_running;
  wire [31:0] s_hart_data0_rdata, s_hart_data0_wdata;
  wire        s_hart_data0_wen;
  wire [31:0] s_hart_instr_data;
  wire        s_hart_instr_data_vld, s_hart_instr_data_rdy;
  wire        s_hart_instr_caught_exception, s_hart_instr_caught_ebreak;
  wire        s_pwrup_req, s_unblock_out;

  debugTop #(
    .N_HARTS(1),
    .NEXT_DM_ADDR(32'h0000_0000),
    .DTMCS_IDLE_HINT(3'd4),
    .W_PADDR(9)
  ) busMaster_debugIf (
    .sys_reset_req(s_sys_reset_req),
    .sys_reset_done(~s_cpuResetReg),
    .hart_reset_req(s_hart_reset_req),
    .hart_reset_done(~s_cpuResetReg),
    .hart_req_halt(s_hart_req_halt),
    .hart_req_halt_on_reset(s_hart_req_halt_on_reset),
    .hart_req_resume(s_hart_req_resume),
    .hart_halted(s_hart_halted),
    .hart_running(s_hart_running),
    .hart_data0_rdata(s_hart_data0_rdata),
    .hart_data0_wdata(s_hart_data0_wdata),
    .hart_data0_wen(s_hart_data0_wen),
    .hart_instr_data(s_hart_instr_data),
    .hart_instr_data_vld(s_hart_instr_data_vld),
    .hart_instr_data_rdy(s_hart_instr_data_rdy),
    .hart_instr_caught_exception(s_hart_instr_caught_exception),
    .hart_instr_caught_ebreak(s_hart_instr_caught_ebreak),
    .CLK_I(s_debugIf_CLK_I),
    .RST_I(s_debugIf_RST_I),
    .DAT_I(s_debugIf_DAT_I),
    .DAT_O(s_debugIf_DAT_O),
    .ACK_I(s_debugIf_ACK_I),
    .ADDR_O(s_debugIf_ADDR_O),
    .CYC_O(s_debugIf_CYC_O),
    .ERR_I(s_debugIf_ERR_I),
    .SEL_O(s_debugIf_SEL_O),
    .STB_O(s_debugIf_STB_O),
    .WE_O(s_debugIf_WE_O),
    .CTI_O(s_debugIf_CTI_O));
  assign s_debugIf_LOCK_O = 1'b0;
  assign s_debugIf_BTE_O  = 2'd0;

  hazard3_cpu_2port_wb #(
    // EXTENSION_C is off for timing: with C the core only reaches about 41-45 MHz on a
    // speed grade 6 ECP5. Turn it on only with a lower clock.
    // EXTENSION_A and EXTENSION_XH3IRQ are off for timing: with them the core only just
    // reaches 50 MHz on a speed grade 6 ECP5 (49.7-50.3 MHz depending on the placement
    // seed); without them it reaches about 53-54 MHz. Software targets rv32im.
    .EXTENSION_A(0), .EXTENSION_C(0), .EXTENSION_M(1),
    .EXTENSION_XH3IRQ(0),
    .CSR_COUNTER(1), .DEBUG_SUPPORT(1), .BREAKPOINT_TRIGGERS(2),
    .NUM_IRQS(1), .MUL_FAST(1), .MUL_FASTER(0), .MULH_FAST(0), .MULDIV_UNROLL(1),
    .BRANCH_PREDICTOR(0)
  ) cpu (
    .clk(clock),
    .clk_always_on(clock),
    .rst(s_cpuResetReg),
    .reset_vector(32'h0000_0000),
    .mtvec_init(32'h0000_0000),
    .pwrup_req(s_pwrup_req),
    .pwrup_ack(s_pwrup_req),
    .clk_en(),
    .unblock_out(s_unblock_out),
    .unblock_in(s_unblock_out),
    .i_CYC_O(s_cpuInstr_CYC_O),
    .i_STB_O(s_cpuInstr_STB_O),
    .i_ADDR_O(s_cpuInstr_ADDR_O),
    .i_SEL_O(s_cpuInstr_SEL_O),
    .i_WE_O(s_cpuInstr_WE_O),
    .i_DAT_O(s_cpuInstr_DAT_O),
    .i_CTI_O(s_cpuInstr_CTI_O),
    .i_BTE_O(s_cpuInstr_BTE_O),
    .i_LOCK_O(s_cpuInstr_LOCK_O),
    .i_ACK_I(s_cpuInstr_ACK_I),
    .i_ERR_I(s_cpuInstr_ERR_I),
    .i_DAT_I(s_cpuInstr_DAT_I),
    .d_CYC_O(s_cpuData_CYC_O),
    .d_STB_O(s_cpuData_STB_O),
    .d_ADDR_O(s_cpuData_ADDR_O),
    .d_SEL_O(s_cpuData_SEL_O),
    .d_WE_O(s_cpuData_WE_O),
    .d_DAT_O(s_cpuData_DAT_O),
    .d_CTI_O(s_cpuData_CTI_O),
    .d_BTE_O(s_cpuData_BTE_O),
    .d_LOCK_O(s_cpuData_LOCK_O),
    .d_ACK_I(s_cpuData_ACK_I),
    .d_ERR_I(s_cpuData_ERR_I),
    .d_DAT_I(s_cpuData_DAT_I),
    .fence_i_vld(),
    .fence_d_vld(),
    .fence_rdy(1'b1),
    .dbg_req_halt(s_hart_req_halt),
    .dbg_req_halt_on_reset(s_hart_req_halt_on_reset),
    .dbg_req_resume(s_hart_req_resume),
    .dbg_halted(s_hart_halted),
    .dbg_running(s_hart_running),
    .dbg_data0_rdata(s_hart_data0_rdata),
    .dbg_data0_wdata(s_hart_data0_wdata),
    .dbg_data0_wen(s_hart_data0_wen),
    .dbg_instr_data(s_hart_instr_data),
    .dbg_instr_data_vld(s_hart_instr_data_vld),
    .dbg_instr_data_rdy(s_hart_instr_data_rdy),
    .dbg_instr_caught_exception(s_hart_instr_caught_exception),
    .dbg_instr_caught_ebreak(s_hart_instr_caught_ebreak),
    .mhartid_val(32'd0),
    .eco_version(4'd0),
    .irq(1'b0),
    .soft_irq(1'b0),
    .timer_irq(1'b0),
    .ci_id(),
    .ci_start(),
    .ci_dataa(),
    .ci_datab(),
    .ci_done(1'b0),
    .ci_result(32'd0));

  sramSlave #(
    .BaseAddress('h0),
    .AddrBits(AddrBits),
    .DataBits(DataBits),
    .nrOfEntriesInBytes(64*1024)
  ) busSlave_sramSlave (
    .CLK_I(s_sramSlave_CLK_I),
    .RST_I(s_sramSlave_RST_I),
    .DAT_I(s_sramSlave_DAT_I),
    .DAT_O(s_sramSlave_DAT_O),
    .ACK_O(s_sramSlave_ACK_O),
    .ADDR_I(s_sramSlave_ADDR_I),
    .CYC_I(s_sramSlave_CYC_I),
    .ERR_O(s_sramSlave_ERR_O),
    .SEL_I(s_sramSlave_SEL_I),
    .STB_I(s_sramSlave_STB_I),
    .WE_I(s_sramSlave_WE_I),
    .CTI_I(s_sramSlave_CTI_I),
    .BTE_I(s_sramSlave_BTE_I));

  uartBus #(
    .BaseAddress('h10000),
    .AddrBits(AddrBits),
    .DataBits(DataBits)
  ) busSlave_uartBus (
    .CLK_I(s_uartBus_CLK_I),
    .RST_I(s_uartBus_RST_I),
    .DAT_I(s_uartBus_DAT_I),
    .DAT_O(s_uartBus_DAT_O),
    .ACK_O(s_uartBus_ACK_O),
    .ADDR_I(s_uartBus_ADDR_I),
    .CYC_I(s_uartBus_CYC_I),
    .ERR_O(s_uartBus_ERR_O),
    .SEL_I(s_uartBus_SEL_I),
    .STB_I(s_uartBus_STB_I),
    .WE_I(s_uartBus_WE_I),
    .CTI_I(s_uartBus_CTI_I),
    .clock50MHz(s_uartBus_CLK_I),
    .irq(),
    .RxD(RxD),
    .TxD(TxD));

  wishBoneSharedBusTop #(
    .AddrBits(AddrBits),
    .DataBits(DataBits),
    .priorityScheme(priorityScheme)
  ) wishboneBus (
    .debugIf_CLK_I(s_debugIf_CLK_I),
    .debugIf_RST_I(s_debugIf_RST_I),
    .debugIf_DAT_I(s_debugIf_DAT_I),
    .debugIf_DAT_O(s_debugIf_DAT_O),
    .debugIf_ACK_I(s_debugIf_ACK_I),
    .debugIf_ADDR_O(s_debugIf_ADDR_O),
    .debugIf_CYC_O(s_debugIf_CYC_O),
    .debugIf_ERR_I(s_debugIf_ERR_I),
    .debugIf_LOCK_O(s_debugIf_LOCK_O),
    .debugIf_SEL_O(s_debugIf_SEL_O),
    .debugIf_STB_O(s_debugIf_STB_O),
    .debugIf_WE_O(s_debugIf_WE_O),
    .debugIf_CTI_O(s_debugIf_CTI_O),
    .debugIf_BTE_O(s_debugIf_BTE_O),
    .cpuData_CLK_I(s_cpuData_CLK_I),
    .cpuData_RST_I(s_cpuData_RST_I),
    .cpuData_DAT_I(s_cpuData_DAT_I),
    .cpuData_DAT_O(s_cpuData_DAT_O),
    .cpuData_ACK_I(s_cpuData_ACK_I),
    .cpuData_ADDR_O(s_cpuData_ADDR_O),
    .cpuData_CYC_O(s_cpuData_CYC_O),
    .cpuData_ERR_I(s_cpuData_ERR_I),
    .cpuData_LOCK_O(s_cpuData_LOCK_O),
    .cpuData_SEL_O(s_cpuData_SEL_O),
    .cpuData_STB_O(s_cpuData_STB_O),
    .cpuData_WE_O(s_cpuData_WE_O),
    .cpuData_CTI_O(s_cpuData_CTI_O),
    .cpuData_BTE_O(s_cpuData_BTE_O),
    .cpuInstr_CLK_I(s_cpuInstr_CLK_I),
    .cpuInstr_RST_I(s_cpuInstr_RST_I),
    .cpuInstr_DAT_I(s_cpuInstr_DAT_I),
    .cpuInstr_DAT_O(s_cpuInstr_DAT_O),
    .cpuInstr_ACK_I(s_cpuInstr_ACK_I),
    .cpuInstr_ADDR_O(s_cpuInstr_ADDR_O),
    .cpuInstr_CYC_O(s_cpuInstr_CYC_O),
    .cpuInstr_ERR_I(s_cpuInstr_ERR_I),
    .cpuInstr_LOCK_O(s_cpuInstr_LOCK_O),
    .cpuInstr_SEL_O(s_cpuInstr_SEL_O),
    .cpuInstr_STB_O(s_cpuInstr_STB_O),
    .cpuInstr_WE_O(s_cpuInstr_WE_O),
    .cpuInstr_CTI_O(s_cpuInstr_CTI_O),
    .cpuInstr_BTE_O(s_cpuInstr_BTE_O),
    .sramSlave_CLK_I(s_sramSlave_CLK_I),
    .sramSlave_RST_I(s_sramSlave_RST_I),
    .sramSlave_DAT_I(s_sramSlave_DAT_I),
    .sramSlave_DAT_O(s_sramSlave_DAT_O),
    .sramSlave_ACK_O(s_sramSlave_ACK_O),
    .sramSlave_ADDR_I(s_sramSlave_ADDR_I),
    .sramSlave_CYC_I(s_sramSlave_CYC_I),
    .sramSlave_ERR_O(s_sramSlave_ERR_O),
    .sramSlave_LOCK_I(s_sramSlave_LOCK_I),
    .sramSlave_SEL_I(s_sramSlave_SEL_I),
    .sramSlave_STB_I(s_sramSlave_STB_I),
    .sramSlave_WE_I(s_sramSlave_WE_I),
    .sramSlave_CTI_I(s_sramSlave_CTI_I),
    .sramSlave_BTE_I(s_sramSlave_BTE_I),
    .uartBus_CLK_I(s_uartBus_CLK_I),
    .uartBus_RST_I(s_uartBus_RST_I),
    .uartBus_DAT_I(s_uartBus_DAT_I),
    .uartBus_DAT_O(s_uartBus_DAT_O),
    .uartBus_ACK_O(s_uartBus_ACK_O),
    .uartBus_ADDR_I(s_uartBus_ADDR_I),
    .uartBus_CYC_I(s_uartBus_CYC_I),
    .uartBus_ERR_O(s_uartBus_ERR_O),
    .uartBus_LOCK_I(s_uartBus_LOCK_I),
    .uartBus_SEL_I(s_uartBus_SEL_I),
    .uartBus_STB_I(s_uartBus_STB_I),
    .uartBus_WE_I(s_uartBus_WE_I),
    .uartBus_CTI_I(s_uartBus_CTI_I),
    .uartBus_BTE_I(s_uartBus_BTE_I),
    .CLK_O(s_SYSCON_CLK_O),
    .RST_O(s_SYSCON_RST_O));

endmodule
