`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/04/2018 05:08:17 PM
// Design Name: 
// Module Name: dds_tb
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


module dds_tb(

    );
    
    reg clk100 = 0;
        
    initial begin
        forever begin
            clk100 = ~clk100;
            #5;
        end
    end
    
     wire [7:0] phase_vals = 8'd20;
     
     wire phase_valid = 1;
     wire error;
     wire data_valid;
     
     wire signed [25:0] sin_theta;
     wire signed [25:0] cos_theta;
     wire signed [63:0] sin_cos;
     
     assign sin_theta = sin_cos[57:32];
     assign cos_theta = sin_cos[25:0];

    
     dds_compiler_0 uut(.aclk(clk100), .s_axis_phase_tvalid(phase_valid),
            .s_axis_phase_tdata(phase_vals),
            .m_axis_data_tvalid(data_valid), .m_axis_data_tdata(sin_cos),
            .event_phase_in_invalid(error));
            
            
            
            
endmodule
