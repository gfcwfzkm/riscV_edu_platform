library ieee;
use ieee.std_logic_1164.all;

-- Original Verilog comments:
-- /*****************************************************************************\
-- |                        Copyright (C) 2022 Luke Wren                         |
-- |                     SPDX-License-Identifier: Apache-2.0                     |
-- \*****************************************************************************/
--
-- // Standalone bus shim for connecting the DM's System Bus Access to AHB
--
-- `default_nettype none
--
-- module hazard3_sbus_to_ahb #(
-- 	parameter W_ADDR = 32,
-- 	parameter W_DATA = 32
-- ) (
-- 	input wire               clk,
-- 	input wire               rst_n,
--
-- 	input  wire [W_ADDR-1:0] sbus_addr,
-- 	input  wire              sbus_write,
-- 	input  wire [1:0]        sbus_size,
-- 	input  wire              sbus_vld,
-- 	output wire              sbus_rdy,
-- 	output wire              sbus_err,
-- 	input  wire [W_DATA-1:0] sbus_wdata,
-- 	output wire [W_DATA-1:0] sbus_rdata,
--
-- 	output wire [W_ADDR-1:0] ahblm_haddr,
-- 	output wire              ahblm_hwrite,
-- 	output wire [1:0]        ahblm_htrans,
-- 	output wire [2:0]        ahblm_hsize,
-- 	output wire [2:0]        ahblm_hburst,
-- 	output wire [3:0]        ahblm_hprot,
-- 	output wire              ahblm_hmastlock,
-- 	input  wire              ahblm_hready,
-- 	input  wire              ahblm_hresp,
-- 	output wire [W_DATA-1:0] ahblm_hwdata,
-- 	input  wire [W_DATA-1:0] ahblm_hrdata
-- );

entity hazard3_sbus_to_ahb is
	generic (
		W_ADDR : positive := 32;
		W_DATA : positive := 32
	);
	port (
		clk             : in std_logic;
		rst_n           : in std_logic;

		sbus_addr       : in std_logic_vector(W_ADDR - 1 downto 0);
		sbus_write      : in std_logic;
		sbus_size       : in std_logic_vector(1 downto 0);
		sbus_vld        : in std_logic;
		sbus_rdy        : out std_logic;
		sbus_err        : out std_logic;
		sbus_wdata      : in std_logic_vector(W_DATA - 1 downto 0);
		sbus_rdata      : out std_logic_vector(W_DATA - 1 downto 0);
		
		ahblm_haddr     : out std_logic_vector(W_ADDR - 1 downto 0);
		ahblm_hwrite    : out std_logic;
		ahblm_htrans    : out std_logic_vector(1 downto 0);
		ahblm_hsize     : out std_logic_vector(2 downto 0);
		ahblm_hburst    : out std_logic_vector(2 downto 0);
		ahblm_hprot     : out std_logic_vector(3 downto 0);
		ahblm_hmastlock : out std_logic;
		ahblm_hready    : in std_logic;
		ahblm_hresp     : in std_logic;
		ahblm_hwdata    : out std_logic_vector(W_DATA - 1 downto 0);
		ahblm_hrdata    : in std_logic_vector(W_DATA - 1 downto 0)
	);
end entity hazard3_sbus_to_ahb;

architecture rtl of hazard3_sbus_to_ahb is
	signal dph_active_reg : std_logic;
	signal ahblm_htrans_comb : std_logic_vector(1 downto 0);
begin

	-- Most signals are simple tie-throughs
	ahblm_haddr  <= sbus_addr;
	ahblm_hwrite <= sbus_write;
	ahblm_hsize  <= '0' & sbus_size;
	ahblm_hwdata <= sbus_wdata;

	-- HPROT = noncacheable nonbufferable privileged data access:
	ahblm_hprot     <= "0011";
	ahblm_hmastlock <= '0';
	ahblm_hburst    <= "000";

	sbus_err   <= ahblm_hresp;
	sbus_rdata <= ahblm_hrdata;

	-- Handshaking
	process (clk, rst_n)
	begin
		if rst_n = '0' then
			dph_active_reg <= '0';
		elsif rising_edge(clk) then
			if ahblm_hready = '1' then
				dph_active_reg <= ahblm_htrans_comb(1);
			end if;
		end if;
	end process;

	ahblm_htrans_comb <= "10" when sbus_vld = '1' and dph_active_reg = '0' else
		"00";
	ahblm_htrans <= ahblm_htrans_comb;
	sbus_rdy <= '1' when ahblm_hready = '1' and dph_active_reg = '1' else
		'0';

end architecture rtl;
