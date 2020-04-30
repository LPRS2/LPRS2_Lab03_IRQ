
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library lprs2_qsys;

entity nios2_lprs2_pio_7segm_timer is
	generic(
		-- Default frequency used in synthesis.
		constant CLK_FREQ : positive := 12000000
	);
	port(
		-- On MAX1000.
		-- System signals.
		i_clk                      :  in std_logic; -- 12MHz clock.
		in_rst                     :  in std_logic;
		
		
		-- LEDs.
		o_led                      : out std_logic_vector(7 downto 0);
		
		
		
		-- On LPRS1_MAX1000_Shield.
		
		-- RGB 8x8 LED matrix and 7-segm outputs.
		o_n_col_0_or_7segm_a       : out std_logic;
		o_n_col_1_or_7segm_b       : out std_logic;
		o_n_col_2_or_7segm_c       : out std_logic;
		o_n_col_3_or_7segm_d       : out std_logic;
		o_n_col_4_or_7segm_e       : out std_logic;
		o_n_col_5_or_7segm_f       : out std_logic;
		o_n_col_6_or_7segm_g       : out std_logic;
		o_n_col_7_or_7segm_dp      : out std_logic;
		
		o_mux_row_or_digit         : out std_logic_vector(2 downto 0);
		
		o_mux_sel_color_or_7segm   : out std_logic_vector(1 downto 0);
		
		-- Inputs.
		i_sw                       :  in std_logic_vector(7 downto 0)
	);
end entity;

architecture nios2_lprs2_pio_7segm_timer_arch of nios2_lprs2_pio_7segm_timer is
	
	signal rst : std_logic;
	
	signal mux_digit   : std_logic_vector(7 downto 0);
	signal sel_digit   : std_logic_vector(1 downto 0);
	signal n_mux_digit : std_logic_vector(7 downto 0);
	
begin
	
	rst <= not in_rst;
	
	u0 : entity lprs2_qsys.lprs2_qsys
	port map (
		clk_clk    => i_clk,
		rst_reset  => rst,
		pio_pi     => i_sw,
		pio_po     => o_led,
		segm_mux_digit => mux_digit,
		segm_sel_digit => sel_digit
	);
	
	
	n_mux_digit <= not mux_digit;
	
	o_n_col_0_or_7segm_a  <= n_mux_digit(0);
	o_n_col_1_or_7segm_b  <= n_mux_digit(1);
	o_n_col_2_or_7segm_c  <= n_mux_digit(2);
	o_n_col_3_or_7segm_d  <= n_mux_digit(3);
	o_n_col_4_or_7segm_e  <= n_mux_digit(4);
	o_n_col_5_or_7segm_f  <= n_mux_digit(5);
	o_n_col_6_or_7segm_g  <= n_mux_digit(6);
	o_n_col_7_or_7segm_dp <= n_mux_digit(7);
	
	o_mux_row_or_digit    <= '0' & sel_digit;
	
	o_mux_sel_color_or_7segm <= "11";

end architecture;
