--==================================================================================--

-- 	Module Name : 	KNN_TOP.vhd
-- 	Project	   	: 	KNN Implementation (AI Chip Design: Liquid Identification)
-- 	Author	   	: 	Ekin AKYILDIRIM
-- 	Change Log	:	10.12.2024 | Ekin Akyildirim | v0.2
--	Description	:

--==================================================================================--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity KNN_TOP is
	generic(
		g_clkfreq	     : integer := 100_000_000;
		g_baudrate	     : integer := 115_200;
		g_stopbit	     : integer := 2;
		g_data_width	 : integer := 16;
		g_depth          : integer := 128;
		g_addr_width     : integer := 8
		);
	
	port(
		clk		: in  std_logic;
		reset   : in  std_logic;
		rx		: in  std_logic;
		tx		: out std_logic
		);

end KNN_TOP;

architecture Behavioral of KNN_TOP is

-----------------COMPONENTS-------------------
component Memory
	generic (
		DATA_WIDTH		: integer	:= 16;
		ADDR_WIDTH		: integer 	:= 8;
		DEPTH			: integer 	:= 128
	);
	port(
		clk			 	: in  std_logic;
		write_enable 	: in  std_logic;
		read_enable	 	: in  std_logic;
		addr 		 	: in  std_logic_vector (g_addr_width - 1 downto 0);
		data_in		 	: in  std_logic_vector (g_data_width - 1 downto 0);
		data_out	 	: out std_logic_vector (g_data_width - 1 downto 0)
	);
end component;
	
component uart_tx
	generic (
		g_clkfreq		: integer := 100_000_000;
		g_baudrate		: integer := 115_200;
		g_stopbit		: integer := 2
	);
	
	port (
		clk				: in  std_logic;
		din_i			: in  std_logic_vector (7 downto 0);
		tx_start_i		: in  std_logic;
		tx_reset_i 		: in  std_logic;
		tx_o			: out std_logic;
		tx_done_tick_o	: out std_logic 
		
	);
end component;

component uart_rx
	generic(
		g_clkfreq		: integer := 100_000_000;
		g_baudrate		: integer := 115_200
	);
	port(
		clk				: in  std_logic;
		rx_i		    : in  std_logic;
		rx_reset_i		: in  std_logic;
		rx_done_tick_o	: out std_logic;
		dout_o			: out std_Logic_vector (7 downto 0)
	);
end component;

component KNN
	generic(
		g_data_width 	: integer := 32;
		g_addr_width 	: integer := 8;
		g_depth		 	: integer := 64
	);
	port (
		reset		   	: in  std_logic;
        clk            	: in  std_logic;
        en             	: in  std_logic;
		predict_valid  	: out std_logic;		
        ref_data_diff  	: in  std_logic_vector ((g_data_width/2)-1 downto 0);
        ref_data_ppm   	: in  std_logic_vector ((g_data_width/2)-1 downto 0);
        test_data_diff 	: in  std_logic_vector ((g_data_width/2)-1 downto 0);
        test_data_ppm  	: in  std_logic_vector ((g_data_width/2)-1 downto 0);
        result         	: out std_logic_vector (7 downto 0)
    );
end component;

-------- SIGNALS --------

-- UART_TX SIGNALS --
	signal tx_start_s 	   : std_logic;
	signal tx_data_valid_s : std_logic;
	signal tx_din_s		   : std_logic_vector(7 downto 0);

-- UART_RX SIGNALS --
	signal rx_data_valid_s : std_logic;
	signal rx_dout_s	   : std_logic_vector (7 downto 0);
	
-- DATA MEMORY SIGNALS --
	signal wen_s		   : std_logic;
	signal rden_s		   : std_logic;
	signal addr_s		   : std_logic_vector ( 7 downto 0);
	signal memory_din_s    : std_logic_vector (15 downto 0);
	signal memory_dout_s   : std_logic_vector (15 downto 0);
	
-- KNN SIGNALS --
    signal knn_en_s 			: std_logic;
	signal predict_valid_s  	: std_logic;
    signal memory_data_diff_s 	: std_logic_vector	(g_data_width - 1 downto 0);
    signal memory_data_ppm_s 	: std_logic_vector	(g_data_width - 1 downto 0);
    signal test_data_diff_s 	: std_logic_vector 	(g_data_width - 1 downto 0);
    signal test_data_ppm_s  	: std_logic_vector 	(g_data_width - 1 downto 0);
    signal result_s  			: std_logic_vector 	(7 downto 0);
    
-- PROCESS SIGNALS --
    signal address_counter_s  	: integer range 0 to 119 := 0; 
    signal data_write_mode      : integer range 0 to 1 := 0;  
    signal read_delay_counter_s : integer range 0 to 2 := 0;
    signal msb_low             	: std_logic := '0';
    signal data_type            : std_logic := '0';
    signal knn_ready            : std_logic := '0';

-- STATES --
    type states is (s_idle, s_liquid_burst, s_liquid_serial, s_refdata, s_testdata, s_predict);
	signal state : states := s_idle;
					
				
------------------------INST.-----------------------------
begin

	uart_tx_inst : uart_tx 
		generic  map (
			g_clkfreq 		=> g_clkfreq,
			g_baudrate 		=> g_baudrate,
			g_stopbit 		=> g_stopbit
		)
		port map (
			clk			   	=> clk,
			din_i		   	=> tx_din_s,
			tx_start_i     	=> tx_start_s,
			tx_reset_i     	=> reset,
			tx_o 		   	=> tx,
			tx_done_tick_o 	=> tx_data_valid_s
		);
		
	uart_rx_inst : uart_rx 
		generic  map (
			g_clkfreq 		=> g_clkfreq,
			g_baudrate 		=> g_baudrate
			
		)
		port map (
			clk			   	=> clk,
			dout_o		   	=> rx_dout_s,
			rx_reset_i     	=> reset,
			rx_i 		   	=> rx,
			rx_done_tick_o 	=> rx_data_valid_s
		);
			
	data_memory_inst : Memory
        generic map (
            DATA_WIDTH 		=> g_data_width,
            ADDR_WIDTH 		=> g_addr_width,
            DEPTH      		=> g_depth
        )
        port map (
            clk          	=> clk,
            write_enable 	=> wen_s,
            read_enable  	=> rden_s,
            addr         	=> addr_s,
            data_in      	=> memory_din_s,
            data_out     	=> memory_dout_s
        );

    KNN_inst : KNN
		generic map (
			g_data_width 	=> g_data_width*2,
			g_addr_width 	=> g_addr_width,
			g_depth     	=> g_depth/2
		)
		port map (
			clk            	=> clk,
			reset		   	=> reset,
			en             	=> knn_en_s,       
			ref_data_diff  	=> memory_data_diff_s,
			ref_data_ppm   	=> memory_data_ppm_s,
			test_data_diff 	=> test_data_diff_s,
			test_data_ppm 	=> test_data_ppm_s,
			predict_valid  	=> predict_valid_s,
			result         	=> result_s
		);
    

-------------PROCESS-----------------------
	process(clk)
    begin
        if rising_edge(clk) then
            
			if ( reset = '1') then
				tx_din_s <= x"00";
				tx_start_s <= '0';
				address_counter_s <= 0;
				data_type <= '0';
                knn_ready <= '0';
                rden_s <= '0';
				knn_en_s <= '0';		
            else
                
				case state is 
                    
----------------------------------------------------IDLE------------------------------------------V
					
					when s_idle =>
                        tx_start_s <= '0';
                        address_counter_s <= 0;
                       
                        if rx_data_valid_s = '1' and rx_dout_s = x"01" then				--MODE1:BURST
                            tx_start_s <= '1';
                            tx_din_s <= x"01";
                            state <= s_liquid_burst;
                        elsif rx_data_valid_s = '1' and rx_dout_s = x"02" then			--MODE2:SERIAL
                            tx_start_s <= '1';
                            tx_din_s <= x"02";
                            state <= s_liquid_serial;
                        elsif rx_data_valid_s = '1' and rx_dout_s = x"03" then			--MODE3:TEST-PREDICTION
                            state <= s_testdata;
                            tx_din_s <= x"03";
                            tx_start_s <= '1';
                        end if;
						
--------------------------------------LIQUID-BURST-CONFIGURATION------------------------------------V		
					
					when s_liquid_burst  =>    
                        tx_start_s <= '0';
                        data_write_mode <= 0;
                        if rx_data_valid_s = '1' and rx_dout_s = x"01" then				--LIQUID1: EMPTY
                            addr_s <= x"00";
                            tx_start_s <= '1';
                            tx_din_s <= x"00";
                            state <= s_refdata;
                        elsif rx_data_valid_s = '1' and rx_dout_s = x"02" then		    --LIQUID2
                            addr_s <= x"14";
                            tx_start_s <= '1';
                            tx_din_s <= x"01";
                            state <= s_refdata;
                        elsif rx_data_valid_s = '1' and rx_dout_s = x"03" then		    --LIQUID3
                            addr_s <= x"28";
                            tx_start_s <= '1';
                            tx_din_s <= x"02";
                            state <= s_refdata;
                        elsif rx_data_valid_s = '1' and rx_dout_s = x"04" then			--LIQUID4
                            addr_s <= x"3C";
                            tx_start_s <= '1';
                            tx_din_s <= x"03";
                            state <= s_refdata;
                        elsif rx_data_valid_s = '1' and rx_dout_s = x"05" then			--LIQUID5
                            addr_s <= x"50";
                            tx_start_s <= '1';
                            tx_din_s <= x"04";
                            state <= s_refdata;
                        elsif rx_data_valid_s = '1' and rx_dout_s = x"06" then			--LIQUID6
                            addr_s <= x"64";
                            tx_start_s <= '1';
                            tx_din_s <= x"05";
                            state <= s_refdata;
                        end if;  
						
----------------------------------------LIQUID-SERIAL-CONFIGURATION--------------------------------V
                    
                    when s_liquid_serial =>
                        tx_start_s <= '0';
                        data_write_mode <= 1;
                        if rx_data_valid_s = '1' and rx_dout_s = x"5E" then				--APPROVE
                            addr_s <= x"00";
                            tx_start_s <= '1';
                            tx_din_s <= x"5E";
                            state <= s_refdata;
                        end if;
						
-----------------------------------------REFERENCE-DATA-WRITE--------------------------------------V
                          
                    when s_refdata =>
                        tx_start_s <= '0';      
                        if (data_write_mode = 0) then					--! BURST PROCESS
                            if (address_counter_s = 20) then
                                tx_start_s <= '1';
                                tx_din_s <= x"00";
                                state <= s_idle;   
                                wen_s <= '0';
                                rden_s <= '0'; 
                            elsif (address_counter_s = 0) then
                                wen_s <= '0';
                                rden_s <= '0';
                                if rx_data_valid_s = '1' and msb_low = '0' then
                                    memory_din_s(15 downto 8) <= rx_dout_s;
                                    msb_low <= '1';
                                elsif rx_data_valid_s = '1' and msb_low = '1' then
                                    memory_din_s(7 downto 0) <= rx_dout_s;
                                    msb_low <= '0';
                                    wen_s <= '1';
                                    addr_s <= std_logic_vector(unsigned(addr_s));
                                    address_counter_s <= address_counter_s + 1;
                                end if;
                            else										
                                wen_s <= '0';
                                rden_s <= '0';
                                if rx_data_valid_s = '1' and msb_low = '0' then
                                    memory_din_s(15 downto 8) <= rx_dout_s;
                                    msb_low <= '1';
                                elsif rx_data_valid_s = '1' and msb_low = '1' then
                                    memory_din_s(7 downto 0) <= rx_dout_s;
                                    msb_low <= '0';
                                    wen_s <= '1';
                                    addr_s <= std_logic_vector(unsigned(addr_s) + 1);
                                    address_counter_s <= address_counter_s + 1;
                                end if; 
                            end if;
                        elsif (data_write_mode = 1) then				--! SERIAL PROCESS
                            if (address_counter_s = 120) then
                                tx_start_s <= '1';
                                tx_din_s <= x"01";
                                state <= s_idle;  
                                wen_s <= '0';
                                rden_s <= '0';  
                            elsif (address_counter_s = 0) then
                                wen_s <= '0';
                                rden_s <= '0';
                                if rx_data_valid_s = '1' and msb_low = '0' then
                                    memory_din_s(15 downto 8) <= rx_dout_s;
                                    msb_low <= '1';
                                elsif rx_data_valid_s = '1' and msb_low = '1' then
                                    memory_din_s(7 downto 0) <= rx_dout_s;
                                    msb_low <= '0';
                                    wen_s <= '1';
                                    addr_s <= std_logic_vector(unsigned(addr_s));
                                    address_counter_s <= address_counter_s + 1;          
                                end if;
                            else
                                wen_s <= '0';
                                rden_s <= '0';
                                if rx_data_valid_s = '1' and msb_low = '0' then
                                    memory_din_s(15 downto 8) <= rx_dout_s;
                                    msb_low <= '1';
                                elsif rx_data_valid_s = '1' and msb_low = '1' then
                                    memory_din_s(7 downto 0) <= rx_dout_s;
                                    msb_low <= '0';
                                    wen_s <= '1';
                                    addr_s <= std_logic_vector(unsigned(addr_s) + 1);
                                    address_counter_s <= address_counter_s + 1;
                                end if; 
                            end if;       
                        end if;
						
--------------------------------------------TEST-DATA-INPUT------------------------------------------V
                    
                    when s_testdata =>
                        tx_start_s <= '0';
                        if rx_data_valid_s = '1' and msb_low = '0' and data_type = '0' then		--! DIFF
                            test_data_diff_s(15 downto 8) <= rx_dout_s;
                            msb_low <= '1';
                        elsif rx_data_valid_s = '1' and msb_low = '1' and data_type = '0' then
                            test_data_diff_s(7 downto 0) <= rx_dout_s;
                            msb_low <= '0';
                            data_type <= '1';
                        elsif rx_data_valid_s = '1' and msb_low = '0' and data_type = '1' then	 --! PPM
                            test_data_ppm_s(15 downto 8) <= rx_dout_s;
                            msb_low <= '1';
                        elsif rx_data_valid_s = '1' and msb_low = '1' and data_type = '1' then
                            test_data_ppm_s(7 downto 0) <= rx_dout_s;
                            msb_low <= '0';
                            data_type <= '0'; 
                            addr_s <= x"00";
                            state <= s_predict;               
                        end if; 

-----------------------------------------------PREDICTION--------------------------------------------V		
                          
                    when s_predict =>
                        tx_start_s <= '0';
                        if (address_counter_s = 60 ) then  
                            if (predict_valid_s = '1') then
                                tx_din_s <= result_s;
                                tx_start_s <= '1';
                                data_type <= '0';
                                knn_ready <= '0';
                                rden_s <= '0';
                                address_counter_s <= 0;
                                state <= s_idle;
                            end if;    
                        elsif (address_counter_s = 0) then
                             if(knn_ready = '0' and data_type = '0') then
                                knn_en_s <= '0';
                                rden_s <= '1';
                                if ( read_delay_counter_s = 2) then
                                    memory_data_diff_s <= memory_dout_s;                                
                                    data_type <= '1';
                                    read_delay_counter_s <= 0;
                                    addr_s <= std_logic_vector(unsigned(addr_s)+ 1);
                                else
                                    read_delay_counter_s <= read_delay_counter_s +1;
                                end if; 
                            elsif (knn_ready = '0' and data_type = '1') then
                                  
                                  if ( read_delay_counter_s = 2) then
                                    memory_data_ppm_s <= memory_dout_s; 
                                    address_counter_s <= address_counter_s + 1;
                                    knn_ready <= '1';
                                    read_delay_counter_s <= 0;
                                    addr_s <= std_logic_vector(unsigned(addr_s)+ 1);
                                  else
                                    read_delay_counter_s <= read_delay_counter_s +1 ;
                                  end if;           
                            elsif (knn_ready = '1' and data_type = '1') then
                                knn_en_s <= '1';
                                data_type <= '0';
                                knn_ready <= '0';
                           end if;                  
                        else
                            if(knn_ready = '0' and data_type = '0') then
                                knn_en_s <= '0';
                                if (read_delay_counter_s = 2) then
                                    memory_data_diff_s <= memory_dout_s;
                                    data_type <= '1';
                                    read_delay_counter_s <= 0;
                                    addr_s <= std_logic_vector(unsigned(addr_s)+ 1);
                                 else 
                                    read_delay_counter_s <= read_delay_counter_s +1;
                                 end if;
                            elsif (knn_ready = '0' and data_type = '1') then
                                 if (read_delay_counter_s = 2) then
                                    memory_data_ppm_s <= memory_dout_s; 
                                    addr_s <= std_logic_vector(unsigned(addr_s)+1); 
                                    address_counter_s <= address_counter_s + 1;
                                    knn_ready <= '1';
                                 else
                                    read_delay_counter_s <= read_delay_counter_s +1;
                                 end if; 
                            elsif (knn_ready = '1' and data_type = '1') then
                                knn_en_s <= '1';
                                data_type <= '0';
                                knn_ready <= '0';
                            end if;
                        end if;   

----------------------------------------------------------------------------------------------------------		
							
                end case;
            end if;
        end if;
    end process;
end Behavioral;
