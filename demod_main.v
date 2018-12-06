////////////////////////////////////////////////////////////////////////////////
// Demod block version v2
// Author: Megan Yamoah and Francisca Vasconcelos
// Date: 19/11/2018
////////////////////////////////////////////////////////////////////////////////

module demod_main(
    // general inputs
    input clk, clk200, rst,

    // PcPort
    input [13:0] MEM_sdi_mem_S_address,
    input MEM_sdi_mem_S_rdEn, MEM_sdi_mem_S_wrEn,
    input [32:0] MEM_sdi_mem_S_wrData,
    output [32:0] MEM_sdi_mem_M_rdData,

    // hvi_port interface
    input [9:0] HVI_sdi_mem_S_address,
    input HVI_sdi_mem_S_rdEn, HVI_sdi_mem_S_wrEn,
    input [31:0] HVI_sdi_mem_S_wrData,
    output [31:0] HVI_sdi_mem_M_rdData,

    // Trigger in
    input [4:0] trigger_in,

    // Input 0
    input [15:0] data0_in_sdi_dataStreamFCx5_S_data_0,
    input [15:0] data0_in_sdi_dataStreamFCx5_S_data_1,
    input [15:0] data0_in_sdi_dataStreamFCx5_S_data_2,
    input [15:0] data0_in_sdi_dataStreamFCx5_S_data_3,
    input [15:0] data0_in_sdi_dataStreamFCx5_S_data_4,
    input data0_in_sdi_dataStreamFCx5_S_valid,

    // Input 1
    input [15:0] data1_in_sdi_dataStreamFCx5_S_data_0,
    input [15:0] data1_in_sdi_dataStreamFCx5_S_data_1,
    input [15:0] data1_in_sdi_dataStreamFCx5_S_data_2,
    input [15:0] data1_in_sdi_dataStreamFCx5_S_data_3,
    input [15:0] data1_in_sdi_dataStreamFCx5_S_data_4,
    input data1_in_sdi_dataStreamFCx5_S_valid,

    // Input 2
    input [15:0] data2_in_sdi_dataStreamFCx5_S_data_0,
    input [15:0] data2_in_sdi_dataStreamFCx5_S_data_1,
    input [15:0] data2_in_sdi_dataStreamFCx5_S_data_2,
    input [15:0] data2_in_sdi_dataStreamFCx5_S_data_3,
    input [15:0] data2_in_sdi_dataStreamFCx5_S_data_4,
    input data2_in_sdi_dataStreamFCx5_S_valid,

    // Input 3
    input [15:0] data3_in_sdi_dataStreamFCx5_S_data_0,
    input [15:0] data3_in_sdi_dataStreamFCx5_S_data_1,
    input [15:0] data3_in_sdi_dataStreamFCx5_S_data_2,
    input [15:0] data3_in_sdi_dataStreamFCx5_S_data_3,
    input [15:0] data3_in_sdi_dataStreamFCx5_S_data_4,
    input data3_in_sdi_dataStreamFCx5_S_valid,

    // Output 0
    output [15:0] data0_out_sdi_dataStreamFCx5_S_data_0,
    output [15:0] data0_out_sdi_dataStreamFCx5_S_data_1,
    output [15:0] data0_out_sdi_dataStreamFCx5_S_data_2,
    output [15:0] data0_out_sdi_dataStreamFCx5_S_data_3,
    output [15:0] data0_out_sdi_dataStreamFCx5_S_data_4,
    output data0_out_sdi_dataStreamFCx5_S_valid,

    // Output 1
    output [15:0] data1_out_sdi_dataStreamFCx5_S_data_0,
    output [15:0] data1_out_sdi_dataStreamFCx5_S_data_1,
    output [15:0] data1_out_sdi_dataStreamFCx5_S_data_2,
    output [15:0] data1_out_sdi_dataStreamFCx5_S_data_3,
    output [15:0] data1_out_sdi_dataStreamFCx5_S_data_4,
    output data1_out_sdi_dataStreamFCx5_S_valid,

    // Output 2
    output [15:0] data2_out_sdi_dataStreamFCx5_S_data_0,
    output [15:0] data2_out_sdi_dataStreamFCx5_S_data_1,
    output [15:0] data2_out_sdi_dataStreamFCx5_S_data_2,
    output [15:0] data2_out_sdi_dataStreamFCx5_S_data_3,
    output [15:0] data2_out_sdi_dataStreamFCx5_S_data_4,
    output data2_out_sdi_dataStreamFCx5_S_valid,

    // Output 3
    output [15:0] data3_out_sdi_dataStreamFCx5_S_data_0,
    output [15:0] data3_out_sdi_dataStreamFCx5_S_data_1,
    output [15:0] data3_out_sdi_dataStreamFCx5_S_data_2,
    output [15:0] data3_out_sdi_dataStreamFCx5_S_data_3,
    output [15:0] data3_out_sdi_dataStreamFCx5_S_data_4,
    output data3_out_sdi_dataStreamFCx5_S_valid,

    // Triggers out
    output [4:0] trigger0_out, trigger1_out, trigger2_out, trigger3_out

    );
    
    wire iq_valid;
    wire [31:0] i_val;
    wire [31:0] q_val;
    wire [1:0] analyze_mode;
    wire [15:0] i_bin_width, q_bin_width;
    wire [4:0] i_bin_num, q_bin_num;
    wire signed [15:0] i_bin_min, q_bin_min;
    wire signed [31:0] i_vec_perp, q_vec_perp;
    wire signed [31:0] i_pt_line, q_pt_line;
    wire output_mode;
    
    
    top_main top_module(
        // inputs
        .clk100(clk), .reset(rst),
        // config control
        .MEM_sdi_mem_S_address(MEM_sdi_mem_S_address),
        .MEM_sdi_mem_S_wrEn(MEM_sdi_mem_S_wrEn),
        .MEM_sdi_mem_S_wrData(MEM_sdi_mem_S_wrData),
        // I input values
        .data0_in_0(data0_in_sdi_dataStreamFCx5_S_data_0),
        .data0_in_1(data0_in_sdi_dataStreamFCx5_S_data_1),
        .data0_in_2(data0_in_sdi_dataStreamFCx5_S_data_2),
        .data0_in_3(data0_in_sdi_dataStreamFCx5_S_data_3),
        .data0_in_4(data0_in_sdi_dataStreamFCx5_S_data_4),
        // Q input values
        .data1_in_0(data1_in_sdi_dataStreamFCx5_S_data_0),
        .data1_in_1(data1_in_sdi_dataStreamFCx5_S_data_1),
        .data1_in_2(data1_in_sdi_dataStreamFCx5_S_data_2),
        .data1_in_3(data1_in_sdi_dataStreamFCx5_S_data_3),
        .data1_in_4(data1_in_sdi_dataStreamFCx5_S_data_4),
        .trigger(trigger_in[0]),
        
        //outputs
        .iq_valid(iq_valid),
        .i_val(i_val), .q_val(q_val),
        // configurated prameters to pass to lower modules
        .analyze_mode(analyze_mode),
        .x_bin_width(i_bin_width), .y_bin_width(q_bin_width),
        .x_bin_num(i_bin_num), .y_bin_num(q_bin_num),
        .x_bin_min(i_bin_min), .y_bin_min(q_bin_min),
        .i_vec_perp(i_vec_perp), .q_vec_perp(q_vec_perp),
        .i_pt_line(i_pt_line), .q_pt_line(q_pt_line),
        .output_mode(output_mode));

endmodule // demod_top