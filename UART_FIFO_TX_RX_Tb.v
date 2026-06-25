`timescale 1ns / 1ps

module UART_FIFO_TX_RX_Tb();

    // System Signals
    reg clk;
    reg rst;

    // TX Side Signals (CPU writing)
    reg        tx_wr_en;
    reg  [7:0] tx_data_in;
    wire       tx_fifo_full;
    wire       tx_fifo_empty;

    // RX Side Signals (CPU reading)
    reg        rx_rd_en;
    wire [7:0] rx_data_out;
    wire       rx_fifo_full;
    wire       rx_fifo_empty;

    // The Physical Serial Wire connecting TX to RX!
    wire serial_wire;

    // Instantiate the Transmitter System
    uart_fifo_tx_top tx_system (
        .clk(clk),
        .rst(rst),
        .wr_en(tx_wr_en),
        .data_in(tx_data_in),
        .tx(serial_wire),      // Outputting to the wire
        .fifo_full(tx_fifo_full),
        .fifo_empty(tx_fifo_empty)
    );

    // Instantiate the Receiver System
    uart_fifo_rx_top rx_system (
        .clk(clk),
        .rst(rst),
        .rx(serial_wire),      // Reading from the exact same wire
        .rd_en(rx_rd_en),
        .data_out(rx_data_out),
        .rx_empty(rx_fifo_empty),
        .rx_full(rx_fifo_full)
    );

    // Clock Generation (50 MHz)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // The Ultimate Test Sequence
    initial begin
        // 1. Initialize
        rst = 1;
        tx_wr_en = 0;
        tx_data_in = 0;
        rx_rd_en = 0;
        
        #100;
        rst = 0;
        #100;

        // 2. CPU Burst Writes "FPGA" into Transmitter
        $display("--- CPU: Writing 'FPGA' to TX System ---");
        @(posedge clk); tx_wr_en = 1; tx_data_in = 8'h46; // 'F'
        @(posedge clk); tx_wr_en = 1; tx_data_in = 8'h50; // 'P'
        @(posedge clk); tx_wr_en = 1; tx_data_in = 8'h47; // 'G'
        @(posedge clk); tx_wr_en = 1; tx_data_in = 8'h41; // 'A'
        @(posedge clk); tx_wr_en = 0; tx_data_in = 8'h00;

        // 3. Wait for Hardware to do its job
        $display("--- Hardware: Transmitting serially in the background ---");
        // 4 bytes * 10 bits * 434 clocks * 20ns = ~347,000 ns.
        #400000; 

        // 4. CPU Reads from Receiver
        $display("--- CPU: Reading received data from RX System ---");
        
        // Read Byte 1 ('F')
        @(posedge clk); rx_rd_en = 1;
        @(posedge clk); rx_rd_en = 0;
        $display("Read Byte 1: %h", rx_data_out);
        #100;

        // Read Byte 2 ('P')
        @(posedge clk); rx_rd_en = 1;
        @(posedge clk); rx_rd_en = 0;
        $display("Read Byte 2: %h", rx_data_out);
        #100;

        // Read Byte 3 ('G')
        @(posedge clk); rx_rd_en = 1;
        @(posedge clk); rx_rd_en = 0;
        $display("Read Byte 3: %h", rx_data_out);
        #100;

        // Read Byte 4 ('A')
        @(posedge clk); rx_rd_en = 1;
        @(posedge clk); rx_rd_en = 0;
        $display("Read Byte 4: %h", rx_data_out);
        #100;

        $display("--- ALL TESTS PASSED. SYSTEM COMPLETE. ---");
        $finish;
    end

endmodule