
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library work;

entity lprs2_timer is
	port(
		-- System.
		clk              :  in std_logic;
		reset            :  in std_logic;
		
		-- Avalon slave.
		avs_chipselect   :  in std_logic;
		-- Word address.
		avs_address      :  in std_logic_vector(3 downto 0);
		avs_write        :  in std_logic;
		avs_writedata    :  in std_logic_vector(31 downto 0);
		avs_read         :  in std_logic;
		avs_readdata     : out std_logic_vector(31 downto 0);
		
		-- IRQ.
		ins_tc           : out std_logic
	);
end entity;

architecture lprs2_timer_arch of lprs2_timer is
	
	signal cnt : std_logic_vector(31 downto 0);
	signal next_cnt : std_logic_vector(31 downto 0);
	signal tc : std_logic;
	signal irq_th : std_logic_vector(31 downto 0);
begin
	
	tc <= '1' when cnt = 12000000 else '0';
	next_cnt <= (others => '0') when tc = '1' else cnt+1;
	
	process(clk, reset)
	begin
		if reset = '1' then
			cnt <= (others => '0');
		elsif rising_edge(clk) then
			cnt <= next_cnt;
		end if;
	end process;
	
	avs_readdata <= cnt;
	
	process(clk, reset)
	begin
		if reset = '1' then
			irq_th <= x"00000002";
		elsif rising_edge(clk) then
			if avs_chipselect = '1' and avs_write = '1' and avs_address = 0 then
				irq_th <= avs_writedata;
			end if;
		end if;
	end process;
	
	ins_tc <= '1' when cnt < irq_th else '0';
	-- process(clk, reset)
	-- begin
	-- 	if reset = '1' then
	-- 		ins_tc <= '0';
	-- 	elsif rising_edge(clk) then
	-- 		if tc = '1' then
	-- 			ins_tc <= '1';
	-- 		elsif avs_chipselect = '1' and avs_write = '1' and avs_address = 0 then
	-- 			ins_tc <= '0';
	-- 		end if;
	-- 	end if;
	-- end process;

end architecture;
