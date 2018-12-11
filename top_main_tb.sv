`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/03/2018 09:56:35 AM
// Design Name: 
// Module Name: top_main_tb
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


module top_main_tb(
    );

    reg clk100 = 0;
    initial begin
        forever begin
            clk100 = ~clk100;
            #5;
        end
    end
    
    reg reset = 0;
    reg config_reset = 0;
    reg trigger = 0;
    wire signed [4:0] [15:0] data_i_in;
    wire signed [4:0] [15:0] data_q_in;
    reg [4:0] [5:0] phase = {6'd4,6'd3,6'd2,6'd1,6'd0};
    
    wire signed [4:0] [25:0] sin_theta;
    wire signed [4:0] [25:0] cos_theta;
    wire [4:0] [63:0] sin_cos;
    
    genvar g;
    generate
        for (g = 0; g < 5; g = g + 1) begin
            assign sin_theta[g] = sin_cos[g][57:32];
            assign cos_theta[g] = sin_cos[g][25:0];
        end
    endgenerate
    
    
    wire phase_valid = 1;
    wire error0;
    wire error1;
    wire error2;
    wire error3;
    wire error4;
    wire data_valid0;
    wire data_valid1;
    wire data_valid2;
    wire data_valid3;
    wire data_valid4;
    
    dds_compiler_0 dds1(.aclk(clk100), .s_axis_phase_tvalid(phase_valid),
        .s_axis_phase_tdata(phase[0]),
        .m_axis_data_tvalid(data_valid0), .m_axis_data_tdata(sin_cos[0]),
        .event_phase_in_invalid(error0));
    dds_compiler_0 dds2(.aclk(clk100), .s_axis_phase_tvalid(phase_valid),
        .s_axis_phase_tdata(phase[1]),
        .m_axis_data_tvalid(data_valid1), .m_axis_data_tdata(sin_cos[1]),
        .event_phase_in_invalid(error1));
    dds_compiler_0 dds3(.aclk(clk100), .s_axis_phase_tvalid(phase_valid),
        .s_axis_phase_tdata(phase[2]),
        .m_axis_data_tvalid(data_valid2), .m_axis_data_tdata(sin_cos[2]),
        .event_phase_in_invalid(error2));
    dds_compiler_0 dds4(.aclk(clk100), .s_axis_phase_tvalid(phase_valid),
        .s_axis_phase_tdata(phase[3]),
        .m_axis_data_tvalid(data_valid3), .m_axis_data_tdata(sin_cos[3]),
        .event_phase_in_invalid(error3));
    dds_compiler_0 dds5(.aclk(clk100), .s_axis_phase_tvalid(phase_valid),
        .s_axis_phase_tdata(phase[4]),
        .m_axis_data_tvalid(data_valid4), .m_axis_data_tdata(sin_cos[4]),
        .event_phase_in_invalid(error4));
    
    
    genvar k;
    generate
        for (k = 0; k < 5; k = k + 1) begin
            assign data_i_in[k] = sin_cos[k][57:42];
            assign data_q_in[k] = sin_cos[k][25:10];
        end
    endgenerate

    integer j;
    wire iq_valid;
    
    initial begin
        #1;
        reset = 1;
        #10;
        reset = 0;
        forever begin
            #10;
            if (iq_valid) begin
                #20;
                trigger = 1;
                #10;
                trigger = 0;
            end
            for (j = 0; j < 5; j = j + 1) begin
                if (phase[j] < 45)
                    phase[j] = phase[j] + 5;
                else
                    phase[j] = phase[j] + 5 - 50;
            end
        end
    end

    initial begin
        #11;
        config_reset = 1;
        #10;
        config_reset = 0;
        #20;
        trigger = 1;
        #10;
        trigger = 0;
    end
            
    wire [31:0] i_val;
    wire [31:0] q_val;
    wire [1:0] analyze_mode;
    wire [15:0] x_bin_width;
    wire [15:0] y_bin_width;
    wire [4:0] x_bin_num;
    wire [4:0] y_bin_num;
    wire signed [15:0] x_bin_min;
    wire signed [15:0] y_bin_min;
    
        
    top_main #(
        .DEMOD_FREQ(5),
        .SAMPLE_LENGTH(200),
        .SAMPLE_FREQ(5),
        .DELAY_TIME(50),
        .ANALYZE_MODE(0),
        .X_BIN_WIDTH(100),
        .Y_BIN_WIDTH(100),
        .X_BIN_NUM(10),
        .Y_BIN_NUM(10),
        .X_BIN_MIN(0),
        .Y_BIN_MIN(0))
        uut(
        // inputs
        .clk100(clk100), .reset(reset),
        // I input values
        .data0_in_0(data_i_in[0]),
        .data0_in_1(data_i_in[1]),
        .data0_in_2(data_i_in[2]),
        .data0_in_3(data_i_in[3]),
        .data0_in_4(data_i_in[4]),
        // Q input values
        .data1_in_0(data_q_in[0]),
        .data1_in_1(data_q_in[1]),
        .data1_in_2(data_q_in[2]),
        .data1_in_3(data_q_in[3]),
        .data1_in_4(data_q_in[4]),
        .trigger(trigger),
        
        //outputs
        .iq_valid(iq_valid),
        .i_val(i_val), .q_val(q_val),
        // configurated prameters to pass to lower modules
        .analyze_mode(analyze_mode),
        .i_bin_width(x_bin_width), .q_bin_width(y_bin_width),
        .i_bin_num(x_bin_num), .q_bin_num(y_bin_num),
        .i_bin_min(x_bin_min), .q_bin_min(y_bin_min));

endmodule
