////////////////////////////////////////////////////////////////////////////////
// Top Modules version v1
// Author: Megan Yamoah
// Date: 28/11/2018
////////////////////////////////////////////////////////////////////////////////

module config_params(
    // inputs
    input clk100,
    input reset,
    input config_reset,
    // update values
    input [3:0] demod_freq_new, // freq divided by 10 MHz
    input [10:0] sample_length_new, // max 20 us
    input [5:0] sample_freq_new, // min 8 MHz
    input [9:0] delay_time_new, // max 10 us
    input [1:0] analyze_mode_new, // data dump, binning, classifier
    input [15:0] x_bin_width_new, // width of bin in x_direction 
    input [15:0] y_bin_width_new, // width of bin in y_direction 
    input [4:0] x_bin_num_new, // number of bins along x_direction 
    input [4:0] y_bin_num_new, // number of bins along y_direction 
    input signed [15:0] x_bin_min_new, // start of bins x_direction 
    input signed [15:0] y_bin_min_new, // start of bins y_direction
    // outputs
    output reg [3:0] demod_freq, // freq divided by 10 MHz
    output reg [10:0] sample_length, // max 20 us
    output reg [5:0] sample_freq, // min 8 MHz
    output reg [13:0] delay_time, // max 163 us
    output reg [1:0] analyze_mode, // data dump, binning, classifier
    output reg [15:0] x_bin_width, // width of bin in x_direction
    output reg [15:0] y_bin_width, // width of bin in y_direction
    output reg [4:0] x_bin_num, // number of bins along x_direction
    output reg [4:0] y_bin_num, // number of bins along y_direction
    output reg signed [15:0] x_bin_min, // start of bins x_direction
    output reg signed [15:0] y_bin_min // start of bins y_direction
    );

    always @(posedge clk100) begin
        if (reset) begin
            demod_freq <= 4'd5; // 50 MHz
            sample_length <= 11'd2000; // 20 us
            sample_freq <= 6'd5; // 100 MHz
            delay_time <= 14'd5000;
            analyze_mode <= 2'd0;
            x_bin_width <= 16'd100;
            y_bin_width <= 16'd100;
            x_bin_num <= 5'd10;
            y_bin_num <= 5'd10;
            x_bin_min <= 16'd0;
            y_bin_min <= 16'd0; 
        end
        else if (config_reset) begin
            demod_freq <= demod_freq_new;
            sample_length <= sample_length_new;
            sample_freq <= sample_freq_new;
            delay_time <= delay_time_new;
            analyze_mode <= analyze_mode_new;
            x_bin_width <= x_bin_width_new;
            y_bin_width <= y_bin_width_new;
            x_bin_num <= x_bin_num_new;
            y_bin_num <= y_bin_num_new;
            x_bin_min <= x_bin_min_new;
            y_bin_min <= y_bin_min_new; 
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
        if (reset) begin
            state <= IDLE;
            counter <= 14'b0;
            start_collect <= 0;
        end

        case (state) 
            IDLE:
            begin
                start_collect <= 0;
                if (trigger) begin
                    state <= DELAY;
                    counter <= counter + 1;
                end
            end

            DELAY:
            begin
                if (counter < delay)
                    counter <= counter + 1;
                else if (~reset && counter == delay) begin
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
    input clk100,
    input reset,
    input start,
    input signed [15:0] [4:0] data_i_in, // packed
    input signed [15:0] [4:0] data_q_in, // packed
    input [3:0] demod_freq,
    input [10:0] sample_length,
    input [5:0] sample_freq,
    output reg signed [15:0] [4:0] data_i_shift, // packed
    output reg signed [15:0] [4:0] data_q_shift, // packed
    output reg [17:0] [4:0] phase_vals); // packed

    parameter IDLE = 0;
    parameter SAMPLE = 1;

    reg state = IDLE;
    reg [10:0] counter = 0;
    reg [13:0] sample_skip;
    reg [2:0] skip_hold;

    wire [1:0] skip_hold_LUT [3:0] [3:0];
    assign skip_hold_LUT = {{0, 0, 0, 0},
    						{1, 0, 1, 0},
    						{1, 2, 0, 1},
    						{3, 0, 1, 2}};
    integer i;
    
    always @(posedge clk100) begin
        if (reset) begin
            state <= IDLE;
            counter <= 0;
            sample_skip <= sample_freq;
            phase_vals <= {5{14'b0}};
        end

        // make sure data values match phase_vals
        data_i_shift <= data_i_in;
        data_q_shift <= data_q_in;

        case (state)
            IDLE: begin
                if (start) begin // from timing, assert on same clock sample as value to sample
                    state <= SAMPLE;
                    counter <= 1;
                    if (sample_skip < 5) begin
                        if (sample_skip == 1) begin
                            phase_vals[0] <= 0; // phase_vals set at next clock cycle
                            phase_vals[1] <= demod_freq;
                            phase_vals[2] <= demod_freq * 2;
                            phase_vals[3] <= demod_freq * 3;
                            phase_vals[4] <= demod_freq * 4;
                            skip_hold <= 0;
                        end
                        else if (sample_skip == 2) begin
                            phase_vals[0] <= 0;
                            phase_vals[1] <= 0;
                            phase_vals[2] <= demod_freq * 2;
                            phase_vals[3] <= 0;
                            phase_vals[4] <= demod_freq * 4;
                            skip_hold <= 0;
                        end
                        else if (sample_skip == 3) begin
                            phase_vals[0] <= 0;
                            phase_vals[1] <= 0;
                            phase_vals[2] <= 0;
                            phase_vals[3] <= demod_freq * 3;
                            phase_vals[4] <= 0;
                            skip_hold <= 1;
                        end
                        else if (sample_skip == 4) begin
                            phase_vals[0] <= 0;
                            phase_vals[1] <= 0;
                            phase_vals[2] <= 0;
                            phase_vals[3] <= 0;
                            phase_vals[4] <= demod_freq * 4;
                            skip_hold <= 3;
                        end
                    end // if (sample_skip < 5)
                    else begin // sample_skip > 5
                        phase_vals[0] <= 0;
                        phase_vals[1] <= 0;
                        phase_vals[2] <= 0;
                        phase_vals[3] <= 0;
                        phase_vals[4] <= 0;
                        skip_hold <= sample_skip - 5;
                    end
                end // if (start)
                else // IDLE && ~start
                    phase_vals <= {5{14'b0}};
            end 

            SAMPLE: begin
                if (counter < sample_length) begin // within sampling range
                    counter <= counter + 1;
                    if ((skip_hold < 5) && (sample_skip < 5)) begin
                        for (i = 0; i < 5; i = i + 1) begin
                            if (skip_hold == i)
                                phase_vals[i] <= 1;
                            if ((skip_hold + sample_skip) == i)
                                phase_vals[i] <= 1;
                            if ((skip_hold + 2 * sample_skip) == i)
                                phase_vals[i] <= 1;
                            if ((skip_hold + 3 * sample_skip) == i)
                                phase_vals[i] <= 1;
                            if ((skip_hold + 4 * sample_skip) == i)
                                phase_vals[i] <= 1;
                        end // for (i = 0; i < 5; i = i + 1)
                        skip_hold <= skip_hold_LUT[sample_skip-1][skip_hold];
                    end // if ((skip_hold < 5) && (sample_skip < 5))

                    else if ((skip_hold < 5) && (sample_skip >= 5)) begin
                        if (skip_hold == 0) begin
                            phase_vals[0] <= 1;
                            phase_vals[1] <= 0;
                            phase_vals[2] <= 0;
                            phase_vals[3] <= 0;
                            phase_vals[4] <= 0;
                            skip_hold <= sample_skip - 5;
                        end
                        else if (skip_hold == 1) begin
                            phase_vals[0] <= 0;
                            phase_vals[1] <= 1;
                            phase_vals[2] <= 0;
                            phase_vals[3] <= 0;
                            phase_vals[4] <= 0;
                            skip_hold <= sample_skip - 4;
                        end
                        else if (skip_hold == 2) begin
                            phase_vals[0] <= 0;
                            phase_vals[1] <= 0;
                            phase_vals[2] <= 1;
                            phase_vals[3] <= 0;
                            phase_vals[4] <= 0;
                            skip_hold <= sample_skip - 3;
                        end
                        else if (skip_hold == 3) begin
                            phase_vals[0] <= 0;
                            phase_vals[1] <= 0;
                            phase_vals[2] <= 0;
                            phase_vals[3] <= 1;
                            phase_vals[4] <= 0;
                            skip_hold <= sample_skip - 2;
                        end
                        else if (skip_hold == 4) begin
                            phase_vals[0] <= 0;
                            phase_vals[1] <= 0;
                            phase_vals[2] <= 0;
                            phase_vals[3] <= 0;
                            phase_vals[4] <= 1;
                            skip_hold <= sample_skip - 1;
                        end
                    end // else if ((skip_hold < 5) && (sample_skip >= 5))
                    else // ((skip_hold > 5) && (sample_skip >= 5))
                        skip_hold <= skip_hold - 5;
                end // if (counter < sample_length)

                else begin // stop sampling, set to IDLE
                    counter <= 0;
                    state <= IDLE;
                    phase_vals <= {5{14'b0}};
                end
            end

            default: begin
                counter <= 0;
                state <= IDLE;
                phase_vals <= {5{14'b0}};
            end
        endcase
    end

endmodule // sampler


module multiplier(
    input clk100,
    input reset,
    input [17:0] [4:0] phase_vals, // packed
    input signed [15:0] [4:0] data_i_in,
    input signed [15:0] [4:0] data_q_in,
    output reg signed [15:0] [4:0] data_i_rot,
    output reg signed [15:0] [4:0] data_q_rot);

    wire signed [15:0] [4:0] sin_theta;
    wire signed [15:0] [4:0] cos_theta;
    wire signed [31:0] [4:0] sin_cos;
    
    wire [7:0] [4:0] phase_vals_mod;

    genvar g;

    generate
        for (g = 0; g < 5; g = g + 1) begin
            assign sin_cos[g] = {sin_theta[g], cos_theta[g]};
            assign phase_vals_mod[g] = phase_vals[g] % 50;
        end
    endgenerate

    wire phase_valid = 1;
    wire error;
    wire data_valid;

    // DDS COMPILERS
    // mode: sine/cosine LUT
    // input phase: 8 bit
    // output {sine, cosine}: 32 bit
    // latency: 1
    dds_compiler_0 sin_cos0(.aclk(clk100), .s_axis_phase_tvalid(phase_valid),
        .s_axis_phase_tdata(phase_vals_mod[0]),
        .m_axis_data_tvalid(data_valid), .m_axis_data_tdata(sin_cos[0]),
        .event_phase_in_invalid(error));
    dds_compiler_0 sin_cos1(.aclk(clk100), .s_axis_phase_tvalid(phase_valid),
        .s_axis_phase_tdata(phase_vals_mod[1]),
        .m_axis_data_tvalid(data_valid), .m_axis_data_tdata(sin_cos[1]),
        .event_phase_in_invalid(error));
    dds_compiler_0 sin_cos2(.aclk(clk100), .s_axis_phase_tvalid(phase_valid),
        .s_axis_phase_tdata(phase_vals_mod[2]),
        .m_axis_data_tvalid(data_valid), .m_axis_data_tdata(sin_cos[2]),
        .event_phase_in_invalid(error));
    dds_compiler_0 sin_cos3(.aclk(clk100), .s_axis_phase_tvalid(phase_valid),
        .s_axis_phase_tdata(phase_vals_mod[3]),
        .m_axis_data_tvalid(data_valid), .m_axis_data_tdata(sin_cos[3]),
        .event_phase_in_invalid(error));
    dds_compiler_0 sin_cos4(.aclk(clk100), .s_axis_phase_tvalid(phase_valid),
        .s_axis_phase_tdata(phase_vals_mod[4]),
        .m_axis_data_tvalid(data_valid), .m_axis_data_tdata(sin_cos[4]),
        .event_phase_in_invalid(error));

    reg signed [15:0] [4:0] data_i_hold;
    reg signed [15:0] [4:0] data_q_hold;

    integer i, k;

    always @(posedge clk100) begin
        if (reset) begin
            data_i_rot <= {5{16'b0}};
            data_q_rot <= {5{16'b0}};
        end
        else begin
            for (i = 0; i < 5; i = i + 1) begin
                if (~(phase_vals[i] == 0)) begin
                    data_i_rot[i] <= data_i_hold[i]*cos_theta[i] + data_q_hold[i]*sin_theta[i];
                    data_q_rot[i] <= data_q_hold[i]*cos_theta[i] - data_i_hold[i]*sin_theta[i];
                end
            end
        end

        for (k = 0; k < 5; k = k+1) begin
            data_i_hold[k] <= data_i_in[k];
            data_q_hold[k] <= data_q_in[k];
        end
    end

endmodule // multiplier


module integrator(
    input clk100,
    input reset,
    input start,
    input [10:0] sample_length,
    input signed [15:0] data_i_rot [4:0],
    input signed [15:0] data_q_rot [4:0],
    output reg iq_valid,
    output reg [31:0] i_val,
    output reg [31:0] q_val);

    parameter IDLE = 0;
    parameter INTEGRATE = 1;

    reg state = IDLE;
    reg [10:0] counter = 0;

    integer i;
    
    always @(posedge clk100) begin
        if (reset) begin
            state <= IDLE;
            counter <= 0;
            i_val <= 0;
            q_val <= 0;
        end

        case (state)
            IDLE: begin
                iq_valid <= 0;
                if (start) begin
                    counter <= counter + 1;
                    state <= INTEGRATE;
                    i_val <= 0;
                    q_val <= 0;
                end
            end

            INTEGRATE: begin
                if (counter < sample_length) begin
                    for (i = 0; i < 5; i = i + 1) begin
                        i_val <= i_val + data_i_rot[i];
                        q_val <= q_val + data_q_rot[i];
                    end
                end
                else if (counter == sample_length) begin
                    state <= IDLE;
                    counter <= 0;
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
