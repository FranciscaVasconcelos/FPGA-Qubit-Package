`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Top Modules version v1
// Author: Megan Yamoah
// Date: 28/11/2018
////////////////////////////////////////////////////////////////////////////////

module config_params(
    // inputs
    input clk100,
    input reset,
    // control inputs
    input [13:0] MEM_sdi_mem_S_address, // parameter location
    input MEM_sdi_mem_S_wrEn, // write enable
    input [32:0] MEM_sdi_mem_S_wrData, // parameter value

    // outputs
    output reg [4:0] demod_freq, // freq divided by 10 MHz
    output reg [15:0] num_data_pts, // total number of measurements
    output reg [9:0] [4:0] [5:0] demod_mod50_LUT, // LUT containing values for mod 50 updated for each value of demod_freq
    output reg [10:0] sample_length, // max 20 us
    output reg [5:0] sample_freq, // min 8 MHz
    output reg [13:0] delay_time, // max 163 us
    output reg [1:0] analyze_mode, // data dump, binning, classifier
    output reg [15:0] i_bin_width, q_bin_width, // width of bin in i, q_direction
    output reg [4:0] i_bin_num, q_bin_num, // number of bins along i, q_direction
    output reg signed [15:0] i_bin_min, q_bin_min, // start of bins i, q_direction
    output reg signed [31:0] i_vec_perp, q_vec_perp, // perpendicular classifier lines
    output reg signed [31:0] i_pt_line, q_pt_line,
    output output_mode);

    always @(posedge clk100) begin
        if (reset) begin // reset to default
            demod_freq <= 5'd5; // 50 MHz
            
            demod_mod50_LUT <= {{6'd45, 6'd40, 6'd35, 6'd30, 6'd25},
                                {6'd20, 6'd15, 6'd10, 6'd05, 6'd00},
                                {6'd45, 6'd40, 6'd35, 6'd30, 6'd25},
                                {6'd20, 6'd15, 6'd10, 6'd05, 6'd00},
                                {6'd45, 6'd40, 6'd35, 6'd30, 6'd25},
                                {6'd20, 6'd15, 6'd10, 6'd05, 6'd00},
                                {6'd45, 6'd40, 6'd35, 6'd30, 6'd25},
                                {6'd20, 6'd15, 6'd10, 6'd05, 6'd00},
                                {6'd45, 6'd40, 6'd35, 6'd30, 6'd25},
                                {6'd20, 6'd15, 6'd10, 6'd05, 6'd00}};
            sample_length <= 11'd2000;
            sample_freq <= 6'd5; // 100 MHz
            delay_time <= 14'd5000; // 50 us
            analyze_mode <= 2'd0;
            i_bin_width <= 16'd100;
            q_bin_width <= 16'd100;
            i_bin_num <= 5'd10;
            q_bin_num <= 5'd10;
            i_bin_min <= 16'd0;
            q_bin_min <= 16'd0;
            i_vec_perp <= 32'd0;
            q_vec_perp <= 32'd0;
            i_pt_line <= 32'd0;
            q_pt_line <= 32'd0;
        end
        else if (MEM_sdi_mem_S_wrEn) begin // reconfigure values
            // search for correct address
            if (MEM_sdi_mem_S_address == 14'd0)
                demod_freq <= MEM_sdi_mem_S_wrData[4:0];
            else if (MEM_sdi_mem_S_address == 14'd1)
                num_data_pts <= MEM_sdi_mem_S_wrData[15:0];

            else if (MEM_sdi_mem_S_address == 14'd10)
                demod_mod50_LUT[0] <= MEM_sdi_mem_S_wrData[29:0];
            else if (MEM_sdi_mem_S_address == 14'd11)
                demod_mod50_LUT[1] <= MEM_sdi_mem_S_wrData[29:0];
            else if (MEM_sdi_mem_S_address == 14'd12)
                demod_mod50_LUT[2] <= MEM_sdi_mem_S_wrData[29:0];
            else if (MEM_sdi_mem_S_address == 14'd13)
                demod_mod50_LUT[3] <= MEM_sdi_mem_S_wrData[29:0];
            else if (MEM_sdi_mem_S_address == 14'd14)
                demod_mod50_LUT[4] <= MEM_sdi_mem_S_wrData[29:0];
            else if (MEM_sdi_mem_S_address == 14'd15)
                demod_mod50_LUT[5] <= MEM_sdi_mem_S_wrData[29:0];
            else if (MEM_sdi_mem_S_address == 14'd16)
                demod_mod50_LUT[6] <= MEM_sdi_mem_S_wrData[29:0];
            else if (MEM_sdi_mem_S_address == 14'd17)
                demod_mod50_LUT[7] <= MEM_sdi_mem_S_wrData[29:0];
            else if (MEM_sdi_mem_S_address == 14'd18)
                demod_mod50_LUT[8] <= MEM_sdi_mem_S_wrData[29:0];
            else if (MEM_sdi_mem_S_address == 14'd19)
                demod_mod50_LUT[9] <= MEM_sdi_mem_S_wrData[29:0];

            else if (MEM_sdi_mem_S_address == 14'd20)
                sample_length <= MEM_sdi_mem_S_wrData[10:0];
            else if (MEM_sdi_mem_S_address == 14'd21)
                sample_freq <= MEM_sdi_mem_S_wrData[5:0];
            else if (MEM_sdi_mem_S_address == 14'd22)
                delay_time <= MEM_sdi_mem_S_wrData[13:0];

            else if (MEM_sdi_mem_S_address == 14'd30)
                analyze_mode <= MEM_sdi_mem_S_wrData[1:0];
            else if (MEM_sdi_mem_S_address == 14'd31)
                i_bin_width <= MEM_sdi_mem_S_wrData[15:0];
            else if (MEM_sdi_mem_S_address == 14'd32)
                q_bin_width <= MEM_sdi_mem_S_wrData[15:0];
            else if (MEM_sdi_mem_S_address == 14'd33)
                i_bin_num <= MEM_sdi_mem_S_wrData[5:0];
            else if (MEM_sdi_mem_S_address == 14'd34)
                q_bin_num <= MEM_sdi_mem_S_wrData[5:0];
            else if (MEM_sdi_mem_S_address == 14'd35)
                i_bin_min <= MEM_sdi_mem_S_wrData[15:0];
            else if (MEM_sdi_mem_S_address == 14'd36)
                q_bin_min <= MEM_sdi_mem_S_wrData[15:0];
            else if (MEM_sdi_mem_S_address == 14'd37)
                i_vec_perp <= MEM_sdi_mem_S_wrData[31:0];
            else if (MEM_sdi_mem_S_address == 14'd38)
                q_vec_perp <= MEM_sdi_mem_S_wrData[31:0];
            else if (MEM_sdi_mem_S_address == 14'd39)
                i_pt_line <= MEM_sdi_mem_S_wrData[31:0];
            else if (MEM_sdi_mem_S_address == 14'd40)
                q_pt_line <= MEM_sdi_mem_S_wrData[31:0];
        end
    end

endmodule // config


module timing(  
    input clk100,
    input reset,
    input trigger,
    input [13:0] delay,
    output reg start_collect);

    parameter IDLE = 0;
    parameter DELAY = 1;

    reg state = IDLE;
    reg [13:0] counter = 0;

    always @(posedge clk100) begin
        if (reset) begin // at reset, reset our count and wait for trigger
            state <= IDLE;
            counter <= 14'b0;
            start_collect <= 0;
        end

        case (state) 
            IDLE:
            begin
                start_collect <= 0;
                if (trigger) begin // once triggered, begin count
                    state <= DELAY;
                    counter <= counter + 1;
                end
            end

            DELAY:
            begin
                if (counter < delay)
                    counter <= counter + 1;
                else if (~reset && counter == delay) begin // only assert start_collect if reset not assert on same clock cycle
                    counter <= 0;
                    start_collect <= 1; // asserted on same clock cycle of first value to sample
                    state <= IDLE;
                end
            end

            default:
            begin
                state <= IDLE;
                counter <= 14'd0;
                start_collect <= 0;
            end

        endcase
    end

endmodule // timing


module sampler(
    // inputs
    input clk100,
    input reset,
    input start,
    input signed [4:0] [15:0] data_i_in, // packed
    input signed [4:0] [15:0] data_q_in, // packed
    input [4:0] demod_freq,
    input [9:0] [4:0] [5:0] demod_mod50_LUT,
    input [10:0] sample_length,
    input [5:0] sample_skip, // equal to sample_freq
    // outputs
    output reg signed [4:0] [15:0] data_i_shift, // I and Q values shifted one clock cylce to match phase_vals
    output reg signed [4:0] [15:0] data_q_shift,
    output reg [4:0] [7:0] phase_vals); // packed

    // state parameter
    parameter IDLE = 0;
    parameter SAMPLE = 1;

    reg state = IDLE;
    reg [10:0] counter = 0;
    reg [3:0] count_mult = 0;
    reg [5:0] skip_hold; // stores value which determines offset of each count based on previous cycle
    
    // for sample_skips less than five
    // maps sample_skip and skip_hold at time t to to skip_hold at time t+1
    wire [3:0] [3:0] [1:0] skip_hold_LUT;
    assign skip_hold_LUT = {{2'd2, 2'd1, 2'd0, 2'd3},
                            {2'd1, 2'd0, 2'd2, 2'd1},
                            {2'd0, 2'd1, 2'd0, 2'd1},
                            {2'd0, 2'd0, 2'd0, 2'd0}};
    
    // for loop interation variable
    integer i, j;
    
    always @(posedge clk100) begin
        if (reset) begin // at reset, move to IDLE state and wait for new start signal
            state <= IDLE;
            counter <= 0;
            phase_vals <= {5{8'b0}};
        end

        // make sure data values match phase_vals
        data_i_shift <= data_i_in;
        data_q_shift <= data_q_in;

        case (state)
            IDLE: begin
                if (start) begin // from timing, assert on same clock cycle as value to sample
                    state <= SAMPLE; // change states to sampling
                    counter <= 1;
                    count_mult <= 1;
                    // if sample_skip < 5, we need to assign phase values on this cycle
                    if (sample_skip < 5) begin
                        // which phase values we sample depends on value of sample_skip
                        if (sample_skip == 1) begin // every time step
                            phase_vals[0] <= 0; // phase_vals set at next clock cycle
                            phase_vals[1] <= demod_mod50_LUT[0][1];
                            phase_vals[2] <= demod_mod50_LUT[0][2];
                            phase_vals[3] <= demod_mod50_LUT[0][3];
                            phase_vals[4] <= demod_mod50_LUT[0][4];
                            skip_hold <= 0;
                        end
                        else if (sample_skip == 2) begin // every other
                            phase_vals[0] <= 0; // the first value is always sampled, but the phase = 0
                            phase_vals[1] <= 0;
                            phase_vals[2] <= demod_mod50_LUT[0][2];
                            phase_vals[3] <= 0;
                            phase_vals[4] <= demod_mod50_LUT[0][4];
                            skip_hold <= 1;
                        end
                        else if (sample_skip == 3) begin // every third
                            phase_vals[0] <= 0; // the first value is always sampled, but the phase = 0
                            phase_vals[1] <= 0;
                            phase_vals[2] <= 0;
                            phase_vals[3] <= demod_mod50_LUT[0][3];
                            phase_vals[4] <= 0;
                            skip_hold <= 1;
                        end
                        else if (sample_skip == 4) begin // every fourth
                            phase_vals[0] <= 0; // the first value is always sampled, but the phase = 0
                            phase_vals[1] <= 0;
                            phase_vals[2] <= 0;
                            phase_vals[3] <= 0;
                            phase_vals[4] <= demod_mod50_LUT[0][4];
                            skip_hold <= 3;
                        end
                    end // if (sample_skip < 5)
                    else begin // if sample_skip > 5, we don't sample anything except the first value this cycle
                        phase_vals[0] <= 0;
                        phase_vals[1] <= 0;
                        phase_vals[2] <= 0;
                        phase_vals[3] <= 0;
                        phase_vals[4] <= 0;
                        skip_hold <= sample_skip - 5;
                    end
                end // if (start)
                else // IDLE && ~start
                    phase_vals <= {5{8'b0}};
            end 

            SAMPLE: begin
                if (counter < sample_length) begin // within sampling range
                    counter <= counter + 1;
                    if (count_mult < 9)
                        count_mult <= count_mult + 1;
                    else
                        count_mult <= 0;
                    
                    if (sample_skip < 5) begin // when sample_skip < 5, skip_hold < 4
                        // since each cycle of five may have more than one sampled value, we need if statements for each value in our array
                        // test each position to assign value
                        // set to zero otherwise
                        for (i = 0; i < 5; i = i + 1) begin
                            if ((skip_hold == i) ||
                               ((skip_hold + sample_skip) == i) || ((skip_hold + 2 * sample_skip) == i) ||
                               ((skip_hold + 3 * sample_skip) == i) || ((skip_hold + 4 * sample_skip) == i))
                                phase_vals[i] <= demod_mod50_LUT[count_mult][i];
                            else
                                phase_vals[i] <= 0;
                        end
                        skip_hold <= skip_hold_LUT[sample_skip-1][skip_hold]; // set skip_hold for next cycle based on current skip_hold and sample_skip
                    end

                    else if ((skip_hold < 5) && (sample_skip >= 5)) begin // if skip_hold < 5, we will sample a value this cycle
                        // need to determine which value
                        // all other set to zero
                        for (j = 0; j < 5; j = j + 1) begin
                            phase_vals[j] <= (skip_hold == j) ? demod_mod50_LUT[count_mult][j] : 0;
                        end
                        skip_hold <= sample_skip - (5 - skip_hold); // redefine skip_hold
                    end
                    
                    else begin
                        skip_hold <= skip_hold - 5; // if we don't sample this cycle, we decrement skip_hold and check next cycle
                        phase_vals <= {5{8'b0}};
                    end
                end

                else begin // stop sampling, set to IDLE
                    counter <= 0;
                    state <= IDLE;
                    phase_vals <= {5{8'b0}};
                end
            end

            default: begin
                counter <= 0;
                state <= IDLE;
                phase_vals <= {5{8'b0}};
            end
        endcase
    end

endmodule // sampler


module multiplier(
    input clk100,
    input reset,
    input [4:0] [7:0] phase_vals, // packed
    input signed [4:0] [15:0] data_i_in,
    input signed [4:0] [15:0] data_q_in,
    // output
    // rotation data values (multiplied by sine and cosine)
    // outputs always active, only non-zero for sampled values
    output reg signed [4:0] [31:0] data_i_rot,
    output reg signed [4:0] [31:0] data_q_rot);

    // create outputs for DDS compiler
    wire signed [4:0] [25:0] sin_theta;
    wire signed [4:0] [25:0] cos_theta;
    wire signed [4:0] [63:0] sin_cos;
    
    // set up our concatenated sin_cos bus
    genvar g;
    generate
        for (g = 0; g < 5; g = g + 1) begin
            assign sin_theta[g] = sin_cos[g][57:32];
            assign cos_theta[g] = sin_cos[g][25:0];
        end
    endgenerate

    // initiation values for DDS
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

    // DDS COMPILERS
    // mode: sine/cosine LUT
    // modulus: 50
    // input phase: 8 bit
    // output {sine, cosine}: 32 bit
    // latency: 1
    dds_compiler_0 sincos0(.aclk(clk100), .s_axis_phase_tvalid(phase_valid),
        .s_axis_phase_tdata(phase_vals[0]),
        .m_axis_data_tvalid(data_valid0), .m_axis_data_tdata(sin_cos[0]),
        .event_phase_in_invalid(error0));
    dds_compiler_0 sincos1(.aclk(clk100), .s_axis_phase_tvalid(phase_valid),
        .s_axis_phase_tdata(phase_vals[1]),
        .m_axis_data_tvalid(data_valid1), .m_axis_data_tdata(sin_cos[1]),
        .event_phase_in_invalid(error1));
    dds_compiler_0 sincos2(.aclk(clk100), .s_axis_phase_tvalid(phase_valid),
        .s_axis_phase_tdata(phase_vals[2]),
        .m_axis_data_tvalid(data_valid2), .m_axis_data_tdata(sin_cos[2]),
        .event_phase_in_invalid(error2));
    dds_compiler_0 sincos3(.aclk(clk100), .s_axis_phase_tvalid(phase_valid),
        .s_axis_phase_tdata(phase_vals[3]),
        .m_axis_data_tvalid(data_valid3), .m_axis_data_tdata(sin_cos[3]),
        .event_phase_in_invalid(error3));
    dds_compiler_0 sincos4(.aclk(clk100), .s_axis_phase_tvalid(phase_valid),
        .s_axis_phase_tdata(phase_vals[4]),
        .m_axis_data_tvalid(data_valid4), .m_axis_data_tdata(sin_cos[4]),
        .event_phase_in_invalid(error4));

    // create registers to hold our I and Q data in order to match with DDS output
    reg signed [4:0] [15:0] data_i_hold;
    reg signed [4:0] [15:0] data_q_hold;

    integer i;

    always @(posedge clk100) begin
        if (reset) begin
            data_i_rot <= {5{32'b0}};
            data_q_rot <= {5{32'b0}};
        end
        else begin
            for (i = 0; i < 5; i = i + 1) begin
                data_i_rot[i] <= data_i_hold[i]*cos_theta[i] + data_q_hold[i]*sin_theta[i];
                data_q_rot[i] <= data_q_hold[i]*cos_theta[i] - data_i_hold[i]*sin_theta[i];
            end
        end
        
        // clock our I and Q data
        data_i_hold <= data_i_in;
        data_q_hold <= data_q_in;
    end

endmodule // multiplier


module integrator(
    input clk100,
    input reset,
    input start,
    input [10:0] sample_length,
    input signed [4:0] [31:0] data_i_rot, // latency: 2
    input signed [4:0] [31:0] data_q_rot,
    output reg iq_valid, // asserted HIGH on the same clock cycle as when integrated I and Q values are valid
    output reg signed [31:0] i_val_tot,
    output reg signed [31:0] q_val_tot);
    
    // state parameters
    parameter IDLE = 0;
    parameter DELAY = 1; // require an extra state to account for latency of previous modules of 2
    parameter INTEGRATE = 2;

    reg [1:0] state = IDLE;
    reg [10:0] counter = 0;
    
    // store added I and Q values 
    reg [4:0] [31:0] i_vals;
    reg [4:0] [31:0] q_vals;
    
    integer i;
    
    always @(posedge clk100) begin
        if (reset) begin // at reset, stop integrating and reset sums to zero
            state <= IDLE;
            counter <= 11'b0;
            i_vals <= {5{32'b0}};
            q_vals <= {5{32'b0}};
        end

        case (state)
            IDLE: begin
                iq_valid <= 0;
                if (start) begin // at start change states
                    state <= DELAY;
                    i_vals <= {5{32'b0}};
                    q_vals <= {5{32'b0}};
                end
            end
            
            DELAY: begin // account of latency from previous modules of 2
                state <= INTEGRATE;
            end

            INTEGRATE: begin
                counter <= counter + 1;
                if (counter < sample_length) begin // when sampling, sum over each index
                    for (i = 0; i < 5; i = i + 1) begin
                        i_vals[i] <= i_vals[i] + data_i_rot[i];
                        q_vals[i] <= q_vals[i] + data_q_rot[i];
                    end
                end
                else if (counter == sample_length) begin
                    state <= IDLE;
                    counter <= 0;
                    // at end of sample length, sum over indices
                    // I and Q total values valid until end of next sampling period
                    i_val_tot <= i_vals[0] + i_vals[1] + i_vals[2] + i_vals[3] + i_vals[4];
                    q_val_tot <= q_vals[0] + q_vals[1] + q_vals[2] + q_vals[3] + q_vals[4];
                    iq_valid <= 1;
                end
            end

            default: begin
                state <= IDLE;
                counter <= 0;
                iq_valid <= 0;
            end
        endcase
    end

endmodule // iq_output
