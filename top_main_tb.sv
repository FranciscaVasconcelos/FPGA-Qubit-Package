`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/03/2018 09:56:35 AM
// Design Name: 
// Module Name: top_main_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_main_tb(
    );

    reg clk100 = 0;
    initial begin
        forever begin
            clk100 = ~clk100;
            #5;
        end
    end
    
    wire reset = 0;
    reg config_reset = 0;
    reg trigger = 0;
    reg [4:0] [15:0] data_i_in = 0;
    reg [4:0] [15:0] data_q_in = 0;
    
    integer k;
    wire iq_valid;
    
    initial begin
        #1;
        forever begin
            for (k = 0; k < 5; k = k + 1) begin
                data_i_in[k] = data_i_in[k] + k;
                data_q_in[k] = data_q_in[k] + k;
            end
            #10;
            if (iq_valid) begin
                #20;
                trigger = 1;
                #10;
                trigger = 0;
            end
        end
    end

    initial begin
        #11;
        config_reset = 1;
        #10;
        config_reset = 0;
        #20;
        trigger = 1;
        #10;
        trigger = 0;
    end
            
    wire [31:0] i_val;
    wire [31:0] q_val;
    wire [1:0] analyze_mode;
    wire [15:0] x_bin_width;
    wire [15:0] y_bin_width;
    wire [4:0] x_bin_num;
    wire [4:0] y_bin_num;
    wire signed [15:0] x_bin_min;
    wire signed [15:0] y_bin_min;
    
        
    top_main #(
        .DEMOD_FREQ(5),
        .SAMPLE_LENGTH(200),
        .SAMPLE_FREQ(5),
        .DELAY_TIME(50),
        .ANALYZE_MODE(0),
        .X_BIN_WIDTH(100),
        .Y_BIN_WIDTH(100),
        .X_BIN_NUM(10),
        .Y_BIN_NUM(10),
        .X_BIN_MIN(0),
        .Y_BIN_MIN(0))
        uut(
        // inputs
        .clk100(clk100), .reset(reset), .config_reset(config_reset),
        // I input values
        .data0_in_0(data_i_in[0]),
        .data0_in_1(data_i_in[1]),
        .data0_in_2(data_i_in[2]),
        .data0_in_3(data_i_in[3]),
        .data0_in_4(data_i_in[4]),
        // Q input values
        .data1_in_0(data_q_in[0]),
        .data1_in_1(data_q_in[1]),
        .data1_in_2(data_q_in[2]),
        .data1_in_3(data_q_in[3]),
        .data1_in_4(data_q_in[4]),
        .trigger(trigger),
        
        //outputs
        .iq_valid(iq_valid),
        .i_val(i_val), .q_val(q_val),
        // configurated prameters to pass to lower modules
        .analyze_mode(analyze_mode),
        .x_bin_width(x_bin_width), .y_bin_width(y_bin_width),
        .x_bin_num(x_bin_num), .y_bin_num(y_bin_num),
        .x_bin_min(x_bin_min), .y_bin_min(y_bin_min));

endmodule
