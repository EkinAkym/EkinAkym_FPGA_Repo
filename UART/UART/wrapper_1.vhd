-- INFO
-- Project : UART
-- Module: Wrapper_TX
-- Designer : Ekin Akyýldýrým
-- Supervisor and Mentor: Göktuð Saray


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity wrapper_tx is
generic (
            g_clkfreq		: integer := 100_000_000;
			g_baudrate		: integer := 115_200;
			g_stopbit		: integer := 2;
			g_autodatagen   : string:= "YES"  -- YES OR NO
		);
port (  
            clk : in std_logic;
            tx_o : out std_logic;
            tx_rst_i : in std_logic;
            din_i    : in std_logic_vector (7  downto 0);
            tx_start_i : in std_logic;
            tx_done_tick_o: out std_logic;
            tx_ready_o    : out std_logic
      );
		


end wrapper_tx;

architecture Behavioral of wrapper_tx is
    
    --CONSTANTS
    constant delay_cnt_c : integer := (g_clkfreq) / 10000;

    --STATE DEFN
    type fsm_t is (send_st, wait_st, delay_st);
    signal fsm_s : fsm_t;
    
    --SIGNALS
    signal din_s : std_logic_vector(7 downto 0);
    signal tx_start_s : std_logic;
    signal tx_done_tick_s : std_logic;	
    signal tx_probe_rst :  std_logic_vector(0 DOWNTO 0) ;    
    signal rst_s : std_logic;   
    signal delay_counter_s : integer;
    signal tx_done_tick_d1_s : std_logic;

--COMPONENT UART_TX
component uart_tx is
		--GENERIC
			generic (
			g_clkfreq		: integer := 10_000_000;
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
			tx_done_tick_o	: out std_logic;
			tx_ready_o      : out std_logic
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

     --UART_TX
    i_uart_tx : uart_tx
    generic map (
    g_clkfreq => g_clkfreq,
    g_baudrate => g_baudrate,		
    g_stopbit => g_stopbit
    )
    port map (
    clk				=> clk,
    din_i			=> din_s,
    tx_start_i		=> tx_start_s,
    tx_reset_i      => rst_s,
    tx_o			=> tx_o,
    tx_done_tick_o	=> tx_done_tick_s,
    tx_ready_o      => tx_ready_o
    );

    --VIO
    Vio : rst_vio
    port map (
        clk => clk,
        probe_out0 => tx_probe_rst
              );
    
    --rst_s <= probe_out0(0);
 
 
--OTO INPUT PROCESS         
process (clk) begin        
        if(rising_edge(clk)) then         
            
            if (tx_rst_i = '1') then
                rst_s <= tx_rst_i;                       
            else
                rst_s <= tx_probe_rst(0);              
            end if;                                     
            
            if(rst_s = '1') then
                
                if (g_autodatagen = "NO") then
                    din_s <= (others => '0');
                    tx_done_tick_d1_s <= '0';
                    tx_start_s <= '0';
                else                         
                    din_s <= (others => '0');
                    tx_start_s <= '0';
                    delay_counter_s <= 0;                       
                    tx_done_tick_d1_s <= '0';                        
                    fsm_s <= send_st;
                end if;
                
            else
                if (g_autodatagen = "NO") then
                    din_s <= din_i;
                    tx_done_tick_d1_s <= '0';
                    tx_start_s <= tx_start_i;
                    tx_done_tick_o <= tx_done_tick_s;
                     
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
        end if;   
    end process;
end Behavioral;
