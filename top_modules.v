////////////////////////////////////////////////////////////////////////////////
// Top Modules version v1
// Author: Megan Yamoah
// Date: 19/11/2018
////////////////////////////////////////////////////////////////////////////////

module config_params(
    input clk100,
    input reset,
    input config_reset,
    input [3:0] demod_freq_new, // freq divided by 10 MHz
    input [10:0] sample_length_new, // max 20 us
    input [5:0] sample_freq_new, // min 8 MHz
    input [9:0] delay_time_new, // max 10 us
    input [1:0] analyze_mode_new, // data dump, binning, classifier
    input [3:0] x_bin_new,
    input [3:0] y_bin_new,
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

    always @(posedge clk_100) begin
        if (reset) begin
            demod_freq_new <= 4'd5; // 50 MHz
            sample_length <= 11'd20000; // 20 us
            sample_freq <= 6'd5; // 100 MHz
            delay_time <= 14'd5000;
            analyze_mode <= 2'd0;
            x_bin <= 3'd10;
            y_bin <= 3'd10;
        end // if (reset)
        else if (config_reset) begin
            demod_freq <= demod_freq_new;
            sample_length <= sample_length_new;
            sample_freq <= sample_freq_new;
            delay_time <= delay_time_new;
            analyze_mode <= analyze_mode_new;
            x_bin <= x_bin_new;
            y_bin <= y_bin_new;
        end // if (config_reset_new)
    end

endmodule // config


module timing(
    input clk100
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
                start_collect <= 0
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
                    start_collect <= 1;
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
    input [15:0] data_i_in [4:0],
    input [15:0] data_q_in [4:0],
    input [3:0] demod_freq,
    input [10:0] sample_length,
    input [13:0] sample_freq,
    output reg [15:0] data_i_out [4:0],
    output reg [15:0] data_q_out [4:0],
    output reg [13:0] phase_vals [4:0]);

    parameter IDLE = 0;
    parameter SAMPLE = 1;

    reg state = IDLE;
    reg [10:0] counter = 0;
    reg [13:0] sample_skip;
    reg [2:0] skip_hold;

    always @(posedge clk100) begin
        if (reset) begin
            state <= IDLE;
            counter <= 0;
            sample_skip <= sample_freq;
            phase_vals <= {5{14'b0}};
        end

        data_i_out <= data_i_in;
        data_q_out <= data_q_in;

        case (state) begin
            IDLE: begin
                if (start) begin
                    state <= SAMPLE;
                    counter <= counter + 1;
                    phase_vals[1] <= (1 % sample_skip == 0) ? demod_freq : 0;
                    phase_vals[2] <= (2 % sample_skip == 0) ? 2*demod_freq : 0;
                    phase_vals[3] <= (3 % sample_skip == 0) ? 3*demod_freq : 0;
                    phase_vals[4] <= (4 % sample_skip == 0) ? 4*demod_freq : 0;
                end 
                else
                    phase_vals <= {5{14'b0}};
            end 

            SAMPLE: begin
                if (counter < sample_length) begin
                    counter <= counter + 1;
                    phase_vals[0] <= (5*counter % sample_skip == 0) ? demod_freq * (5*counter) : 0;
                    phase_vals[1] <= ((5*counter + 1) % sample_skip == 0) ? demod_freq * (5*counter + 1) : 0;
                    phase_vals[2] <= ((5*counter + 2) % sample_skip == 0) ? demod_freq * (5*counter + 2) : 0;
                    phase_vals[3] <= ((5*counter + 3) % sample_skip == 0) ? demod_freq * (5*counter + 3) : 0;
                    phase_vals[4] <= ((5*counter + 4) % sample_skip == 0) ? demod_freq * (5*counter + 4) : 0;
                end
                else begin
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
    input [13:0] phase_vals [4:0],
    input [15:0] data_i_in [4:0],
    input [15:0] data_q_in [4:0],
    output reg signed [15:0] data_i_rot [4:0],
    output reg signed [15:0] data_q_rot [4:0]);

    wire signed [15:0] sin_theta [4:0];
    wire signed [15:0] cos_theta [4:0];

    assign sin_theta = //dds using phase_vals;
    assign cos_theta = //dds using phase_vals;

    integer i;
    always @(posedge clk100) begin
        if (reset) begin
            data_i_rot <= {5{16'b0}};
            data_q_rot <= {5{16'b0}};
        end
        else if begin
            for (i = 0; i < 5; i = i + 1) begin
                if ~(phase_vals[i] == 0) begin
                    data_i_rot[i] <= data_i_in[i]*cos_theta[i] + data_q_in[i]*sin_theta[i];
                    data_q_rot[i] <= data_q_in[i]*cos_theta[i] - data_i_in[i]*sin_theta[i];
                end
            end
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
    input [13:0] phase_vals [4:0],
    output iq_valid,
    output [31:0] i_val,
    output [31:0] q_val);

    IDLE = 0;
    INTEGRATE = 1;

    reg state = IDLE;
    reg [10:0] counter = 0;

    always @(posedge clk100) begin
        if (reset) begin
            state <= IDLE;
            counter <= 0;
            i_val <= 0;
            q_val <= 0;
        end

        case (state) begin
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
                        if ~(phase_vals[i] == 0) begin
                            i_val <= i_val + data_i_rot[i];
                            q_val <= q_val + data_q_rot[i];
                        end
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

endmodule // iq_output
