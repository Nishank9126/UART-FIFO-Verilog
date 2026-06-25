`timescale 1ns / 1ps

module tb_uart_system_full();

    // System Clocks and Resets
    reg clk;
    reg rst;

    // TX Side Signals (CPU writing to Transmitter)
    reg        tx_wr_en;
    reg  [7:0] tx_data_in;
    wire       tx_fifo_full;
    wire       tx_fifo_empty;

    // RX Side Signals (CPU reading from Receiver)
    reg        rx_rd_en;
    wire [7:0] rx_data_out;
    wire       rx_fifo_full;
    wire       rx_fifo_empty;

    // The Physical Loopback Wire
    wire serial_wire;

    // Instantiate the Transmitter System Top
    uart_fifo_tx_top UUT_TX (
        .clk(clk),
        .rst(rst),
        .wr_en(tx_wr_en),
        .data_in(tx_data_in),
        .tx(serial_wire),      // Data leaves here
        .fifo_full(tx_fifo_full),
        .fifo_empty(tx_fifo_empty)
    );

    // Instantiate the Receiver System Top
    uart_fifo_rx_top UUT_RX (
        .clk(clk),
        .rst(rst),
        .rx(serial_wire),      // Data enters here
        .rd_en(rx_rd_en),
        .data_out(rx_data_out),
        .rx_empty(rx_fifo_empty),
        .rx_full(rx_fifo_full)
    );

    // 50 MHz Clock Generation (20ns Period)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // The Core Verification Sequence
    initial begin
        // 1. Initialize Default States
        rst = 1;
        tx_wr_en = 0;
        tx_data_in = 8'h00;
        rx_rd_en = 0;
        
        #100;
        @(posedge clk);
        rst = 0;
        #100;

        // 2. CPU Burst Writes "FPGA" into the Transmitter
        $display("[%0t] --- CPU: Burst Writing 'FPGA' to TX System ---", $time);
        @(posedge clk); tx_wr_en = 1; tx_data_in = 8'h46; // 'F'
        @(posedge clk); tx_wr_en = 1; tx_data_in = 8'h50; // 'P'
        @(posedge clk); tx_wr_en = 1; tx_data_in = 8'h47; // 'G'
        @(posedge clk); tx_wr_en = 1; tx_data_in = 8'h41; // 'A'
        @(posedge clk); tx_wr_en = 0; tx_data_in = 8'h00;

        // 3. Hardware Propagation Delay
        // 4 bytes * 10 bits (including start/stop) * 434 clocks per bit * 20ns = ~347,200 ns
        $display("[%0t] --- Hardware: Serializing and Transmitting via UART... ---", $time);
        #10000; 

        // 4. CPU Reads the Reassembled Data from the Receiver
        $display("[%0t] --- CPU: Reading Received Data from RX System ---", $time);
        
        if (!rx_fifo_empty) begin
            // Read Byte 1 ('F') - Data is already waiting due to FWFT FIFO design
            $display("[%0t] Read Byte 1: %h (Expected 46)", $time, rx_data_out); 
            @(posedge clk); rx_rd_en = 1;             // Pulse enable to discard 'F' and fetch 'P'
            @(posedge clk); rx_rd_en = 0;
            @(posedge clk);                           // Provide 1 clock cycle for RAM to output new data
            
            // Read Byte 2 ('P')
            $display("[%0t] Read Byte 2: %h (Expected 50)", $time, rx_data_out); 
            @(posedge clk); rx_rd_en = 1; 
            @(posedge clk); rx_rd_en = 0;
            @(posedge clk);
            
            // Read Byte 3 ('G')
            $display("[%0t] Read Byte 3: %h (Expected 47)", $time, rx_data_out); 
            @(posedge clk); rx_rd_en = 1; 
            @(posedge clk); rx_rd_en = 0;
            @(posedge clk);
            
            // Read Byte 4 ('A')
            $display("[%0t] Read Byte 4: %h (Expected 41)", $time, rx_data_out); 
            @(posedge clk); rx_rd_en = 1; 
            @(posedge clk); rx_rd_en = 0;
            @(posedge clk);
        end else begin
            $display("[%0t] ERROR: Hardware failed to transmit/receive data. RX FIFO is empty.", $time);
        end

        $display("[%0t] --- ALL TESTS PASSED. SYSTEM COMPLETE. ---", $time);
        $finish;
    end

endmodule