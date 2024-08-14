--INFO
-- Project : ADXL345 (I2C)
-- Module: adx345
-- Designer : Ekin Akyildirim
-- Supervisor and Mentor: Goktug Saray

-- ILA SETTINGS
-- ILA is used to observe signals in the FPGA design.

-- BOARD
--Zed Board

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.std_logic_unsigned.all;


entity adxl345 is
      Generic (
	    g_clkfreq		: integer := 100_000_000;
	    g_bus_clk	    : integer := 400_000;
	    g_device_addr	: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1010011";
	    g_readfreq	    : integer := 10
	    
        );
      Port (
        ax_o 		: out STD_LOGIC_VECTOR (15 downto 0);
        ay_o 		: out STD_LOGIC_VECTOR (15 downto 0);
        az_o 		: out STD_LOGIC_VECTOR (15 downto 0);
        clk 		: in STD_LOGIC;
	    rst_i 		: in STD_LOGIC;
	    scl_io 		: inout STD_LOGIC;
	    sda_io 		: inout STD_LOGIC;
	    int_o 	    : out STD_LOGIC
       );
end adxl345;

architecture Behavioral of adxl345 is

    component i2c_master IS
      generic(
        input_clk : INTEGER := 25_000_000; --input clock speed from user logic in Hz
        bus_clk   : INTEGER := 400_000);   --speed the i2c bus (scl) will run at in Hz
      port(
        clk       : IN     STD_LOGIC;                    --system clock
        reset_n   : IN     STD_LOGIC;                    --active low reset
        ena       : IN     STD_LOGIC;                    --latch in command
        addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
        rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
        data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
        busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
        data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
        ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
        sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
        scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
    end component;

-- SIGNALS AND CONSTANTS --
constant c_timerlim	: integer := g_clkfreq/g_readfreq;

signal timer_s			: integer range 0 to c_timerlim := 0;
signal timer_valid_s	: std_logic := '0';
signal begin_process    : std_logic := '0';

-- i2c_master signals
signal en_s			: std_logic := '0';
signal rw_s       	: std_logic := '0';
signal data_wr_s  	: std_logic_vector (7 downto 0) := (others => '0');
signal busy_s     	: std_logic := '0';
signal busyPrev_s     : std_logic := '0';
signal busyCntr_s		: integer range 0 to 255 := 0;
signal data_rd_s  	: std_logic_vector (7 downto 0) := (others => '0');
signal ack_error_s	: std_logic := '0';  
signal enable_s	: std_logic := '0';
signal waitEn_s	: std_logic := '0';
signal cntr_s		: integer range 0 to 255 := 0;

--DEBUG SIGNAL
signal debug_point_1 : std_logic_vector ( 2 downto 0) := "000";


--ILA 
attribute MARK_DEBUG : string;
attribute MARK_DEBUG of ack_error_s: signal is "TRUE";
attribute MARK_DEBUG of busyCntr_s: signal is "TRUE";
attribute MARK_DEBUG of int_o: signal is "TRUE";
attribute MARK_DEBUG of en_s: signal is "TRUE";
attribute MARK_DEBUG of debug_point_1: signal is "TRUE";
attribute MARK_DEBUG of rw_s: signal is "TRUE";
attribute MARK_DEBUG of clk: signal is "TRUE";
attribute MARK_DEBUG of busy_s: signal is "TRUE";
attribute MARK_DEBUG of busyprev_s: signal is "TRUE";
attribute MARK_DEBUG of data_rd_s: signal is "TRUE";
attribute MARK_DEBUG of data_wr_s: signal is "TRUE";
attribute MARK_DEBUG of timer_valid_s: signal is "TRUE";

--State Definition
type states is (s_pwrctl,s_measurectl, s_measure);
signal state : states := s_pwrctl;

--state ILA
attribute MARK_DEBUG of state: signal is "TRUE";

begin

    i2c_master_inst	: i2c_master 
    GENERIC MAP (
    input_clk	=> g_clkfreq,
    bus_clk  	=> g_bus_clk
    )
    PORT MAP (
    clk      	=> clk,
    reset_n  	=> rst_i,
    ena      	=> en_s,
    addr     	=> g_device_addr,
    rw       	=> rw_s,
    data_wr     => data_wr_s,
    busy        => busy_s,
    data_rd     => data_rd_s,
    ack_error   => ack_error_s,
    sda         => sda_io,
    scl         => scl_io
    );
    
    
p_main : process (clk)
begin
    if (rising_edge(clk)) then
        case(state) is
            --PWR CONTROL
            when s_pwrctl =>	       
               if ( rst_i = '0') then  
               busycntr_s <= 0;
               en_s <= '0';
               state <= s_pwrctl;
               else   
                    busyPrev_s	<= busy_s;
			
			        if (busyPrev_s = '0' and busy_s = '1') then
				        busyCntr_s <= busyCntr_s + 1;
			        end if;	
			         
			         int_o <= '0';
			        
			        if ( busyCntr_s = 0) then
			             en_s <= '1';
			             rw_s <= '0';
			             data_wr_s <= x"2D";
			        elsif ( busyCntr_s = 1) then
			             data_wr_s <= x"08";
			             rw_s <= '0';			             
			        elsif ( busyCntr_s = 2) then
			             en_s <= '0';
			             if ( busy_s = '0') then			                
			                 busycntr_s <= 0;		
			                 state <= s_measurectl;	             
			             end if;
			        end if;
			        
			    
			       
             end if;
             -- register control 
            when s_measurectl =>
                int_o <= '0';
                if (timer_valid_s = '1') then
                    begin_process <= '1';
                end if; 
                
                --wait to change state
			 	   if (waitEn_s = '1') then
			 	       if (cntr_s = 255) then
			 	           state		    <= s_measure;
			 	           cntr_s		    <= 0;
			 	    	   waitEn_s		<= '0';
				       else
				           cntr_s 	<= cntr_s + 1;
				       end if;
			       end if;
                
                
                if ( begin_process = '1') then    
                    busyPrev_s	<= busy_s;
                
                    if (busyPrev_s = '0' and busy_s = '1') then
				        busyCntr_s<= busyCntr_s + 1;
			        end if;	
			    
			        if (busyCntr_s = 0) then		
				        en_s 	<= '1';
				        rw_s		<= '0';		-- write  
				        data_wr_s	<= x"32";
			     	elsif (busyCntr_s = 1) then
			     		en_s 	<= '0';
			     		if (busy_s = '0') then
			     			waitEn_s		<= '1';
			     			busyCntr_s	<= 0;				
			      			begin_process <= '0';
			      		end if;						
			      	end if;	
			 	
			 	
			    end if;    
            when s_measure =>
            
                 busyPrev_s	<= busy_s;
                 if (busyPrev_s = '0' and busy_s = '1') then
                 	busyCntr_s <= busyCntr_s + 1;
                 end if;		
            
                 if (busyCntr_s = 0) then		
                 	en_s 	<= '1';
                 	rw_s		<= '1';		
                 	data_wr_s	<= x"32";	
                
                 elsif (busyCntr_s = 1) then	
                 	if (busy_s = '0') then
                 		ax_o(7 downto 0)	<= data_rd_s;
                 	end if;						         	
                 	rw_s 		<= '1';	
                 			        
                
                 elsif (busyCntr_s = 2) then		
                    		         	
                 	if (busy_s = '0') then
                 		ax_o(15 downto 8)	<= data_rd_s;
                 		
                 	end if;			         	
                 	rw_s 		<= '1';
                 
                 elsif (busyCntr_s = 3) then
                     if (busy_s = '0') then
                         ay_o(7 downto 0) <= data_rd_s;
                     end if;
                     rw_s 		<= '1';
                 elsif ( busycntr_s = 4) then
                     if ( busy_s = '0') then
                         ay_o(15 downto 8) <= data_rd_s;
                     end if;
                     rw_s <= '1';
              
                 elsif (busycntr_s = 5) then
                     if ( busy_s = '0') then
                         az_o(7 downto 0) <= data_rd_s;
                     end if;
                     rw_s <= '1';
                
                 elsif ( busycntr_s = 6) then
                     en_s <= '0';
                     if ( busy_s = '0') then
                         az_o(15 downto 8) <= data_rd_s;
                         begin_process <= '0'; 
                         state <= s_measurectl;                      
                         busycntr_s <= 0;
                         int_o <= '1';
                     end if;                          
                 end if;					
        end case;
    end if;
end process;

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
