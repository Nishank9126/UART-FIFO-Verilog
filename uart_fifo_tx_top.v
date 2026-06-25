`timescale 1ns / 1ps

module uart_fifo_tx_top (
    input  wire       clk,
    input  wire       rst,
    input  wire       wr_en,    // User pushes data into FIFO
    input  wire [7:0] data_in,  // User data
    output wire       tx,       // Serial wire going to the outside world
    output wire       fifo_full,
    output wire       fifo_empty
);

    // Internal Wires connecting the FIFO to the UART
    wire [7:0] internal_data;
    wire       tx_busy;
    wire       tx_start_pulse;

    // The Glue Logic: 
    // We want to pull data from the FIFO and start transmitting IF:
    // 1. The FIFO is NOT empty (there is data to send)
    // 2. The UART is NOT busy (it is ready to send)
    assign tx_start_pulse = (!fifo_empty) && (!tx_busy);

    // Instantiate the FIFO
    FIFO my_fifo (
        .clk(clk),
        .rst(rst),
        .buf_in(data_in),
        .buf_out(internal_data),
        .wr_en(wr_en),
        .rd_en(tx_start_pulse), // Pop a byte exactly when UART starts
        .buf_empty(fifo_empty),
        .buf_full(fifo_full),
        .fifo_counter() // Left blank because we don't need it at the top level
    );

    // Instantiate the UART Transmitter
    uart_tx #(
        .CLKS_PER_BIT(8)
    ) my_uart_tx (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start_pulse),
        .tx_data(internal_data),
        .tx(tx),
        .tx_busy(tx_busy)
    );

endmodule