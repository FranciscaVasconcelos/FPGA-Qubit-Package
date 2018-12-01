`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/30/2018 10:40:17 AM
// Design Name: 
// Module Name: integrator_tb
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


module integrator_tb(
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
    
    reg [15:0] [4:0] data_i_rot = 0;
    reg [15:0] [4:0] data_q_rot = 0;
    
    integer i;
    
    initial begin
        #2;
        forever begin
            for (i = 0; i < 5; i = i + 1) begin
                data_i_rot[i] = data_i_rot[i] + i;
                data_q_rot[i] = data_q_rot[i] + i;
            end
            #10;
        end
    end
            
    wire [15:0] [4:0] data_i_shift;
    wire [15:0] [4:0] data_q_shift;
    wire iq_valid;
    wire [31:0] i_val;
    wire [31:0] q_val;    
    
    integrator integrator_main(
        // inputs
        .clk100(clk100), .reset(reset), .start(start_collect),
        .sample_length(sample_length),
        .data_i_rot(data_i_rot), .data_q_rot(data_q_rot),
        // outputs
        .iq_valid(iq_valid),
        .i_val(i_val), .q_val(q_val));
    
endmodule
