`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/30/2018 08:19:42 AM
// Design Name: 
// Module Name: sampler_tb
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


module sampler_tb(
    );

    reg clk100 = 0;
    
    initial begin
        forever begin
            clk100 = ~clk100;
            #5;
        end
    end
    
    wire reset = 0;
    reg start_collect = 0;
    wire [4:0] demod_freq = 5'd6; // 50 MHz
    wire [10:0] sample_length = 11'd2000; // 20 us
    wire [5:0] sample_freq = 6'd7;
    wire [4:0] [9:0] [5:0] demod_mod50_LUT;
    
    genvar i, j;
    generate
        for (i = 0; i < 5; i = i + 1) begin : gen1
            for (j = 0; j < 10; j = j + 1) begin : gen2
                assign demod_mod50_LUT[i][j] = (demod_freq * (i + 5 * j)) % 50;
            end
        end
    endgenerate
    
    reg [4:0] [15:0] data_i_in = 0;
    reg [4:0] [15:0] data_q_in = 0;
    
    integer k;
    
    initial begin
        #1;
        forever begin
            for (k = 0; k < 5; k = k + 1) begin
                data_i_in[k] = data_i_in[k] + k;
                data_q_in[k] = data_q_in[k] + k;
            end
            #10;
        end
    end

    initial begin
        #1;
        start_collect = 1;
        #10;
        start_collect = 0;
    end
            
    wire [4:0] [15:0] data_i_shift;
    wire [4:0] [15:0] data_q_shift;
    wire [4:0] [17:0] phase_vals;
    
    
    sampler uut(
        // inputs
        .clk100(clk100), .reset(reset), .start(start_collect),
        .data_i_in(data_i_in), .data_q_in(data_q_in),
        .demod_freq(demod_freq), .demod_mod50_LUT(demod_mod50_LUT),
        .sample_length(sample_length), .sample_skip(sample_freq),
        // outputs
        .data_i_shift(data_i_shift), .data_q_shift(data_q_shift),
        .phase_vals(phase_vals));

endmodule
