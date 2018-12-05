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


module classify_master_tb(
    );

    reg clk100 = 0;
    
    always #10 clk100 = ~clk100;
    
    reg [15:0] num_data_pts = 16'd10;
    
    reg data_in = 0;
    reg signed [31:0] i_val = -32'd3, q_val = -32'd3;
    
    reg stream_mode = 1;
    
    reg signed [31:0] i_pt_line=0, q_pt_line=0;
    
    reg signed [31:0] i_vec_perp=32'd1, q_vec_perp=32'd1;
    
    wire [127:0] fpga_output;
    
    initial begin
        #2
        forever begin
            data_in = 1;
            #20;
            i_val = i_val + 1;
            q_val = q_val + 1;
            data_in = 0;
            #100;
        end
    end
   
 
    classify_master uut(.clk100(clk100), .num_data_pts(num_data_pts), .data_in(data_in), .i_val(i_val), 
                        .q_val(q_val), .stream_mode(stream_mode), .i_pt_line(i_pt_line), .q_pt_line(q_pt_line), 
                        .i_vec_perp(i_vec_perp), .q_vec_perp(q_vec_perp), .fpga_output(fpga_output));

endmodule
