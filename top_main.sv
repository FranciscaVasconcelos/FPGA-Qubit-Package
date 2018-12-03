////////////////////////////////////////////////////////////////////////////////
// Top Modules Instantiation version v1
// Author: Megan Yamoah
// Date: 28/11/2018
////////////////////////////////////////////////////////////////////////////////

module top_main #(
	DEMOD_FREQ = 5,
	SAMPLE_LENGTH = 20000,
	SAMPLE_FREQ = 5,
	DELAY_TIME = 5000,
	ANALYZE_MODE = 0,
	X_BIN_WIDTH = 100,
	Y_BIN_WIDTH = 100,
	X_BIN_NUM = 10,
	Y_BIN_NUM = 10,
	X_BIN_MIN = 0,
	Y_BIN_MIN = 0)(
	input clk100, reset, config_reset,
	input [15:0] data0_in_0, data0_in_1, data0_in_2, data0_in_3, data0_in_4,
	input [15:0] data1_in_0, data1_in_1, data1_in_2, data1_in_3, data1_in_4,
	input trigger,
	output iq_valid,
	output [31:0] i_val,
	output [31:0] q_val,
	// configurated prameters to pass to lower modules
	output [1:0] analyze_mode,
    output [15:0] x_bin_width,
    output [15:0] y_bin_width,
    output [4:0] x_bin_num,
    output [4:0] y_bin_num,
    output signed [15:0] x_bin_min,
    output signed [15:0] y_bin_min
	);

	// configuration parameters
	// parameterized for testing
	wire [4:0] demod_freq_new = DEMOD_FREQ;
    wire [10:0] sample_length_new = SAMPLE_LENGTH;
    wire [5:0] sample_freq_new = SAMPLE_FREQ;
    wire [9:0] delay_time_new = DELAY_TIME;
    wire [1:0] analyze_mode_new = ANALYZE_MODE;
    wire [15:0] x_bin_width_new = X_BIN_WIDTH;
    wire [15:0] y_bin_width_new = Y_BIN_WIDTH;
    wire[4:0] x_bin_num_new = X_BIN_NUM;
    wire [4:0] y_bin_num_new = Y_BIN_NUM;
    wire signed [15:0] x_bin_min_new = X_BIN_MIN;
    wire signed [15:0] y_bin_min_new = Y_BIN_MIN;
       
    // build mod50 LUT
    wire [4:0] [9:0] [5:0] demod_mod50_LUT_new;
    genvar i, j;
    generate
        for (i = 0; i < 5; i = i + 1) begin : gen1
            for (j = 0; j < 10; j = j + 1) begin : gen2
                assign demod_mod50_LUT_new[i][j] = (DEMOD_FREQ * (i + 5 * j)) % 50;
            end
        end
    endgenerate

    // configurated values
    wire [4:0] demod_freq;
    wire [10:0] sample_length;
    wire [5:0] sample_freq;
    wire [13:0] delay_time;
    wire [4:0] [9:0] [5:0] demod_mod50_LUT;

	config_params config_main(.clk100(clk100), .reset(reset), .config_reset(config_reset),
		.demod_freq_new(demod_freq_new), .demod_mod50_LUT_new(demod_mod50_LUT_new),
		.sample_length_new(sample_length_new), .sample_freq_new(sample_freq_new),
		.delay_time_new(delay_time_new),
		.analyze_mode_new(analyze_mode_new),
		.x_bin_width_new(x_bin_width_new), .y_bin_width_new(y_bin_width_new),
        .x_bin_num_new(x_bin_num_new), .y_bin_num_new(y_bin_num_new),
        .x_bin_min_new(x_bin_min_new), .y_bin_min_new(y_bin_min_new),
		.demod_freq(demod_freq), .demod_mod50_LUT(demod_mod50_LUT),
		.sample_length(sample_length), .sample_freq(sample_freq),
		.delay_time(delay_time),
		.analyze_mode(analyze_mode),
		.x_bin_width(x_bin_width), .y_bin_width(y_bin_width),
		.x_bin_num(x_bin_num), .y_bin_num(y_bin_num),
		.x_bin_min(x_bin_min), .y_bin_min(y_bin_min));

	// start data collection
	// output from timing module
	wire start_collect;

	timing timing_main(
		// inputs
		.clk100(clk100), .reset(reset), .trigger(trigger),
		.delay(delay_time),
		// ouputs
		.start_collect(start_collect));

	// set up data arrays
	wire signed [4:0] [15:0] data_i_in;
	wire signed [4:0] [15:0] data_q_in;
    
    // shifted arrays are fed into multiplier
	wire signed [4:0] [15:0] data_i_shift;
	wire signed [4:0] [15:0] data_q_shift;

	// assign data arrays
	assign data_i_in = {data0_in_0, data0_in_1, data0_in_2, data0_in_3, data0_in_4};
	assign data_q_in = {data1_in_0, data1_in_1, data1_in_2, data1_in_3, data1_in_4};

	wire [4:0] [7:0] phase_vals;

	sampler sampler_main(
		// inputs
		.clk100(clk100), .reset(reset), .start(start_collect),
    	.data_i_in(data_i_in), .data_q_in(data_q_in),
    	.demod_freq(demod_freq), .demod_mod50_LUT(demod_mod50_LUT),
    	.sample_length(sample_length), .sample_skip(sample_freq),
    	// outputs
    	.data_i_shift(data_i_shift), .data_q_shift(data_q_shift),
    	.phase_vals(phase_vals));
    // shifted arrays ensure matching between phase_vals and I-Q data
    
	// set up rotated data arrays
	wire signed [4:0] [31:0] data_i_rot;
	wire signed [4:0] [31:0] data_q_rot;

	multiplier multiplier_main(
		// inputs
		.clk100(clk100), .reset(reset),
		.phase_vals(phase_vals),
		.data_i_in(data_i_shift), .data_q_in(data_q_shift), // shifted values
		// outputs
		.data_i_rot(data_i_rot), .data_q_rot(data_q_rot)); // counter rotated outputs

	integrator integrator_main(
		// inputs
		.clk100(clk100), .reset(reset), .start(start_collect),
		.sample_length(sample_length),
		.data_i_rot(data_i_rot), .data_q_rot(data_q_rot),
		// outputs
		.iq_valid(iq_valid),
		.i_val_tot(i_val), .q_val_tot(q_val));

endmodule // top_main
