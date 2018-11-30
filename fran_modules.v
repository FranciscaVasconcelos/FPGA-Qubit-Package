// FRAN STUFF

module data_dump(
    input clk100, // clock
    input data_in, // indicates if new i,q data is coming in 
    input [31:0] i_val, q_val,

    output [63:0] i_q_vals);

    always @(posedge clk100) begin
        if(data_in) begin
            i_q_vals <= {i_val,q_val}
        end
    end

endmodule // data_dump

module hist2d(
    input clk100,
    input data_in,
    input [31:0] i_val, q_val,
    input [4:0] x_bin_num, y_bin_num,
    input [15:0] x_bin_width, y_bin_width,
    input signed [15:0] x_min, y_min

    output);

    // IMPLEMENT OVERFLOW BINS
    

endmodule // data_dump

module classify(
    input clk100,
    input data_in, // indicates if new i,q data is coming in 
    input signed [31:0] i_val, q_val, // pt to be classified
    input signed [31:0] i_pt_line, q_pt_line, // pt on classification line
    // vector from origin with slope perpendicular to line, pts in direction of excited state
    input signed [31:0] i_vec_perp, q_vec_perp,

    // classified state of input 
    output reg [1:0] state);
    
    reg signed [31:0] i_vec_pt, q_vec_pt; // vector from origin to pt to classify

    reg signed [63:0] dot_product;

    // output state parameters
    parameter GROUND_STATE = 2'b01;
    parameter EXCITED_STATE = 2'b10;
    parameter CLASSIFY_LINE = 2'b11;

    always @(posedge clk100) begin
        if(data_in) begin
            i_vec_pt <= i_val - i_pt_line;
            q_vec_pt <= q_val - q_pt_line;

            // basic implementation, can be improved by looking just at signs/with tricks
            dot_product <= i_vec_pt*i_vec_perp + q_vec_pt*q_vec_perp;

            // EXCITED STATE CLASSIFICATION
            if(dot_product>0) state <= EXCITED_STATE;
            // GROUND STATE CLASSIFICATION
            else if (dot_product<0) state <= GROUND_STATE;
            // PT ON CLASSIFICATION LINE
            else state <= CLASSIFY_LINE;
        end
    end

endmodule // data_dump

module analyze_fsm(
    input clk100,
    input [1:0] analyze_mode, // fsm state
    
    // i-q data parameters
    input data_in,
    input [31:0] i_val, q_val

    // histogram inputs 
    input [3:0] x_bin, y_bin,

    // classification inputs
    input signed [31:0] i_vec_perp, q_vec_perp,
    input signed [31:0] i_pt_line, q_pt_line, 

    // output data and mode
    output [1:0] output_mode,
    output reg [63:0] output_channels);

    wire [1:0] state = analyze_mode;

    // define states
    parameter DATA_DUMP_MODE = 2'b00;
    parameter CLASSIFY_MODE = 2'b01
    parameter HIST2D_MODE = 2'b11;

    // for reading output of different modules
    wire [63:0] read_classify;
    wire [63:0] read_hist2d;

    

    // analysis FSM
    always @(posedge clk100) begin
        output_mode <= state;
        case(state)
            DATA_DUMP_MODE: begin
                if (data_in) output_channels <= {i_val, q_val}
            end // DATA_DUMP_MODE

            CLASSIFY_MODE: begin
                output_channels <= read_classify;
            end // CLASSIFY_MODE

            HIST2D_MODE: begin
                output_channels <= read_hist2d;
            end // HIST2D_MODE

            default: output_channels <= 64'b0; 

        endcase
    end
    
    // instantiate analysis modules
    hist2d hist(.clk100(clk100),);

    classify class(.clk100(clk100), .data_in(data_in), .i_val(i_val), .q_val(q_val), 
                   .i_pt_line(i_pt_line), .q_pt_line(q_pt_line), .i_vec_perp(i_vec_perp), 
                   .q_vec_perp(q_vec_perp),.state(read_classify));

endmodule // data_dump