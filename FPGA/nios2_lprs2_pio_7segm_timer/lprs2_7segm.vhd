
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library lprs2_qsys;

entity lprs2_7segm is
	port(
		-- System.
		clk              : in  std_logic;
		reset            : in  std_logic;
		
		-- Avalon slave.
		avs_chipselect   : in  std_logic;
		-- Word address.
		avs_address      : in  std_logic_vector(4 downto 0);
		avs_write        : in  std_logic;
		avs_writedata    : in  std_logic_vector(31 downto 0);
		avs_read         : in  std_logic;
		avs_readdata     : out std_logic_vector(31 downto 0);
		
		-- Conduit.
		coe_mux_digit    : out std_logic_vector(7 downto 0);
		coe_sel_digit    : out std_logic_vector(1 downto 0)
	);

end entity;

architecture lprs2_7segm_arch of lprs2_7segm is
	-- TODO Is there way for Qsys to propagate this constant.
	constant CLK_FREQ : positive := 12000000;
	
	signal n_rst   : std_logic;
	
	signal addr_ri : std_logic_vector(3 downto 0);
	signal addr_gr : std_logic_vector(3 downto 0);
	signal addr    : std_logic_vector(7 downto 0);
	signal wr      : std_logic;
	
	signal en_digit : std_logic;
	signal sel_digit : std_logic_vector(1 downto 0);
	
	type t_digit_array is array(0 to 3) of std_logic_vector(3 downto 0);
	signal digit_array      : t_digit_array;
	signal digit            : std_logic_vector(3 downto 0);
	
	signal segm_afbgecd : std_logic_vector(6 downto 0);
begin
	
	addr_ri <= "0" & avs_address(2 downto 0);
	addr_gr <= "00" & avs_address(4 downto 3);
	addr <= addr_gr & addr_ri;
	wr <= avs_chipselect and avs_write;
	process(clk, reset)
	begin
		if reset = '1' then
			digit_array(3) <= x"3";
			digit_array(2) <= x"2";
			digit_array(1) <= x"1";
			digit_array(0) <= x"0";
		elsif rising_edge(clk) then
			
			-- Because flags.
			avs_readdata <= (others => '0');
			case addr is
				when x"00" | x"11" =>
					avs_readdata(3 downto 0) <= digit_array(0);
					if wr = '1' then
						digit_array(0) <= avs_writedata(3 downto 0);
					end if;
					
				when x"01" | x"13" =>
					avs_readdata(3 downto 0) <= digit_array(1);
					if wr = '1' then
						digit_array(1) <= avs_writedata(3 downto 0);
					end if;
					
				when x"02" | x"12" =>
					avs_readdata(3 downto 0) <= digit_array(2);
					if wr = '1' then
						digit_array(2) <= avs_writedata(3 downto 0);
					end if;
					
				when x"03" | x"10" =>
					avs_readdata(3 downto 0) <= digit_array(3);
					if wr = '1' then
						digit_array(3) <= avs_writedata(3 downto 0);
					end if;
					
				-- packed
				when x"04" | x"17" =>
					avs_readdata <= 
						x"0" & digit_array(3) &
						x"0" & digit_array(2) &
						x"0" & digit_array(1) &
						x"0" & digit_array(0);
					if wr = '1' then
						digit_array(3) <= avs_writedata(27 downto 24);
						digit_array(2) <= avs_writedata(19 downto 16);
						digit_array(1) <= avs_writedata(11 downto  8);
						digit_array(0) <= avs_writedata( 3 downto  0);
					end if;
					
				when others =>
					avs_readdata <= x"deadbeef";
					-- Other regs are RO.
			end case;
		end if;
	end process;
	
	--------------------
	
	n_rst <= not reset;
	
	en_row_cnt_inst: entity lprs2_qsys.counter
	generic map(
		CNT_MOD  => CLK_FREQ/2400,
		CNT_BITS => 13
	)
	port map(
		i_clk  => clk,
		in_rst => n_rst,
		
		i_rst  => '0',
		i_en   => '1',
		o_cnt  => open,
		o_tc   => en_digit
	);
	
	-- Time-multiplexing.
	mux_row_or_digit_cnt_inst: entity lprs2_qsys.counter
	generic map(
		CNT_MOD  => 4,
		CNT_BITS => 2
	)
	port map(
		i_clk  => clk,
		in_rst => n_rst,
		
		i_rst  => '0',
		i_en   => en_digit,
		o_cnt  => sel_digit,
		o_tc   => open
	);
	
	-- Mux for digits.
	digit <= digit_array(conv_integer(sel_digit));
		
	-- 7-segm decoder.
	with digit select segm_afbgecd <=
		     '1'&
		'1'&      '1'&
		     '0'&
		'1'&      '1'&
		     '1'
				when "0000",
		     '0'&
		'0'&      '1'&
		     '0'&
		'0'&      '1'&
		     '0'
				when "0001",
		     '1'&
		'0'&      '1'&
		     '1'&
		'1'&      '0'&
		     '1'
				when "0010",
		     '1'&
		'0'&      '1'&
		     '1'&
		'0'&      '1'&
		     '1'
				when "0011",
		     '0'&
		'1'&      '1'&
		     '1'&
		'0'&      '1'&
		     '0'
				when "0100",
		     '1'&
		'1'&      '0'&
		     '1'&
		'0'&      '1'&
		     '1'
				when "0101",
		     '1'&
		'1'&      '0'&
		     '1'&
		'1'&      '1'&
		     '1'
				when "0110",
		     '1'&
		'0'&      '1'&
		     '0'&
		'0'&      '1'&
		     '0'
				when "0111",
		     '1'&
		'1'&      '1'&
		     '1'&
		'1'&      '1'&
		     '1'
				when "1000",
		     '1'&
		'1'&      '1'&
		     '1'&
		'0'&      '1'&
		     '1'
				when "1001",
		     '0'&
		'0'&      '0'&
		     '0'&
		'0'&      '0'&
		     '0'
				when others;
		
	coe_mux_digit(0) <= segm_afbgecd(6);
	coe_mux_digit(1) <= segm_afbgecd(4);
	coe_mux_digit(2) <= segm_afbgecd(1);
	coe_mux_digit(3) <= segm_afbgecd(0);
	coe_mux_digit(4) <= segm_afbgecd(2);
	coe_mux_digit(5) <= segm_afbgecd(5);
	coe_mux_digit(6) <= segm_afbgecd(3);
	coe_mux_digit(7) <= '0'; -- No point.
	
	coe_sel_digit <= sel_digit;

end architecture;
