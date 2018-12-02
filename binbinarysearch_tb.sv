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


module binbinarysearch_tb(
    );

    reg clk100 = 0;
    
    always #10 clk100 = ~clk100;
    
    reg data_in = 0;
    
    reg signed [31:0] value = -32'd5;
    reg [5:0] num_bins = 6'd3;
    reg [15:0] bin_width = 16'd10;
    
    reg signed [15:0] origin = -16'd3; 
    
    wire binned;
    wire [5:0] bin_val;
    
    initial begin
        #2
        forever begin
            data_in = 1;
            #20;
            value = value + 2;
            data_in = 0;
            #20;
        end
    end
   
    
    /*always @(posedge clk100) begin 
        if(data_in == 1) data_in <= 0;
        
        if(counter== 7'd100) begin 
            data_in = 1;
            i_val = i_val + 1;
            q_val = q_val + 1;
            counter <= 7'd0;
        end
        else counter <= counter + 1;
    end*/
 
    bin_binary_search uut(.clk100(clk100), .data_in(data_in), .value(value), .num_bins(num_bins), .bin_width(bin_width), .origin(origin), .binned(binned), .current(bin_val));

endmodule
