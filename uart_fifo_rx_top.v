`timescale 1ns / 1ps

module uart_fifo_rx_top (
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,       // Serial wire coming from the outside world
    input  wire       rd_en,    // CPU reads data from RX FIFO
    output wire [7:0] data_out, // Data going to CPU
    output wire       rx_empty,
    output wire       rx_full
);

    // Internal wires connecting the UART RX to the RX FIFO
    wire [7:0] internal_rx_data;
    wire       internal_rx_dv;

    // Instantiate the UART Receiver
    uart_rx #(
        .CLKS_PER_BIT(8)
    ) my_uart_rx (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .rx_data(internal_rx_data),
        .rx_dv(internal_rx_dv)
    );

    // Instantiate the RX FIFO
    FIFO my_rx_fifo (
        .clk(clk),
        .rst(rst),
        .buf_in(internal_rx_data),
        .buf_out(data_out),
        .wr_en(internal_rx_dv), // UART pushes data in automatically
        .rd_en(rd_en),          // CPU pulls data out manually
        .buf_empty(rx_empty),
        .buf_full(rx_full),
        .fifo_counter()         // Left unconnected at top level
    );

endmodule