`timescale 1ns / 1ps

module uart_tx #(
    parameter CLKS_PER_BIT = 434 // For 50 MHz clock and 115200 Baud
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       tx_start,  // Triggered when FIFO is not empty
    input  wire [7:0] tx_data,   // Data coming from the FIFO
    output reg        tx,        // The actual serial wire going out
    output reg        tx_busy    // Tells the FIFO "Wait, I'm transmitting!"
);

    // FSM State Encoding
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state;
    
    // Internal Registers
    reg [8:0] clk_count;  // Counts up to CLKS_PER_BIT (434 requires 9 bits)
    reg [2:0] bit_index;  // Counts which of the 8 data bits we are sending
    reg [7:0] saved_data; // Latches the input data so it doesn't change mid-transmission

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= IDLE;
            tx         <= 1'b1; // UART line is HIGH when idle
            tx_busy    <= 1'b0;
            clk_count  <= 0;
            bit_index  <= 0;
            saved_data <= 0;
        end else begin
            case (state)
                
                // ----------------------------------------
                // STATE 0: IDLE
                // ----------------------------------------
                IDLE: begin
                    tx        <= 1'b1;
                    tx_busy   <= 1'b0;
                    clk_count <= 0;
                    bit_index <= 0;
                    
                    if (tx_start) begin
                        saved_data <= tx_data; // Grab the data from the FIFO
                        tx_busy    <= 1'b1;
                        state      <= START;
                    end
                end
                
                // ----------------------------------------
                // STATE 1: START BIT (Pull line LOW)
                // ----------------------------------------
                START: begin
                    tx <= 1'b0;
                    
                    // Wait for one full Baud cycle
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state     <= DATA;
                    end
                end
                
                // ----------------------------------------
                // STATE 2: DATA BITS (Send 8 bits, LSB first)
                // ----------------------------------------
                DATA: begin
                    tx <= saved_data[bit_index]; // Put current bit on the wire
                    
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        
                        // Check if we have sent all 8 bits
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state     <= STOP;
                        end
                    end
                end
                
                // ----------------------------------------
                // STATE 3: STOP BIT (Pull line HIGH)
                // ----------------------------------------
                STOP: begin
                    tx <= 1'b1;
                    
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state     <= IDLE; // Transmission complete, go back to IDLE
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule