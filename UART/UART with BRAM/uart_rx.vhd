--INFO
-- Project : UART with BRAM
-- Module: uart_rx

-- """"""
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity uart_rx is
		--GENERIC
			generic (
			g_clkfreq		: integer := 100_000_000;
			g_baudrate		: integer := 115_200
			);
		--PORTS	
			port (
			clk				: in std_logic;
			rx_i				: in std_logic;
			rx_reset_i		: in std_logic;
			dout_o			: out std_logic_vector (7 downto 0);
			rx_done_tick_o	: out std_logic
		    );
end uart_rx;

architecture Behavioral of uart_rx is
	
	--CONSTANTS
	constant c_bittimerlim 	: integer := g_clkfreq/g_baudrate;
	
	--STATE DEFINITION
	type states is (s_idle, s_start, s_data_process, s_stop);
	signal state : states := s_idle;
	
	--SIGNALS
	signal bittimer : integer range 0 to c_bittimerlim*3/2 := 0;
	signal bitcntr	: integer range 0 to 7 := 0;
	signal data_reg	: std_logic_vector (7 downto 0) := (others => '0');

begin

p_rx : process (clk) begin
	if (rising_edge(clk)) then
		
		--RESET
		if (rx_reset_i = '1') then
		dout_o <= x"00";
		rx_done_tick_o <= '0';
		else

			case state is
				
				--IDLE
				when s_idle =>
			
					rx_done_tick_o	<= '0';
					bittimer		<= 0;
			
					if (rx_i = '0') then
						state	<= s_start;
					end if;
				
				--START
				when s_start =>
		
					if (bittimer = c_bittimerlim/2-1) then
						state		<= s_data_process;
						bittimer	<= 0;
					else
						bittimer	<= bittimer + 1;
					end if;
				
				--DATA PROCESS
				when s_data_process =>
		
					if (bittimer = c_bittimerlim-1) then
						if (bitcntr = 7) then
							state	<= s_stop;
							bitcntr	<= 0;
						else
							bitcntr	<= bitcntr + 1;
						end if;
						data_reg(bitcntr)		<= rx_i;
						bittimer	<= 0;
					else
						bittimer	<= bittimer + 1;
					end if;
				
				--STOP
				when s_stop =>
		
					if (bittimer = c_bittimerlim-1) then
						state			<= s_idle;
						bittimer		<= 0;
						rx_done_tick_o	<= '1';
					else
						bittimer	<= bittimer + 1;
					end if;			
	
			end case;
			dout_o	<= data_reg;
		end if;
	end if;
end process p_rx;
end Behavioral;