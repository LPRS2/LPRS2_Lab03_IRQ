
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library work;

entity lprs2_7segm is
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
		coe_mux_digit    : out std_logic_vector(7 downto 0);
		coe_sel_digit    : out std_logic_vector(1 downto 0)
	);

end entity;

architecture lprs2_7segm_arch of lprs2_7segm is
	
begin
	
end architecture;
