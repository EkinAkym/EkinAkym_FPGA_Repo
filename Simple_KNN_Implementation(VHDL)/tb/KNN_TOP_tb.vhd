----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.11.2024 11:09:42
-- Design Name: 
-- Module Name: KNN_TOP_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;



entity KNN_TOP_tb is
end KNN_TOP_tb;

architecture Behavioral of KNN_TOP_tb is
    signal clk : std_logic := '0';
    signal tx_s  : std_logic ;
    signal tx  : std_logic ;
    signal din_s : std_logic_vector(7 downto 0) ;
    signal tx_done_tick_s : std_logic;
    signal reset : std_logic;
    signal tx_start_s : std_logic;
    
    constant CLK_PERIOD : time := 10 ns;
    
    type memory_array is array(0 to 59) of STD_LOGIC_VECTOR(15 downto 0);
    
    signal ref_data_diff_arr : memory_array := (
        "0000000000000000", "0000000000000000", "0000000000000000", "0000000000000000",
"0000000000000000", "0000000000000000", "0000000000000000", "0000000000000000",
"0000000000000000", "0000000000000000", "0000000001111000", "0000000001110111",
"0000000001111001", "0000000001111100", "0000000001111011", "0000000001111010",
"0000000001110110", "0000000001111110", "0000000001111101", "0000000001111100",
"0000000010001001", "0000000010001100", "0000000010001010", "0000000010001011",
"0000000010001010", "0000000010001101", "0000000010001001", "0000000010001010",
"0000000010001100", "0000000010001101", "0000000000010110", "0000000000010111",
"0000000000010110", "0000000000010111", "0000000000010101", "0000000000011000",
"0000000000010111", "0000000000010110", "0000000000010101", "0000000000010110",
"0000000010000000", "0000000010000001", "0000000001111111",
"0000000010000010", "0000000010000011", "0000000010000000", "0000000001111111",
"0000000010000001", "0000000010000001", "0000000000110011",
"0000000000110000", "0000000000110000", "0000000000110000", "0000000000110010",
"0000000000110011", "0000000000110010", "0000000000110010", "0000000000110010",
"0000000000110001", "0000000000110000"

    );

   signal ref_data_ppm_arr  : memory_array := (
"0000000000000000", "0000000000000000", "0000000000000000", "0000000000000000",
"0000000000000000", "0000000000000000", "0000000000000000", "0000000000000000",
"0000000000000000", "0000000000000000", "0000000001001100", "0000000001001100",
"0000000001001100", "0000000001001101", "0000000001001101", "0000000001001100",
"0000000001001100", "0000000001001101", "0000000001001100", "0000000001001101",
"0000000000000000", "0000000000000000", "0000000000000000", "0000000000000000",
"0000000000000000", "0000000000000000", "0000000000000000", "0000000000000000",
"0000000000000000", "0000000000000000", "0000001001010101", "0000001001010101",
"0000001001010101", "0000001001010101", "0000001001010101", "0000001001010101",
"0000001001010101", "0000001001010101", "0000001001010101", "0000000000010110",
"0000001000001000", "0000001000001000","0000001000001000", "0000001000001000", 
"0000001000001000", "0000001000001000","0000001000001000", "0000001000001000", 
"0000001000001000", "0000001000001000","0000000000000000", "0000000000000000", 
"0000000000000000","0000000000000000", "0000000000000000", "0000000000000000", 
"0000000000000000", "0000000000000000", "0000000000000000", "0000000000000000"
);
    
    component uart_tx
	generic (
		g_clkfreq		: integer := 50_000_000;
		g_baudrate		: integer := 115_200;
		g_stopbit		: integer := 2
	);
	
	port (
		clk				: in std_logic;
		din_i			: in std_logic_vector (7 downto 0);
		tx_start_i		: in std_logic;
		tx_reset_i 		: in std_logic;
		tx_o			: out std_logic;
		tx_done_tick_o	: out std_logic 
	);
	end component;

begin
    uart_tx_inst : uart_tx 
		generic  map (
			g_clkfreq 	=> 50_000_000,
			g_baudrate 	=> 115_200,
			g_stopbit 	=> 2
		)
		port map (
			clk			   => clk,
			din_i		   => din_s,
			tx_start_i     => tx_start_s,
			tx_reset_i     => reset,
			tx_o 		   => tx_s,
			tx_done_tick_o => tx_done_tick_s
		);

    dut : entity work.KNN_TOP
        generic map (
            g_clkfreq =>    50_000_000,
            g_baudrate =>   115_200,
            g_stopbit =>    2,
            g_data_width => 16,
            g_depth =>      128,
            g_addr_width => 8,
            g_numberOfLiquid => 6
        )
        port map(
            clk => clk,
            tx  => tx,
            rx  => tx_s,
            reset => reset 
            );
            
     clk_process :process
    begin     
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;     
    end process;
    
    stim_proc : process
        variable i: integer := 0;
        variable j: integer := 0;
        
        begin  
            
            reset <= '0';
            wait for 2*CLK_PERIOD;
            
            
            din_s <= x"02";
            tx_start_s <= '1';
            wait for 2*CLK_PERIOD;
            tx_start_s <= '0';
            
            wait for 100 us;
            din_s <= x"0A";
            tx_start_s <= '1';
            wait for 2*CLK_PERIOD;
            tx_start_s <= '0';
            
            while i < 60  loop
                wait for 100 us;
                din_s <= ref_data_diff_arr(i)(15 downto 8);
                tx_start_s <= '1';
                wait for 2*CLK_PERIOD;
                tx_start_s <= '0';
                wait for 100 us;
                din_s <= ref_data_diff_arr(i)(7 downto 0);
                tx_start_s <= '1';
                wait for 2*CLK_PERIOD;
                tx_start_s <= '0';
                wait for 100 us;
                din_s <= ref_data_ppm_arr(i)(15 downto 8);
                tx_start_s <= '1';
                wait for 2*CLK_PERIOD;
                tx_start_s <= '0';
                wait for 100 us;
                din_s <= ref_data_ppm_arr(i)(7 downto 0);
                tx_start_s <= '1';
                wait for 2*CLK_PERIOD;
                tx_start_s <= '0';
                i := i+1 ;
            end loop;
            wait for 2*CLK_PERIOD;
            wait for 100 us;
            din_s <= "00000011";
            tx_start_s <= '1';
            wait for 2*CLK_PERIOD;
            tx_start_s <= '0';
            wait for 100 us;
            din_s <= "00000000";
            tx_start_s <= '1';
            wait for 2*CLK_PERIOD;
            tx_start_s <= '0';
            wait for 100 us;
            din_s <="10000011";
            tx_start_s <= '1';
            wait for 2*CLK_PERIOD;
            tx_start_s <= '0';
             wait for 100 us;
            din_s <= "00000010";
            tx_start_s <= '1';
            wait for 2*CLK_PERIOD;
            tx_start_s <= '0';
             wait for 100 us;
            din_s <= "00001000";
            tx_start_s <= '1';
            wait for 2*CLK_PERIOD;
            tx_start_s <= '0';
             wait for 100 us;
             wait;
            
           
           
            
     
    end process;
            
        

end Behavioral;
