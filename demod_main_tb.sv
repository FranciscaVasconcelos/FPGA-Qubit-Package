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


module demod_main_tb(
    );

    reg clk100 = 0;
    reg reset = 0;
    
    always #5 clk100 = ~clk100;
    
    
    reg [13:0] MEM_sdi_mem_S_address = 0;
    reg MEM_sdi_mem_S_rdEn, MEM_sdi_mem_S_wrEn = 0;
    reg [32:0] MEM_sdi_mem_S_wrData = 0;
    reg [32:0] MEM_sdi_mem_M_rdData = 0;
    
    // hvi_port interface
    reg [9:0] HVI_sdi_mem_S_address = 0;
    reg HVI_sdi_mem_S_rdEn, HVI_sdi_mem_S_wrEn = 0;
    reg [31:0] HVI_sdi_mem_S_wrData = 0;
    wire [31:0] HVI_sdi_mem_M_rdData = 0;
    
    // Trigger in
    reg [4:0] trigger_in = 0;
    
    // Input 0
    reg signed [15:0] data0_in_sdi_dataStreamFCx5_S_data_0 = 0;
    reg signed [15:0] data0_in_sdi_dataStreamFCx5_S_data_1 = 0;
    reg signed [15:0] data0_in_sdi_dataStreamFCx5_S_data_2 = 0;
    reg signed [15:0] data0_in_sdi_dataStreamFCx5_S_data_3 = 0;
    reg signed [15:0] data0_in_sdi_dataStreamFCx5_S_data_4 = 0;
    wire data0_in_sdi_dataStreamFCx5_S_valid;
    
    // Input 1
    reg signed [15:0] data1_in_sdi_dataStreamFCx5_S_data_0 = 0;
    reg signed [15:0] data1_in_sdi_dataStreamFCx5_S_data_1 = 0;
    reg signed [15:0] data1_in_sdi_dataStreamFCx5_S_data_2 = 0;
    reg signed [15:0] data1_in_sdi_dataStreamFCx5_S_data_3 = 0;
    reg signed [15:0] data1_in_sdi_dataStreamFCx5_S_data_4 = 0;
    reg data1_in_sdi_dataStreamFCx5_S_valid;
    
    // Output 3
    wire [15:0] d30, d20, d10, d00;
    wire [15:0] d31, d21, d11, d01;
    wire [15:0] d32, d22, d12, d02;
    wire [15:0] d33, d23, d13, d03;
    wire [15:0] d34, d24, d14, d04;
    wire dv3, dv2, dv1, dv0;
    
    wire [5:0]
    
    
    

    reg [15:0] count = 0;
    
   
    initial begin
        #2;
        reset = 1;
        #10;
        reset = 0;
        #10;
        while(count < 10) begin
            trigger_in = 1;
            #10;
            trigger_in = 0;
            #200;
            data0_in_sdi_dataStreamFCx5_S_data_0 = data0_in_sdi_dataStreamFCx5_S_data_0 + 1;
            data0_in_sdi_dataStreamFCx5_S_data_1 = data0_in_sdi_dataStreamFCx5_S_data_1 + 1;
            data0_in_sdi_dataStreamFCx5_S_data_2 = data0_in_sdi_dataStreamFCx5_S_data_2 + 1;
            data0_in_sdi_dataStreamFCx5_S_data_3 = data0_in_sdi_dataStreamFCx5_S_data_3 + 1;
            data0_in_sdi_dataStreamFCx5_S_data_4 = data0_in_sdi_dataStreamFCx5_S_data_4 + 1;
            
            data1_in_sdi_dataStreamFCx5_S_data_0 = data1_in_sdi_dataStreamFCx5_S_data_0 + 1;
            data1_in_sdi_dataStreamFCx5_S_data_1 = data1_in_sdi_dataStreamFCx5_S_data_1 + 1;
            data1_in_sdi_dataStreamFCx5_S_data_2 = data1_in_sdi_dataStreamFCx5_S_data_2 + 1;
            data1_in_sdi_dataStreamFCx5_S_data_3 = data1_in_sdi_dataStreamFCx5_S_data_3 + 1;
            data1_in_sdi_dataStreamFCx5_S_data_4 = data1_in_sdi_dataStreamFCx5_S_data_4 + 1;
            count = count + 1;
            #200;
        end
    end
   
               
    demod_main fpga_package(.clk(clk100), .rst(reset),
                   // PcPort
                   .MEM_sdi_mem_S_address(MEM_sdi_mem_S_address),
                   .MEM_sdi_mem_S_rdEn(MEM_sdi_mem_S_rdEn), .MEM_sdi_mem_S_wrEn(MEM_sdi_mem_S_wrEn),
                   .MEM_sdi_mem_S_wrData(MEM_sdi_mem_S_wrData),
                   .MEM_sdi_mem_M_rdData(MEM_sdi_mem_M_rdData),
               
                   // hvi_port interface
                   .HVI_sdi_mem_S_address(HVI_sdi_mem_S_address),
                   .HVI_sdi_mem_S_rdEn(HVI_sdi_mem_S_rdEn), .HVI_sdi_mem_S_wrEn(HVI_sdi_mem_S_wrEn),
                   .HVI_sdi_mem_S_wrData(HVI_sdi_mem_S_wrData),
                   .HVI_sdi_mem_M_rdData(HVI_sdi_mem_M_rdData),
               
                   // Trigger in
                   .trigger_in(trigger_in),
               
                   // Input 0
                   .data0_in_sdi_dataStreamFCx5_S_data_0(data0_in_sdi_dataStreamFCx5_S_data_0),
                   .data0_in_sdi_dataStreamFCx5_S_data_1(data0_in_sdi_dataStreamFCx5_S_data_1),
                   .data0_in_sdi_dataStreamFCx5_S_data_2(data0_in_sdi_dataStreamFCx5_S_data_2),
                   .data0_in_sdi_dataStreamFCx5_S_data_3(data0_in_sdi_dataStreamFCx5_S_data_3),
                   .data0_in_sdi_dataStreamFCx5_S_data_4(data0_in_sdi_dataStreamFCx5_S_data_4),
                   .data0_in_sdi_dataStreamFCx5_S_valid(1),
               
                   // Input 1
                   .data1_in_sdi_dataStreamFCx5_S_data_0(data1_in_sdi_dataStreamFCx5_S_data_0),
                   .data1_in_sdi_dataStreamFCx5_S_data_1(data1_in_sdi_dataStreamFCx5_S_data_1),
                   .data1_in_sdi_dataStreamFCx5_S_data_2(data1_in_sdi_dataStreamFCx5_S_data_2),
                   .data1_in_sdi_dataStreamFCx5_S_data_3(data1_in_sdi_dataStreamFCx5_S_data_3),
                   .data1_in_sdi_dataStreamFCx5_S_data_4(data1_in_sdi_dataStreamFCx5_S_data_4),
                   .data1_in_sdi_dataStreamFCx5_S_valid(1),
               
                   // Output 0
                   .data0_out_sdi_dataStreamFCx5_M_data_0(d00),
                  .data0_out_sdi_dataStreamFCx5_M_data_1(d01),
                  .data0_out_sdi_dataStreamFCx5_M_data_2(d02),
                  .data0_out_sdi_dataStreamFCx5_M_data_3(d03),
                  .data0_out_sdi_dataStreamFCx5_M_data_4(d04),
                  .data0_out_sdi_dataStreamFCx5_M_valid(d0v),
               
                   // Output 1
                   .data1_out_sdi_dataStreamFCx5_M_data_0(d10),
                  .data1_out_sdi_dataStreamFCx5_M_data_1(d11),
                  .data1_out_sdi_dataStreamFCx5_M_data_2(d12),
                  .data1_out_sdi_dataStreamFCx5_M_data_3(d13),
                  .data1_out_sdi_dataStreamFCx5_M_data_4(d14),
                  .data1_out_sdi_dataStreamFCx5_M_valid(d1v),
                   
                   // Output 2
                   .data2_out_sdi_dataStreamFCx5_M_data_0(d20),
                  .data2_out_sdi_dataStreamFCx5_M_data_1(d21),
                  .data2_out_sdi_dataStreamFCx5_M_data_2(d22),
                  .data2_out_sdi_dataStreamFCx5_M_data_3(d23),
                  .data2_out_sdi_dataStreamFCx5_M_data_4(d24),
                  .data2_out_sdi_dataStreamFCx5_M_valid(d2v),
               
                   // Output 3
                   .data3_out_sdi_dataStreamFCx5_M_data_0(d30),
                   .data3_out_sdi_dataStreamFCx5_M_data_1(d31),
                   .data3_out_sdi_dataStreamFCx5_M_data_2(d32),
                   .data3_out_sdi_dataStreamFCx5_M_data_3(d33),
                   .data3_out_sdi_dataStreamFCx5_M_data_4(d34),
                   .data3_out_sdi_dataStreamFCx5_M_valid(d3v),
                   
                   // Trigger out
                   .trigger3_out(t3),
                   .trigger2_out(t2)            
                   );

endmodule
