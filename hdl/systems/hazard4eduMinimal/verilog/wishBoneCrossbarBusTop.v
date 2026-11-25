module wishBoneCrossbarBusTop
  #( parameter DataBits = 32,
     parameter AddrBits = 32,
     parameter priorityScheme = 1)
   (
    // Here the signals for the master "debugIf" are defined
    // Note that although the signals are noted with _O/_I their direction is oposite defined
    // as they connect directly with the same signals on the master.
    output wire debugIf_CLK_I,
    output wire debugIf_RST_I,
    output wire [DataBits - 1:0] debugIf_DAT_I,
    input  wire [DataBits - 1:0] debugIf_DAT_O,
    output wire debugIf_ACK_I,
    input  wire [AddrBits - 1:0] debugIf_ADDR_O,
    input  wire debugIf_CYC_O,
    output wire debugIf_ERR_I,
    input  wire debugIf_LOCK_O,
    input  wire [(DataBits / 8) - 1:0] debugIf_SEL_O,
    input  wire debugIf_STB_O,
    input  wire debugIf_WE_O,
    input  wire [2:0] debugIf_CTI_O,
    input  wire [1:0] debugIf_BTE_O,

    // Here the signals for the master "cpuData" are defined
    // Note that although the signals are noted with _O/_I their direction is oposite defined
    // as they connect directly with the same signals on the master.
    output wire cpuData_CLK_I,
    output wire cpuData_RST_I,
    output wire [DataBits - 1:0] cpuData_DAT_I,
    input  wire [DataBits - 1:0] cpuData_DAT_O,
    output wire cpuData_ACK_I,
    input  wire [AddrBits - 1:0] cpuData_ADDR_O,
    input  wire cpuData_CYC_O,
    output wire cpuData_ERR_I,
    input  wire cpuData_LOCK_O,
    input  wire [(DataBits / 8) - 1:0] cpuData_SEL_O,
    input  wire cpuData_STB_O,
    input  wire cpuData_WE_O,
    input  wire [2:0] cpuData_CTI_O,
    input  wire [1:0] cpuData_BTE_O,

    // Here the signals for the master "cpuInstr" are defined
    // Note that although the signals are noted with _O/_I their direction is oposite defined
    // as they connect directly with the same signals on the master.
    output wire cpuInstr_CLK_I,
    output wire cpuInstr_RST_I,
    output wire [DataBits - 1:0] cpuInstr_DAT_I,
    input  wire [DataBits - 1:0] cpuInstr_DAT_O,
    output wire cpuInstr_ACK_I,
    input  wire [AddrBits - 1:0] cpuInstr_ADDR_O,
    input  wire cpuInstr_CYC_O,
    output wire cpuInstr_ERR_I,
    input  wire cpuInstr_LOCK_O,
    input  wire [(DataBits / 8) - 1:0] cpuInstr_SEL_O,
    input  wire cpuInstr_STB_O,
    input  wire cpuInstr_WE_O,
    input  wire [2:0] cpuInstr_CTI_O,
    input  wire [1:0] cpuInstr_BTE_O,

    // Here the signals for the slave "sramSlave" are defined
    // Note that although the signals are noted with _O/_I their direction is oposite defined
    // as they connect directly with the same signals on the master.
    output wire sramSlave_CLK_I,
    output wire sramSlave_RST_I,
    output wire [DataBits - 1:0] sramSlave_DAT_I,
    input  wire [DataBits - 1:0] sramSlave_DAT_O,
    input  wire sramSlave_ACK_O,
    output wire [AddrBits - 1:0] sramSlave_ADDR_I,
    output wire sramSlave_CYC_I,
    input  wire sramSlave_ERR_O,
    output wire sramSlave_LOCK_I,
    output wire [(DataBits / 8) - 1:0] sramSlave_SEL_I,
    output wire sramSlave_STB_I,
    output wire sramSlave_WE_I,
    output wire [2:0] sramSlave_CTI_I,
    output wire [1:0] sramSlave_BTE_I,

    // Here the signals for the slave "uartBus" are defined
    // Note that although the signals are noted with _O/_I their direction is oposite defined
    // as they connect directly with the same signals on the master.
    output wire uartBus_CLK_I,
    output wire uartBus_RST_I,
    output wire [DataBits - 1:0] uartBus_DAT_I,
    input  wire [DataBits - 1:0] uartBus_DAT_O,
    input  wire uartBus_ACK_O,
    output wire [AddrBits - 1:0] uartBus_ADDR_I,
    output wire uartBus_CYC_I,
    input  wire uartBus_ERR_O,
    output wire uartBus_LOCK_I,
    output wire [(DataBits / 8) - 1:0] uartBus_SEL_I,
    output wire uartBus_STB_I,
    output wire uartBus_WE_I,
    output wire [2:0] uartBus_CTI_I,
    output wire [1:0] uartBus_BTE_I,

    // Here the Syscon connections are defined
    // Connect the signals with the same name together
    // Note that although we have the _O suffix these are inputs as
    // they are outputs on the syscon component
    input wire CLK_O,
    input wire RST_O);

  wire [DataBits - 1:0] s_sramSlave_debugIf_DAT_I;
  wire [DataBits - 1:0] s_uartBus_debugIf_DAT_I;
  wire s_debugIf_ACK_I;
  wire s_sramSlave_debugIf_ACK_I;
  wire s_uartBus_debugIf_ACK_I;
  wire s_sramSlave_debugIf_ERR_I;
  wire s_uartBus_debugIf_ERR_I;
  wire s_debugIf_arbiterTimeOut;
  reg [15:0] s_debugIf_arbiterTimeOutCounter;
  wire [DataBits - 1:0] s_sramSlave_cpuData_DAT_I;
  wire [DataBits - 1:0] s_uartBus_cpuData_DAT_I;
  wire s_cpuData_ACK_I;
  wire s_sramSlave_cpuData_ACK_I;
  wire s_uartBus_cpuData_ACK_I;
  wire s_sramSlave_cpuData_ERR_I;
  wire s_uartBus_cpuData_ERR_I;
  wire s_cpuData_arbiterTimeOut;
  reg [15:0] s_cpuData_arbiterTimeOutCounter;
  wire [DataBits - 1:0] s_sramSlave_cpuInstr_DAT_I;
  wire [DataBits - 1:0] s_uartBus_cpuInstr_DAT_I;
  wire s_cpuInstr_ACK_I;
  wire s_sramSlave_cpuInstr_ACK_I;
  wire s_uartBus_cpuInstr_ACK_I;
  wire s_sramSlave_cpuInstr_ERR_I;
  wire s_uartBus_cpuInstr_ERR_I;
  wire s_cpuInstr_arbiterTimeOut;
  reg [15:0] s_cpuInstr_arbiterTimeOutCounter;

  // Here all master clock connections are defined
  assign debugIf_CLK_I = CLK_O;
  assign debugIf_RST_I = RST_O;
  assign cpuData_CLK_I = CLK_O;
  assign cpuData_RST_I = RST_O;
  assign cpuInstr_CLK_I = CLK_O;
  assign cpuInstr_RST_I = RST_O;

  wishBoneSlaveArbiter #(
    .AddrBits(AddrBits),
    .DataBits(DataBits),
    .BaseAddress('h0),
    .EndAddress('hffff),
    .priorityScheme(priorityScheme)
  ) arbiter0 (
    .debugIf_DAT_I(s_sramSlave_debugIf_DAT_I),
    .debugIf_DAT_O(debugIf_DAT_O),
    .debugIf_ACK_I(s_sramSlave_debugIf_ACK_I),
    .debugIf_ADDR_O(debugIf_ADDR_O),
    .debugIf_CYC_O(debugIf_CYC_O),
    .debugIf_ERR_I(s_sramSlave_debugIf_ERR_I),
    .debugIf_LOCK_O(debugIf_LOCK_O),
    .debugIf_SEL_O(debugIf_SEL_O),
    .debugIf_STB_O(debugIf_STB_O),
    .debugIf_WE_O(debugIf_WE_O),
    .debugIf_CTI_O(debugIf_CTI_O),
    .debugIf_BTE_O(debugIf_BTE_O),
    .cpuData_DAT_I(s_sramSlave_cpuData_DAT_I),
    .cpuData_DAT_O(cpuData_DAT_O),
    .cpuData_ACK_I(s_sramSlave_cpuData_ACK_I),
    .cpuData_ADDR_O(cpuData_ADDR_O),
    .cpuData_CYC_O(cpuData_CYC_O),
    .cpuData_ERR_I(s_sramSlave_cpuData_ERR_I),
    .cpuData_LOCK_O(cpuData_LOCK_O),
    .cpuData_SEL_O(cpuData_SEL_O),
    .cpuData_STB_O(cpuData_STB_O),
    .cpuData_WE_O(cpuData_WE_O),
    .cpuData_CTI_O(cpuData_CTI_O),
    .cpuData_BTE_O(cpuData_BTE_O),
    .cpuInstr_DAT_I(s_sramSlave_cpuInstr_DAT_I),
    .cpuInstr_DAT_O(cpuInstr_DAT_O),
    .cpuInstr_ACK_I(s_sramSlave_cpuInstr_ACK_I),
    .cpuInstr_ADDR_O(cpuInstr_ADDR_O),
    .cpuInstr_CYC_O(cpuInstr_CYC_O),
    .cpuInstr_ERR_I(s_sramSlave_cpuInstr_ERR_I),
    .cpuInstr_LOCK_O(cpuInstr_LOCK_O),
    .cpuInstr_SEL_O(cpuInstr_SEL_O),
    .cpuInstr_STB_O(cpuInstr_STB_O),
    .cpuInstr_WE_O(cpuInstr_WE_O),
    .cpuInstr_CTI_O(cpuInstr_CTI_O),
    .cpuInstr_BTE_O(cpuInstr_BTE_O),
    .slave_port_CLK_I(sramSlave_CLK_I),
    .slave_port_RST_I(sramSlave_RST_I),
    .slave_port_DAT_I(sramSlave_DAT_I),
    .slave_port_DAT_O(sramSlave_DAT_O),
    .slave_port_ACK_O(sramSlave_ACK_O),
    .slave_port_ADDR_I(sramSlave_ADDR_I),
    .slave_port_CYC_I(sramSlave_CYC_I),
    .slave_port_ERR_O(sramSlave_ERR_O),
    .slave_port_LOCK_I(sramSlave_LOCK_I),
    .slave_port_SEL_I(sramSlave_SEL_I),
    .slave_port_STB_I(sramSlave_STB_I),
    .slave_port_WE_I(sramSlave_WE_I),
    .slave_port_CTI_I(sramSlave_CTI_I),
    .slave_port_BTE_I(sramSlave_BTE_I),
    .CLK_O(CLK_O),
    .RST_O(RST_O));

  wishBoneSlaveArbiter #(
    .AddrBits(AddrBits),
    .DataBits(DataBits),
    .BaseAddress('h10000),
    .EndAddress('h10007),
    .priorityScheme(priorityScheme)
  ) arbiter1 (
    .debugIf_DAT_I(s_uartBus_debugIf_DAT_I),
    .debugIf_DAT_O(debugIf_DAT_O),
    .debugIf_ACK_I(s_uartBus_debugIf_ACK_I),
    .debugIf_ADDR_O(debugIf_ADDR_O),
    .debugIf_CYC_O(debugIf_CYC_O),
    .debugIf_ERR_I(s_uartBus_debugIf_ERR_I),
    .debugIf_LOCK_O(debugIf_LOCK_O),
    .debugIf_SEL_O(debugIf_SEL_O),
    .debugIf_STB_O(debugIf_STB_O),
    .debugIf_WE_O(debugIf_WE_O),
    .debugIf_CTI_O(debugIf_CTI_O),
    .debugIf_BTE_O(debugIf_BTE_O),
    .cpuData_DAT_I(s_uartBus_cpuData_DAT_I),
    .cpuData_DAT_O(cpuData_DAT_O),
    .cpuData_ACK_I(s_uartBus_cpuData_ACK_I),
    .cpuData_ADDR_O(cpuData_ADDR_O),
    .cpuData_CYC_O(cpuData_CYC_O),
    .cpuData_ERR_I(s_uartBus_cpuData_ERR_I),
    .cpuData_LOCK_O(cpuData_LOCK_O),
    .cpuData_SEL_O(cpuData_SEL_O),
    .cpuData_STB_O(cpuData_STB_O),
    .cpuData_WE_O(cpuData_WE_O),
    .cpuData_CTI_O(cpuData_CTI_O),
    .cpuData_BTE_O(cpuData_BTE_O),
    .cpuInstr_DAT_I(s_uartBus_cpuInstr_DAT_I),
    .cpuInstr_DAT_O(cpuInstr_DAT_O),
    .cpuInstr_ACK_I(s_uartBus_cpuInstr_ACK_I),
    .cpuInstr_ADDR_O(cpuInstr_ADDR_O),
    .cpuInstr_CYC_O(cpuInstr_CYC_O),
    .cpuInstr_ERR_I(s_uartBus_cpuInstr_ERR_I),
    .cpuInstr_LOCK_O(cpuInstr_LOCK_O),
    .cpuInstr_SEL_O(cpuInstr_SEL_O),
    .cpuInstr_STB_O(cpuInstr_STB_O),
    .cpuInstr_WE_O(cpuInstr_WE_O),
    .cpuInstr_CTI_O(cpuInstr_CTI_O),
    .cpuInstr_BTE_O(cpuInstr_BTE_O),
    .slave_port_CLK_I(uartBus_CLK_I),
    .slave_port_RST_I(uartBus_RST_I),
    .slave_port_DAT_I(uartBus_DAT_I),
    .slave_port_DAT_O(uartBus_DAT_O),
    .slave_port_ACK_O(uartBus_ACK_O),
    .slave_port_ADDR_I(uartBus_ADDR_I),
    .slave_port_CYC_I(uartBus_CYC_I),
    .slave_port_ERR_O(uartBus_ERR_O),
    .slave_port_LOCK_I(uartBus_LOCK_I),
    .slave_port_SEL_I(uartBus_SEL_I),
    .slave_port_STB_I(uartBus_STB_I),
    .slave_port_WE_I(uartBus_WE_I),
    .slave_port_CTI_I(uartBus_CTI_I),
    .slave_port_BTE_I(uartBus_BTE_I),
    .CLK_O(CLK_O),
    .RST_O(RST_O));

  // Here the master output signals are defined
  assign debugIf_DAT_I =
    s_sramSlave_debugIf_DAT_I |
    s_uartBus_debugIf_DAT_I;

  assign debugIf_ACK_I = s_debugIf_ACK_I;
  assign s_debugIf_ACK_I =
    s_sramSlave_debugIf_ACK_I |
    s_uartBus_debugIf_ACK_I;

  assign debugIf_ERR_I =
    s_sramSlave_debugIf_ERR_I |
    s_uartBus_debugIf_ERR_I |
    s_debugIf_arbiterTimeOut;

  assign cpuData_DAT_I =
    s_sramSlave_cpuData_DAT_I |
    s_uartBus_cpuData_DAT_I;

  assign cpuData_ACK_I = s_cpuData_ACK_I;
  assign s_cpuData_ACK_I =
    s_sramSlave_cpuData_ACK_I |
    s_uartBus_cpuData_ACK_I;

  assign cpuData_ERR_I =
    s_sramSlave_cpuData_ERR_I |
    s_uartBus_cpuData_ERR_I |
    s_cpuData_arbiterTimeOut;

  assign cpuInstr_DAT_I =
    s_sramSlave_cpuInstr_DAT_I |
    s_uartBus_cpuInstr_DAT_I;

  assign cpuInstr_ACK_I = s_cpuInstr_ACK_I;
  assign s_cpuInstr_ACK_I =
    s_sramSlave_cpuInstr_ACK_I |
    s_uartBus_cpuInstr_ACK_I;

  assign cpuInstr_ERR_I =
    s_sramSlave_cpuInstr_ERR_I |
    s_uartBus_cpuInstr_ERR_I |
    s_cpuInstr_arbiterTimeOut;

  assign s_debugIf_arbiterTimeOut = (s_debugIf_arbiterTimeOutCounter == 16'd0) ? 1'd1 : 1'd0;
  always @(posedge CLK_O)
    begin
      s_debugIf_arbiterTimeOutCounter <= (RST_O == 1'b1 || debugIf_CYC_O == 1'b0 || s_debugIf_ACK_I == 1'b1) ? {16{1'b1}} :
            (s_debugIf_arbiterTimeOut == 1'b0) ? s_debugIf_arbiterTimeOutCounter - 16'd1 : s_debugIf_arbiterTimeOutCounter;
    end

  assign s_cpuData_arbiterTimeOut = (s_cpuData_arbiterTimeOutCounter == 16'd0) ? 1'd1 : 1'd0;
  always @(posedge CLK_O)
    begin
      s_cpuData_arbiterTimeOutCounter <= (RST_O == 1'b1 || cpuData_CYC_O == 1'b0 || s_cpuData_ACK_I == 1'b1) ? {16{1'b1}} :
            (s_cpuData_arbiterTimeOut == 1'b0) ? s_cpuData_arbiterTimeOutCounter - 16'd1 : s_cpuData_arbiterTimeOutCounter;
    end

  assign s_cpuInstr_arbiterTimeOut = (s_cpuInstr_arbiterTimeOutCounter == 16'd0) ? 1'd1 : 1'd0;
  always @(posedge CLK_O)
    begin
      s_cpuInstr_arbiterTimeOutCounter <= (RST_O == 1'b1 || cpuInstr_CYC_O == 1'b0 || s_cpuInstr_ACK_I == 1'b1) ? {16{1'b1}} :
            (s_cpuInstr_arbiterTimeOut == 1'b0) ? s_cpuInstr_arbiterTimeOutCounter - 16'd1 : s_cpuInstr_arbiterTimeOutCounter;
    end

endmodule