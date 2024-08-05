--INFO
-- Project : UART with BRAM
-- Module: block_ram


------------------------------------------------------------------
--library ieee;
--use ieee.std_logic_1164.all;

--package ram_pkg is
--    function clogb2 (depth: in natural) return integer;
--end ram_pkg;
--
--package body ram_pkg is
--
--function clogb2( depth : natural) return integer is
--variable temp    : integer := depth;
--variable ret_val : integer := 0;
--begin
--    while temp > 1 loop
--        ret_val := ret_val + 1;
--        temp    := temp / 2;
--    end loop;
--  	return ret_val;
--end function;
--
--end package body ram_pkg;
-------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--use work.ram_pkg.all;
USE std.textio.all;

entity block_ram is
generic (
g_ram_width 		: integer 	:= 16;				-- Specify RAM data width
g_ram_depth 		: integer 	:= 128;				-- Specify RAM depth (number of entries)
g_ram_performance   : string 	:= "LOW_LATENCY";    -- Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
g_ram_type 		    : string 	:= "block"    -- Select "block" or "distributed" 

);
port (
addra : in std_logic_vector(7 downto 0);    -- Address bus, width determined from RAM_DEPTH
dina  : in std_logic_vector(g_ram_width-1 downto 0);		  		-- RAM input data
clka  : in std_logic;                       			  		-- Clock
wea   : in std_logic;                       			  		-- Write enable
douta : out std_logic_vector(g_ram_width-1 downto 0)   			-- RAM output data
);
end block_ram;

architecture Behavioral of block_ram is

constant c_ram_width 		: integer := g_ram_width;
constant c_ram_depth 		: integer := g_ram_depth;
constant c_ram_performance 	: string := g_ram_performance;

signal douta_reg : std_logic_vector(c_ram_width-1 downto 0) := (others => '0');
type ram_type is array (c_ram_depth-1 downto 0) of std_logic_vector (c_ram_width-1 downto 0);          -- 2D Array Declaration for RAM signal
signal ram_data : std_logic_vector(c_ram_width-1 downto 0) ;

-- Following code defines RAM
signal ram_name : ram_type := (others => (others => '0'));

-- ram_style attribute
attribute ram_style : string;
attribute ram_style of ram_name : signal is g_ram_type;

begin

-- write process
process(clka)
begin
if(rising_edge(clka)) then

	if(wea = '1') then
		ram_name(to_integer(unsigned(addra))) <= dina;
	end if;
	ram_data <= ram_name(to_integer(unsigned(addra)));
	
end if;
end process;

--  Following code generates LOW_LATENCY (no output register)
--  Following is a 1 clock cycle read latency at the cost of a longer clock-to-out timing

no_output_register : if c_ram_performance = "LOW_LATENCY" generate
    douta <= ram_data;
end generate;

--  Following code generates HIGH_PERFORMANCE (use output register)
--  Following is a 2 clock cycle read latency with improved clock-to-out timing
output_register : if c_ram_performance = "HIGH_PERFORMANCE"  generate
process(clka)
begin
    if(rising_edge(clka)) then
		douta_reg <= ram_data;
	end if;
end process;
douta <= douta_reg;

end generate;

end Behavioral;