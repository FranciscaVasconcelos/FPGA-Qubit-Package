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
	X_BIN = 10,
	Y_BIN = 10)(
	input clk100, reset, config_reset,
	input [15:0] data0_in_0, data0_in_1, data0_in_2, data0_in_3, data0_in_4,
	input [15:0] data1_in_0, data1_in_1, data1_in_2, data1_in_3, data1_in_4,
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
	wire [3:0] demod_freq_new = DEMOD_FREQ;
    wire [10:0] sample_length_new = SAMPLE_LENGTH;
    wire [5:0] sample_freq_new = SAMPLE_FREQ;
    wire [9:0] delay_time_new = DELAY_TIME;
    wire [1:0] analyze_mode_new = ANALYZE_MODE;
    wire [3:0] x_bin_new = X_BIN;
    wire [3:0] y_bin_new = Y_BIN;

    // configurated values
    wire [3:0] demod_freq;
    wire [10:0] sample_length;
    wire [5:0] sample_freq;
    wire [13:0] delay_time;
    wire [1:0] analyze_mode;

	config_params config_main(.clk100(clk100), .reset(reset), .config_reset(config_reset),
		.demod_freq_new(demod_frew_new), .sample_length_new(sample_length_new), .sample_freq_new(sample_freq_new),
		.delay_time_new(delay_time_new),
		.analyze_mode_new(analyze_mode_new),
		.x_bin_new(x_bin_new), .y_bin_new(y_bin_new),
		.demod_freq(demod_freq), .sample_length(sample_length), .sample_freq(sample_freq),
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
	wire [15:0] data_i_in [4:0];
	wire [15:0] data_q_in [4:0];

	wire [15:0] data_i_out [4:0];
	wire [15:0] data_q_out [4:0];

	// assign data arrays
	assign data_i_in = {data0_in_0, data0_in_1, data0_in_2, data0_in_3, data0_in_4};
	assign data_q_in = {data1_in_0, data1_in_1, data1_in_2, data1_in_3, data1_in_4};

	assign data_i_out = {data0_out_0, data0_out_1, data0_out_2, data0_out_3, data0_out_4};
	assign data_q_out = {data1_out_0, data1_out_1, data1_out_2, data1_out_3, data1_out_4};

	wire [13:0] phase_vals [4:0];

	sampler sampler_main(
		// inputs
		.clk100(clk100), .reset(reset), .start(start_collect),
    	.data_i_in(data_i_in), .data_q_in(data_q_in),
    	.demod_freq(demod_freq), .sample_length(sample_length), .sample_freq(sample_freq),
    	// outputs
    	.data_i_out(data_i_out), .data_q_out(data_q_out),
    	.phase_vals(phase_vals));

	// set up rotated data arrays
	wire signed [15:0] data_i_rot [4:0];
	wire signed [15:0] data_q_rot [4:0];

	multiplier multiplier_main(
		// inputs
		.clk100(clk100), .reset(reset),
		.phase_vals(phase_vals),
		.data_i_in(data_i_in), .data_q_in(data_q_in),
		// outputs
		.data_i_rot(data_i_rot), .data_q_rot(data_q_rot));

	integrator integrator_main(
		// inputs
		.clk100(clk100), .reset(reset), .start(start),
		.sample_length(sample_length),
		.data_i_rot(data_i_rot), .data_q_rot(data_q_rot),
		.phase_vals(phase_vals),
		// outputs
		.iq_valid(iq_valid),
		.i_val(i_val), .q_val(q_val));

endmodule // top_main
