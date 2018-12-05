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


module hist2d_store_bin_tb(
    );

    reg clk100 = 0;
    
    always #10 clk100 = ~clk100;
    
    reg data_in = 0;
    reg [7:0] i_bin_coord = 0, q_bin_coord = 0;

    reg [7:0] i_bin_num=0, q_bin_num=0; 

    initial begin
        #2
        forever begin
            data_in = 1;
            #20;
            data_in = 0;
            #100;
        end
    end
   
 
    hist2d_store_bin hist(.clk100(clk100),.data_in(data_in),.i_bin_coord(i_bin_coord), .q_bin_coord(q_bin_coord),
                          .i_bin_num(i_bin_num), .q_bin_num(q_bin_num));

endmodule
