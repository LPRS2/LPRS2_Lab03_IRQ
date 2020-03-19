
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library work;

entity lprs2_timer is
	port(
		-- System.
		clk              : in  std_logic;
		reset            : in  std_logic;
		
		-- Avalon slave.
		avs_chipselect   : in  std_logic;
		-- Word address.
		avs_address      : in  std_logic_vector(5 downto 0);
		avs_write        : in  std_logic;
		avs_writedata    : in  std_logic_vector(31 downto 0);
		avs_read         : in  std_logic;
		avs_readdata     : out std_logic_vector(31 downto 0);
		
		-- IRQ.
		ins_wrap      : out std_logic
	);
end entity;

architecture lprs2_timer_arch of lprs2_timer is
	
	-- TODO Use entity.
	component monostable_multivibrator is
		generic(
			DURATION_CLKS : natural := 8;
			BITS : natural := 4
		);
		port(
			i_clk            : in  std_logic;
			i_rst            : in  std_logic;
			
			i_trigger        : in  std_logic;
			
			o_pulse          : out std_logic
		);
	end component;
	
	
	signal cnt_reg : std_logic_vector(31 downto 0);
	signal wrap : std_logic;
	signal wrap_cnt : std_logic_vector(31 downto 0);
	signal reset_cnt : std_logic_vector(31 downto 0);
	signal next_cnt : std_logic_vector(31 downto 0);
	
	signal addr : std_logic_vector(7 downto 0);
	signal modulo_reg : std_logic_vector(31 downto 0);
	signal reset_flag : std_logic;
	signal pause_flag : std_logic;
	signal wrap_flag : std_logic;
	signal wrapped_flag : std_logic;
	
	
	signal wr : std_logic;
begin
	
	wrap <= '1' when cnt_reg = modulo_reg else '0';
	wrap_cnt <= (others => '0') when wrap = '1' else cnt_reg+1;
	reset_cnt <= (others => '0') when reset_flag = '1' else wrap_cnt;
	next_cnt <= cnt_reg when pause_flag = '1' else reset_cnt;
	
	wrap_flag <= wrap;
	
	addr <= "00" & avs_address;
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
				when x"00" =>
					avs_readdata <= cnt_reg;
					if wr = '1' then
						cnt_reg <= avs_writedata;
					end if;
					
				-- modulo_reg
				when x"01" =>
					avs_readdata <= modulo_reg;
					if wr = '1' then
						modulo_reg <= avs_writedata;
					end if;
					
				-- flags
				when x"02" =>
					avs_readdata(0) <= reset_flag;
					avs_readdata(1) <= pause_flag;
					avs_readdata(2) <= wrap_flag;
					avs_readdata(3) <= wrapped_flag;
					if wr = '1' then
						reset_flag <= avs_writedata(0);
						pause_flag <= avs_writedata(1);
						-- wrap_flag is RO.
						wrapped_flag <= avs_writedata(3);
					end if;
				
				-- unpacked flags
				when x"04" =>
					avs_readdata(0) <= reset_flag;
					if wr = '1' then
						reset_flag <= avs_writedata(0);
					end if;
				when x"05" =>
					avs_readdata(0) <= pause_flag;
					if wr = '1' then
						pause_flag <= avs_writedata(0);
					end if;
				when x"06" =>
					avs_readdata(0) <= wrap_flag;
					-- wrap_flag is RO.
				when x"07" =>
					avs_readdata(0) <= wrapped_flag;
					if wr = '1' then
						wrapped_flag <= avs_writedata(0);
					end if;
						
				when others =>
					avs_readdata <= x"babadeda";
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
	
	irq_pulse_inst: component monostable_multivibrator
	port map(
		i_clk     => clk,
		i_rst     => reset,
		i_trigger => wrap,
		o_pulse   => ins_wrap
	);
end architecture;
