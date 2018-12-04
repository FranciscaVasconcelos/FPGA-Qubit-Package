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


module hist2d_bram_tb(
    );

    reg clk100 = 0;
    
    
    always #10 clk100 = ~clk100;
    
    reg [15:0] address;
    reg write; 
    reg [15:0] write_val;
    wire [15:0] read_val;
    
    initial begin
        #2

        address = 0;
        write = 1;
        write_val = 0;
        #20;
        
        address = 1;
        write = 0;
        write_val = 1;
        #20;
        forever begin
            write = 1;
            address = address + 2;
            #20;
            write = 0;  
            address = address - 1;
            write_val = write_val + 1;
            #20;
        end
    end
   
    hist2d_bram uut(.clk100(clk100), .address(address), .write(write), .write_val(write_val), .read_val(read_val));

endmodule
