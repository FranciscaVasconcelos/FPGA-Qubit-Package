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


module classify_count_tb(
    );

    reg clk100 = 0;
    
    /*initial begin
        forever begin
            clk100 = ~clk100;
            #10;
        end
    end*/
    
    always #10 clk100 = ~clk100;
    
    reg reset = 0;
    reg data_in = 0;
    reg [1:0] state = 2'b00;
    
    wire [15:0] excited_count, ground_count, line_count;
    
    initial begin
        #2
        forever begin
            reset = 0;
            data_in = 1;
            state = 2'b11;
            #20;
            data_in = 0;
            #20;
            data_in = 1;
            state = 2'b01;
            #20;
            data_in = 0;
            #20;
            data_in = 1;
            state = 2'b10;
            #20;
            data_in = 0;
            #20;
            reset = 1;
            #40;
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
 
    classify_count bin(.clk100(clk100), .reset(reset),.data_in(data_in), .state(state),
                       .excited_count(excited_count), .ground_count(ground_count), .line_count(line_count));

endmodule
