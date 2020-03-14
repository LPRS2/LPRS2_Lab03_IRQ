
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity monostable_multivibrator is
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
end entity;

architecture monostable_multivibrator_arch of monostable_multivibrator is
	signal cnt : std_logic_vector(BITS-1 downto 0);
begin
	--TODO assert.
	
	process(i_clk, i_rst)
	begin
		if i_rst = '1' then
			cnt <= (others => '0');
		elsif rising_edge(i_clk) then
			if cnt = 0 then
				if i_trigger = '1' then
					cnt <= cnt+1;
				end if;
			elsif cnt = DURATION_CLKS then
				cnt <= (others => '0');
			else
				cnt <= cnt+1;
			end if;
		end if;
	end process;
	
	o_pulse <= '1' when cnt /= 0 else '0';

end architecture;
