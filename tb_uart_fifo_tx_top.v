`timescale 1ns / 1ps

module tb_uart_fifo_tx_top();

    // 1. Inputs to the Top Module
    reg clk;
    reg rst;
    reg wr_en;
    reg [7:0] data_in;

    // 2. Outputs from the Top Module
    wire tx;
    wire fifo_full;
    wire fifo_empty;

    // 3. Instantiate the Top Module
    uart_fifo_tx_top uut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .data_in(data_in),
        .tx(tx),
        .fifo_full(fifo_full),
        .fifo_empty(fifo_empty)
    );

    // 4. Clock Generation (50 MHz = 20ns period)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // 5. The "CPU" Test Sequence
    initial begin
        // Initialize Inputs
        rst = 1;
        wr_en = 0;
        data_in = 0;

        #100;
        rst = 0;
        #100;

        // BURST WRITE: Push "HELLO" into the FIFO at maximum speed
        // ASCII Hex values: H=0x48, E=0x45, L=0x4C, L=0x4C, O=0x4F
        
        $display("CPU: Pushing 'H'...");
        @(posedge clk); wr_en = 1; data_in = 8'h48;
        
        $display("CPU: Pushing 'E'...");
        @(posedge clk); wr_en = 1; data_in = 8'h45;
        
        $display("CPU: Pushing 'L'...");
        @(posedge clk); wr_en = 1; data_in = 8'h4C;
        
        $display("CPU: Pushing 'L'...");
        @(posedge clk); wr_en = 1; data_in = 8'h4C;
        
        $display("CPU: Pushing 'O'...");
        @(posedge clk); wr_en = 1; data_in = 8'h4F;

        // Stop writing immediately after the 5th byte
        @(posedge clk); 
        wr_en = 0; 
        data_in = 8'h00;

        $display("CPU: Done writing in 5 clock cycles! Going to sleep.");
        $display("Hardware: UART is now transmitting from the FIFO...");

        // Wait for all 5 bytes to transmit serially.
        // Math: 5 bytes * 10 bits/byte * 434 clocks/bit * 20ns = 434,000 ns.
        // We will wait 500,000 ns just to safely catch the end.
        #500000;

        $display("Simulation Complete!");
        $finish;
    end

endmodule