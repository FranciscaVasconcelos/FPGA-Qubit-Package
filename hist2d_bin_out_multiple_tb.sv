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


module hist2d_bin_out_multiple_tb(
    );

    reg clk100 = 0;
    
    always #10 clk100 = ~clk100;
    
    reg data_in = 0;
    reg [7:0] i_bin_coord = 0, q_bin_coord = 0;
    
                       
    reg start_data_out = 0;             
                                      
    // static input                   
    reg [15:0] num_data_pts = 5;
    reg [7:0] i_bin_num = 10, q_bin_num = 10; 
                                      
    wire stream_data_out;
    wire [15:0] bin_val;       
    wire [7:0] i_bin_out, q_bin_out;
         
    reg [15:0] stream_mem_read_val=0;  
    wire [15:0] stream_mem_address;  
    wire stream_mem_write;           
    wire stream_mem_reset;           
    wire [15:0] stream_mem_write_val;

    reg [15:0] store_mem_read_val;  
    wire [15:0] store_mem_address;  
    wire store_mem_write;           
    wire store_mem_reset;           
    wire [15:0] store_mem_write_val;
    
    wire [15:0] mem_read_val;  
    reg [15:0] mem_address=0;  
    reg mem_write=0;           
    reg mem_reset=0;           
    reg [15:0] mem_write_val=0;
    
    reg [10:0] count = 0;
    
    initial begin
        #2
        mem_reset = 1;
        #20;
        mem_reset = 0;
        #20;
        assign mem_address = store_mem_address;
        assign mem_write = store_mem_write;
        assign mem_reset = store_mem_reset;
        assign mem_write_val = store_mem_write_val;
        assign store_mem_read_val = mem_read_val;
        #20;
        
        while(count < num_data_pts) begin
            
            data_in = 1;
            #20;
            data_in = 0;
            i_bin_coord = i_bin_coord + 1;
            q_bin_coord = q_bin_coord + 1;
            #100;
            count = count + 1;
        end
        
        assign mem_address = stream_mem_address;
        assign mem_write = stream_mem_write;
        assign mem_reset = stream_mem_reset;
        assign mem_write_val = stream_mem_write_val;
        assign stream_mem_read_val = mem_read_val;
        start_data_out =  1;
        #20;
        forever begin
            start_data_out =  0;
            #100;
        end
    end
    
    hist2d_store_bin store_vals(.clk100(clk100),.data_in(data_in),.i_bin_coord(i_bin_coord), .q_bin_coord(q_bin_coord),
                                     .i_bin_num(i_bin_num), .q_bin_num(q_bin_num), .mem_read_val(store_mem_read_val), .mem_address(store_mem_address),
                                     .mem_write(store_mem_write), .mem_reset(store_mem_reset), .mem_write_val(store_mem_write_val));
   
 
    hist2d_bin_out_stream stream(.clk100(clk100), .start_data_out(start_data_out), .num_data_pts(num_data_pts), 
                                   .i_bin_num(i_bin_num), .q_bin_num(q_bin_num), .data_out(stream_data_out), 
                                   .bin_val(bin_val), .i_bin_out(i_bin_out), .q_bin_out(q_bin_out),
                                   .mem_read_val(stream_mem_read_val), .mem_address(stream_mem_address), .mem_write(stream_mem_write), 
                                   .mem_reset(stream_mem_reset), .mem_write_val(stream_mem_write_val));
                                   
     hist2d_bram hist_memory(.clk100(clk100), .address(mem_address), .write(mem_write), .reset(mem_reset), .write_val(mem_write_val), .read_val(mem_read_val), .extended_read_val(extended_read_val));

endmodule
