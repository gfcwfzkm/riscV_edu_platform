module wishBoneSlaveArbiter
  #( parameter DataBits = 32,
     parameter AddrBits = 32,
     parameter BaseAddress,
     parameter EndAddress,
     parameter priorityScheme = 1)
   (
    // Here the signals for the master "debugIf" are defined
    // Note that although the signals are noted with _O/_I their direction is oposite defined
    // as they connect directly with the same signals on the master.
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

    // Here the signals for the slave "slave_port" are defined
    // Note that although the signals are noted with _O/_I their direction is oposite defined
    // as they connect directly with the same signals on the master.
    output wire slave_port_CLK_I,
    output wire slave_port_RST_I,
    output wire [DataBits - 1:0] slave_port_DAT_I,
    input  wire [DataBits - 1:0] slave_port_DAT_O,
    input  wire slave_port_ACK_O,
    output wire [AddrBits - 1:0] slave_port_ADDR_I,
    output wire slave_port_CYC_I,
    input  wire slave_port_ERR_O,
    output wire slave_port_LOCK_I,
    output wire [(DataBits / 8) - 1:0] slave_port_SEL_I,
    output wire slave_port_STB_I,
    output wire slave_port_WE_I,
    output wire [2:0] slave_port_CTI_I,
    output wire [1:0] slave_port_BTE_I,

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
  wire [DataBits - 1:0] s_masked_cpuData_DAT_O;
  wire [AddrBits - 1:0] s_masked_cpuData_ADDR_O;
  wire s_masked_cpuData_CYC_O;
  wire s_masked_cpuData_LOCK_O;
  wire [(DataBits / 8) - 1:0] s_masked_cpuData_SEL_O;
  wire s_masked_cpuData_STB_O;
  wire s_masked_cpuData_WE_O;
  wire [2:0] s_masked_cpuData_CTI_O;
  wire [1:0] s_masked_cpuData_BTE_O;
  wire [DataBits - 1:0] s_masked_cpuInstr_DAT_O;
  wire [AddrBits - 1:0] s_masked_cpuInstr_ADDR_O;
  wire s_masked_cpuInstr_CYC_O;
  wire s_masked_cpuInstr_LOCK_O;
  wire [(DataBits / 8) - 1:0] s_masked_cpuInstr_SEL_O;
  wire s_masked_cpuInstr_STB_O;
  wire s_masked_cpuInstr_WE_O;
  wire [2:0] s_masked_cpuInstr_CTI_O;
  wire [1:0] s_masked_cpuInstr_BTE_O;
  wire [2:0] s_arbiterMasterCycs;
  wire [2:0] s_arbiterMasterLocks;
  wire [2:0] s_arbiterBusEnables;
  reg [2:0] s_arbiterMaskReg;
  reg [2:0] s_arbiterEnablesReg;
  reg s_arbiterBusIsUsedReg;
  wire [2:0] s_arbiterBeforeMeCarries;
  wire [2:0] s_arbiterAferMeCarries;
  wire [2:0] s_arbiterBeforeMeMask;
  wire [2:0] s_arbiterAfterMeMask;
  wire [2:0] s_arbiterNewMask;
  wire s_arbiterServeRequest;
  wire s_arbiterIsBusRelease;

  // Here we connect all clocks and resets to the syscon
  assign slave_port_CLK_I = CLK_O;
  assign slave_port_RST_I = RST_O;

  // Here the arbiter signals are mapped
  assign s_arbiterMasterLocks[0] = (debugIf_ADDR_O >= BaseAddress && debugIf_ADDR_O <= EndAddress) ? debugIf_LOCK_O : 1'b0;
  assign s_arbiterMasterLocks[1] = (cpuData_ADDR_O >= BaseAddress && cpuData_ADDR_O <= EndAddress) ? cpuData_LOCK_O : 1'b0;
  assign s_arbiterMasterLocks[2] = (cpuInstr_ADDR_O >= BaseAddress && cpuInstr_ADDR_O <= EndAddress) ? cpuInstr_LOCK_O : 1'b0;
  assign s_arbiterMasterCycs[0] = (debugIf_ADDR_O >= BaseAddress && debugIf_ADDR_O <= EndAddress) ? debugIf_CYC_O : 1'b0;
  assign s_arbiterMasterCycs[1] = (cpuData_ADDR_O >= BaseAddress && cpuData_ADDR_O <= EndAddress) ? cpuData_CYC_O : 1'b0;
  assign s_arbiterMasterCycs[2] = (cpuInstr_ADDR_O >= BaseAddress && cpuInstr_ADDR_O <= EndAddress) ? cpuInstr_CYC_O : 1'b0;

  // Here the masked master signals are defined
  assign s_masked_debugIf_DAT_O = (s_arbiterBusEnables[0] == 1'b1) ? debugIf_DAT_O : {DataBits{1'b0}};
  assign s_masked_debugIf_ADDR_O = (s_arbiterBusEnables[0] == 1'b1) ? debugIf_ADDR_O : {AddrBits{1'b0}};
  assign s_masked_debugIf_CYC_O = (s_arbiterBusEnables[0] == 1'b1) ? debugIf_CYC_O : 1'b0;
  assign s_masked_debugIf_LOCK_O = (s_arbiterBusEnables[0] == 1'b1) ? debugIf_LOCK_O : 1'b0;
  assign s_masked_debugIf_SEL_O = (s_arbiterBusEnables[0] == 1'b1) ? debugIf_SEL_O : {(DataBits / 8){1'b0}};
  assign s_masked_debugIf_STB_O = (s_arbiterBusEnables[0] == 1'b1) ? debugIf_STB_O : 1'b0;
  assign s_masked_debugIf_WE_O = (s_arbiterBusEnables[0] == 1'b1) ? debugIf_WE_O : 1'b0;
  assign s_masked_debugIf_CTI_O = (s_arbiterBusEnables[0] == 1'b1) ? debugIf_CTI_O : {3{1'b0}};
  assign s_masked_debugIf_BTE_O = (s_arbiterBusEnables[0] == 1'b1) ? debugIf_BTE_O : {2{1'b0}};
  assign s_masked_cpuData_DAT_O = (s_arbiterBusEnables[1] == 1'b1) ? cpuData_DAT_O : {DataBits{1'b0}};
  assign s_masked_cpuData_ADDR_O = (s_arbiterBusEnables[1] == 1'b1) ? cpuData_ADDR_O : {AddrBits{1'b0}};
  assign s_masked_cpuData_CYC_O = (s_arbiterBusEnables[1] == 1'b1) ? cpuData_CYC_O : 1'b0;
  assign s_masked_cpuData_LOCK_O = (s_arbiterBusEnables[1] == 1'b1) ? cpuData_LOCK_O : 1'b0;
  assign s_masked_cpuData_SEL_O = (s_arbiterBusEnables[1] == 1'b1) ? cpuData_SEL_O : {(DataBits / 8){1'b0}};
  assign s_masked_cpuData_STB_O = (s_arbiterBusEnables[1] == 1'b1) ? cpuData_STB_O : 1'b0;
  assign s_masked_cpuData_WE_O = (s_arbiterBusEnables[1] == 1'b1) ? cpuData_WE_O : 1'b0;
  assign s_masked_cpuData_CTI_O = (s_arbiterBusEnables[1] == 1'b1) ? cpuData_CTI_O : {3{1'b0}};
  assign s_masked_cpuData_BTE_O = (s_arbiterBusEnables[1] == 1'b1) ? cpuData_BTE_O : {2{1'b0}};
  assign s_masked_cpuInstr_DAT_O = (s_arbiterBusEnables[2] == 1'b1) ? cpuInstr_DAT_O : {DataBits{1'b0}};
  assign s_masked_cpuInstr_ADDR_O = (s_arbiterBusEnables[2] == 1'b1) ? cpuInstr_ADDR_O : {AddrBits{1'b0}};
  assign s_masked_cpuInstr_CYC_O = (s_arbiterBusEnables[2] == 1'b1) ? cpuInstr_CYC_O : 1'b0;
  assign s_masked_cpuInstr_LOCK_O = (s_arbiterBusEnables[2] == 1'b1) ? cpuInstr_LOCK_O : 1'b0;
  assign s_masked_cpuInstr_SEL_O = (s_arbiterBusEnables[2] == 1'b1) ? cpuInstr_SEL_O : {(DataBits / 8){1'b0}};
  assign s_masked_cpuInstr_STB_O = (s_arbiterBusEnables[2] == 1'b1) ? cpuInstr_STB_O : 1'b0;
  assign s_masked_cpuInstr_WE_O = (s_arbiterBusEnables[2] == 1'b1) ? cpuInstr_WE_O : 1'b0;
  assign s_masked_cpuInstr_CTI_O = (s_arbiterBusEnables[2] == 1'b1) ? cpuInstr_CTI_O : {3{1'b0}};
  assign s_masked_cpuInstr_BTE_O = (s_arbiterBusEnables[2] == 1'b1) ? cpuInstr_BTE_O : {2{1'b0}};

  // Here the slave -> master databus is defined
  assign debugIf_DAT_I = (s_arbiterBusEnables[0] == 1'b1) ? slave_port_DAT_O : {DataBits{1'b0}};
  assign cpuData_DAT_I = (s_arbiterBusEnables[1] == 1'b1) ? slave_port_DAT_O : {DataBits{1'b0}};
  assign cpuInstr_DAT_I = (s_arbiterBusEnables[2] == 1'b1) ? slave_port_DAT_O : {DataBits{1'b0}};

  // Here the master -> slave databus is defined
  assign slave_port_DAT_I =
      s_masked_debugIf_DAT_O |
      s_masked_cpuData_DAT_O |
      s_masked_cpuInstr_DAT_O;

  // Here all master inputs are mapped
  assign debugIf_ACK_I = slave_port_ACK_O & s_arbiterBusEnables[0];
  assign debugIf_ERR_I = slave_port_ERR_O & s_arbiterBusEnables[0];
  assign cpuData_ACK_I = slave_port_ACK_O & s_arbiterBusEnables[1];
  assign cpuData_ERR_I = slave_port_ERR_O & s_arbiterBusEnables[1];
  assign cpuInstr_ACK_I = slave_port_ACK_O & s_arbiterBusEnables[2];
  assign cpuInstr_ERR_I = slave_port_ERR_O & s_arbiterBusEnables[2];

  // Here all slave inputs are mapped
  assign slave_port_ADDR_I =
      s_masked_debugIf_ADDR_O |
      s_masked_cpuData_ADDR_O |
      s_masked_cpuInstr_ADDR_O;
  assign slave_port_CYC_I =
      s_masked_debugIf_CYC_O |
      s_masked_cpuData_CYC_O |
      s_masked_cpuInstr_CYC_O;
  assign slave_port_LOCK_I =
      s_masked_debugIf_LOCK_O |
      s_masked_cpuData_LOCK_O |
      s_masked_cpuInstr_LOCK_O;
  assign slave_port_SEL_I =
      s_masked_debugIf_SEL_O |
      s_masked_cpuData_SEL_O |
      s_masked_cpuInstr_SEL_O;
  assign slave_port_STB_I =
      s_masked_debugIf_STB_O |
      s_masked_cpuData_STB_O |
      s_masked_cpuInstr_STB_O;
  assign slave_port_WE_I =
      s_masked_debugIf_WE_O |
      s_masked_cpuData_WE_O |
      s_masked_cpuInstr_WE_O;
  assign slave_port_CTI_I =
      s_masked_debugIf_CTI_O |
      s_masked_cpuData_CTI_O |
      s_masked_cpuInstr_CTI_O;
  assign slave_port_BTE_I =
      s_masked_debugIf_BTE_O |
      s_masked_cpuData_BTE_O |
      s_masked_cpuInstr_BTE_O;

  // Here the arbiter is defined
  assign s_arbiterBusEnables = s_arbiterEnablesReg;
  assign s_arbiterBeforeMeCarries[0] = ~s_arbiterMasterCycs[0];
  assign s_arbiterAferMeCarries[0] = 1'b0;
  assign s_arbiterBeforeMeMask[0] = s_arbiterMasterCycs[0];
  assign s_arbiterAfterMeMask[0] = 1'b0;
  assign s_arbiterIsBusRelease = (((s_arbiterMasterCycs & s_arbiterEnablesReg) == 3'd0) && ((s_arbiterMasterLocks & s_arbiterEnablesReg) == 3'd0)) ? s_arbiterBusIsUsedReg : 1'b0;
  assign s_arbiterNewMask = (priorityScheme == 1 || s_arbiterAfterMeMask == 3'd0) ? s_arbiterBeforeMeMask : s_arbiterAfterMeMask;
  assign s_arbiterServeRequest = (s_arbiterMasterCycs != 3'd0 && s_arbiterBusIsUsedReg == 1'b0) ? 1'b1 : 1'b0;

  genvar i;
  generate
    for (i = 1; i < 3; i = i + 1)
    begin : arbiterGen
      assign s_arbiterBeforeMeCarries[i] = s_arbiterBeforeMeCarries[i-1] & ~s_arbiterMasterCycs[i];
      assign s_arbiterBeforeMeMask[i] = s_arbiterMasterCycs[i] & s_arbiterBeforeMeCarries[i-1];
      assign s_arbiterAferMeCarries[i] = s_arbiterMaskReg[i] | (s_arbiterAferMeCarries[i-1] & ~s_arbiterMasterCycs[i]);
      assign s_arbiterAfterMeMask[i] = s_arbiterAferMeCarries[i-1] & s_arbiterMasterCycs[i];
    end
  endgenerate

  always @(posedge CLK_O)
  begin
    s_arbiterBusIsUsedReg <= (RST_O == 1'b1 || s_arbiterIsBusRelease == 1'b1) ? 1'b0 : (s_arbiterServeRequest == 1'b1) ? 1'b1 : s_arbiterBusIsUsedReg;
    s_arbiterEnablesReg <= (RST_O == 1'b1 || s_arbiterIsBusRelease == 1'b1) ? 3'd0 : (s_arbiterServeRequest == 1'b1) ? s_arbiterNewMask : s_arbiterEnablesReg;
    s_arbiterMaskReg <= (s_arbiterServeRequest == 1'b1) ? s_arbiterNewMask : (s_arbiterBusIsUsedReg == 1'b0) ? 3'd0 : s_arbiterMaskReg;
  end

endmodule