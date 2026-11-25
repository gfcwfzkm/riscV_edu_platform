localparam AddrBits = 32;
localparam DataBits = 32;
localparam priorityScheme = 1;

// Here all signals are defined that are used to connect the
// master and slaves to the shared bus component.
// You can copy-paste them in your toplevel file.

  wire s_debugIf_CLK_I;
  wire s_debugIf_RST_I;
  wire [DataBits - 1:0] s_debugIf_DAT_I;
  wire [DataBits - 1:0] s_debugIf_DAT_O;
  wire s_debugIf_ACK_I;
  wire [AddrBits - 1:0] s_debugIf_ADDR_O;
  wire s_debugIf_CYC_O;
  wire s_debugIf_ERR_I;
  wire s_debugIf_LOCK_O;
  wire [(DataBits / 8) - 1:0] s_debugIf_SEL_O;
  wire s_debugIf_STB_O;
  wire s_debugIf_WE_O;
  wire [2:0] s_debugIf_CTI_O;
  wire [1:0] s_debugIf_BTE_O;
  wire s_cpuData_CLK_I;
  wire s_cpuData_RST_I;
  wire [DataBits - 1:0] s_cpuData_DAT_I;
  wire [DataBits - 1:0] s_cpuData_DAT_O;
  wire s_cpuData_ACK_I;
  wire [AddrBits - 1:0] s_cpuData_ADDR_O;
  wire s_cpuData_CYC_O;
  wire s_cpuData_ERR_I;
  wire s_cpuData_LOCK_O;
  wire [(DataBits / 8) - 1:0] s_cpuData_SEL_O;
  wire s_cpuData_STB_O;
  wire s_cpuData_WE_O;
  wire [2:0] s_cpuData_CTI_O;
  wire [1:0] s_cpuData_BTE_O;
  wire s_cpuInstr_CLK_I;
  wire s_cpuInstr_RST_I;
  wire [DataBits - 1:0] s_cpuInstr_DAT_I;
  wire [DataBits - 1:0] s_cpuInstr_DAT_O;
  wire s_cpuInstr_ACK_I;
  wire [AddrBits - 1:0] s_cpuInstr_ADDR_O;
  wire s_cpuInstr_CYC_O;
  wire s_cpuInstr_ERR_I;
  wire s_cpuInstr_LOCK_O;
  wire [(DataBits / 8) - 1:0] s_cpuInstr_SEL_O;
  wire s_cpuInstr_STB_O;
  wire s_cpuInstr_WE_O;
  wire [2:0] s_cpuInstr_CTI_O;
  wire [1:0] s_cpuInstr_BTE_O;
  wire s_sramSlave_CLK_I;
  wire s_sramSlave_RST_I;
  wire [DataBits - 1:0] s_sramSlave_DAT_I;
  wire [DataBits - 1:0] s_sramSlave_DAT_O;
  wire s_sramSlave_ACK_O;
  wire [AddrBits - 1:0] s_sramSlave_ADDR_I;
  wire s_sramSlave_CYC_I;
  wire s_sramSlave_ERR_O;
  wire s_sramSlave_LOCK_I;
  wire [(DataBits / 8) - 1:0] s_sramSlave_SEL_I;
  wire s_sramSlave_STB_I;
  wire s_sramSlave_WE_I;
  wire [2:0] s_sramSlave_CTI_I;
  wire [1:0] s_sramSlave_BTE_I;
  wire s_uartBus_CLK_I;
  wire s_uartBus_RST_I;
  wire [DataBits - 1:0] s_uartBus_DAT_I;
  wire [DataBits - 1:0] s_uartBus_DAT_O;
  wire s_uartBus_ACK_O;
  wire [AddrBits - 1:0] s_uartBus_ADDR_I;
  wire s_uartBus_CYC_I;
  wire s_uartBus_ERR_O;
  wire s_uartBus_LOCK_I;
  wire [(DataBits / 8) - 1:0] s_uartBus_SEL_I;
  wire s_uartBus_STB_I;
  wire s_uartBus_WE_I;
  wire [2:0] s_uartBus_CTI_I;
  wire [1:0] s_uartBus_BTE_I;
  wire s_SYSCON_CLK_O;
  wire s_SYSCON_RST_O;

// Here all your master and slave connections are mapped
// Probably you have to change it slightly to adapt to your
// masters/slaves

  debugIf #(
    .AddrBits(AddrBits),
    .DataBits(DataBits)
  ) busMaster_debugIf (
    .CLK_I(s_debugIf_CLK_I),
    .RST_I(s_debugIf_RST_I),
    .DAT_I(s_debugIf_DAT_I),
    .DAT_O(s_debugIf_DAT_O),
    .ACK_I(s_debugIf_ACK_I),
    .ADDR_O(s_debugIf_ADDR_O),
    .CYC_O(s_debugIf_CYC_O),
    .ERR_I(s_debugIf_ERR_I),
    .LOCK_O(s_debugIf_LOCK_O),
    .SEL_O(s_debugIf_SEL_O),
    .STB_O(s_debugIf_STB_O),
    .WE_O(s_debugIf_WE_O),
    .CTI_O(s_debugIf_CTI_O),
    .BTE_O(s_debugIf_BTE_O));

  cpuData #(
    .AddrBits(AddrBits),
    .DataBits(DataBits)
  ) busMaster_cpuData (
    .CLK_I(s_cpuData_CLK_I),
    .RST_I(s_cpuData_RST_I),
    .DAT_I(s_cpuData_DAT_I),
    .DAT_O(s_cpuData_DAT_O),
    .ACK_I(s_cpuData_ACK_I),
    .ADDR_O(s_cpuData_ADDR_O),
    .CYC_O(s_cpuData_CYC_O),
    .ERR_I(s_cpuData_ERR_I),
    .LOCK_O(s_cpuData_LOCK_O),
    .SEL_O(s_cpuData_SEL_O),
    .STB_O(s_cpuData_STB_O),
    .WE_O(s_cpuData_WE_O),
    .CTI_O(s_cpuData_CTI_O),
    .BTE_O(s_cpuData_BTE_O));

  cpuInstr #(
    .AddrBits(AddrBits),
    .DataBits(DataBits)
  ) busMaster_cpuInstr (
    .CLK_I(s_cpuInstr_CLK_I),
    .RST_I(s_cpuInstr_RST_I),
    .DAT_I(s_cpuInstr_DAT_I),
    .DAT_O(s_cpuInstr_DAT_O),
    .ACK_I(s_cpuInstr_ACK_I),
    .ADDR_O(s_cpuInstr_ADDR_O),
    .CYC_O(s_cpuInstr_CYC_O),
    .ERR_I(s_cpuInstr_ERR_I),
    .LOCK_O(s_cpuInstr_LOCK_O),
    .SEL_O(s_cpuInstr_SEL_O),
    .STB_O(s_cpuInstr_STB_O),
    .WE_O(s_cpuInstr_WE_O),
    .CTI_O(s_cpuInstr_CTI_O),
    .BTE_O(s_cpuInstr_BTE_O));

  sramSlave #(
    .BaseAddress('h0),
    .AddrBits(AddrBits),
    .DataBits(DataBits)
  ) busSlave_sramSlave (
    .CLK_I(s_sramSlave_CLK_I),
    .RST_I(s_sramSlave_RST_I),
    .DAT_I(s_sramSlave_DAT_I),
    .DAT_O(s_sramSlave_DAT_O),
    .ACK_O(s_sramSlave_ACK_O),
    .ADDR_I(s_sramSlave_ADDR_I),
    .CYC_I(s_sramSlave_CYC_I),
    .ERR_O(s_sramSlave_ERR_O),
    .LOCK_I(s_sramSlave_LOCK_I),
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
    .LOCK_I(s_uartBus_LOCK_I),
    .SEL_I(s_uartBus_SEL_I),
    .STB_I(s_uartBus_STB_I),
    .WE_I(s_uartBus_WE_I),
    .CTI_I(s_uartBus_CTI_I),
    .BTE_I(s_uartBus_BTE_I));

//Finally here the wishboneBus is mapped
  wishBoneCrossbarBusTop #(
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

