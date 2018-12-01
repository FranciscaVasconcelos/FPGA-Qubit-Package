`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/30/2018 10:40:17 AM
// Design Name: 
// Module Name: multiplier_tb
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


module multiplier_tb(
    );
    
    reg clk100 = 0;
    
    initial begin
        forever begin
            clk100 = ~clk100;
            #10;
        end
    end
    
    wire reset = 0;
    wire start_collect = 1;
    wire [3:0] demod_freq = 4'd5; // 50 MHz
    wire [10:0] sample_length = 11'd2000; // 20 us
    wire [5:0] sample_freq = 6'd5;
    
    reg [15:0] [4:0] data_i_in = 0;
    reg [15:0] [4:0] data_q_in = 0;
    
    integer i;
    
    initial begin
        #2;
        forever begin
            for (i = 0; i < 5; i = i + 1) begin
                data_i_in[i] = data_i_in[i] + i;
                data_q_in[i] = data_q_in[i] + i;
            end
            #10;
        end
    end
            
    wire [15:0] [4:0] data_i_rot;
    wire [15:0] [4:0] data_q_rot;
    wire [13:0] [4:0] phase_vals;
    
    
    multiplier uut(
        // inputs
        .clk100(clk100), .reset(reset),
        .phase_vals(phase_vals),
        .data_i_in(data_i_in), .data_q_in(data_q_in),
        // outputs
        .data_i_rot(data_i_rot), .data_q_rot(data_q_rot));

endmodule
