--INFO
-- Project : UART with FIFO

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
