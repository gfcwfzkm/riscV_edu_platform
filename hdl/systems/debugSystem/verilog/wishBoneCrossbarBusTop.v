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

    // Here the signals for the slave "leds" are defined
    // Note that although the signals are noted with _O/_I their direction is oposite defined
    // as they connect directly with the same signals on the master.
    output wire leds_CLK_I,
    output wire leds_RST_I,
    output wire [DataBits - 1:0] leds_DAT_I,
    input  wire [DataBits - 1:0] leds_DAT_O,
    input  wire leds_ACK_O,
    output wire [AddrBits - 1:0] leds_ADDR_I,
    output wire leds_CYC_I,
    input  wire leds_ERR_O,
    output wire leds_LOCK_I,
    output wire [(DataBits / 8) - 1:0] leds_SEL_I,
    output wire leds_STB_I,
    output wire leds_WE_I,
    output wire [2:0] leds_CTI_I,
    output wire [1:0] leds_BTE_I,

    // Here the signals for the slave "sevenSegments" are defined
    // Note that although the signals are noted with _O/_I their direction is oposite defined
    // as they connect directly with the same signals on the master.
    output wire sevenSegments_CLK_I,
    output wire sevenSegments_RST_I,
    output wire [DataBits - 1:0] sevenSegments_DAT_I,
    input  wire [DataBits - 1:0] sevenSegments_DAT_O,
    input  wire sevenSegments_ACK_O,
    output wire [AddrBits - 1:0] sevenSegments_ADDR_I,
    output wire sevenSegments_CYC_I,
    input  wire sevenSegments_ERR_O,
    output wire sevenSegments_LOCK_I,
    output wire [(DataBits / 8) - 1:0] sevenSegments_SEL_I,
    output wire sevenSegments_STB_I,
    output wire sevenSegments_WE_I,
    output wire [2:0] sevenSegments_CTI_I,
    output wire [1:0] sevenSegments_BTE_I,

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
  wire [DataBits - 1:0] s_leds_debugIf_DAT_I;
  wire [DataBits - 1:0] s_sevenSegments_debugIf_DAT_I;
  wire [DataBits - 1:0] s_uartBus_debugIf_DAT_I;
  wire s_debugIf_ACK_I;
  wire s_sramSlave_debugIf_ACK_I;
  wire s_leds_debugIf_ACK_I;
  wire s_sevenSegments_debugIf_ACK_I;
  wire s_uartBus_debugIf_ACK_I;
  wire s_sramSlave_debugIf_ERR_I;
  wire s_leds_debugIf_ERR_I;
  wire s_sevenSegments_debugIf_ERR_I;
  wire s_uartBus_debugIf_ERR_I;
  wire s_debugIf_arbiterTimeOut;
  reg [15:0] s_debugIf_arbiterTimeOutCounter;

  // Here all master clock connections are defined
  assign debugIf_CLK_I = CLK_O;
  assign debugIf_RST_I = RST_O;

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
    .EndAddress('h107ff),
    .priorityScheme(priorityScheme)
  ) arbiter1 (
    .debugIf_DAT_I(s_leds_debugIf_DAT_I),
    .debugIf_DAT_O(debugIf_DAT_O),
    .debugIf_ACK_I(s_leds_debugIf_ACK_I),
    .debugIf_ADDR_O(debugIf_ADDR_O),
    .debugIf_CYC_O(debugIf_CYC_O),
    .debugIf_ERR_I(s_leds_debugIf_ERR_I),
    .debugIf_LOCK_O(debugIf_LOCK_O),
    .debugIf_SEL_O(debugIf_SEL_O),
    .debugIf_STB_O(debugIf_STB_O),
    .debugIf_WE_O(debugIf_WE_O),
    .debugIf_CTI_O(debugIf_CTI_O),
    .debugIf_BTE_O(debugIf_BTE_O),
    .slave_port_CLK_I(leds_CLK_I),
    .slave_port_RST_I(leds_RST_I),
    .slave_port_DAT_I(leds_DAT_I),
    .slave_port_DAT_O(leds_DAT_O),
    .slave_port_ACK_O(leds_ACK_O),
    .slave_port_ADDR_I(leds_ADDR_I),
    .slave_port_CYC_I(leds_CYC_I),
    .slave_port_ERR_O(leds_ERR_O),
    .slave_port_LOCK_I(leds_LOCK_I),
    .slave_port_SEL_I(leds_SEL_I),
    .slave_port_STB_I(leds_STB_I),
    .slave_port_WE_I(leds_WE_I),
    .slave_port_CTI_I(leds_CTI_I),
    .slave_port_BTE_I(leds_BTE_I),
    .CLK_O(CLK_O),
    .RST_O(RST_O));

  wishBoneSlaveArbiter #(
    .AddrBits(AddrBits),
    .DataBits(DataBits),
    .BaseAddress('h10800),
    .EndAddress('h1081f),
    .priorityScheme(priorityScheme)
  ) arbiter2 (
    .debugIf_DAT_I(s_sevenSegments_debugIf_DAT_I),
    .debugIf_DAT_O(debugIf_DAT_O),
    .debugIf_ACK_I(s_sevenSegments_debugIf_ACK_I),
    .debugIf_ADDR_O(debugIf_ADDR_O),
    .debugIf_CYC_O(debugIf_CYC_O),
    .debugIf_ERR_I(s_sevenSegments_debugIf_ERR_I),
    .debugIf_LOCK_O(debugIf_LOCK_O),
    .debugIf_SEL_O(debugIf_SEL_O),
    .debugIf_STB_O(debugIf_STB_O),
    .debugIf_WE_O(debugIf_WE_O),
    .debugIf_CTI_O(debugIf_CTI_O),
    .debugIf_BTE_O(debugIf_BTE_O),
    .slave_port_CLK_I(sevenSegments_CLK_I),
    .slave_port_RST_I(sevenSegments_RST_I),
    .slave_port_DAT_I(sevenSegments_DAT_I),
    .slave_port_DAT_O(sevenSegments_DAT_O),
    .slave_port_ACK_O(sevenSegments_ACK_O),
    .slave_port_ADDR_I(sevenSegments_ADDR_I),
    .slave_port_CYC_I(sevenSegments_CYC_I),
    .slave_port_ERR_O(sevenSegments_ERR_O),
    .slave_port_LOCK_I(sevenSegments_LOCK_I),
    .slave_port_SEL_I(sevenSegments_SEL_I),
    .slave_port_STB_I(sevenSegments_STB_I),
    .slave_port_WE_I(sevenSegments_WE_I),
    .slave_port_CTI_I(sevenSegments_CTI_I),
    .slave_port_BTE_I(sevenSegments_BTE_I),
    .CLK_O(CLK_O),
    .RST_O(RST_O));

  wishBoneSlaveArbiter #(
    .AddrBits(AddrBits),
    .DataBits(DataBits),
    .BaseAddress('h10820),
    .EndAddress('h10827),
    .priorityScheme(priorityScheme)
  ) arbiter3 (
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
    s_leds_debugIf_DAT_I |
    s_sevenSegments_debugIf_DAT_I |
    s_uartBus_debugIf_DAT_I;

  assign debugIf_ACK_I = s_debugIf_ACK_I;
  assign s_debugIf_ACK_I =
    s_sramSlave_debugIf_ACK_I |
    s_leds_debugIf_ACK_I |
    s_sevenSegments_debugIf_ACK_I |
    s_uartBus_debugIf_ACK_I;

  assign debugIf_ERR_I =
    s_sramSlave_debugIf_ERR_I |
    s_leds_debugIf_ERR_I |
    s_sevenSegments_debugIf_ERR_I |
    s_uartBus_debugIf_ERR_I |
    s_debugIf_arbiterTimeOut;

  assign s_debugIf_arbiterTimeOut = (s_debugIf_arbiterTimeOutCounter == 16'd0) ? 1'd1 : 1'd0;
  always @(posedge CLK_O)
    begin
      s_debugIf_arbiterTimeOutCounter <= (RST_O == 1'b1 || debugIf_CYC_O == 1'b0 || s_debugIf_ACK_I == 1'b1) ? {16{1'b1}} :
            (s_debugIf_arbiterTimeOut == 1'b0) ? s_debugIf_arbiterTimeOutCounter - 16'd1 : s_debugIf_arbiterTimeOutCounter;
    end

endmodule