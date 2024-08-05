--INFO
-- Project : UART with BRAM
-- Module: top



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
USE std.textio.all;


entity top is
    generic(
        g_ram_width 		: integer 	:= 16;				-- Specify RAM data width
        g_ram_depth 		: integer 	:= 128;				-- Specify RAM depth (number of entries)
        g_ram_performance   : string 	:= "LOW_LATENCY";    -- Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        g_ram_type 		    : string 	:= "block";    -- Select "block" or "distributed" 
        g_clkfreq		: integer := 100_000_000;
		g_baudrate		: integer := 115_200;
		g_stopbit		: integer := 2
    );
    port   (
        clk				: in std_logic;
        rx_i			: in std_logic;
        tx_o			: out std_logic   
    );
end top;

architecture Behavioral of top is
     -- STATE MACHINE
     type states is (s_idle, s_transmit_d,s_read_d, s_write_d );
     signal state : states := s_idle;
     
     -- reset SIGNALS
     signal rst_s: std_logic;
      
     -- uart_tx SIGNALS
     signal din_s : std_logic_vector ( 7 downto 0);
     signal tx_start_s : std_logic;
     signal tx_valid_s : std_logic;
     
     
     -- uart_rx SIGNALS
     signal dout_s : std_logic_vector ( 7 downto 0);
     signal rx_valid_s: std_logic;
     
     --block_ram SIGNALS
     signal addra_s : std_logic_vector(7 downto 0);
     signal dina_s  : std_logic_vector(g_ram_width-1 downto 0);
     signal wea_s   : std_logic;
     signal douta_s  : std_logic_vector(g_ram_width-1 downto 0);
     
     -- Process SIGNALS
     signal databuffer_s : std_logic_vector (4*8-1 downto 0) := (others => '0');
     signal cntr_s			: integer range 0 to 255 := 0;
    
    --COMPONENT BLOCK_RAM
    component block_ram is
        generic (
        g_ram_width 		: integer 	:= 16;				-- Specify RAM data width
        g_ram_depth 		: integer 	:= 128;				-- Specify RAM depth (number of entries)
        g_ram_performance   : string 	:= "LOW_LATENCY";    -- Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        g_ram_type 		    : string 	:= "block"    -- Select "block" or "distributed" 
        
        );
        port (
        addra : in std_logic_vector(7 downto 0);    -- Address bus, width determined from RAM_DEPTH
        dina  : in std_logic_vector(g_ram_width-1 downto 0);		  		-- RAM input data
        clka  : in std_logic;                       			  		-- Clock
        wea   : in std_logic;                       			  		-- Write enable
        douta : out std_logic_vector(g_ram_width-1 downto 0)   			-- RAM output data
        );
    end component;
    
    --COMPONENT UART_TX
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
			tx_reset_i : in std_logic;
			tx_o			: out std_logic;
			tx_done_tick_o	: out std_logic 
			--tx_ready_o      : out std_logic
			 );
     end component;
     
     --COMPONENT UART_RX
     component uart_rx is
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
      end component;
    
    
begin

    i_uart_rx : uart_rx
        generic map(
        g_clkfreq		=> g_clkfreq,
        g_baudrate		=> g_baudrate
        )
        port map(
        clk				=> clk,
        rx_i			=> rx_i,
        dout_o			=> dout_s,
        rx_reset_i      => rst_s,
        rx_done_tick_o	=> rx_valid_s
        );
        
    i_uart_tx : uart_tx
        generic map(
        g_clkfreq		=> g_clkfreq	,
        g_baudrate		=> g_baudrate	,
        g_stopbit		=> g_stopbit	
        )
        port map(
        clk				=> clk,
        din_i			=> din_s,
        tx_start_i		=> tx_start_s,
        tx_o			=> tx_o,
        tx_reset_i      => rst_s,
        tx_done_tick_o	=> tx_valid_s
        );
        
     i_ram128x16 : block_ram
        generic map(
        g_ram_width 		=> g_ram_width 		  ,
        g_ram_depth 		=> g_ram_depth 		  ,
        g_ram_performance    => g_ram_performance    ,
        g_ram_type 		=> g_ram_type 		
        )
        port map(
        addra => addra_s    ,
        dina  => dina_s     ,
        clka  => clk      ,
        wea   => wea_s      ,
        douta => douta_s
        );

process (clk) begin
    if (rising_edge(clk)) then
     
        case state is
		
		when s_idle =>
		
			wea_s		<= '0';
			cntr_s	<= 0;
		
			if (rx_valid_s = '1') then
				databuffer_s(7 downto 0) 			<= dout_s;
				databuffer_s(4*8-1 downto 1*8) 	<= databuffer_s(3*8-1 downto 0*8);
			end if;
			
			if (databuffer_s(4*8-1 downto 3*8) = x"0A") then	-- yaz komutu
				state	<= s_write_d;
			end if;
			
			if (databuffer_s(4*8-1 downto 3*8) = x"0B") then	-- oku komutu
				state	<= s_read_d;
			end if;
		
		when s_write_d =>
		
			addra_s		<= databuffer_s(3*8-2 downto 2*8);
			dina_s		<= databuffer_s(2*8-1 downto 0*8);
			wea_s			<= '1';
			state		<= S_IDLE;
			databuffer_S	<= (others => '0');
		
		when s_read_d =>
		
			addra_s	<= databuffer_s(3*8-2 downto 2*8);
			cntr_s	<= cntr_s + 1;
			if (cntr_s = 1) then
				databuffer_s(2*8-1 downto 0*8)	<= douta_s;
				state							<= s_transmit_d;	
				cntr_s							<= 3;
				din_s							<= databuffer_s(4*8-1 downto 3*8);
				tx_start_s						<= '1';
			end if;
		
		when s_transmit_d => 
			
			if (cntr_s = 0) then
				tx_start_s	<= '0';
				if (tx_valid_s = '1') then
					state		<= s_idle;
					databuffer_s	<= (others => '0');
				end if;
			else
				din_s		<= databuffer_s(cntr_s*8-1 downto (cntr_s-1)*8);
				if (tx_valid_s = '1') then
					cntr_s	<= cntr_s - 1;
				end if;				
			end if;
		
	end case;   
    
    end if;

end process;


end Behavioral;
