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


module hist2d_tb(
    );

    reg clk100 = 0;
    
    /*initial begin
        forever begin
            clk100 = ~clk100;
            #10;
        end
    end*/
    
    always #10 clk100 = ~clk100;
    
    wire signed [31:0] i_pt_line = 32'd0;
    wire signed [31:0] q_pt_line = 32'd2;
    
    wire signed [31:0] i_vec_perp = 32'd0;
    wire signed [31:0] q_vec_perp = 32'd1;
    
    reg data_in = 0;
    reg signed [31:0] i_val = 32'd0; 
    reg signed [31:0] q_val = 32'd0;
    
    reg [6:0] counter = 7'd90;
    
    wire [1:0] output_state;
    wire valid_output;
    
    initial begin
        i_val = -32'd3;
        q_val = -32'd3;
        #2
        forever begin
            data_in = 1;
            #20;
            i_val = i_val + 1;
            q_val = q_val + 1;
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
 
    classify uut(.clk100(clk100), .data_in(data_in), .i_val(i_val), .q_val(q_val), .i_pt_line(i_pt_line), .q_pt_line(q_pt_line), 
                 .i_vec_perp(i_vec_perp), .q_vec_perp(q_vec_perp), .state(output_state), .valid_output(valid_output));

endmodule
