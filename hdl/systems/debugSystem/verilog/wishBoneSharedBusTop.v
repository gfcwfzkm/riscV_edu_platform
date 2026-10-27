module wishBoneSharedBusTop
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

  wire [DataBits - 1:0] s_masked_debugIf_DAT_O;
  wire [AddrBits - 1:0] s_masked_debugIf_ADDR_O;
  wire s_masked_debugIf_CYC_O;
  wire s_masked_debugIf_LOCK_O;
  wire [(DataBits / 8) - 1:0] s_masked_debugIf_SEL_O;
  wire s_masked_debugIf_STB_O;
  wire s_masked_debugIf_WE_O;
  wire [2:0] s_masked_debugIf_CTI_O;
  wire [1:0] s_masked_debugIf_BTE_O;
  wire [DataBits - 1:0] s_masked_sramSlave_DAT_O;
  wire [DataBits - 1:0] s_masked_leds_DAT_O;
  wire [DataBits - 1:0] s_masked_sevenSegments_DAT_O;
  wire [DataBits - 1:0] s_masked_uartBus_DAT_O;
  wire [DataBits - 1:0] s_sharedBusMaster_DAT;
  wire s_sharedBusMaster_ACK;
  wire s_sharedBusMaster_ERR;
  wire [DataBits - 1:0] s_sharedBusSlave_DAT;
  wire [AddrBits - 1:0] s_sharedBusSlave_ADDR;
  wire s_sharedBusSlave_CYC;
  wire s_sharedBusSlave_LOCK;
  wire [(DataBits / 8) - 1:0] s_sharedBusSlave_SEL;
  wire s_sharedBusSlave_STB;
  wire s_sharedBusSlave_WE;
  wire [2:0] s_sharedBusSlave_CTI;
  wire [1:0] s_sharedBusSlave_BTE;
  wire s_arbiterMasterCycs;
  wire s_arbiterMasterLocks;
  wire s_arbiterBusEnables;
  wire s_arbiterErrorOut;
  reg s_arbiterMaskReg;
  reg s_arbiterEnablesReg;
  reg [15:0] s_arbiterTimeOutReg;
  reg s_arbiterBusIsUsedReg;
  wire s_arbiterBeforeMeCarries;
  wire s_arbiterAferMeCarries;
  wire s_arbiterBeforeMeMask;
  wire s_arbiterAfterMeMask;
  wire s_arbiterNewMask;
  wire s_arbiterServeRequest;
  wire s_arbiterIsTimeOut;
  wire s_arbiterIsBusRelease;

  // Here we connect all clocks and resets to the syscon
  assign debugIf_CLK_I = CLK_O;
  assign debugIf_RST_I = RST_O;
  assign sramSlave_CLK_I = CLK_O;
  assign sramSlave_RST_I = RST_O;
  assign leds_CLK_I = CLK_O;
  assign leds_RST_I = RST_O;
  assign sevenSegments_CLK_I = CLK_O;
  assign sevenSegments_RST_I = RST_O;
  assign uartBus_CLK_I = CLK_O;
  assign uartBus_RST_I = RST_O;

  // Here the arbiter signals are mapped
  assign s_arbiterMasterLocks = debugIf_LOCK_O;
  assign s_arbiterMasterCycs = debugIf_CYC_O;

  // Here the masked slave signals are defined
  assign s_masked_sramSlave_DAT_O = (sramSlave_ACK_O == 1'b1) ? sramSlave_DAT_O : {DataBits{1'b0}};
  assign s_masked_leds_DAT_O = (leds_ACK_O == 1'b1) ? leds_DAT_O : {DataBits{1'b0}};
  assign s_masked_sevenSegments_DAT_O = (sevenSegments_ACK_O == 1'b1) ? sevenSegments_DAT_O : {DataBits{1'b0}};
  assign s_masked_uartBus_DAT_O = (uartBus_ACK_O == 1'b1) ? uartBus_DAT_O : {DataBits{1'b0}};

  // Here the masked master signals are defined
  assign s_masked_debugIf_DAT_O = (s_arbiterBusEnables == 1'b1) ? debugIf_DAT_O : {DataBits{1'b0}};
  assign s_masked_debugIf_ADDR_O = (s_arbiterBusEnables == 1'b1) ? debugIf_ADDR_O : {AddrBits{1'b0}};
  assign s_masked_debugIf_CYC_O = (s_arbiterBusEnables == 1'b1) ? debugIf_CYC_O : 1'b0;
  assign s_masked_debugIf_LOCK_O = (s_arbiterBusEnables == 1'b1) ? debugIf_LOCK_O : 1'b0;
  assign s_masked_debugIf_SEL_O = (s_arbiterBusEnables == 1'b1) ? debugIf_SEL_O : {(DataBits / 8){1'b0}};
  assign s_masked_debugIf_STB_O = (s_arbiterBusEnables == 1'b1) ? debugIf_STB_O : 1'b0;
  assign s_masked_debugIf_WE_O = (s_arbiterBusEnables == 1'b1) ? debugIf_WE_O : 1'b0;
  assign s_masked_debugIf_CTI_O = (s_arbiterBusEnables == 1'b1) ? debugIf_CTI_O : {3{1'b0}};
  assign s_masked_debugIf_BTE_O = (s_arbiterBusEnables == 1'b1) ? debugIf_BTE_O : {2{1'b0}};

  // Here the slave -> master databus is defined
  assign debugIf_DAT_I = s_sharedBusMaster_DAT;
  assign s_sharedBusMaster_DAT =
      s_masked_sramSlave_DAT_O |
      s_masked_leds_DAT_O |
      s_masked_sevenSegments_DAT_O |
      s_masked_uartBus_DAT_O;

  // Here the master -> slave databus is defined
  assign sramSlave_DAT_I = s_sharedBusSlave_DAT;
  assign leds_DAT_I = s_sharedBusSlave_DAT;
  assign sevenSegments_DAT_I = s_sharedBusSlave_DAT;
  assign uartBus_DAT_I = s_sharedBusSlave_DAT;
  assign s_sharedBusSlave_DAT =
      s_masked_debugIf_DAT_O;

  // Here all master inputs are mapped
  assign debugIf_ACK_I = s_sharedBusMaster_ACK & s_arbiterBusEnables;
  assign debugIf_ERR_I = s_sharedBusMaster_ERR & s_arbiterBusEnables;
  assign s_sharedBusMaster_ACK =
      sramSlave_ACK_O |
      leds_ACK_O |
      sevenSegments_ACK_O |
      uartBus_ACK_O;
  assign s_sharedBusMaster_ERR =
      s_arbiterErrorOut |
      sramSlave_ERR_O |
      leds_ERR_O |
      sevenSegments_ERR_O |
      uartBus_ERR_O;

  // Here all slave inputs are mapped
  assign sramSlave_ADDR_I = s_sharedBusSlave_ADDR;
  assign sramSlave_CYC_I = s_sharedBusSlave_CYC;
  assign sramSlave_LOCK_I = s_sharedBusSlave_LOCK;
  assign sramSlave_SEL_I = s_sharedBusSlave_SEL;
  assign sramSlave_STB_I = s_sharedBusSlave_STB;
  assign sramSlave_WE_I = s_sharedBusSlave_WE;
  assign sramSlave_CTI_I = s_sharedBusSlave_CTI;
  assign sramSlave_BTE_I = s_sharedBusSlave_BTE;
  assign leds_ADDR_I = s_sharedBusSlave_ADDR;
  assign leds_CYC_I = s_sharedBusSlave_CYC;
  assign leds_LOCK_I = s_sharedBusSlave_LOCK;
  assign leds_SEL_I = s_sharedBusSlave_SEL;
  assign leds_STB_I = s_sharedBusSlave_STB;
  assign leds_WE_I = s_sharedBusSlave_WE;
  assign leds_CTI_I = s_sharedBusSlave_CTI;
  assign leds_BTE_I = s_sharedBusSlave_BTE;
  assign sevenSegments_ADDR_I = s_sharedBusSlave_ADDR;
  assign sevenSegments_CYC_I = s_sharedBusSlave_CYC;
  assign sevenSegments_LOCK_I = s_sharedBusSlave_LOCK;
  assign sevenSegments_SEL_I = s_sharedBusSlave_SEL;
  assign sevenSegments_STB_I = s_sharedBusSlave_STB;
  assign sevenSegments_WE_I = s_sharedBusSlave_WE;
  assign sevenSegments_CTI_I = s_sharedBusSlave_CTI;
  assign sevenSegments_BTE_I = s_sharedBusSlave_BTE;
  assign uartBus_ADDR_I = s_sharedBusSlave_ADDR;
  assign uartBus_CYC_I = s_sharedBusSlave_CYC;
  assign uartBus_LOCK_I = s_sharedBusSlave_LOCK;
  assign uartBus_SEL_I = s_sharedBusSlave_SEL;
  assign uartBus_STB_I = s_sharedBusSlave_STB;
  assign uartBus_WE_I = s_sharedBusSlave_WE;
  assign uartBus_CTI_I = s_sharedBusSlave_CTI;
  assign uartBus_BTE_I = s_sharedBusSlave_BTE;
  assign s_sharedBusSlave_ADDR =
      s_masked_debugIf_ADDR_O;
  assign s_sharedBusSlave_CYC =
      s_masked_debugIf_CYC_O;
  assign s_sharedBusSlave_LOCK =
      s_masked_debugIf_LOCK_O;
  assign s_sharedBusSlave_SEL =
      s_masked_debugIf_SEL_O;
  assign s_sharedBusSlave_STB =
      s_masked_debugIf_STB_O;
  assign s_sharedBusSlave_WE =
      s_masked_debugIf_WE_O;
  assign s_sharedBusSlave_CTI =
      s_masked_debugIf_CTI_O;
  assign s_sharedBusSlave_BTE =
      s_masked_debugIf_BTE_O;

  // Here the arbiter is defined
  assign s_arbiterBusEnables = 1'b1;
  assign s_arbiterErrorOut = s_arbiterIsTimeOut;
  assign s_arbiterIsTimeOut = (s_arbiterTimeOutReg == 16'd0) ? 1'b1 : 1'b0;
  always @(posedge CLK_O)
  begin
    s_arbiterTimeOutReg <= (debugIf_CYC_O == 1'b0 || s_sharedBusMaster_ACK == 1'b1) ? {16{1'b1}} : (s_arbiterIsTimeOut == 1'b0) ? s_arbiterTimeOutReg - 16'd1 : s_arbiterTimeOutReg;
  end
endmodule
