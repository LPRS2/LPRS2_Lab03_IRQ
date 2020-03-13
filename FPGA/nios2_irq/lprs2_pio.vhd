
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library work;

entity lprs2_pio is
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
		
		-- Conduit.
		coe_pi           :  in std_logic_vector(7 downto 0);
		coe_po           : out std_logic_vector(7 downto 0)
	);
end entity;

architecture lprs2_pio_arch of lprs2_pio is
	
	signal po                 : std_logic_vector(7 downto 0);
	signal prev_pi            : std_logic_vector(7 downto 0);
	signal pi                 : std_logic_vector(7 downto 0);
	signal pi_change_occured  : std_logic_vector(7 downto 0);
	signal pi_changed         : std_logic_vector(7 downto 0);
	signal read_pi_changed    : std_logic;
	signal read_pi_changed_d1 : std_logic;
begin
	
	process(clk, reset)
	begin
		if reset = '1' then
			po <= x"05";
		elsif rising_edge(clk) then
			if avs_chipselect = '1' and avs_write = '1' then
				if avs_address < 8 then
					po(conv_integer(avs_address)) <= avs_writedata(0);
				elsif avs_address = 8 then
					po <= avs_writedata(7 downto 0);
				elsif avs_address = 10 then
					if avs_writedata(0) = '0' then
						po <= (others => '0');
					else
						po <= (others => '1');
					end if;
				elsif avs_address = 11 then
					po <= not po;
				end if;
			end if;
		end if;
	end process;
	
	coe_po <= po;
	
	
	process(clk, reset)
	begin
		if reset = '1' then
			prev_pi <= x"00";
			pi <= x"00";
		elsif rising_edge(clk) then
			prev_pi <= pi;
			pi <= coe_pi;
		end if;
	end process;
	
	process(avs_address, pi, pi_changed)
	begin
		if avs_address < 8 then
			avs_readdata <= conv_std_logic_vector(0, 31) &
				pi(conv_integer(avs_address));
		elsif avs_address = 8 then
			avs_readdata <= x"000000" & pi;
		elsif avs_address = 9 then
			avs_readdata <= x"000000" & pi_changed;
		elsif avs_address = 10 then
			avs_readdata <= (others => '0');
		elsif avs_address = 11 then
			avs_readdata <= (others => '0');
		else
			avs_readdata <= x"babadeda";
		end if;
	end process;
	
	
	read_pi_changed <= 
		'1' when 
			avs_chipselect = '1' and
			avs_read = '1' and
			avs_address = 9 else
		'0';
	process(clk, reset)
	begin
		if reset = '1' then
			read_pi_changed_d1 <= '0';
		elsif rising_edge(clk) then
			read_pi_changed_d1 <= read_pi_changed;
		end if;
	end process;
	
	pi_change_occured <= prev_pi xor pi;
	
	process(clk, reset)
	begin
		if reset = '1' then
			pi_changed <= x"00";
		elsif rising_edge(clk) then
			if read_pi_changed_d1 = '1' then
				pi_changed <= x"00";
			else
				pi_changed <= pi_changed or pi_change_occured;
			end if;
		end if;
	end process;

end architecture;
