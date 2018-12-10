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


module analyze_fsm_tb(
    );

    reg clk100 = 0;
    
    
    always #5 clk100 = ~clk100;
    
    reg data_in;
    reg [1:0] analyze_mode = 2'b11;
    reg signed [31:0] i_val, q_val;

    reg [7:0] i_bin_num = 8'd133, q_bin_num = 8'd255;
    reg [15:0] i_bin_width = 1, q_bin_width = 30;
    reg signed [15:0] i_min = 0, q_min = 0; 
    
    reg [15:0] count = 0;
    
    wire data_output_trigger;
    wire [79:0] output_channels;
    
   
    initial begin
        i_val = 32'b1111_1111_1111_1111_0000_0000_0000_0000;
        q_val = 32'b0000_0000_0000_0000_1111_1111_1111_1111;
        #2
        forever begin
            data_in = 1;
            #10;
            i_val = i_val  - 22;
            q_val = q_val + 30;
            data_in = 0;
            count = count + 1;   
            #500;
        end
    end
   
 
    analyze_fsm uut(.clk100(clk100), .system_reset(system_reset), .analyze_mode(analyze_mode), .num_data_pts(), // total number of points
                    .output_mode(), .data_in(data_in), .i_val(i_val), .q_val(q_val), .i_bin_num(i_bin_num), .q_bin_num(q_bin_num), // number of bins on each axis
                    .i_bin_width(i_bin_width), .q_bin_width(q_bin_width), .i_min(i_min), .q_min(q_min), .i_vec_perp(), .q_vec_perp(),
                    .i_pt_line(), .q_pt_line(), .data_output_trigger(data_output_trigger), .output_channels(output_channels));

endmodule
