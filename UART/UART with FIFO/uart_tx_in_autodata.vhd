--INFO
-- Project : UART with FIFO
-- Module: uart_tx_in_autodata
-- Designer : Ekin Akyildirim
-- Supervisor and Mentor: Göktug Saray

--GENERAL DESIGN INFO
--First, the transmitter, which automatically generates data between 0 and 255, starts sending signals to the receiver. 
--The receiver then receives the signals and converts them into data, which is written to the FIFO. 
--Next, the FIFO reads the data and sends it to the transmitter, which then transmits this data externally.

--DESIGN INFO OF PARTICULAR MODULE (uart_tx_in_autodata)
--This module enables a TX to automatically generate data between 0 and 255, and the delay time can be adjusted.

--COMPONENTS OF MODULE
--uart_tx_in

-- SETTINGS
--Adjust the delay_cnt_c. DEFAULT (g_clkfreq/10000) => for simulation   (g_clkfreq/10) => for implemantation

-- ILA SETTINGS
-- """"""

-- VIO SETTINGS
-- """"""

-- BOARD
--Zed Board


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity uart_tx_in_autodata is
generic (
            g_clkfreq		: integer := 100_000_000;
			g_baudrate		: integer := 115_200;
			g_stopbit		: integer := 2			
		);
port (  
            clk : in std_logic;
            tx_o : out std_logic;
            tx_rst_i : in std_logic
            
            --din_i    : in std_logic_vector (7  downto 0);
            --tx_start_i : in std_logic;
            --tx_done_tick_o: out std_logic;
            --tx_ready_o    : out std_logic
      );
		


end uart_tx_in_autodata;

architecture Behavioral of uart_tx_in_autodata is
    
    --CONSTANTS
    constant delay_cnt_c : integer := (g_clkfreq) / 10000;

    --STATE DEFN
    type fsm_t is (send_st, wait_st, delay_st);
    signal fsm_s : fsm_t;
    
    --SIGNALS
    signal din_s : std_logic_vector(7 downto 0);
    signal tx_start_s : std_logic;
    signal tx_done_tick_s : std_logic;	
   
   --RESET SIGNALS
    --signal tx_probe_rst :  std_logic_vector(0 DOWNTO 0) ;    
    --signal rst_s : std_logic;   
    
    signal delay_counter_s : integer;
    signal tx_done_tick_d1_s : std_logic;

--COMPONENT UART_TX
component uart_tx_in is
		--GENERIC
			generic (
			g_clkfreq		: integer := 100_000_000;
			g_baudrate		: integer := 115_200;
			g_stopbit		: integer := 2
			
			  );
		--PORTS
			port (
			clk				: in std_logic;
			din_i			: in std_logic_vector (7 downto 0);
			tx_start_i		: in std_logic;
			tx_reset_i      : in std_logic;
			tx_o			: out std_logic;
			tx_done_tick_o	: out std_logic
			
			--tx_ready_o      : out std_logic
			 );
end component;





begin

     --UART_TX
    i_uart_tx : uart_tx_in
    generic map (
    g_clkfreq => g_clkfreq,
    g_baudrate => g_baudrate,		
    g_stopbit => g_stopbit
    )
    port map (
    clk				=> clk,
    din_i			=> din_s,
    tx_start_i		=> tx_start_s,
    tx_reset_i      => tx_rst_i,
    tx_o			=> tx_o,
    tx_done_tick_o	=> tx_done_tick_s
    
    );

  
 
 
--OTO INPUT PROCESS         
process (clk) begin        
        if(rising_edge(clk)) then         
            
                                                
            
            if(tx_rst_i = '1') then
                
                                        
                    din_s <= (others => '0');
                    tx_start_s <= '0';
                    delay_counter_s <= 0;                       
                    tx_done_tick_d1_s <= '0';                        
                    fsm_s <= send_st;
                
                
            else
                                
                    tx_start_s <= '0';  
                    tx_done_tick_d1_s <= tx_done_tick_s;
                
                
                case fsm_s is                     
                    when send_st =>
                        
                        din_s <= std_logic_vector(unsigned(din_s) + 1);
                        tx_start_s <= '1';
                        fsm_s <= wait_st;
                   
                    when wait_st =>
                        
                        if(tx_done_tick_d1_s = '0' and tx_done_tick_s = '1') then
                            fsm_s <= delay_st;
                        else
                            fsm_s <= wait_st;
                        end if;
                    
                    when delay_st =>
                        
                        if(delay_counter_s = delay_cnt_c) then
                            delay_counter_s <= 0;
                            fsm_s <= send_st;
                        else
                            delay_counter_s <= delay_counter_s + 1;
                        end if;
                end case;
             end if;
         end if;               
          
    end process;
end Behavioral;
