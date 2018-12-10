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


module hist2d_pt_to_bin_tb(
    );

    reg clk100 = 0;
    
    
    always #5 clk100 = ~clk100;
    
    // dynamic input
    reg data_in;
    reg analyze_mode = 2'b11;
    reg signed [31:0] i_val, q_val;

    reg [7:0] i_bin_num = 8'd133, q_bin_num = 8'd255;
    reg [15:0] i_bin_width = 1, q_bin_width = 30;
    reg signed [15:0] i_min = 0, q_min = 0;
    
    wire i_q_found;
    wire [7:0] i_bin_coord;
    wire [7:0] q_bin_coord;  
    
    reg [15:0] count = 0;
    
   
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
   
 
    hist2d_pt_to_bin uut(.clk100(clk100), .system_reset(1'b0), .data_in(data_in), .i_val(i_val), .q_val(q_val), .i_bin_num(i_bin_num), .q_bin_num(q_bin_num),
               .i_bin_width(i_bin_width), .q_bin_width(q_bin_width), .i_min(i_min), .q_min(q_min), 
               .i_q_found_out(i_q_found), .i_bin_coord_out(i_bin_coord), .q_bin_coord_out(q_bin_coord));

endmodule
