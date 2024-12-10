--==================================================================================--

-- 	Module Name : 	KNN.vhd
-- 	Project	   	: 	KNN Implementation (AI Chip Design: Liquid Identification)
-- 	Author	   	: 	Ekin AKYILDIRIM
-- 	Change Log	:	10.12.2024 | Ekin Akyildirim | v0.2
--	Description	:

--==================================================================================--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-----------------------------------------
------------------ PORTS ----------------
-----------------------------------------
entity KNN is
    generic (
        
        g_data_width : integer := 32;  
        g_addr_width : integer := 8;   
        g_depth      : integer := 64   
    );
    port (
        clk            : in  std_logic;
		reset		   : in  std_logic;
        en             : in  std_logic;       
        ref_data_diff  : in  std_logic_vector((g_data_width/2)-1 downto 0);
        ref_data_ppm   : in  std_logic_vector((g_data_width/2)-1 downto 0);
        test_data_diff : in  std_logic_vector((g_data_width/2)-1 downto 0);
        test_data_ppm  : in  std_logic_vector((g_data_width/2)-1 downto 0);
        predict_valid  : out std_logic;
        result         : out std_logic_vector(g_addr_width -1 downto 0):= "FF"
    );
end KNN;

-----------------------------------------
---------------- RTL --------------------
-----------------------------------------
architecture Behavioral of KNN is

-- Signals --
    signal distance      : std_logic_vector(g_data_width-1 downto 0):= x"00000000";
    signal addr          : std_logic_vector(g_addr_width-1 downto 0) := (others => '0');
    signal write_enable  : std_logic := '0';
    signal min_distance  : std_logic_vector(g_data_width-1 downto 0) := (others => '1'); 
    signal read_enable   : std_logic := '0';
    signal read_enable_toggle   : std_logic := '0';
    signal current_addr     : std_logic_vector(g_addr_width-1 downto 0) ;
    signal memory_out : std_logic_vector(g_data_width-1 downto 0);
   
-- Components --
    component Memory
        generic (
            DATA_WIDTH : integer := 32;
            ADDR_WIDTH : integer := 8;
            DEPTH      : integer := 64
        );
        port (
            clk          : in  std_logic;
            write_enable : in  std_logic;
            read_enable  : in  std_logic;
            addr         : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
            data_in      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            data_out     : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component;
  
begin

-- Inst. --
    memory_inst : Memory
        generic map (
            DATA_WIDTH => g_data_width,
            ADDR_WIDTH => g_addr_width,
            DEPTH      => g_depth
        )
        port map (
            clk          => clk,
            write_enable => write_enable,
            read_enable  => read_enable,
            addr         => addr,
            data_in      => distance,
            data_out     => memory_out
        );

-- Process --
    process(clk)
    begin
        if rising_edge(clk) then
			if reset = '1' then	
				read_enable_toggle <= '0';
				write_enable <= '0';
				read_enable <= '0';
				predict_valid <= '0';
				current_addr <= x"00";
				addr <= x"00";
				min_distance <= (others => '1');
			else

                if read_enable_toggle = '0' and en = '1' then
                    write_enable <= '1';
					
                   -------------------------------------------CALCULATION-----------------------------------------------------------------------------
					distance <= std_logic_vector(
						(abs(signed(ref_data_diff) - signed(test_data_diff)) * abs(signed(ref_data_diff) - signed(test_data_diff))) +
						(abs(signed(ref_data_ppm) - signed(test_data_ppm)) * abs(signed(ref_data_ppm) - signed(test_data_ppm)))
						);
				   -----------------------------------------------------------------------------------------------------------------------------------
					
                elsif (read_enable_toggle = '0' or read_enable_toggle = '1') and en = '0' then
                    write_enable <= '0';
                end if;
                
                if write_enable = '1' and read_enable = '0' then
                    addr <= std_logic_vector(unsigned(addr) + 1);
                    current_addr <= x"00";
                    predict_valid <= '0';
                end if;
                
				if addr = std_logic_vector(to_unsigned(g_depth-5, g_addr_width)) then
                        write_enable <= '0'; 
                        read_enable_toggle <= '1';  
                        addr <= "00000000";            
                end if;
            
                if read_enable_toggle = '1' then
                    read_enable <= '1';
                    addr <= "00000000";   
                end if;
    
                if read_enable = '1' then    
                    if unsigned(memory_out) < unsigned(min_distance) and addr /= x"00" then
                        min_distance <= memory_out;           
                        current_addr <= std_logic_vector(unsigned(addr) - 1);
                    end if;
                        
                    if addr = std_logic_vector(to_unsigned(g_depth-4, g_addr_width)) then
                        read_enable <= '0';
                        read_enable_toggle <= '0';
                        addr <= "00000000";
                        predict_valid <= '1';
                        min_distance <= (others => '1');
						
						------------------------------PREDICTION------------------------------------------
                        if 	  unsigned(current_addr) >= 0 and unsigned(current_addr) <= 9 then
                            result <= "00000001";  -- Result 1 : Empty
                        elsif unsigned(current_addr) >= 10 and unsigned(current_addr) <= 19 then
                            result <= "00000010";  -- Result 2 : Water
                        elsif unsigned(current_addr) >= 20 and unsigned(current_addr) <= 29 then
                            result <= "00000011";  -- Result 3 : Soap
                        elsif unsigned(current_addr) >= 30 and unsigned(current_addr) <= 39 then
                            result <= "00000100";  -- Result 4 : Oil
                        elsif unsigned(current_addr) >= 40 and unsigned(current_addr) <= 49 then
                            result <= "00000101";  -- Result 5 : Vinegar
                        elsif unsigned(current_addr) >= 50 and unsigned(current_addr) <= 59 then
                            result <= "00000110";  -- Result 6 : Cologne      
                        else
                            result <= x"FF";  --error
                        end if;
						--------------------------------------------------------------------------------
                     else
                        addr <= std_logic_vector(unsigned(addr) + 1);
                        predict_valid <= '0';
                     end if;
                end if;
            end if;
		end if;
    end process;
end Behavioral;

