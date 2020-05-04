
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
	
	subtype t_half_addr is std_logic_vector(3 downto 0);
	subtype t_addr is std_logic_vector(7 downto 0);
	type t_mem_map is array (0 to 3) of std_logic_vector(4*4-1 downto 0);
	constant MM : t_mem_map := (
		x"0123",
		x"1320",
		x"0321",
		x"0321"
	);
	function r(
		gr : integer range 0 to 3;
		s : integer range 0 to 3
	)
	return t_addr is
		variable n : integer;
		variable addr_ri : t_half_addr;
	begin
		n := 3 - s;
		addr_ri := MM(gr)(n*4+3 downto n*4);
		return conv_std_logic_vector(gr, 4) & addr_ri;
	end function;
	function f(
		gr : integer range 0 to 3;
		s : integer range 0 to 3
	)
	return natural is
		variable n : integer;
		variable addr_ri : t_half_addr;
		variable ri : integer;
	begin
		n := 3 - s;
		addr_ri := MM(gr)(n*4+3 downto n*4);
		ri := conv_integer(addr_ri);
		return ri*8;
	end function;
	
	signal addr_ri : t_half_addr;
	signal addr_gr : t_half_addr;
	signal addr    : t_addr;
	signal wr      : std_logic;
	
	signal en_digit  : std_logic;
	signal sel_digit : std_logic_vector(1 downto 0);
	
	type t_digits is array(0 to 3) of std_logic_vector(3 downto 0);
	signal digits : t_digits;
	signal digit  : std_logic_vector(3 downto 0);
	
	signal segm_afbgecd : std_logic_vector(6 downto 0);
begin
	
	addr_ri <= "0" & avs_address(2 downto 0);
	addr_gr <= "00" & avs_address(4 downto 3);
	addr <= addr_gr & addr_ri;
	wr <= avs_chipselect and avs_write;
	process(clk, reset)
	begin
		if reset = '1' then
			digits(3) <= x"3";
			digits(2) <= x"2";
			digits(1) <= x"1";
			digits(0) <= x"0";
		elsif rising_edge(clk) then
			
			-- Because flags.
			avs_readdata <= (others => '0');
			case addr is
				when r(0, 0) | r(1, 0) | r(2, 0) | r(3, 0) =>
					avs_readdata(3 downto 0) <= digits(0);
					if wr = '1' then
						digits(0) <= avs_writedata(3 downto 0);
					end if;
					
				when r(0, 1) | r(1, 1) | r(2, 1) | r(3, 1) =>
					avs_readdata(3 downto 0) <= digits(1);
					if wr = '1' then
						digits(1) <= avs_writedata(3 downto 0);
					end if;
					
				when r(0, 2) | r(1, 2) | r(2, 2) | r(3, 2) =>
					avs_readdata(3 downto 0) <= digits(2);
					if wr = '1' then
						digits(2) <= avs_writedata(3 downto 0);
					end if;
					
				when r(0, 3) | r(1, 3) | r(2, 3) | r(3, 3) =>
					avs_readdata(3 downto 0) <= digits(3);
					if wr = '1' then
						digits(3) <= avs_writedata(3 downto 0);
					end if;
					
				-- packed
				when x"04" =>
					avs_readdata(f(0, 0)+3 downto f(0, 0)) <= digits(0);
					avs_readdata(f(0, 1)+3 downto f(0, 1)) <= digits(1);
					avs_readdata(f(0, 2)+3 downto f(0, 2)) <= digits(2);
					avs_readdata(f(0, 3)+3 downto f(0, 3)) <= digits(3);
					if wr = '1' then
						digits(0) <= avs_writedata(f(0, 0)+3 downto f(0, 0));
						digits(1) <= avs_writedata(f(0, 1)+3 downto f(0, 1));
						digits(2) <= avs_writedata(f(0, 2)+3 downto f(0, 2));
						digits(3) <= avs_writedata(f(0, 3)+3 downto f(0, 3));
					end if;
				when x"14" =>
					avs_readdata(f(1, 0)+3 downto f(1, 0)) <= digits(0);
					avs_readdata(f(1, 1)+3 downto f(1, 1)) <= digits(1);
					avs_readdata(f(1, 2)+3 downto f(1, 2)) <= digits(2);
					avs_readdata(f(1, 3)+3 downto f(1, 3)) <= digits(3);
					if wr = '1' then
						digits(0) <= avs_writedata(f(1, 0)+3 downto f(1, 0));
						digits(1) <= avs_writedata(f(1, 1)+3 downto f(1, 1));
						digits(2) <= avs_writedata(f(1, 2)+3 downto f(1, 2));
						digits(3) <= avs_writedata(f(1, 3)+3 downto f(1, 3));
					end if;
				when x"24" =>
					avs_readdata(f(2, 0)+3 downto f(2, 0)) <= digits(0);
					avs_readdata(f(2, 1)+3 downto f(2, 1)) <= digits(1);
					avs_readdata(f(2, 2)+3 downto f(2, 2)) <= digits(2);
					avs_readdata(f(2, 3)+3 downto f(2, 3)) <= digits(3);
					if wr = '1' then
						digits(0) <= avs_writedata(f(2, 0)+3 downto f(2, 0));
						digits(1) <= avs_writedata(f(2, 1)+3 downto f(2, 1));
						digits(2) <= avs_writedata(f(2, 2)+3 downto f(2, 2));
						digits(3) <= avs_writedata(f(2, 3)+3 downto f(2, 3));
					end if;
				when x"34" =>
					avs_readdata(f(3, 0)+3 downto f(3, 0)) <= digits(0);
					avs_readdata(f(3, 1)+3 downto f(3, 1)) <= digits(1);
					avs_readdata(f(3, 2)+3 downto f(3, 2)) <= digits(2);
					avs_readdata(f(3, 3)+3 downto f(3, 3)) <= digits(3);
					if wr = '1' then
						digits(0) <= avs_writedata(f(3, 0)+3 downto f(3, 0));
						digits(1) <= avs_writedata(f(3, 1)+3 downto f(3, 1));
						digits(2) <= avs_writedata(f(3, 2)+3 downto f(3, 2));
						digits(3) <= avs_writedata(f(3, 3)+3 downto f(3, 3));
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
	digit <= digits(conv_integer(sel_digit));
		
	-- 7-segm decoder.
	with digit select segm_afbgecd <=
		     '1'&
		'1'&      '1'&
		     '0'&
		'1'&      '1'&
		     '1'
				when x"0",
		     '0'&
		'0'&      '1'&
		     '0'&
		'0'&      '1'&
		     '0'
				when x"1",
		     '1'&
		'0'&      '1'&
		     '1'&
		'1'&      '0'&
		     '1'
				when x"2",
		     '1'&
		'0'&      '1'&
		     '1'&
		'0'&      '1'&
		     '1'
				when x"3",
		     '0'&
		'1'&      '1'&
		     '1'&
		'0'&      '1'&
		     '0'
				when x"4",
		     '1'&
		'1'&      '0'&
		     '1'&
		'0'&      '1'&
		     '1'
				when x"5",
		     '1'&
		'1'&      '0'&
		     '1'&
		'1'&      '1'&
		     '1'
				when x"6",
		     '1'&
		'0'&      '1'&
		     '0'&
		'0'&      '1'&
		     '0'
				when x"7",
		     '1'&
		'1'&      '1'&
		     '1'&
		'1'&      '1'&
		     '1'
				when x"8",
		     '1'&
		'1'&      '1'&
		     '1'&
		'0'&      '1'&
		     '1'
				when x"9",
		     '1'&
		'1'&      '1'&
		     '1'&
		'1'&      '1'&
		     '0'
				when x"a",
		     '0'&
		'1'&      '0'&
		     '1'&
		'1'&      '1'&
		     '1'
				when x"b",
		     '1'&
		'1'&      '0'&
		     '0'&
		'1'&      '0'&
		     '1'
				when x"c",
		     '0'&
		'1'&      '1'&
		     '1'&
		'1'&      '1'&
		     '1'
				when x"d",
		     '1'&
		'1'&      '0'&
		     '1'&
		'1'&      '0'&
		     '1'
				when x"e",
		     '1'&
		'1'&      '0'&
		     '1'&
		'1'&      '0'&
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
