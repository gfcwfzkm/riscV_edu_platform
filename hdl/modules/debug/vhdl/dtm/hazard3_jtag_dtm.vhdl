library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Original Verilog comments:
-- /*****************************************************************************\
-- |                      Copyright (C) 2021-2022 Luke Wren                      |
-- |                     SPDX-License-Identifier: Apache-2.0                     |
-- \*****************************************************************************/
--
-- // Implementation of standard RISC-V JTAG-DTM with an APB Debug Module
-- // Interface. The TAP itself is clocked directly by JTAG TCK; a clock
-- // crossing is instantiated internally between the TCK domain and the DMI bus
-- // clock domain.
--
-- `default_nettype none
--
-- module hazard3_jtag_dtm #(
-- 	parameter IDCODE          = 32'h0000_0001,
-- 	parameter DTMCS_IDLE_HINT = 3'd4,
-- 	parameter W_PADDR         = 9,
-- 	parameter ABITS           = W_PADDR - 2 // do not modify
-- ) (
-- 	// Standard JTAG signals -- the JTAG hardware is clocked directly by TCK.
-- 	input  wire               tck,
-- 	input  wire               trst_n,
-- 	input  wire               tms,
-- 	input  wire               tdi,
-- 	output reg                tdo,
--
-- 	// This is synchronous to TCK and asserted for one TCK cycle only
-- 	output wire               dmihardreset_req,
--
-- 	// Bus clock + reset for Debug Module Interface
-- 	input  wire               clk_dmi,
-- 	input  wire               rst_n_dmi,
--
-- 	// Debug Module Interface (APB)
-- 	output wire               dmi_psel,
-- 	output wire               dmi_penable,
-- 	output wire               dmi_pwrite,
-- 	output wire [W_PADDR-1:0] dmi_paddr,
-- 	output wire [31:0]        dmi_pwdata,
-- 	input  wire [31:0]        dmi_prdata,
-- 	input  wire               dmi_pready,
-- 	input  wire               dmi_pslverr
-- );

entity hazard3_jtag_dtm is
	generic (
		IDCODE          : std_logic_vector(31 downto 0) := x"00000001";
		DTMCS_IDLE_HINT : std_logic_vector(2 downto 0)  := "100";
		W_PADDR         : natural                       := 9;
		ABITS           : natural                       := W_PADDR - 2 -- do not modify
	);
	port (
		-- Standard JTAG signals -- the JTAG hardware is clocked directly by TCK.
		tck    : in std_logic;
		trst_n : in std_logic;
		tms    : in std_logic;
		tdi    : in std_logic;
		tdo    : out std_logic;

		-- This is synchronous to TCK and asserted for one TCK cycle only
		dmihardreset_req : out std_logic;

		-- Bus clock + reset for Debug Module Interface
		clk_dmi   : in std_logic;
		rst_n_dmi : in std_logic;

		-- Debug Module Interface (APB)
		dmi_psel    : out std_logic;
		dmi_penable : out std_logic;
		dmi_pwrite  : out std_logic;
		dmi_paddr   : out std_logic_vector(W_PADDR - 1 downto 0);
		dmi_pwdata  : out std_logic_vector(31 downto 0);
		dmi_prdata  : in std_logic_vector(31 downto 0);
		dmi_pready  : in std_logic;
		dmi_pslverr : in std_logic
	);
end entity hazard3_jtag_dtm;

architecture rtl of hazard3_jtag_dtm is
	constant S_RESET      : std_logic_vector(3 downto 0) := x"0";
	constant S_RUN_IDLE   : std_logic_vector(3 downto 0) := x"1";
	constant S_SELECT_DR  : std_logic_vector(3 downto 0) := x"2";
	constant S_CAPTURE_DR : std_logic_vector(3 downto 0) := x"3";
	constant S_SHIFT_DR   : std_logic_vector(3 downto 0) := x"4";
	constant S_EXIT1_DR   : std_logic_vector(3 downto 0) := x"5";
	constant S_PAUSE_DR   : std_logic_vector(3 downto 0) := x"6";
	constant S_EXIT2_DR   : std_logic_vector(3 downto 0) := x"7";
	constant S_UPDATE_DR  : std_logic_vector(3 downto 0) := x"8";
	constant S_SELECT_IR  : std_logic_vector(3 downto 0) := x"9";
	constant S_CAPTURE_IR : std_logic_vector(3 downto 0) := x"A";
	constant S_SHIFT_IR   : std_logic_vector(3 downto 0) := x"B";
	constant S_EXIT1_IR   : std_logic_vector(3 downto 0) := x"C";
	constant S_PAUSE_IR   : std_logic_vector(3 downto 0) := x"D";
	constant S_EXIT2_IR   : std_logic_vector(3 downto 0) := x"E";
	constant S_UPDATE_IR  : std_logic_vector(3 downto 0) := x"F";

	constant W_IR       : natural                             := 5;
	constant IR_IDCODE  : std_logic_vector(W_IR - 1 downto 0) := "00001";
	constant IR_DTMCS   : std_logic_vector(W_IR - 1 downto 0) := "10000";
	constant IR_DMI     : std_logic_vector(W_IR - 1 downto 0) := "10001";
	constant W_DR_SHIFT : natural                             := ABITS + 32 + 2;

	signal tap_state_reg          : std_logic_vector(3 downto 0);
	signal ir_shift_reg           : std_logic_vector(W_IR - 1 downto 0);
	signal ir_reg                 : std_logic_vector(W_IR - 1 downto 0);
	signal dr_shift_reg           : std_logic_vector(W_DR_SHIFT - 1 downto 0);
	signal core_dr_wen            : std_logic;
	signal core_dr_ren            : std_logic;
	signal core_dr_sel_dmi_ndtmcs : std_logic;
	signal core_dr_wdata          : std_logic_vector(W_DR_SHIFT - 1 downto 0);
	signal core_dr_rdata          : std_logic_vector(W_DR_SHIFT - 1 downto 0);
	signal tdo_reg                : std_logic;
begin

	process (tck, trst_n)
	begin
		if trst_n = '0' then
			tap_state_reg <= S_RESET;
		elsif rising_edge(tck) then
			case tap_state_reg is
				when S_RESET      => tap_state_reg <= S_RESET     when (tms = '1') else S_RUN_IDLE;
				when S_RUN_IDLE   => tap_state_reg <= S_SELECT_DR when (tms = '1') else S_RUN_IDLE;

				when S_SELECT_DR  => tap_state_reg <= S_SELECT_IR when (tms = '1') else S_CAPTURE_DR;
				when S_CAPTURE_DR => tap_state_reg <= S_EXIT1_DR  when (tms = '1') else S_SHIFT_DR;
				when S_SHIFT_DR   => tap_state_reg <= S_EXIT1_DR  when (tms = '1') else S_SHIFT_DR;
				when S_EXIT1_DR   => tap_state_reg <= S_UPDATE_DR when (tms = '1') else S_PAUSE_DR;
				when S_PAUSE_DR   => tap_state_reg <= S_EXIT2_DR  when (tms = '1') else S_PAUSE_DR;
				when S_EXIT2_DR   => tap_state_reg <= S_UPDATE_DR when (tms = '1') else S_SHIFT_DR;
				when S_UPDATE_DR  => tap_state_reg <= S_SELECT_DR when (tms = '1') else S_RUN_IDLE;

				when S_SELECT_IR  => tap_state_reg <= S_RESET     when (tms = '1') else S_CAPTURE_IR;
				when S_CAPTURE_IR => tap_state_reg <= S_EXIT1_IR  when (tms = '1') else S_SHIFT_IR;
				when S_SHIFT_IR   => tap_state_reg <= S_EXIT1_IR  when (tms = '1') else S_SHIFT_IR;
				when S_EXIT1_IR   => tap_state_reg <= S_UPDATE_IR when (tms = '1') else S_PAUSE_IR;
				when S_PAUSE_IR   => tap_state_reg <= S_EXIT2_IR  when (tms = '1') else S_PAUSE_IR;
				when S_EXIT2_IR   => tap_state_reg <= S_UPDATE_IR when (tms = '1') else S_SHIFT_IR;
				when S_UPDATE_IR  => tap_state_reg <= S_SELECT_DR when (tms = '1') else S_RUN_IDLE;
				
				when others => 
					tap_state_reg <= S_RESET; -- Safe fallback for uninitialized or invalid states
			end case;
		end if;
	end process;

	process (tck, trst_n)
	begin
		if trst_n = '0' then
			ir_shift_reg <= (others => '0');
			ir_reg       <= IR_IDCODE;
		elsif rising_edge(tck) then
			if tap_state_reg = S_RESET then
				ir_shift_reg <= (others => '0');
				ir_reg       <= IR_IDCODE;
			elsif tap_state_reg = S_CAPTURE_IR then
				ir_shift_reg <= ir_reg;
			elsif tap_state_reg = S_SHIFT_IR then
				-- Shift operation: append 'tdi' to the MSB and drop the LSB
				ir_shift_reg <= tdi & ir_shift_reg(W_IR-1 downto 1);
			elsif tap_state_reg = S_UPDATE_IR then
				ir_reg <= ir_shift_reg;
			end if;
		end if;
	end process;

	process (tck, trst_n)
    begin
        if trst_n = '0' then
            dr_shift_reg <= (others => '0');
        elsif rising_edge(tck) then
            
            if tap_state_reg = S_SHIFT_DR then
                -- 1. Default full-chain shift
                dr_shift_reg <= tdi & dr_shift_reg(W_DR_SHIFT-1 downto 1);
                
                -- 2. Shorten DR shift chain according to IR (overrides bits from above)
                if ir_reg = IR_DMI then
                    dr_shift_reg(W_DR_SHIFT - 1) <= tdi;
                elsif (ir_reg = IR_IDCODE) or (ir_reg = IR_DTMCS) then
                    dr_shift_reg(31) <= tdi;
                else
                    -- BYPASS
                    dr_shift_reg(0) <= tdi;
                end if;
                
            elsif tap_state_reg = S_CAPTURE_DR then
                
                if (ir_reg = IR_DMI) or (ir_reg = IR_DTMCS) then
                    dr_shift_reg <= core_dr_rdata;
                elsif ir_reg = IR_IDCODE then
                    -- Pad zeros to the MSBs, leaving IDCODE in the lower 32 bits
                    dr_shift_reg <= (W_DR_SHIFT - 1 downto 32 => '0') & IDCODE;
                else
                    -- BYPASS
                    dr_shift_reg <= (others => '0');
                end if;
                
            end if;
        end if;
    end process;

	process (tck, trst_n)
    begin
        if trst_n = '0' then
            tdo_reg <= '0';
        elsif falling_edge(tck) then
            tdo_reg <= ir_shift_reg(0) when (tap_state_reg = S_SHIFT_IR) else
                   	   dr_shift_reg(0) when (tap_state_reg = S_SHIFT_DR) else 
                   	   '0';
        end if;
    end process;
	tdo <= tdo_reg;

	core_dr_sel_dmi_ndtmcs <= '1' when ir_reg = IR_DMI else
		'0';
	core_dr_wen <= '1' when (ir_reg = IR_DMI or ir_reg = IR_DTMCS) and tap_state_reg = S_UPDATE_DR else
		'0';
	core_dr_ren <= '1' when (ir_reg = IR_DMI or ir_reg = IR_DTMCS) and tap_state_reg = S_CAPTURE_DR else
		'0';
	core_dr_wdata <= dr_shift_reg;

	dtm_core : entity work.hazard3_jtag_dtm_core
		generic map(
			DTMCS_IDLE_HINT => DTMCS_IDLE_HINT,
			W_ADDR          => ABITS
		)
		port map
		(
			tck               => tck,
			trst_n            => trst_n,
			clk_dmi           => clk_dmi,
			rst_n_dmi         => rst_n_dmi,
			dr_wen            => core_dr_wen,
			dr_ren            => core_dr_ren,
			dr_sel_dmi_ndtmcs => core_dr_sel_dmi_ndtmcs,
			dr_wdata          => core_dr_wdata,
			dr_rdata          => core_dr_rdata,
			dmihardreset_req  => dmihardreset_req,
			dmi_psel          => dmi_psel,
			dmi_penable       => dmi_penable,
			dmi_pwrite        => dmi_pwrite,
			dmi_paddr         => dmi_paddr(W_PADDR - 1 downto 2),
			dmi_pwdata        => dmi_pwdata,
			dmi_prdata        => dmi_prdata,
			dmi_pready        => dmi_pready,
			dmi_pslverr       => dmi_pslverr
		);

	dmi_paddr(1 downto 0) <= "00";

end architecture rtl;
