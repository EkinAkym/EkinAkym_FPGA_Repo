--INFO
-- Project : ADC Click 3204 (SPI)
-- Module: top
-- Designer : Ekin Akyildirim
-- Supervisor and Mentor: Goktug Saray

-- ILA SETTINGS
-- ILA is used to observe and analyze miso_i, mosi_o, cs_o and sclk_o  signals in the FPGA design.

-- BOARD
--Zed Board



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity top is
    generic (
        g_clkfreq       : integer := 100_000_000;
        g_sclkfreq      : integer := 1_000_000 ;
        g_readfreq      : integer := 1000;       
		g_baudrate		: integer := 115_200;
		g_stopbit		: integer := 2;
        g_cpha          : std_logic := '0';
        g_cpol          : std_logic := '0'
        );
    port (
        clk     : in std_logic;
        rx_i    : in std_logic;
        miso_i  : in  std_logic;
        cs_o    : out std_logic;
        mosi_o  : out std_logic;
        sclk_o  : out std_logic;
        tx_o    : out std_logic
        --output_data_ready_o: out std_logic
               
         );
        
end top;
  

architecture Behavioral of top is
 
 -- COUNTERS AND TRIGGERS
signal rx_cntr_s : integer range 0 to 2 := 0;
signal tx_cntr_s : integer range 0 to 3 := 0;
signal rx_ready_s : std_logic; 
signal tx_sent_trig_s   : std_logic;
signal input_data_ready_s : std_logic;
 
 --ADC SIGNALS   
signal d2d1d0_s     : std_logic_vector (2 downto 0);
signal sgl_diff_s   : std_logic;
signal tx_buffer_s       : std_logic_vector (23 downto 0);
signal ready_s      : std_logic;
signal data_ready_s : std_logic;

-- UART TX SIGNALS
signal tx_start_s       : std_logic;
signal tx_datavalid_s   : std_logic;
signal tx_din_s         : std_logic_vector ( 7 downto 0);
signal tx_reset_s       : std_logic;
signal tx_din_s_1       : std_logic_vector ( 7 downto 0);

-- UART RX SIGNALS
signal rx_datavalid_s   : std_logic;
signal rx_dout_s        : std_logic_vector ( 7 downto 0);
signal rx_reset_s       : std_logic;


attribute MARK_DEBUG : string;
attribute MARK_DEBUG of miso_i: signal is "TRUE";
attribute MARK_DEBUG of mosi_o: signal is "TRUE";
attribute MARK_DEBUG of cs_o: signal is "TRUE";
attribute MARK_DEBUG of sclk_o: signal is "TRUE";

				
				

    component adc is    
        generic (
            g_clkfreq       : integer := 100_000_000;
            g_sclkfreq      : integer := 1_000_000 ;
            g_cpol          : std_logic := '0';
            g_cpha          : std_logic := '0';
            g_readfreq	    : integer := 100
            );
        port (
            clk           : in std_logic;
            d2d1d0        : in std_logic_vector (2 downto 0);
            sgl_diff      : in std_logic;
            cs_o          : out std_logic;
            miso_i        : in std_logic;
            input_data_ready_i : in std_logic;
            sclk_o        : out std_logic;
            ready_o       : out std_logic;
            data_ready_o   : out std_logic;
            mosi_o        : out std_logic;
            dout_o        : out std_logic_vector (23 downto 0)
            
            );
    end component;

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
   
    component uart_rx is
		--GENERIC
			generic (
			g_clkfreq		: integer := 100_000_000;
			g_baudrate		: integer := 115_200
			);
		--PORTS	
			port (
			clk				: in std_logic;
			rx_i		    : in std_logic;
			rx_reset_i		: in std_logic;
			dout_o			: out std_logic_vector (7 downto 0);
			rx_done_tick_o	: out std_logic
		    );
    end component;


begin

i_adc : adc
    generic map (                                              
        g_clkfreq      => g_clkfreq ,  
        g_sclkfreq     => g_sclkfreq , 
        g_cpol         => g_cpol     , 
        g_cpha         => g_cpha     , 
        g_readfreq	   => g_readfreq	 
        )                                                
    port map (                                                 
        clk           =>    clk             ,
        d2d1d0        =>    d2d1d0_s          ,
        sgl_diff      =>    sgl_diff_s        ,
        cs_o          =>    cs_o            ,
        miso_i        =>    miso_i          ,
        sclk_o        =>    sclk_o          ,
        input_data_ready_i => input_data_ready_s,
        ready_o       =>    ready_s         ,
        data_ready_o  =>    data_ready_s    ,
        mosi_o        =>    mosi_o          ,
        dout_o        =>    tx_buffer_s                                                                 
        );         

i_uart_tx : uart_tx  
		--GENERIC
			generic map (
			g_clkfreq		=>    g_clkfreq	,
			g_baudrate		=>    g_baudrate,
			g_stopbit		=>    g_stopbit	
			  )            
		--PORTS             
			port map (          
			clk				=>    clk		          ,    
			din_i			=>    tx_din_s			      ,
			tx_start_i		=>    tx_start_s          ,
			tx_reset_i      =>    tx_reset_s          ,
			tx_o			=>    tx_o			      ,
			tx_done_tick_o	=>    tx_datavalid_s	
			 );
			 
i_uart_rx : uart_rx
          
		--GENERIC MAP
			generic map (
			g_clkfreq		=>    g_clkfreq	,
			g_baudrate		=>    g_baudrate
			)              
		--PORT MAP	        
			port map (     
			clk				=>    clk	        ,		
			rx_i		    =>    rx_i		   ,
			rx_reset_i		=>    rx_reset_s    ,
			dout_o			=>    rx_dout_s         ,
			rx_done_tick_o	=>    rx_datavalid_s      
		    );
		   
process (clk) begin
    if (rising_edge(clk)) then
        --output_data_ready_o <= '0';
        if ( rx_cntr_s = 0) then            
            if ( rx_datavalid_s = '1') then
                input_data_ready_s <= '0';
                rx_cntr_s <= rx_cntr_s +1;  
                d2d1d0_s <= rx_dout_s(6 downto 4);
                sgl_diff_s  <= rx_dout_s(7);    
            end if;
        
        elsif ( rx_cntr_s = 1) then
            --if (rx_datavalid_s = '1') then
                rx_cntr_s <= 0;
                input_data_ready_s <= '1';             
            --end if;  
       
        
        end if;
        
        if (ready_s = '1') then
            tx_sent_trig_s <= '1';
            tx_cntr_s      <= 2;
            --tx_din_s <= tx_buffer_s((1*8)-1 downto (0)*8);
        end if;
        
            
            
            if (tx_sent_trig_s = '1') then
                    tx_start_s <= '1';
                if (tx_cntr_s = 2) then
                  
                    tx_din_s <= tx_buffer_s((2*8)-1 downto (1)*8);
                    tx_cntr_s <= tx_cntr_s -1;
                    tx_start_s <= '1';
                
                elsif ( tx_cntr_s = 0) then
                    tx_start_s <= '0';    
                    if( tx_datavalid_s = '1') then
                        tx_sent_trig_s <= '0'; 
                        --output_data_ready_o <= '1';    
                    end if;
                
                else 
                    tx_din_s <= tx_buffer_s((1*8)-1 downto (0)*8);
                    if ( tx_datavalid_s = '1') then                                      
                        tx_cntr_s <= tx_cntr_s -1 ;  
                        tx_start_s <= '1';
                         
                    end if;                     
                end if;
            end if;       
    end if;
end process;
end Behavioral;
