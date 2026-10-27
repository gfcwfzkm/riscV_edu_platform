/*****************************************************************************\
|                      Copyright (C) 2021-2022 Luke Wren                      |
|                     SPDX-License-Identifier: Apache-2.0                     |
|                                                                             |
|                     Modified 2026 by Theo Kluter                            |
|                     Changes:                                                |
|                       - removed E-extention                                 |
|                       - removed Reset of Regfile                            |
|                       - mapped to ECP5-Lutram                               |
|                       - removed reset line                                  |
\*****************************************************************************/

// Register file
// Single write port, dual read port

module hazard3_regfile_1w2r (
	input wire clk,

	input wire [4:0]  raddr1,
	output reg [31:0] rdata1,

	input wire [4:0]  raddr2,
	output reg [31:0] rdata2,

	input wire [4:0]  waddr,
	input wire [31:0] wdata,
	input wire        wen
);

wire [31:0] s_regAData, s_regBData;

sramLutRam #( .nrOfAddressBits(5),
              .nrOfDataBits(32) ) dataARam
            ( .clock(clk),
              .writeEnable(wen),
              .writeAddress(waddr),
              .readAddress(raddr1),
              .writeData(wdata),
              .readData(s_regAData));

sramLutRam #( .nrOfAddressBits(5),
              .nrOfDataBits(32) ) dataBRam
            ( .clock(clk),
              .writeEnable(wen),
              .writeAddress(waddr),
              .readAddress(raddr2),
              .writeData(wdata),
              .readData(s_regBData));

always @(posedge clk)
  begin
    rdata1 <= (raddr1 == 5'd0) ? 32'd0 : s_regAData; // make sure we read 0 at address 0
    rdata2 <= (raddr2 == 5'd0) ? 32'd0 : s_regBData; // make sure we read 0 at address 0
  end

endmodule


