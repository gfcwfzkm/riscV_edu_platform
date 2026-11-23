/*****************************************************************************\
|                     SPDX-License-Identifier: Apache-2.0                     |
|                                                                             |
|  Wishbone B4 classic master for one Hazard3 core bus port (registered       |
|  outputs). Replaces the AHB-Lite glue of hazard3_cpu_2port.                 |
\*****************************************************************************/

// The core's bus handshake is AHB-shaped: an address phase (aph_req /
// aph_ready) followed one cycle later by a data phase (dph_ready / dph_err),
// with the next address phase allowed to overlap the current data phase.
//
// Mapping used here:
//   - AHB address phase  -> address, size and direction are captured into
//                           registers (ADDR_O, SEL_O, WE_O come from flops).
//   - AHB data phase     -> one Wishbone classic cycle: CYC_O = STB_O = 1 until
//                           ACK_I or ERR_I. Store data (DAT_O) is the core's
//                           data-phase write data, which is valid exactly then.
//   - ACK_I              -> dph_ready; the next address phase may be accepted in
//                           the same cycle, so back-to-back transfers keep CYC_O
//                           asserted.
//   - ERR_I              -> emulates the two-cycle AHB error response: the cycle
//                           ends, dph_err is raised for two cycles, dph_ready only
//                           in the second one, and no new address is accepted in
//                           the first one (the core uses it to cancel its next
//                           request).
//
// Only one transfer is outstanding at a time; CTI_O is always 3'b000 (classic).

`default_nettype none

module hazard3_wb_master #(
	parameter W_ADDR = 32,
	parameter W_DATA = 32
) (
	input  wire                  clk,
	input  wire                  rst,

	// Core side
	input  wire                  aph_req,
	output wire                  aph_ready,
	output wire                  dph_ready,
	output wire                  dph_err,
	input  wire [W_ADDR-1:0]     haddr,
	input  wire [2:0]            hsize,
	input  wire                  hwrite,
	input  wire [W_DATA-1:0]     wdata,
	output wire [W_DATA-1:0]     rdata,

	// Wishbone master side
	output wire                  CYC_O,
	output wire                  STB_O,
	output wire [W_ADDR-1:0]     ADDR_O,
	output wire [W_DATA/8-1:0]   SEL_O,
	output wire                  WE_O,
	output wire [W_DATA-1:0]     DAT_O,
	output wire [2:0]            CTI_O,
	output wire [1:0]            BTE_O,
	output wire                  LOCK_O,
	input  wire                  ACK_I,
	input  wire                  ERR_I,
	input  wire [W_DATA-1:0]     DAT_I
);

localparam HSIZE_BYTE  = 3'd0;
localparam HSIZE_HWORD = 3'd1;

reg              busy;      // a Wishbone cycle (= AHB data phase) is in progress
reg              err_pend;  // second cycle of an emulated AHB error response
reg [W_ADDR-1:0] addr_q;
reg [3:0]        sel_q;
reg              we_q;

wire wb_ack = busy && ACK_I && !ERR_I;
wire wb_err = busy && ERR_I;

// A new address is taken when the port is idle, or in the cycle the current
// transfer is acknowledged (like hready high at the end of an AHB data phase).
assign aph_ready = aph_req && !err_pend && !wb_err && (!busy || wb_ack);
assign dph_ready = wb_ack || err_pend;
assign dph_err   = wb_err || err_pend;
assign rdata     = DAT_I;

reg [3:0] sel_next;
always @ (*) begin
	case (hsize)
		HSIZE_BYTE:  sel_next = 4'b0001 << haddr[1:0];
		HSIZE_HWORD: sel_next = haddr[1] ? 4'b1100 : 4'b0011;
		default:     sel_next = 4'b1111;
	endcase
end

always @ (posedge clk) begin
	if (rst) begin
		busy     <= 1'b0;
		err_pend <= 1'b0;
		addr_q   <= {W_ADDR{1'b0}};
		sel_q    <= 4'h0;
		we_q     <= 1'b0;
	end else begin
		err_pend <= wb_err;
		if (aph_ready) begin
			busy   <= 1'b1;
			addr_q <= {haddr[W_ADDR-1:2], 2'b00};
			sel_q  <= sel_next;
			we_q   <= hwrite;
		end else if (wb_ack || wb_err) begin
			busy   <= 1'b0;
		end
	end
end

assign CYC_O  = busy;
assign STB_O  = busy;
assign ADDR_O = addr_q;
assign SEL_O  = sel_q;
assign WE_O   = we_q;
assign DAT_O  = wdata;
assign CTI_O  = 3'b000;
assign BTE_O  = 2'b00;
assign LOCK_O = 1'b0;

endmodule

`ifndef YOSYS
`default_nettype wire
`endif
