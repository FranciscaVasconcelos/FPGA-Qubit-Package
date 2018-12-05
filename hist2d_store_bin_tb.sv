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
                  
    wire [15:0] mem_read_val;  
    wire [15:0] store_mem_address;  
    wire store_mem_write;           
    wire store_mem_reset;           
    wire [15:0] store_mem_write_val;

    initial begin
        #2
        forever begin
            data_in = 1;
            #20;
            data_in = 0;
            #100;
        end
    end
 
     hist2d_store_bin store_vals(.clk100(clk100),.data_in(data_in),.i_bin_coord(i_bin_coord), .q_bin_coord(q_bin_coord),
                                         .i_bin_num(i_bin_num), .q_bin_num(q_bin_num), .mem_read_val(mem_read_val), .mem_address(store_mem_address),
                                         .mem_write(store_mem_write), .mem_reset(store_mem_reset), .mem_write_val(store_mem_write_val));
 
     hist2d_bram hist_memory(.clk100(clk100), .address(store_mem_address), .write(store_mem_write), .reset(store_mem_reset), .write_val(store_mem_write_val), .read_val(mem_read_val), .extended_read_val());

endmodule
