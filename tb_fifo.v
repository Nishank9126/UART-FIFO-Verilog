`timescale 1ns / 1ps

module tb_fifo();

    // 1. Testbench Signals
    reg clk;
    reg rst;
    reg wr_en;
    reg rd_en;
    reg [7:0] buf_in;
    
    wire [7:0] buf_out;
    wire buf_empty;
    wire buf_full;
    wire [6:0] fifo_counter;
    
    integer i;

    // 2. Instantiate the FIFO module
    // The names in the parentheses must match your module's inputs/outputs
    FIFO uut (
        .clk(clk), 
        .rst(rst), 
        .buf_in(buf_in), 
        .buf_out(buf_out), 
        .wr_en(wr_en), 
        .rd_en(rd_en), 
        .buf_empty(buf_empty), 
        .buf_full(buf_full), 
        .fifo_counter(fifo_counter)
    );

    // 3. Generate a 50 MHz Clock (20ns period)
    initial begin
        clk = 0;
        forever #10 clk = ~clk; 
    end

    // 4. Stimulus Process
    initial begin
        // Initialize Inputs
        rst = 0;
        wr_en = 0;
        rd_en = 0;
        buf_in = 0;

        // Apply Reset
        #20 rst = 1; 
        #20 rst = 0;
        #20;

        // TEST 1: Write 64 bytes to completely fill the FIFO
        $display("Starting WRITE test...");
        for (i = 0; i < 64; i = i + 1) begin
            @(posedge clk);
            wr_en = 1;
            buf_in = $random; // Generate a random 8-bit number
        end
        
        // Stop writing
        @(posedge clk);
        wr_en = 0;
        
        // Wait a few clock cycles to observe the full flag
        #40; 

        // TEST 2: Read 64 bytes to completely empty the FIFO
        $display("Starting READ test...");
        for (i = 0; i < 64; i = i + 1) begin
            @(posedge clk);
            rd_en = 1;
        end
        
        // Stop reading
        @(posedge clk);
        rd_en = 0;

        // End Simulation
        #100;
        $finish;
    end

endmodule