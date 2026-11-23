/*****************************************************************************\
|                      Copyright (C) 2021-2022 Luke Wren                      |
|                     SPDX-License-Identifier: Apache-2.0                     |
|                                                                             |
|                     Modified 2026 by Theo Kluter                            |
|                     Changes:                                                |
|                      - Moved to active-high reset                           |
|                      - Moved to synchronous reset                           |
|                      - Added external reset vector                          |
|                      - Added external mtvec_init vector                     |
|                     Wishbone variant of hazard3_cpu_2port:                  |
|                      - AHB5 ports replaced by Wishbone B4 classic masters   |
|                        (hazard3_wb_master, registered address/control)      |
|                      - Debug system bus patch-through removed (the debug    |
|                        module has its own Wishbone master)                  |
|                      - No global exclusive monitor: hexokay tied high       |
\*****************************************************************************/

// Dual-ported top level file for Hazard3 CPU. This file instantiates the
// Hazard3 core, and interfaces its instruction fetch and load/store signals
// to a pair of Wishbone B4 classic master ports.

`ifdef HAZARD3_RVFI_STANDALONE
`include "hazard3_rvfi_standalone_defs.vh"
`endif

`default_nettype none

module hazard3_cpu_2port_wb #(
`include "hazard3_config.vh"
) (
	// Global signals
	input wire                clk,
	input wire                clk_always_on,
	input wire                rst,
	input wire [31:0]         reset_vector,
	input wire [31:0]         mtvec_init,

	// Power control signals
	output wire               pwrup_req,
	input  wire               pwrup_ack,
	output wire               clk_en,
	output wire               unblock_out,
	input  wire               unblock_in,

	`ifdef RISCV_FORMAL
	`RVFI_OUTPUTS ,
	`endif

	// Instruction fetch port: Wishbone B4 classic master (read-only)
	output wire               i_CYC_O,
	output wire               i_STB_O,
	output wire [W_ADDR-1:0]  i_ADDR_O,
	output wire [3:0]         i_SEL_O,
	output wire               i_WE_O,
	output wire [W_DATA-1:0]  i_DAT_O,
	output wire [2:0]         i_CTI_O,
	output wire [1:0]         i_BTE_O,
	output wire               i_LOCK_O,
	input  wire               i_ACK_I,
	input  wire               i_ERR_I,
	input  wire [W_DATA-1:0]  i_DAT_I,

	// Load/store port: Wishbone B4 classic master
	output wire               d_CYC_O,
	output wire               d_STB_O,
	output wire [W_ADDR-1:0]  d_ADDR_O,
	output wire [3:0]         d_SEL_O,
	output wire               d_WE_O,
	output wire [W_DATA-1:0]  d_DAT_O,
	output wire [2:0]         d_CTI_O,
	output wire [1:0]         d_BTE_O,
	output wire               d_LOCK_O,
	input  wire               d_ACK_I,
	input  wire               d_ERR_I,
	input  wire [W_DATA-1:0]  d_DAT_I,

	// Memory ordering signals
	output wire               fence_i_vld,
	output wire               fence_d_vld,
	input  wire               fence_rdy,

	// Debugger run/halt control
	input  wire               dbg_req_halt,
	input  wire               dbg_req_halt_on_reset,
	input  wire               dbg_req_resume,
	output wire               dbg_halted,
	output wire               dbg_running,
	// Debugger access to data0 CSR
	input  wire [W_DATA-1:0]  dbg_data0_rdata,
	output wire [W_DATA-1:0]  dbg_data0_wdata,
	output wire               dbg_data0_wen,
	// Debugger instruction injection
	input  wire [W_DATA-1:0]  dbg_instr_data,
	input  wire               dbg_instr_data_vld,
	output wire               dbg_instr_data_rdy,
	output wire               dbg_instr_caught_exception,
	output wire               dbg_instr_caught_ebreak,
	// Identification CSR values
	input  wire [W_DATA-1:0]  mhartid_val,
	input  wire [3:0]         eco_version,

	// Level-sensitive interrupt sources
	input wire [NUM_IRQS-1:0] irq,       // -> mip.meip
	input wire                soft_irq,  // -> mip.msip
	input wire                timer_irq, // -> mip.mtip

	// custom-instruction interface (nios II compatible)
	output wire	[6:0]		  ci_id,
	output wire               ci_start,
	output wire [W_DATA-1:0]  ci_dataa,
	output wire [W_DATA-1:0]  ci_datab,
	input  wire               ci_done,
	input  wire [W_DATA-1:0]  ci_result
);

// ----------------------------------------------------------------------------
// Processor core

// Instruction fetch signals
wire              core_aph_req_i;
wire              core_aph_ready_i;
wire              core_dph_ready_i;
wire              core_dph_err_i;

wire [W_ADDR-1:0] core_haddr_i;
wire [2:0]        core_hsize_i;
wire              core_priv_i;
wire [W_DATA-1:0] core_rdata_i;


// Load/store signals
wire              core_aph_req_d;
wire              core_aph_excl_d;
wire              core_aph_ready_d;
wire              core_dph_ready_d;
wire              core_dph_err_d;
wire              core_dph_exokay_d;

wire [W_ADDR-1:0] core_haddr_d;
wire [2:0]        core_hsize_d;
wire              core_priv_d;
wire              core_hwrite_d;
wire [W_DATA-1:0] core_wdata_d;
wire [W_DATA-1:0] core_rdata_d;

hazard3_core #(
`include "hazard3_config_inst.vh"
) core (
	.clk                        (clk),
	.clk_always_on              (clk_always_on),
	.rst                        (rst),
	.reset_vector               (reset_vector),
	.mtvec_init                 (mtvec_init),

	.pwrup_req                  (pwrup_req),
	.pwrup_ack                  (pwrup_ack),
	.clk_en                     (clk_en),
	.unblock_out                (unblock_out),
	.unblock_in                 (unblock_in),

	`ifdef RISCV_FORMAL
	`RVFI_CONN ,
	`endif

	.bus_aph_req_i              (core_aph_req_i),
	.bus_aph_panic_i            (/* unused for 2port */),
	.bus_aph_ready_i            (core_aph_ready_i),
	.bus_dph_ready_i            (core_dph_ready_i),
	.bus_dph_err_i              (core_dph_err_i),
	.bus_haddr_i                (core_haddr_i),
	.bus_hsize_i                (core_hsize_i),
	.bus_priv_i                 (core_priv_i),
	.bus_rdata_i                (core_rdata_i),

	.bus_aph_req_d              (core_aph_req_d),
	.bus_aph_excl_d             (core_aph_excl_d),
	.bus_aph_ready_d            (core_aph_ready_d),
	.bus_dph_ready_d            (core_dph_ready_d),
	.bus_dph_err_d              (core_dph_err_d),
	.bus_dph_exokay_d           (core_dph_exokay_d),
	.bus_haddr_d                (core_haddr_d),
	.bus_hsize_d                (core_hsize_d),
	.bus_priv_d                 (core_priv_d),
	.bus_hwrite_d               (core_hwrite_d),
	.bus_wdata_d                (core_wdata_d),
	.bus_rdata_d                (core_rdata_d),

	.fence_i_vld                (fence_i_vld),
	.fence_d_vld                (fence_d_vld),
	.fence_rdy                  (fence_rdy),

	.dbg_req_halt               (dbg_req_halt),
	.dbg_req_halt_on_reset      (dbg_req_halt_on_reset),
	.dbg_req_resume             (dbg_req_resume),
	.dbg_halted                 (dbg_halted),
	.dbg_running                (dbg_running),
	.dbg_data0_rdata            (dbg_data0_rdata),
	.dbg_data0_wdata            (dbg_data0_wdata),
	.dbg_data0_wen              (dbg_data0_wen),
	.dbg_instr_data             (dbg_instr_data),
	.dbg_instr_data_vld         (dbg_instr_data_vld),
	.dbg_instr_data_rdy         (dbg_instr_data_rdy),
	.dbg_instr_caught_exception (dbg_instr_caught_exception),
	.dbg_instr_caught_ebreak    (dbg_instr_caught_ebreak),

	.mhartid_val                (mhartid_val),
	.eco_version                (eco_version),

	.irq                        (irq),
	.soft_irq                   (soft_irq),
	.timer_irq                  (timer_irq),

	.ci_id                      (ci_id),
	.ci_start                   (ci_start),
	.ci_dataa                   (ci_dataa),
	.ci_datab                   (ci_datab),
	.ci_done                    (ci_done),
	.ci_result                  (ci_result)
);

// ----------------------------------------------------------------------------
// Instruction port

hazard3_wb_master #(
	.W_ADDR (W_ADDR),
	.W_DATA (W_DATA)
) i_master (
	.clk       (clk),
	.rst       (rst),
	.aph_req   (core_aph_req_i),
	.aph_ready (core_aph_ready_i),
	.dph_ready (core_dph_ready_i),
	.dph_err   (core_dph_err_i),
	.haddr     (core_haddr_i),
	.hsize     (core_hsize_i),
	.hwrite    (1'b0),
	.wdata     ({W_DATA{1'b0}}),
	.rdata     (core_rdata_i),
	.CYC_O     (i_CYC_O),
	.STB_O     (i_STB_O),
	.ADDR_O    (i_ADDR_O),
	.SEL_O     (i_SEL_O),
	.WE_O      (i_WE_O),
	.DAT_O     (i_DAT_O),
	.CTI_O     (i_CTI_O),
	.BTE_O     (i_BTE_O),
	.LOCK_O    (i_LOCK_O),
	.ACK_I     (i_ACK_I),
	.ERR_I     (i_ERR_I),
	.DAT_I     (i_DAT_I)
);

// ----------------------------------------------------------------------------
// Load/store port

hazard3_wb_master #(
	.W_ADDR (W_ADDR),
	.W_DATA (W_DATA)
) d_master (
	.clk       (clk),
	.rst       (rst),
	.aph_req   (core_aph_req_d),
	.aph_ready (core_aph_ready_d),
	.dph_ready (core_dph_ready_d),
	.dph_err   (core_dph_err_d),
	.haddr     (core_haddr_d),
	.hsize     (core_hsize_d),
	.hwrite    (core_hwrite_d),
	.wdata     (core_wdata_d),
	.rdata     (core_rdata_d),
	.CYC_O     (d_CYC_O),
	.STB_O     (d_STB_O),
	.ADDR_O    (d_ADDR_O),
	.SEL_O     (d_SEL_O),
	.WE_O      (d_WE_O),
	.DAT_O     (d_DAT_O),
	.CTI_O     (d_CTI_O),
	.BTE_O     (d_BTE_O),
	.LOCK_O    (d_LOCK_O),
	.ACK_I     (d_ACK_I),
	.ERR_I     (d_ERR_I),
	.DAT_I     (d_DAT_I)
);

// No global exclusive monitor on the shared Wishbone bus: per the Hazard3
// documentation hexokay is tied high, so only the core's local monitor
// decides LR/SC success (sufficient for a single hart).
assign core_dph_exokay_d = 1'b1;

endmodule

`ifndef YOSYS
`default_nettype wire
`endif
