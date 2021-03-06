////////////////////////////////////////////////////////////////////////////////
// Demod block version v2
// Author: Megan Yamoah and Francisca Vasconcelos
// Date: 11/12/2018
////////////////////////////////////////////////////////////////////////////////

module demod_main(
    // general inputs
    input clk, rst,
    
    // PcPort
    input [13:0] MEM_sdi_mem_S_address,
    input MEM_sdi_mem_S_rdEn, MEM_sdi_mem_S_wrEn,
    input [31:0] MEM_sdi_mem_S_wrData,
    output [31:0] MEM_sdi_mem_M_rdData,

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

    // Output 0
    output [15:0] data0_out_sdi_dataStreamFCx5_M_data_0,
    output [15:0] data0_out_sdi_dataStreamFCx5_M_data_1,
    output [15:0] data0_out_sdi_dataStreamFCx5_M_data_2,
    output [15:0] data0_out_sdi_dataStreamFCx5_M_data_3,
    output [15:0] data0_out_sdi_dataStreamFCx5_M_data_4,
    output data0_out_sdi_dataStreamFCx5_M_valid,

    // Output 1
    output [15:0] data1_out_sdi_dataStreamFCx5_M_data_0,
    output [15:0] data1_out_sdi_dataStreamFCx5_M_data_1,
    output [15:0] data1_out_sdi_dataStreamFCx5_M_data_2,
    output [15:0] data1_out_sdi_dataStreamFCx5_M_data_3,
    output [15:0] data1_out_sdi_dataStreamFCx5_M_data_4,
    output data1_out_sdi_dataStreamFCx5_M_valid,
    
    // Output 2
    output [15:0] data2_out_sdi_dataStreamFCx5_M_data_0,
    output [15:0] data2_out_sdi_dataStreamFCx5_M_data_1,
    output [15:0] data2_out_sdi_dataStreamFCx5_M_data_2,
    output [15:0] data2_out_sdi_dataStreamFCx5_M_data_3,
    output [15:0] data2_out_sdi_dataStreamFCx5_M_data_4,
    output data2_out_sdi_dataStreamFCx5_M_valid,

    // Output 3
    output [15:0] data3_out_sdi_dataStreamFCx5_M_data_0,
    output [15:0] data3_out_sdi_dataStreamFCx5_M_data_1,
    output [15:0] data3_out_sdi_dataStreamFCx5_M_data_2,
    output [15:0] data3_out_sdi_dataStreamFCx5_M_data_3,
    output [15:0] data3_out_sdi_dataStreamFCx5_M_data_4,
    output data3_out_sdi_dataStreamFCx5_M_valid,
    
    // Trigger out
    output [4:0] trigger3_out,
    output [4:0] trigger2_out

    );
    
    wire iq_valid;
    wire signed [31:0] i_val;
    wire signed [31:0] q_val;
    wire [1:0] analyze_mode;
    wire [15:0] num_data_pts;
    wire [15:0] i_bin_width, q_bin_width;
    wire [7:0] i_bin_num, q_bin_num;
    wire signed [15:0] i_bin_min, q_bin_min;
    wire signed [31:0] i_vec_perp, q_vec_perp;
    wire signed [31:0] i_pt_line, q_pt_line;
    wire output_mode;
    
    assign trigger2_out = {4'b0, iq_valid};
    
    // output Megan's I-, Q- data
    // make sure top modules are working
    assign data2_out_sdi_dataStreamFCx5_M_data_0 = 16'b0;
    assign data2_out_sdi_dataStreamFCx5_M_data_1 = q_val[15:0];
    assign data2_out_sdi_dataStreamFCx5_M_data_2 = q_val[31:16];
    assign data2_out_sdi_dataStreamFCx5_M_data_3 = i_val[15:0];
    assign data2_out_sdi_dataStreamFCx5_M_data_4 = i_val[31:16];
    assign data2_out_sdi_dataStreamFCx5_M_valid = 1;

    // set read data to zero; we'll never read config data from the FPGA
    assign MEM_sdi_mem_M_rdData = 32'b0;

    // output our processed data
    // this is what we're interested in!
    wire [79:0] analyze_fsm_output;
    assign data3_out_sdi_dataStreamFCx5_M_data_4 = analyze_fsm_output[79:64];
    assign data3_out_sdi_dataStreamFCx5_M_data_3 = analyze_fsm_output[63:48];
    assign data3_out_sdi_dataStreamFCx5_M_data_2 = analyze_fsm_output[47:32];
    assign data3_out_sdi_dataStreamFCx5_M_data_1 = analyze_fsm_output[31:16];
    assign data3_out_sdi_dataStreamFCx5_M_data_0 = analyze_fsm_output[15:0];
    assign data3_out_sdi_dataStreamFCx5_M_valid = 1;
    

    wire [129:0] sin_theta;
    wire [129:0] cos_theta;
    
    // output DDS signal to ensure DDS working
    assign data0_out_sdi_dataStreamFCx5_M_valid = 1;
    assign data1_out_sdi_dataStreamFCx5_M_valid = 1;
    assign data0_out_sdi_dataStreamFCx5_M_data_0 = sin_theta[25:10];
    assign data0_out_sdi_dataStreamFCx5_M_data_1 = sin_theta[51:36];
    assign data0_out_sdi_dataStreamFCx5_M_data_2 = sin_theta[77:62];
    assign data0_out_sdi_dataStreamFCx5_M_data_3 = sin_theta[103:88];
    assign data0_out_sdi_dataStreamFCx5_M_data_4 = sin_theta[129:114];

    assign data1_out_sdi_dataStreamFCx5_M_data_0 = cos_theta[25:10];
    assign data1_out_sdi_dataStreamFCx5_M_data_1 = cos_theta[51:36];
    assign data1_out_sdi_dataStreamFCx5_M_data_2 = cos_theta[77:62];
    assign data1_out_sdi_dataStreamFCx5_M_data_3 = cos_theta[103:88];
    assign data1_out_sdi_dataStreamFCx5_M_data_4 = cos_theta[129:114];
    
    top_main tm(
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
        .num_data_pts(num_data_pts),
        .i_bin_width(i_bin_width), .q_bin_width(q_bin_width),
        .i_bin_num(i_bin_num), .q_bin_num(q_bin_num),
        .i_bin_min(i_bin_min), .q_bin_min(q_bin_min),
        .i_vec_perp(i_vec_perp), .q_vec_perp(q_vec_perp),
        .i_pt_line(i_pt_line), .q_pt_line(q_pt_line),
        .output_mode(output_mode),
        .sin_theta(sin_theta), .cos_theta(cos_theta));

    analyze_fsm analyze_module(
          
        .clk100(clk), .system_reset(rst),
        
        //config params
        .analyze_mode(analyze_mode), // fsm state
        .num_data_pts(num_data_pts), // total number of points
        .output_mode(output_mode), // stream or no stream? 
        
        // i-q data parameters
        .data_in(iq_valid),
        .i_val(i_val), .q_val(q_val),
    
        // histogram inputs 
        .i_bin_num(i_bin_num), .q_bin_num(q_bin_num), // number of bins on each axis
        .i_bin_width(i_bin_width), .q_bin_width(q_bin_width), // bin width on each axis
        .i_min(i_bin_min), .q_min(q_bin_min), // origin pt of 0,0 bin
    
        // classification inputs
        .i_vec_perp(i_vec_perp), .q_vec_perp(q_vec_perp),
        .i_pt_line(i_pt_line), .q_pt_line(q_pt_line), 
    
        // output data
        .data_output_trigger(trigger3_out),
        .output_channels(analyze_fsm_output));

endmodule // demod_top
