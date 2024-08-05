--INFO
-- Project : UART
-- Module: TOP
-- Designer : Ekin Akyýldýrým
-- Supervisor and Mentor: Göktuð Saray

 
-- SETTINGS
-- Set g_uart_mode to 'rx', 'tx', or 'both' to select the UART module you want to use.
-- Modify g_clkfreq to set the clock frequency. The default recommendation is '100_000_000'.
-- Modify g_baudrate to set the baud rate. The default recommendation is '115_200'.
-- Modify g_stopbit to adjust the UART transmitter stop bit for an 8-bit transmission. The default recommendation is '2'.

-- TX SETTINGS 
-- wrapper_tx module generates data din_i autonomously within the range of 0 to 255.
--You can enable or disable this by changing g_autodatagen to either YES or NO, respectively.

-- ILA SETTINGS
-- ILA is used to observe and analyze rx_done_tick_s and dout_o_s signals in the FPGA design.
-- Changes can be made via wrapper_rx.

-- VIO SETTINGS
-- VIO is used for resets of both RX and TX in wrapper_rx and wrapper_tx.

-- BOARD
--Zed Board


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;



entity uart_TOP is
generic (
            g_uart_mode     : string := "both"; --"tx" , "rx" or "both" to select uart mode
            g_clkfreq		: integer := 100_000_000;
			g_baudrate		: integer := 115_200;
			g_stopbit		: integer := 2;
			g_autodatagen   : string:= "NO"  -- YES OR NO
		);
port (  
            clk : in std_logic;
            tx_o : out std_logic;
            rx_i : in std_logic;
            dout_o : out std_logic_vector( 7 downto 0);
            din_i : in std_logic_vector( 7 downto 0);
            rst_i : in std_logic;  
            rx_data_valid_o : out std_logic   ;
            tx_data_valid_o : out std_logic ; 
            tx_start_i      : in std_logic ; 
            tx_ready_o    : out std_logic 
             
      );
end uart_TOP;

architecture Behavioral of uart_TOP is
       signal uart_mode_s : std_logic_vector (1 downto 0 ):= "00";


--SIGNALS
      signal rst_full_s : std_logic;    
      signal probe_rst : std_logic_vector(0 downto 0); 
    


--COMPONENT WRAPPER-TX   
    component wrapper_tx is
        generic (
            g_clkfreq : integer := 100_000_000;
            g_baudrate : integer := 115_200;
            g_stopbit : integer := 2;
            g_autodatagen   : string:= "NO"  -- YES OR NO
        );
        port (
            clk : in std_logic;
            tx_o : out std_logic;
            tx_rst_i : in std_logic;
            din_i : in std_logic_vector( 7 downto 0) := x"00" ;
            tx_start_i : in std_logic;
            tx_done_tick_o: out std_logic;
            tx_ready_o    : out std_logic                
            
        );
    end component;
    
    
--COMPONENT WRAPPER-RX   
    component wrapper_rx is
        generic (
            g_clkfreq : integer := 100_000_000;
            g_baudrate : integer := 115_200
         );
        port (
            clk : in std_logic;
            rx_i : in std_logic;
            rx_rst_i : in std_logic;
            dout_o : out std_logic_vector (7 downto 0);
            rx_data_valid_o : out std_logic
                      
         );
    end component;
    
    --COMPONENT VIO for RESET  
     component rst_vio is
            port (
               clk : in std_logic;
               probe_out0 : out std_logic_vector(0 DOWNTO 0) 
          );
      end component;
      
  
    

begin
        
       
       
       
        -- RX GENERATION
       
        Wrapper_RX_Gen : if g_uart_mode = "rx" or g_uart_mode = "both" generate        
        Wrapper_RX_Inst : Wrapper_RX
            generic map (
                g_clkfreq => g_clkfreq,
                g_baudrate => g_baudrate               
            )
            port map (               
                clk => clk,
                rx_i => rx_i,
                rx_rst_i => rst_full_s,
                dout_o => dout_o,
                rx_data_valid_o => rx_data_valid_o
            );
        end generate;
        
        -- TX GENERATION
        Wrapper_TX_Gen : if g_uart_mode = "tx" or g_uart_mode = "both" generate
        begin
        Wrapper_TX_Inst : wrapper_tx
            generic map (
                g_clkfreq => g_clkfreq,
                g_baudrate => g_baudrate,
                g_stopbit => g_stopbit,
                g_autodatagen => g_autodatagen
            )
            port map (
                clk => clk,
                tx_o => tx_o,
                tx_rst_i => rst_full_s,
                din_i => din_i,
                tx_start_i => tx_start_i,
                tx_done_tick_o => tx_data_valid_o,
                tx_ready_o     => tx_ready_o
            );
        end generate;
        
        
        
            --VIO RESET
          Vio_rst : rst_vio
           port map (
            clk => clk,
            probe_out0 => probe_rst
         );
                  
             process (clk) begin        
                if(rising_edge(clk)) then         
            
                    if (rst_i = '1') then
                        rst_full_s <= rst_i;                       
                    else
                    rst_full_s <= probe_rst(0);              
                    end if;
                end if;
            end process;
              
          
      

end Behavioral;
