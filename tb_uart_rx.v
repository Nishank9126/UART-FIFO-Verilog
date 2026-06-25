`timescale 1ns / 1ps

module tb_uart_rx();

    parameter CLKS_PER_BIT = 434;
    parameter BIT_PERIOD = 8680; // 434 clocks * 20ns = 8680 ns per bit

    reg clk;
    reg rst;
    reg rx;

    wire [7:0] rx_data;
    wire rx_dv;

    // Instantiate the Unit Under Test (UUT)
    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uut (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .rx_data(rx_data),
        .rx_dv(rx_dv)
    );

    // Clock Generation (50 MHz = 20ns period)
    initial begin
        clk = 0;
        forever #10 clk = ~clk; 
    end

    // ----------------------------------------------------
    // VERILOG TASK: Simulates an incoming UART transmission
    // ----------------------------------------------------
    task send_byte;
        input [7:0] data;
        integer i;
        begin
            // 1. Send Start Bit
            rx = 0;
            #(BIT_PERIOD);
            
            // 2. Send 8 Data Bits (LSB First)
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #(BIT_PERIOD);
            end
            
            // 3. Send Stop Bit
            rx = 1;
            #(BIT_PERIOD);
        end
    endtask
    // ----------------------------------------------------

    // Test Sequence
    initial begin
        // Initialize
        rst = 1;
        rx  = 1; // UART line is HIGH when idle
        #100;
        rst = 0;
        #100;

        // Simulate receiving 'A' (Hex 41 / Dec 65)
        $display("Testbench: Transmitting 0x41 ('A') into the Receiver...");
        send_byte(8'h41);
        
        #20000; // Wait a bit between packets
        
        // Simulate receiving 'Z' (Hex 5A / Dec 90)
        $display("Testbench: Transmitting 0x5A ('Z') into the Receiver...");
        send_byte(8'h5A);

        #20000;
        $display("Simulation Complete.");
        $finish;
    end

endmodule