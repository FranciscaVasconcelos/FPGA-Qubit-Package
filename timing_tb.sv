`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/03/2018 04:46:41 AM
// Design Name: 
// Module Name: timing_tb
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


module timing_tb(
    );

    reg clk100 = 0;
    
    initial begin
        forever begin
            clk100 = ~clk100;
            #5;
        end
    end
    
    wire reset = 0;
    reg trigger = 0;
    wire [13:0] delay_time = 14'd5; // 50 us
    
    initial begin
        #21;
        trigger = 1;
        #10;
        trigger = 0;
    end
        
    wire start_collect;
    
    
    timing uut(
        // inputs
        .clk100(clk100), .reset(reset), .trigger(trigger),
        .delay(delay_time),
        // ouputs
        .start_collect(start_collect));

endmodule
