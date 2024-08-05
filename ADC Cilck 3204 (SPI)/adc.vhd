--INFO
-- Project : ADC Click 3204 (SPI)
-- Module: adc
-- Designer : Ekin Akyildirim
-- Supervisor and Mentor: Goktug Saray

-- BOARD
--Zed Board


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity adc is    
    generic (
        g_clkfreq       : integer := 100_000_000;
        g_sclkfreq      : integer := 1_000_000 ;
        g_cpol          : std_logic := '0';
        g_cpha          : std_logic := '0';
        g_readfreq	    : integer := 10_000
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
end adc;

architecture Behavioral of adc is

component spi_master is
    generic (
        g_clkfreq       : integer := 100_000_000;
        g_sclkfreq      : integer := 1_000_000 ;
        g_cpol          : std_logic := '0';
        g_cpha          : std_logic := '0'
        );
    port    (
        clk            : in std_logic;
        en_i           : in std_logic;
        mosi_data_i    : in std_logic_vector (7 downto 0);
        miso_data_o    : out std_logic_vector (7 downto 0);
        data_ready_o   : out std_logic;
        cs_o           : out std_logic;
        sclk_o         : out std_logic;
        mosi_o         : out std_logic;       
        miso_i         : in std_logic
        
        );
end component;

constant c_timerlim	: integer := g_clkfreq/g_readfreq;

signal din_s : std_logic_vector ( 23 downto 0) := x"000000";
signal  miso_data_s :  std_logic_vector ( 7 downto 0);
signal  mosi_data_s :  std_logic_vector ( 7 downto 0);
signal  sclk_s      : std_logic;
signal data_ready_s : std_logic;
signal cntr_s   : integer range 0 to 3;
signal en_s      : std_logic;

signal begin_process :std_logic := '0';


signal timer_s			: integer range 0 to c_timerlim := 0;
signal timer_valid_s	: std_logic := '0';

begin

    spi_master_i : spi_master
    generic map(
    	g_clkfreq 		=> g_clkfreq 	 ,
    	g_sclkfreq 		=> g_sclkfreq 	 ,
    	g_cpol			=> g_cpol		 ,
    	g_cpha			=> g_cpha		
    )
    Port map( 
    	clk 			=> clk		 ,
    	en_i 			=> en_s 		     ,
    	mosi_data_i 	=> mosi_data_s     ,
    	miso_data_o 	=> miso_data_s     ,
    	data_ready_o 	=> data_ready_s   ,
    	cs_o 			=> cs_o 		 ,
    	sclk_o 			=> sclk_o 		 ,
    	mosi_o 			=> mosi_o 		 ,
    	miso_i 			=> miso_i 	      
    		
    );

data_ready_o <= data_ready_s;
p_main: process (clk) begin
        if (rising_edge(clk)) then
           ready_o <= '0';
           din_s (18) <= '1';
           din_s( 16 downto 14) <= d2d1d0;
           din_s (17) <= sgl_diff;
           
            if (timer_valid_s = '1' and input_data_ready_i = '1') then
                begin_process <= '1';
            end if;
                                         
            if (begin_process = '1') then
                if (cntr_s = 0) then
                    
                    en_s <= '1';
                    mosi_data_s <= din_s (23 downto 16);     
                    cntr_s <= cntr_s +1;                    
                
                elsif ( cntr_s = 1) then
                    
                    if (data_ready_s = '1') then
                        mosi_data_s <= din_s (15 downto 8);
                        dout_o(23 downto 16)  <= miso_data_s;
                        cntr_s <=  cntr_s +1;
                    end if;
                    
                elsif ( cntr_s = 2) then
                    
                    if (data_ready_s = '1') then
                        mosi_data_s <= din_s ( 7 downto 0);
                        dout_o(15 downto 8)  <= miso_data_s;
                        cntr_s <= cntr_s +1;
                     end if;
           
                elsif ( cntr_s = 3) then
                   
                    if(data_ready_s = '1') then
                        dout_o(7 downto 0) <= miso_data_s; 
                        cntr_s <= 0;
                        en_s   <= '0';
                        ready_o <= '1';  
                        begin_process <= '0'; 
                    end if; 
                end if;                   
            end if; 
        end if;
    end process p_main;
    
    p_timer : process (clk) begin
if (rising_edge(clk)) then

	if (timer_s = c_timerlim-1) then
		timer_s 		<= 0;
		timer_valid_s	<= '1';
	else
		timer_s 		<= timer_s + 1;
		timer_valid_s	<= '0';
	end if;

end if;
end process p_timer;

end Behavioral;



