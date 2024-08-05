--INFO
-- Project : UART with BRAM
-- Module: uart_rx

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_tx is
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
			tx_reset_i : in std_logic;
			tx_o			: out std_logic;
			tx_done_tick_o	: out std_logic 
			--tx_ready_o      : out std_logic
			 );
end uart_tx;

architecture Behavioral of uart_tx is
	
	--CONSTANTS
	constant c_bittimerlim 	: integer := g_clkfreq/g_baudrate;
	constant c_stopbitlim 	: integer := (g_clkfreq/g_baudrate)*g_stopbit;
	
	--STATE DEFINITION
	type states is (s_idle, s_start, s_data_process, s_stop);
	signal state : states := s_idle;
	
	--SIGNALS
	signal bittimer : integer range 0 to c_stopbitlim := 0;
	signal bitcntr	: integer range 0 to 8 := 0;
	signal data_reg	: std_logic_vector (7 downto 0) := (others => '0');


begin

p_tx : process (clk) begin
	if (rising_edge(clk)) then
		
		--RESET 
		if (tx_reset_i = '1') then 
				tx_o <= '1';
				tx_done_tick_o <= '0'; 
		else
			case state is
				
				--IDLE
				when s_idle =>
		
					tx_o			<= '1';
					tx_done_tick_o	<= '0';
					bitcntr			<= 0;
			
						if (tx_start_i = '1') then
							state	<= s_start;
							tx_o	<= '0';
							data_reg	<= din_i;
						end if;
				
				--START
				when s_start =>		
			
					if (bittimer = c_bittimerlim-1) then
						state				<= s_data_process;
						tx_o				<= data_reg(bitcntr);				
						bittimer			<= 0;
						bitcntr        <= bitcntr +1;
					else
						bittimer			<= bittimer + 1;
					end if;
				--DATA PROCESS
				when s_data_process =>
					
					-- if (bitcntr = 7) then
					if (bitcntr = 8) then
						if (bittimer = c_bittimerlim-1) then					
							bitcntr				<= 0;
							state				<= s_stop;
							tx_o				<= '1';
							bittimer			<= 0;
						else
							bittimer			<= bittimer + 1;					
						end if;			
					else
						if (bittimer = c_bittimerlim-1) then										
							tx_o				<= data_reg(bitcntr);
							bitcntr				<= bitcntr + 1;
							bittimer			<= 0;
						else
							bittimer			<= bittimer + 1;					
						end if;
					end if;
				
				--STOP
				when s_stop =>
		
					if (bittimer = c_stopbitlim-1) then
						state				<= s_idle;
						tx_done_tick_o		<= '1';
						bittimer			<= 0;
					else
						bittimer			<= bittimer + 1;				
					end if;		
	
			end case;
		end if;
	end if;
end process;
end Behavioral;