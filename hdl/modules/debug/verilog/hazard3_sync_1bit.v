/*****************************************************************************\
|                      Copyright (C) 2021-2022 Luke Wren                      |
|                     SPDX-License-Identifier: Apache-2.0                     |
|                                                                             |
|                     Modified 2026 by Theo Kluter                            |
|                     Changes:                                                |
|                       - removed HAZARD3_REG_KEEP_ATTRIBUTE                  |
|                       - moved to active high reset                          |
\*****************************************************************************/

// A 2FF synchronizer to mitigate metastabilities. This is a baseline
// implementation -- you should replace it with cells specific to your
// FPGA/process

module hazard3_sync_1bit #(
	parameter N_STAGES = 2 // Should be >=2
) (
	input wire clk,
	input wire rst,
	input wire i,
	output wire o
);

reg [N_STAGES-1:0] sync_flops;

always @ (posedge clk or posedge rst)
	if (rst == 1'b1)
		sync_flops <= {N_STAGES{1'b0}};
	else
		sync_flops <= {sync_flops[N_STAGES-2:0], i};

assign o = sync_flops[N_STAGES-1];

endmodule

