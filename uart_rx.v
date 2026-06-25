`timescale 1ns / 1ps

module uart_rx #(
    parameter CLKS_PER_BIT = 434 // For 50 MHz clock and 115200 Baud
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,       // The incoming serial wire
    output reg  [7:0] rx_data,  // The reassembled parallel byte
    output reg        rx_dv     // "Data Valid" pulse to trigger the RX FIFO write
);

    // FSM State Encoding
    localparam IDLE  = 3'b000;
    localparam START = 3'b001;
    localparam DATA  = 3'b010;
    localparam STOP  = 3'b011;
    localparam CLEAN = 3'b100;

    reg [2:0] state;
    reg [8:0] clk_count;
    reg [2:0] bit_index;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            rx_data   <= 0;
            rx_dv     <= 0;
            clk_count <= 0;
            bit_index <= 0;
        end else begin
            case (state)
                
                // ----------------------------------------
                // STATE 0: IDLE (Wait for rx to drop LOW)
                // ----------------------------------------
                IDLE: begin
                    rx_dv     <= 1'b0;
                    clk_count <= 0;
                    bit_index <= 0;

                    if (rx == 1'b0) begin 
                        state <= START;
                    end
                end
                
                // ----------------------------------------
                // STATE 1: START BIT (Mid-Bit Sampling)
                // ----------------------------------------
                START: begin
                    // Wait for HALF a bit period (434 / 2 = 217)
                    if (clk_count == (CLKS_PER_BIT / 2)) begin
                        if (rx == 1'b0) begin
                            clk_count <= 0;  // Reset counter
                            state     <= DATA; // It's a valid start bit!
                        end else begin
                            state <= IDLE; // False alarm, back to IDLE
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
                
                // ----------------------------------------
                // STATE 2: DATA BITS (Sample 8 times)
                // ----------------------------------------
                DATA: begin
                    // Wait for a FULL bit period
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count          <= 0;
                        rx_data[bit_index] <= rx; // Shift the bit into our register

                        // Check if we have received all 8 bits
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state     <= STOP;
                        end
                    end
                end
                
                // ----------------------------------------
                // STATE 3: STOP BIT
                // ----------------------------------------
                STOP: begin
                    // Wait for a FULL bit period
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        rx_dv     <= 1'b1; // Pulse Data Valid High! 
                        clk_count <= 0;
                        state     <= CLEAN;
                    end
                end
                
                // ----------------------------------------
                // STATE 4: CLEANUP
                // ----------------------------------------
                CLEAN: begin
                    rx_dv <= 1'b0; // Turn off Data Valid immediately 
                    state <= IDLE; // Ready for the next byte
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule