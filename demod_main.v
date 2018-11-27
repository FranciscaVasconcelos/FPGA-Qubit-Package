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

endmodule // demod_top