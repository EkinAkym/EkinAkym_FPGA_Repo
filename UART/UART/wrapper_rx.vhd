-- INFO
-- Project : UART
-- Module: Wrapper_RX
-- Designer : Ekin Akyýldýrým
-- Supervisor and Mentor: Göktuð Saray

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity wrapper_rx is
generic (
            g_clkfreq		: integer := 100_000_000;
			g_baudrate		: integer := 115_200
			
		);
port (  
            clk : in std_logic;
            dout_o : out std_logic_vector(7 downto 0);
            rx_i : in std_logic;
            rx_rst_i : in std_logic;      
            rx_data_valid_o: out std_logic
             
            
      );
		
end wrapper_rx;

architecture Behavioral of wrapper_rx is
    
    
   
    --SIGNALS
    signal rx_done_tick_s : std_logic;  
    signal dout_o_s : std_logic_vector(7 downto 0);
    signal rx_probe_rst :  std_logic_vector(0 DOWNTO 0) ;
    signal rst_s : std_logic;   
    signal rx_done_tick_d1_s : std_logic := '0';   
   
   --ILA Attributes
    attribute mark_debug : string;
    attribute MARK_DEBUG of rx_done_tick_s : signal is "TRUE";
    attribute MARK_DEBUG of dout_o_s : signal is "TRUE";

--COMPONENT UART_RX
component uart_rx is
		--GENERIC
			generic (
			g_clkfreq		: integer := 10_000_000;
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


--COMPONENT VIO
component rst_vio
  port (
    clk : in std_logic;
    probe_out0 : out std_logic_vector(0 DOWNTO 0) 
  );
end component;



begin

    --UART_RX
    i_uart_rx : uart_rx
    generic map (
    g_clkfreq => g_clkfreq,
    g_baudrate => g_baudrate		
    )
    port map (
    clk				=> clk,
    dout_o			=> dout_o_s,
    rx_reset_i      => rst_s,
    rx_i			=> rx_i,
    rx_done_tick_o	=> rx_done_tick_s
    );
    
    --VIO
    Vio : rst_vio
    port map (
        clk => clk,
        probe_out0 => rx_probe_rst
              );

    rx_data_valid_o <= rx_done_tick_s;
    dout_o <= dout_o_s;
    process (clk) begin
        if(rising_edge(clk)) then
            if (rx_rst_i = '1') then
                rst_s <= rx_rst_i;
            else
                
                rst_s <= rx_probe_rst(0);
            end if;
        
        
        end if;
    end process;
          
end Behavioral;
