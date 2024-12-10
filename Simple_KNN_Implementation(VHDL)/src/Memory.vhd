--====================================================================================

-- Module Name : Memory.vhd
-- Library	   : --
-- Project	   : KNN Implementation
-- Company	   : --
-- Author	   : Ekin Akyildirim

-- Description: Memory Module for KNN Implementation
-- Change Log:	19.11.2024 | Ekin Akyildirim | v0.1 

-----------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


-----------------------------------------
------------------ PORTS ----------------
-----------------------------------------
entity Memory is
    generic (
        DATA_WIDTH : integer := 16;  
        ADDR_WIDTH : integer := 8;   
        DEPTH      : integer := 120  
    );
    port (
        clk          : in  STD_LOGIC;                        
        write_enable : in  STD_LOGIC;                        
        read_enable  : in  STD_LOGIC;                        
        addr         : in  STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0); 
        data_in      : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0); 
        data_out     : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)  
    );
end Memory;


-----------------------------------------
---------------- RTL --------------------
-----------------------------------------
architecture Behavioral of Memory is
    type memory_array is array (0 to DEPTH-1) of STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0); 
    signal mem : memory_array := (others => (others => '0')); 
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if write_enable = '1' and read_enable = '0' then
                mem(to_integer(unsigned(addr))) <= data_in;
            elsif write_enable = '0' and read_enable = '1' then
                data_out <= mem(to_integer(unsigned(addr)));
            end if;
        end if;
    end process;
end Behavioral;

 
