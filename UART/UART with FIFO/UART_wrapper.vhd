--INFO
-- Project : UART with FIFO
-- Module: UART_wrapper
-- Designer : Ekin Akyildirim
-- Supervisor and Mentor: Goktug Saray

--GENERAL DESIGN INFO
--First, the transmitter, which automatically generates data between 0 and 255, starts sending signals to the receiver. 
--The receiver then receives the signals and converts them into data, which is written to the FIFO. 
--Next, the FIFO reads the data and sends it to the transmitter, which then transmits this data externally.

--DESIGN INFO OF PARTICULAR MODULE (UART_wrapper)
--This module combines TX and RX under a single module and allows monitoring of certain signals for RX. 
--Additionally, it provides configuration options to use only RX, only TX, or both.

--COMPONENTS OF MODULE
--uart_tx
--uart_rx

-- SETTINGS
-- Set g_uart_mode to 'rx', 'tx', or 'both' to select the UART module you want to use. The default recommendation is "both". Otherwise, necessary changes need to be made.
-- Modify g_clkfreq to set the clock frequency. The default recommendation is '100_000_000'.
-- Modify g_baudrate to set the baud rate. The default recommendation is '115_200'.
-- Modify g_stopbit to adjust the UART transmitter stop bit for an 8-bit transmission. The default recommendation is '2'.

-- ILA SETTINGS
-- ILA is used to observe and analyze rx_done_tick_s and dout_o_s signals in the FPGA design.
-- Changes can be made via UART_wrapper

-- VIO SETTINGS
-- """"""

-- BOARD
--Zed Board


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity UART_wrapper is
generic (
            g_uart_mode     : string := "both"; --"tx" , "rx" or "both" to select uart mode
            g_clkfreq		: integer := 100_000_000;
			g_baudrate		: integer := 115_200;
			g_stopbit		: integer := 2					
		);
port (  
            clk : in std_logic;
            tx_o : out std_logic;
            rx_i : in std_logic;
            dout_o : out std_logic_vector( 7 downto 0);
            din_i : in std_logic_vector( 7 downto 0);
            rst_i : in std_logic;  
            rx_data_valid_o : out std_logic   ;
            tx_data_valid_o : out std_logic  ; 
            tx_start_i      : in std_logic  
            
             
      );
end UART_wrapper;

architecture Behavioral of UART_wrapper is

        --SIGNALS
        signal rx_done_tick_s : std_logic;
        signal dout_o_s : std_logic_vector(7 downto 0);
        
        
        --ILA ATTRIBUTES
        attribute mark_debug : string;
        attribute MARK_DEBUG of rx_done_tick_s : signal is "FALSE";
        attribute MARK_DEBUG of dout_o_s : signal is "FALSE";
        
             
      
        --COMPONENT UART_RX
        component uart_rx is
		--GENERIC
			generic (
			g_clkfreq		: integer := 100_000_000;
			g_baudrate		: integer := 115_200
			
			  );
		--PORTS
			port (
			clk				: in std_logic;
			dout_o			: out std_logic_vector (7 downto 0);			
			rx_reset_i      : in std_logic;
			rx_i			: in std_logic;
			rx_done_tick_o	: out std_logic
			 );
            end component;
        
        
        --COMPONENT UART_TX
            component uart_tx is
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
			
			 );
            end component;
            
         

begin
            --UART_RX
            UART_RX_Gen : if g_uart_mode = "rx" or g_uart_mode = "both" generate
            begin
            i_uart_rx : uart_rx
            generic map (
            g_clkfreq => g_clkfreq,
            g_baudrate => g_baudrate		
            )
            port map (
            clk				=> clk,
            dout_o			=> dout_o_s,
            rx_reset_i      => rst_i,
            rx_i			=> rx_i,
            rx_done_tick_o	=> rx_done_tick_s
            );
            end generate;
            
            --UART_TX
            UART_TX_Gen : if g_uart_mode = "tx" or g_uart_mode = "both" generate
            begin
            i_uart_tx : uart_tx
            generic map (
            g_clkfreq => g_clkfreq,
            g_baudrate => g_baudrate,		
            g_stopbit => g_stopbit
            )
            port map (
            clk				=> clk,
            din_i			=> din_i,
            tx_start_i		=> tx_start_i,
            tx_reset_i      => rst_i,
            tx_o			=> tx_o,
            tx_done_tick_o	=> tx_data_valid_o
            
            );
            end generate;
            
            dout_o <= dout_o_s;
            rx_data_valid_o <= rx_done_tick_s;
            
                 


      
end Behavioral;
