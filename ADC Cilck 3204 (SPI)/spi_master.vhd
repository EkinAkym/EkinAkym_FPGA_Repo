--INFO
-- Project : SPI MASTER
-- Module: spi_master
-- Designer : Ekin Akyildirim
-- Supervisor and Mentor: Goktug Saray

-- BOARD
--Zed Board

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity spi_master is
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
end spi_master;

architecture Behavioral of spi_master is
        
        --CONSTANTS
        constant c_edgecntrlimdiv2	: integer := g_clkfreq/(g_sclkfreq*2);
        constant c_delaycntrlim         : integer := 50;
               
        --REGISTER SIGNALS
        signal write_reg_s : std_logic_vector ( 7 downto 0);
        signal read_reg_s : std_logic_vector ( 7 downto 0);
               
        -- ENABLE SIGNALS
        signal mosi_en_s : std_logic;
        signal miso_en_s : std_logic;      
        signal pol_phase	: std_logic_vector (1 downto 0) := (others => '0');
               
        --SCLK SIGNLAS
        signal sclk_fall_s : std_logic;
        signal sclk_rise_s : std_logic;
        signal sclk_prev_s   : std_logic;
        signal sclk_s        : std_logic;
        signal sclk_en_s     : std_logic;
               
        --COUNTER SIGNALS
        signal cntr_s : integer range 0 to 15:= 0;
        signal once_s : std_logic:= '0';
        signal edgecntr_s		: integer range 0 to c_edgecntrlimdiv2 := 0;
        signal delaycntr_s      : integer range 0 to c_delaycntrlim := 0;
      
        -- STATE DEFINITIONS
        type states is (s_idle, s_transfer, s_delay);
        signal state : states := s_idle;
        

begin
        pol_phase <= g_cpol & g_cpha;
        
    --SAMPLE PROCESS              
    sample_p : process (pol_phase, sclk_fall_s, sclk_rise_s)  begin
       
        case pol_phase is
 
		when "00" =>
 
			mosi_en_s <= sclk_fall_s;
			miso_en_s	<= sclk_rise_s;
 
		when "01" =>
 
			mosi_en_s <= sclk_rise_s;
			miso_en_s	<= sclk_fall_s;		
 
		when "10" =>
 
			mosi_en_s <= sclk_rise_s;
			miso_en_s	<= sclk_fall_s;			
 
		when "11" =>
 
			mosi_en_s <= sclk_fall_s;
			miso_en_s	<= sclk_rise_s;	
 
		when others =>
    
	end case;
	
    end process;
    
    --RISE AND FALL DETECTION PROCESS
    risefalldetect_p : process (sclk_s, sclk_prev_s) begin
        if (sclk_s = '1' and sclk_prev_s = '0') then
            sclk_rise_s <= '1';
        else
            sclk_rise_s <= '0';
        end if;
        if (sclk_s = '0' and sclk_prev_s = '1') then
            sclk_fall_s <= '1';
        else
            sclk_fall_s <= '0';
        end if;   
     end process; 
     
     
     --MAIN PROCESS
     main_p : process(clk) begin
        if (rising_edge(clk)) then
           
            data_ready_o <= '0';
            sclk_prev_s <= sclk_s;            
            
            case state is
                
                when s_idle =>
                    
                    cs_o <= '1';
                    delaycntr_s <= 0;
                    mosi_o <= '0';
                    data_ready_o <= '0';
                    sclk_en_s<= '0';
                    cntr_s    <= 0;
                    
                    if (en_i = '1') then
                        state <= s_delay;
                        cs_o <= '0';                
                    end if;  
               
                when s_delay =>  
                    
                    if (g_cpha = '0') then
                        
                        mosi_o      <= mosi_data_i(7);
                        read_reg_s  <= x"00";
                        
                        if(delaycntr_s = c_delaycntrlim) then
                            state <= s_transfer;
                            sclk_en_s <= '1';
                            write_reg_s <= mosi_data_i;
                        else
                            delaycntr_s <= delaycntr_s +1;
                        end if;
                   
                    else
                       
                        if(delaycntr_s = c_delaycntrlim) then
                            state <= s_transfer;
                            sclk_en_s <= '1';
                            write_reg_s <= mosi_data_i;
                        else
                            delaycntr_s <= delaycntr_s +1;
                        end if;
                   
                    end if;                            
                
                when s_transfer =>                   
                                       
                    write_reg_s <= mosi_data_i;
                           
                    if (g_cpha = '1') then
                        if (mosi_en_s = '1') then                          
                            mosi_o <= write_reg_s(7);
                        end if;
                    end if;
                                         
                    if(cntr_s = 0) then    
               
                        if (miso_en_s = '1') then
                            read_reg_s(7-cntr_s)	<= miso_i;   
					     once_s                  <= '1';  
					     cntr_s <= cntr_s + 1;                         
                        end if;
                        
                        if (mosi_en_s = '1') then
                            mosi_o <= write_reg_s(7-cntr_s);
                            
                        end if;
                    
                    elsif (cntr_s = 8) then
                                 
                        if (once_s = '1') then
                           data_ready_o    <= '1';
                           once_s            <= '0';                       
                        end if;  
                   
                        miso_data_o		<= read_reg_s;
                 
						      if (mosi_en_s = '1') then
						              
						          if (en_i ='1') then
						              cntr_s <= 0;
						              state <= S_DELAY;          
						          else 
						              sclk_en_s <= '0';
						              state	<= S_IDLE;
						              cs_o	<= '1';					                  
						          end if;
			                  end if;		
			                  				    
                     else
                             
                        if ( miso_en_s = '1') then
                            read_reg_s(7-cntr_s) <= miso_i;
                            cntr_s <= cntr_s +1;
                        end if;
                        if (mosi_en_s =  '1') then
                            mosi_o  <= write_reg_s(7-cntr_s);
                                                  
                        end if;              
                    end if;
            end case;     
        end if;
     end process;


--SCLK PROCESS     
sclk_gen_p : process (clk) begin
if (rising_edge(clk)) then
 
	if (sclk_en_s = '1') then
		if edgecntr_s = c_edgecntrlimdiv2-1 then
			sclk_s 		<= not sclk_s;
			sclk_o      <= not sclk_s;
			edgecntr_s	<= 0;
		else
			edgecntr_s	<= edgecntr_s + 1;
		end if;	
	else
		edgecntr_s	<= 0;
		if (g_cpol = '0') then
			sclk_s	<= '0';
			sclk_o <= '0';
		else
			sclk_s	<= '1';
			sclk_o  <='1';
			
		end if;
	end if;
 
end if;
end process sclk_gen_p;
 
end Behavioral;



