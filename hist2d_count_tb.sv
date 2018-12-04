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


module hist2d_count_tb(
    );

    reg clk100 = 0;
    
    always #10 clk100 = ~clk100;
    
    reg data_in;
    reg [7:0] i_bin_coord;
    reg [7:0] q_bin_coord;
    reg [15:0] num_data_pts = 16'd10;
    reg [11:0] i_bin_num = 12'd10;
    reg [11:0] q_bin_num = 12'd10;
    
    reg [15:0] count = 0;
    
    wire data_out;
    wire [15:0] bin_val;
    wire [7:0] i_bin_out;
    wire [7:0] q_bin_out;
    
    initial begin
        i_bin_coord = 255;
        q_bin_coord = 255;
        #2
        while(count < num_data_pts) begin
            data_in = 1;
            #20;
            //i_bin_coord = i_bin_coord + 1;
            //q_bin_coord = q_bin_coord + 1;
            data_in = 0;
            #40;
            count=count+1;
        end
        //i_bin_coord = 8'd255;
        //q_bin_coord = 8'd255;
        //data_in = 1;
        //#20;
        //data_in = 0;
        //#40;
        //count=count+1;
    end
 
    hist2d_count uut(.clk100(clk100), .data_in(data_in), .i_bin_coord(i_bin_coord), .q_bin_coord(q_bin_coord), 
                     .num_data_pts(num_data_pts), .i_bin_num(i_bin_num), .q_bin_num(q_bin_num), 
                     .data_out(data_out), .bin_val(bin_val), .i_bin_out(i_bin_out), .q_bin_out(q_bin_out));

endmodule
