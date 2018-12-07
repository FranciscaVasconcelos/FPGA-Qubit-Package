////////////////////////////////////////////////////////////////////////////////
// Top Modules Instantiation version v1
// Author: Megan Yamoah
// Date: 28/11/2018
////////////////////////////////////////////////////////////////////////////////

module top_main (
	input clk100, reset,
	// config control
	input [13:0] MEM_sdi_mem_S_address, // parameter location
    input MEM_sdi_mem_S_wrEn, // write on
    input [32:0] MEM_sdi_mem_S_wrData, // parameter value
    // i input
	input [15:0] data0_in_0, data0_in_1, data0_in_2, data0_in_3, data0_in_4,
	// q input
	input [15:0] data1_in_0, data1_in_1, data1_in_2, data1_in_3, data1_in_4,
	input trigger,
	//outputs
	output iq_valid,
	output [31:0] i_val, q_val,
	// configurated prameters to pass to lower modules
	output [1:0] analyze_mode,
	output [15:0] num_data_pts,
    output [15:0] i_bin_width, q_bin_width,
    output [7:0] i_bin_num, q_bin_num,
    output signed [15:0] i_bin_min, q_bin_min,
    output signed [31:0] i_vec_perp, q_vec_perp,
    output signed [31:0] i_pt_line, q_pt_line,
    output output_mode);

    // configurated values
    wire [4:0] demod_freq;
    wire [10:0] sample_length;
    wire [5:0] sample_freq;
    wire [13:0] delay_time;
    wire [9:0] [4:0] [5:0] demod_mod50_LUT;

    // instantiate parameter configuration
	config_params config_main(.clk100(clk100), .reset(reset),
		// config protocol
		.MEM_sdi_mem_S_address(MEM_sdi_mem_S_address),
        .MEM_sdi_mem_S_wrEn(MEM_sdi_mem_S_wrEn),
        .MEM_sdi_mem_S_wrData(MEM_sdi_mem_S_wrData),
		// parameter
		.demod_freq(demod_freq), .num_data_pts(num_data_pts),
		.demod_mod50_LUT(demod_mod50_LUT),
		.sample_length(sample_length), .sample_freq(sample_freq),
		.delay_time(delay_time),
		.analyze_mode(analyze_mode),
		.i_bin_width(i_bin_width), .q_bin_width(q_bin_width),
		.i_bin_num(i_bin_num), .q_bin_num(q_bin_num),
		.i_bin_min(i_bin_min), .q_bin_min(q_bin_min),
		.i_vec_perp(i_vec_perp), .q_vec_perp(q_vec_perp),
        .i_pt_line(i_pt_line), .q_pt_line(q_pt_line),
        .output_mode(output_mode));

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

	wire [4:0] [7:0] phase_vals; // create phase value array

	// instantiate sampler
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

	// instantiate multiplier
	multiplier multiplier_main(
		// inputs
		.clk100(clk100), .reset(reset),
		.phase_vals(phase_vals),
		.data_i_in(data_i_shift), .data_q_in(data_q_shift), // shifted values
		// outputs
		.data_i_rot(data_i_rot), .data_q_rot(data_q_rot)); // counter rotated outputs

	// instantiate integrator
	integrator integrator_main(
		// inputs
		.clk100(clk100), .reset(reset), .start(start_collect),
		.sample_length(sample_length),
		.data_i_rot(data_i_rot), .data_q_rot(data_q_rot),
		// outputs
		.iq_valid(iq_valid),
		.i_val_tot(i_val), .q_val_tot(q_val));

endmodule // top_main
