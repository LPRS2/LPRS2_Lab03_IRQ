
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library lprs2_qsys;

entity lprs2_timer is
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
		
		-- IRQ.
		ins_wrap      : out std_logic
	);
end entity;

architecture lprs2_timer_arch of lprs2_timer is
	
	subtype t_half_addr is std_logic_vector(3 downto 0);
	subtype t_addr is std_logic_vector(7 downto 0);
	type t_mem_map is array (0 to 3) of std_logic_vector(8*4-1 downto 0);
	constant MM : t_mem_map := (
		x"01230123",
		x"03213012",
		x"03122301",
		x"32103012"
	);
	function r(
		gr : integer range 0 to 3;
		ri : integer range 0 to 7
	)
	return t_addr is
		variable n : integer;
		variable addr_ri : t_half_addr;
	begin
		n := 7 - ri;
		addr_ri := MM(gr)(n*4+3 downto n*4);
		if ri >= 4 then
			addr_ri := addr_ri + 4;
		end if;
		return conv_std_logic_vector(gr, 4) & addr_ri;
	end function;
	function f(
		gr : integer range 0 to 3;
		tf : integer range 0 to 3
	)
	return natural is
		variable n : integer;
		variable addr_ri : t_half_addr;
	begin
		n := 3 - tf;
		return conv_integer(MM(gr)(n*4+3 downto n*4));
	end function;
	signal addr_ri : t_half_addr;
	signal addr_gr : t_half_addr;
	signal addr    : t_addr;
	signal wr      : std_logic;
	
	signal cnt_reg   : std_logic_vector(31 downto 0);
	signal wrap      : std_logic;
	signal wrap_cnt  : std_logic_vector(31 downto 0);
	signal reset_cnt : std_logic_vector(31 downto 0);
	signal next_cnt  : std_logic_vector(31 downto 0);

	signal modulo_reg   : std_logic_vector(31 downto 0);
	signal reset_flag   : std_logic;
	signal pause_flag   : std_logic;
	signal wrap_flag    : std_logic;
	signal wrapped_flag : std_logic;
	
	
begin
	
	wrap <= '1' when cnt_reg = modulo_reg else '0';
	wrap_cnt <= (others => '0') when wrap = '1' else cnt_reg+1;
	reset_cnt <= (others => '0') when reset_flag = '1' else wrap_cnt;
	next_cnt <= cnt_reg when pause_flag = '1' else reset_cnt;
	
	wrap_flag <= wrap;

	addr_ri <= "0" & avs_address(2 downto 0);
	addr_gr <= "00" & avs_address(4 downto 3);
	addr <= addr_gr & addr_ri;
	wr <= avs_chipselect and avs_write;
	process(clk, reset)
	begin
		if reset = '1' then
			cnt_reg <= (others => '0');
			modulo_reg <= conv_std_logic_vector(1, 32);
			reset_flag <= '1';
			pause_flag <= '1';
			wrapped_flag <= '0';
		elsif rising_edge(clk) then
			-- Could be overriden below with writing to cnt_reg.
			cnt_reg <= next_cnt;
			
			
			-- Because flags.
			avs_readdata <= (others => '0');
			case addr is
				-- cnt
				when r(0, 0) | r(1, 0) | r(2, 0) | r(3, 0) =>
					avs_readdata <= cnt_reg;
					if wr = '1' then
						cnt_reg <= avs_writedata;
					end if;
					
				-- modulo
				when r(0, 1) | r(1, 1) | r(2, 1) | r(3, 1) =>
					avs_readdata <= modulo_reg;
					if wr = '1' then
						modulo_reg <= avs_writedata;
					end if;
				
				--TODO If this work make some funs and const,
				-- for nicer, less error prone layout.
				-- ctrl/status packedflags
				when r(0, 2) | r(1, 2) | r(2, 2) | r(3, 2) =>
					case addr_gr is
						when x"0" =>
							avs_readdata(f(0, 0)) <= reset_flag;
							avs_readdata(f(0, 1)) <= pause_flag;
							avs_readdata(f(0, 2)) <= wrap_flag;
							avs_readdata(f(0, 3)) <= wrapped_flag;
							if wr = '1' then
								reset_flag   <= avs_writedata(f(0, 0));
								pause_flag   <= avs_writedata(f(0, 1));
								-- wrap_flag is RO.
								wrapped_flag <= avs_writedata(f(0, 3));
							end if;
						when x"1" =>
							avs_readdata(f(1, 0)) <= reset_flag;
							avs_readdata(f(1, 1)) <= pause_flag;
							avs_readdata(f(1, 2)) <= wrap_flag;
							avs_readdata(f(1, 3)) <= wrapped_flag;
							if wr = '1' then
								reset_flag   <= avs_writedata(f(1, 0));
								pause_flag   <= avs_writedata(f(1, 1));
								-- wrap_flag is RO.
								wrapped_flag <= avs_writedata(f(1, 3));
							end if;
						when x"2" =>
							avs_readdata(f(2, 0)) <= reset_flag;
							avs_readdata(f(2, 1)) <= pause_flag;
							avs_readdata(f(2, 2)) <= wrap_flag;
							avs_readdata(f(2, 3)) <= wrapped_flag;
							if wr = '1' then
								reset_flag   <= avs_writedata(f(2, 0));
								pause_flag   <= avs_writedata(f(2, 1));
								-- wrap_flag is RO.
								wrapped_flag <= avs_writedata(f(2, 3));
							end if;
						when x"3" =>
							avs_readdata(f(3, 0)) <= reset_flag;
							avs_readdata(f(3, 1)) <= pause_flag;
							avs_readdata(f(3, 2)) <= wrap_flag;
							avs_readdata(f(3, 3)) <= wrapped_flag;
							if wr = '1' then
								reset_flag   <= avs_writedata(f(3, 0));
								pause_flag   <= avs_writedata(f(3, 1));
								-- wrap_flag is RO.
								wrapped_flag <= avs_writedata(f(3, 3));
							end if;
						when others =>
							null;
					end case;
				
				-- magic
				when r(0, 3) | r(1, 3) | r(2, 3) | r(3, 3) =>
					avs_readdata <= x"babadeda";
					-- magic is RO.
				
				-- unpacked flags
				when r(0, 4) | r(1, 4) | r(2, 4) | r(3, 4) =>
					avs_readdata(0) <= reset_flag;
					if wr = '1' then
						reset_flag <= avs_writedata(0);
					end if;
				when r(0, 5) | r(1, 5) | r(2, 5) | r(3, 5) =>
					avs_readdata(0) <= pause_flag;
					if wr = '1' then
						pause_flag <= avs_writedata(0);
					end if;
				when r(0, 6) | r(1, 6) | r(2, 6) | r(3, 6) =>
					avs_readdata(0) <= wrap_flag;
					-- wrap_flag is RO.
				when r(0, 7) | r(1, 7) | r(2, 7) | r(3, 7) =>
					avs_readdata(0) <= wrapped_flag;
					if wr = '1' then
						wrapped_flag <= avs_writedata(0);
					end if;
						
				when others =>
					avs_readdata <= x"deadbeef";
					-- Other regs are RO.
			end case;
			
			
			-- After reg. write access, so would not loose setting of flag
			-- if wrap happen at the same time
			-- while SW is clearing wrappeg_flag in register.
			if wrap = '1' then
				wrapped_flag <= '1';
			end if;
		end if;
	end process;
	
	irq_pulse_inst: entity lprs2_qsys.monostable_multivibrator
	port map(
		i_clk     => clk,
		i_rst     => reset,
		i_trigger => wrap,
		o_pulse   => ins_wrap
	);
end architecture;
