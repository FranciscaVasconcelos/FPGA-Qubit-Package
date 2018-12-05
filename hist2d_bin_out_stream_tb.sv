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


module hist2d_bin_out_stream_tb(
    );

    reg clk100 = 0;
    
    
    always #10 clk100 = ~clk100;
    
    reg data_in = 0;
    reg [7:0] i_bin_coord = 0, q_bin_coord = 0;
    
                       
    reg start_data_out = 0;             
                                      
    // static input                   
    reg [15:0] num_data_pts = 5;
    reg [7:0] i_bin_num = 10, q_bin_num = 10; 
                                      
    wire data_out;
    wire [15:0] bin_val;       
    wire [7:0] i_bin_out, q_bin_out;
    
    reg [10:0] count = 0;
    
    initial begin
        #2
        while(count < 4) begin
            data_in = 1;
            #20;
            data_in = 0;
            i_bin_coord = i_bin_coord + 2;
            q_bin_coord = q_bin_coord + 1;
            #100;
            count = count + 1;
        end
        start_data_out =  1;
        #20;
        forever begin
            start_data_out =  0;
            #20;
        end
    end
    
    hist2d_store_bin hist(.clk100(clk100),.data_in(data_in),.i_bin_coord(i_bin_coord), .q_bin_coord(q_bin_coord),
                          .i_bin_num(i_bin_num), .q_bin_num(q_bin_num));
   
 
    hist2d_bin_out_stream stream(.clk100(clk100), .start_data_out(start_data_out), .num_data_pts(num_data_pts), 
                                 .i_bin_num(i_bin_num), .q_bin_num(q_bin_num), .data_out(data_out), 
                                 .bin_val(bin_val), .i_bin_out(i_bin_out), .q_bin_out(q_bin_out));

endmodule
