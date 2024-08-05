--INFO
-- Project : UART with FIFO
-- Module: uart_fifo_top
-- Designer : Ekin Akyildirim
-- Supervisor and Mentor: Goktug Saray

--DESIGN INFO
--If you set the g_gen_tx_in to "yes", then the transmitter, which automatically generates data between 0 and 255, starts sending signals to the receiver. 
--The receiver then receives the signals and converts them into data, which is written to the FIFO. 
--Next, the FIFO reads the data and sends it to the transmitter, which then transmits this data externally.

--If you set the g_gen_tx_in to "no",then the rx_i will connected to reciever.
--The receiver then receives the signals and converts them into data, which is written to the FIFO. 
--Next, the FIFO reads the data and sends it to the transmitter, which then transmits this data externally.

--SIMULATION INFO
--It can be directly simulated. The clock should be forced at 100 ns intervals, and rst_s should be set to '1' for a duration of 200 µs.

--IMPLEMENTATION INFO
--Do not forget add ZedBoard.xdc in to Constraints. And link the ports. (tx_o , rx_i and clk)

--DEBUG SETTINGS
--""""""

-- SETTINGS
-- Set g_uart_mode to 'rx', 'tx', or 'both' to select the UART module you want to use. The default recommendation is "both". Otherwise, necessary changes need to be made.
-- Modify g_clkfreq to set the clock frequency. The default recommendation is '100_000_000'.
-- Modify g_baudrate to set the baud rate. The default recommendation is '115_200'.
-- Modify g_stopbit to adjust the UART transmitter stop bit for an 8-bit transmission. The strongly recommendation is '2'.
-- Modify g_gen_tx_in to turn the transmitter that generates data automatically on and off. 

--COMPONENTS OF MODULE
--UART_wrapper (uart_tx and uart_rx)
--uart_tx_in_autodata (uart_tx_in)
--fifo_generator
--VIO will be added.(for reset)

-- ILA SETTINGS
-- ILA is used to observe and analyze rx_done_tick_s and dout_o_s signals in the FPGA design.
-- Changes can be made via UART_wrapper.

-- VIO SETTINGS
-- Controls rst_s.

-- BOARD
--Zed Board




library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_fifo_top is
    generic (
        g_uart_mode  : string := "both"; -- "tx", "rx" or "both" to select uart mode
        g_clkfreq    : integer := 100_000_000;
        g_baudrate   : integer := 115_200;
        g_stopbit    : integer := 2;    
        g_gen_tx_in  : string  := "on"  -- "on", "off"                
    );
    port (  
        clk             : in std_logic;
        tx_o            : out std_logic;
        --tx_data_valid_o : out std_logic
       
        rx_i            : in std_logic 
        --dout_o          : out std_logic_vector(7 downto 0);
        --din_i           : in std_logic_vector(7 downto 0);
        --rst_i           : in std_logic;  
        --rx_data_valid_o : out std_logic;       
        --tx_start_i      : in std_logic; 
        --tx_ready_o      : out std_logic 
    );
end uart_fifo_top;

architecture Behavioral of uart_fifo_top is
    
    signal probe_rst_s : std_logic_vector (0 downto 0);
    signal rst_s : std_logic := '0';

    -- FIFO SIGNALS
    signal empty_s : std_logic;
    signal full_s  : std_logic;
    signal wr_en_s : std_logic;
    signal rd_en_s : std_logic;
    signal din_s   : std_logic_vector(7 downto 0);
    signal dout_s  : std_logic_vector(7 downto 0);

    -- UART_TX_IN TO UART_RX SIGNAL
    signal tx_to_rx_s : std_logic;

    -- UART_TX_IN SIGNALS                                    
    --signal tx_in_start_s      : std_logic;
    --signal tx_in_data_valid_s : std_logic;
    --signal tx_in_ready_s      : std_logic;

    -- UART_RX SIGNALS
    signal rx_dout_s       : std_logic_vector(7 downto 0);
    signal rx_data_valid_s : std_logic;
    
    -- UART_TX SIGNALS
    signal tx_data_valid_s :  std_logic;

    -- COMPONENT UART_wrapper
    component UART_wrapper is
        generic (
            g_uart_mode : string := "both"; -- "tx", "rx" or "both" to select uart mode
            g_clkfreq   : integer := 100_000_000;
            g_baudrate  : integer := 115_200;
            g_stopbit   : integer := 2
        );
        port (
            clk             : in std_logic;
            tx_o            : out std_logic;
            rx_i            : in std_logic;
            dout_o          : out std_logic_vector(7 downto 0);
            din_i           : in std_logic_vector(7 downto 0);
            rst_i           : in std_logic;
            rx_data_valid_o : out std_logic;
            tx_data_valid_o : out std_logic;
            tx_start_i      : in std_logic
            --tx_ready_o      : out std_logic
        );
    end component;

    -- COMPONENT UART_TX_IN_AUTODATA
    component uart_tx_in_autodata is
        generic (
            g_clkfreq : integer := 100_000_000;
            g_baudrate : integer := 115_200;
            g_stopbit  : integer := 2
        );
        port (
            clk            : in std_logic;
            tx_o           : out std_logic;
            tx_rst_i       : in std_logic
            
            --din_i          : in std_logic_vector(7 downto 0);
           -- tx_start_i     : in std_logic;
           -- tx_done_tick_o : out std_logic;
            --tx_ready_o     : out std_logic
        );
    end component;

     --COMPONENT RST_VIO
    component rst_vio
        port (
            clk : in std_logic;
            probe_out0 : out std_logic_vector(0 downto 0)
       );
    end component;

    -- COMPONENT FIFO_GENERATOR
    component fifo_generator
        port (
            clk   : in std_logic;
            srst  : in std_logic;
            din   : in std_logic_vector(7 downto 0);
            wr_en : in std_logic;
            rd_en : in std_logic;
            dout  : out std_logic_vector(7 downto 0);
            full  : out std_logic;
            empty : out std_logic
        );
    end component;

begin

    -- VIO RESET
    i_Vio_rst : rst_vio
        port map (
            clk => clk,
            probe_out0 => probe_rst_s
        );

    -- FIFO GENERATOR
    i_fifo_gen : fifo_generator
        port map (
            clk   => clk,
            srst  => rst_s,
            din   => din_s,
            wr_en => wr_en_s,
            rd_en => rd_en_s,
            dout  => dout_s,
            full  => full_s,
            empty => empty_s
        );

    -- UART WRAPPER
   UART_RX_Gen : if g_gen_tx_in = "off" generate
    begin
    i_uart_wrapper : UART_wrapper
        generic map (
            g_clkfreq   => g_clkfreq,
            g_baudrate  => g_baudrate,
            g_stopbit   => g_stopbit,
            g_uart_mode => g_uart_mode
        )
        port map (
            clk             => clk,
            tx_o            => tx_o,
            rx_i            => rx_i, -- UART RX connected to rx_i
            dout_o          => rx_dout_s,
            din_i           => dout_s, -- Data from FIFO to UART TX
            rst_i           => rst_s,
            rx_data_valid_o => rx_data_valid_s,
            tx_data_valid_o => tx_data_valid_s,
            tx_start_i      => rd_en_s -- Read enable from FIFO controls TX start
          
           -- tx_ready_o      => tx_ready_o
        );
       end generate;
        
    

    -- UART TX IN AUTODATA GENERATE
    UART_TX_AUTODATA_Gen : if g_gen_tx_in = "on" generate
    begin
        i_uart_tx_in_autodata : uart_tx_in_autodata
            generic map (
                g_clkfreq  => g_clkfreq,
                g_baudrate => g_baudrate,
                g_stopbit  => g_stopbit
            )
            port map (
                clk             => clk,
                tx_o            => tx_to_rx_s, -- Connect tx_o to tx_to_rx_s
                tx_rst_i        => rst_s
                
                --din_i           => din_i -- Connect input data to tx_in_autodata              
               -- tx_done_tick_o  => tx_in_data_valid_s,
               -- tx_ready_o      => tx_in_ready_s
            );
            
     -- UART WRAPPER rx_i connected to tx_to_rx_s
        i2_uart_wrapper : UART_wrapper
            generic map (
                g_clkfreq   => g_clkfreq,
                g_baudrate  => g_baudrate,
                g_stopbit   => g_stopbit,
                g_uart_mode => g_uart_mode
            )
            port map (
                clk             => clk,
                tx_o            => tx_o,
                rx_i            => tx_to_rx_s, -- UART RX connected to tx_to_rx_s
                dout_o          => rx_dout_s,
                din_i           => dout_s, -- Data from FIFO to UART TX
                rst_i           => rst_s,
                rx_data_valid_o => rx_data_valid_s,
                tx_data_valid_o => tx_data_valid_s,
                tx_start_i      => rd_en_s -- Read enable from FIFO controls TX start
              
               -- tx_ready_o      => tx_ready_o
            );
    end generate;
        
        rst_s <= probe_rst_s(0);

    -- FIFO CONTROL LOGIC
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_s = '1' then
                wr_en_s <= '0';
                rd_en_s <= '0';
                din_s <= (others => '0');
            else
                -- Write data to FIFO from UART RX
                if rx_data_valid_s = '1' and full_s = '0' then
                    wr_en_s <= '1';
                    din_s <= rx_dout_s;
                else
                    wr_en_s <= '0';
                end if;

                -- Read data from FIFO and send to UART TX
                if  empty_s = '0' then
                    rd_en_s <= '1';
                else
                    rd_en_s <= '0';
                end if;
            end if;
        end if;
    end process;

end Behavioral;
