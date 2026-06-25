`timescale 1ns / 1ps

module tb_uart_tx();

    // Inputs to the UUT (Unit Under Test)
    reg clk;
    reg rst;
    reg tx_start;
    reg [7:0] tx_data;

    // Outputs from the UUT
    wire tx;
    wire tx_busy;

    // Instantiate the Transmitter
    uart_tx #(
        .CLKS_PER_BIT(434) // 115200 baud at 50MHz
    ) uut (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    // Clock Generation (50 MHz = 20ns period)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // Test Sequence
    initial begin
        // Initialize Inputs
        rst = 1;
        tx_start = 0;
        tx_data = 0;

        // Hold reset for a few clocks
        #100;
        rst = 0;
        #100;

        // Send the letter 'A' (Hex 41 = Binary 01000001)
        $display("Sending Data: 0x41 ('A')");
        @(posedge clk);
        tx_data = 8'h41;
        tx_start = 1;
        
        @(posedge clk);
        tx_start = 0; // Turn off start signal, TX should now be busy

        // Wait for the transmission to finish.
        // 1 bit takes 434 clocks. 10 bits total (Start + 8 Data + Stop) = 4340 clocks.
        // 4340 clocks * 20ns = 86,800 ns. We will wait 100,000 ns to be safe.
        #100000;
        
        $display("Transmission Complete.");
        $finish;
    end

endmodule