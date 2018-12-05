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


module hist2d_master_tb(
    );

    reg clk100 = 0;
    
    
    always #10 clk100 = ~clk100;
    
    // dynamic input
    reg data_in;
    reg signed [31:0] i_val, q_val;

    reg [7:0] i_bin_num = 10, q_bin_num = 10;
    reg [15:0] i_bin_width = 1, q_bin_width = 1;
    reg signed [15:0] i_min = 0, q_min = 0;
    reg [15:0] num_data_pts = 5;
    reg stream_mode = 0;
    
    wire i_q_found;
    wire bin_found;
    wire [7:0] i_bin_coord;
    wire [7:0] q_bin_coord; 
    wire [15:0] bin_val; 
    
    reg [15:0] count = 0;
    
   
    initial begin
        i_val = -32'd3;
        q_val = -32'd3;
        #2
        while(count < num_data_pts) begin
            data_in = 1;
            #20;
            i_val = i_val + 1;
            q_val = q_val + 1;
            data_in = 0;
            count = count + 1;   
            #300;
        end
    end
   
 
    hist2d uut(.clk100(clk100), .data_in(data_in), .i_val(i_val), .q_val(q_val), .i_bin_num(i_bin_num), .q_bin_num(q_bin_num),
               .i_bin_width(i_bin_width), .q_bin_width(q_bin_width), .i_min(i_min), .q_min(q_min), .num_data_pts(num_data_pts),
               .stream_mode(stream_mode), .i_q_found(i_q_found), .bin_found(bin_found), .i_bin_coord(i_bin_coord), 
               .q_bin_coord(q_bin_coord), .bin_val(bin_val));

endmodule
