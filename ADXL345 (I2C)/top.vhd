--INFO
-- Project : ADXL345 (I2C)
-- Module: top
-- Designer : Ekin Akyildirim
-- Supervisor and Mentor: Goktug Saray

-- ILA SETTINGS
-- ILA is used to observe signals in the FPGA design.

-- BOARD
--Zed Board


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity top is
    generic (
        g_clkfreq : integer := 100_000_00;
        g_bus_clk : integer := 100_000;
        g_device_addr : std_logic_vector ( 6 downto 0) := "1010011";
        g_baudrate : integer := 115_200;
        g_stopbit : integer := 2;
        g_readfreq : integer := 10
        );
    port (
        clk : in std_logic;
        tx_o : out std_logic;
        scl : inout std_logic;
        rst_i : in std_logic;
        sda : inout std_logic
        );
         
end top;

architecture Behavioral of top is

component adxl345 is
      Generic (
	    g_clkfreq		: integer := 100_000_000;
	    g_bus_clk	    : integer := 400_000;
	    g_device_addr	: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1010011";
	    g_readfreq      : integer := 10
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
			tx_reset_i : in std_logic;
			tx_o			: out std_logic;
			tx_done_tick_o	: out std_logic 
			--tx_ready_o      : out std_logic
			 );
end component;

--COUNTER AND TRIGGERS
signal cntr_s : integer;
signal send_trig_s : std_logic;

--ADXL SIGNALS
signal int_s : std_Logic;
--signal rst_s : std_logic := '1';

-- TX SIGNALS
signal tx_start_s : std_logic;
signal din_s : std_logic_vector ( 7 downto 0);
signal tx_done_tick_s : std_logic;
signal tx_reset_s : std_logic := '0';

--DATA REGISTERS
signal ax_s : std_logic_vector ( 15 downto 0);
signal ay_s : std_logic_vector ( 15 downto 0);
signal az_s : std_logic_vector ( 15 downto 0);
signal tx_buffer_s : std_logic_vector (47 downto 0);

signal scl_debug : std_logic;
signal sda_debug : std_logic;

attribute MARK_DEBUG : string;
attribute MARK_DEBUG of tx_o: signal is "TRUE";
attribute MARK_DEBUG of ax_s: signal is "TRUE";
attribute MARK_DEBUG of ay_s: signal is "TRUE";
attribute MARK_DEBUG of az_s: signal is "TRUE";
attribute MARK_DEBUG of sda_debug: signal is "FALSE";
attribute MARK_DEBUG of scl_debug: signal is "FALSE";

begin

adxl345_i : adxl345
GENERIC MAP(
	g_CLKFREQ		=> g_CLKFREQ		,
	g_BUS_CLK	=> g_BUS_CLK	,
	g_DEVICE_ADDR	=> g_DEVICE_ADDR,
	g_readfreq      => g_readfreq	
)
PORT MAP( 
	CLK 		=> CLK 		    ,
	RST_i 		=> rst_i 		,
	SCL_io 		=> SCL 		    ,
	SDA_io 		=> SDA 		    ,
	INT_o 	=> int_s	,
	ax_o 		=> ax_s ,	
	ay_o 		=> ay_s,
	az_o 		=> az_s
		
);

UART_TX_i : UART_TX
GENERIC MAP(
g_clkfreq		=> g_clkfreq,
g_baudrate			=> g_baudrate,
g_stopbit			=> g_stopbit

)
PORT MAP(
CLK				=> CLK			 ,
tx_start_i		=> tx_start_s	     ,
DIN_i				=> din_s			 ,
TX_DONE_TICK_o	=> tx_done_tick_s  ,
TX_o				=> tx_o	,
tx_reset_i          => tx_reset_s		
);

process (CLK) begin
if (rising_edge(CLK)) then
    --scl_debug <= scl;
    --sda_debug <= sda;
    
	if (int_s = '1') then
		tx_buffer_s	<= ax_s & ay_s & az_s;
		cntr_s		<= 6;
		send_trig_s	<= '1';
	end if;
	
	din_s <= tx_buffer_s(6*8-1 downto 5*8);
	
	if (send_trig_s = '1') then
		if (cntr_s = 6) then
			
			tx_start_s					<= '1';
			tx_buffer_s(6*8-1 downto 8)	<= tx_buffer_s(5*8-1 downto 0);
			cntr_s						<= cntr_s - 1;	
		elsif (cntr_s = 0) then
			tx_start_s	<= '0';
			if (tx_done_tick_s = '1') then
				send_trig_s	<= '0';
			end if;
		else
			
			if (tx_done_tick_s = '1') then
				cntr_s						<= cntr_s - 1;
				tx_buffer_s(6*8-1 downto 8)	<= tx_buffer_s(5*8-1 downto 0);
			end if;
		end if;
	end if;
	
end if;
end process;


end Behavioral;
