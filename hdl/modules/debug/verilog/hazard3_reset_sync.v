/*****************************************************************************\
|                      Copyright (C) 2021-2022 Luke Wren                      |
|                     SPDX-License-Identifier: Apache-2.0                     |
|                                                                             |
|                     Modified 2026 by Theo Kluter                            |
|                     Changes:                                                |
|                       - removed HAZARD3_REG_KEEP_ATTRIBUTE                  |
|                       - moved to active-high reset                          |
\*****************************************************************************/

// The output is asserted asynchronously when the input is asserted,
// but deasserted synchronously when clocked with the input deasserted.
// Input and output are both active-high.
//
// This is a baseline implementation -- you should replace it with cells
// specific to your FPGA/process

module hazard3_reset_sync #(
	parameter N_STAGES = 2 // Should be >= 2
) (
	input  wire clk,
	input  wire rst_in,
	output wire rst_out
);

reg [N_STAGES-1:0] delay;

always @ (posedge clk or posedge rst_in)
	if (rst_in == 1'b1)
		delay <= {N_STAGES{1'b1}};
	else
		delay <= {delay[N_STAGES-2:0], 1'b0};

assign rst_out = delay[N_STAGES-1];

endmodule

