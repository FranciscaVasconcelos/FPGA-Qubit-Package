// FRAN STUFF

// recursive algorithm to find bin! :D
module bin_binary_search(
    // dynamic input
    input clk100,
    input data_in,
    input signed [31:0] value,
    // static input
    input [5:0] num_bins, // value must be in range 1-63 
    input [15:0] bin_width,    
    input signed [15:0] origin,
    
    output reg binned, // boolean that outputs 1 when value has been binned
    output reg [5:0] current); // contains value bin when binned=1 (in range 0 to num_bins, 63 if out of range)
    
    reg signed [31:0] val; // for storing value when data_in = 1;
    
    reg [5:0] max; // max possible bin value
    reg [5:0] min; // max possible bin value
    reg signed [31:0] bin_value; // current bin value we are comparing to
    
    wire signed [6:0] current_signed;
    wire signed [16:0] bin_width_signed;
    
    assign current_signed = current; // convert current to signed 
    assign bin_width_signed = bin_width; // convert bin_width to signed
    
    reg [1:0] search_state; // make FSM to run search algo and properly update values
    parameter UPDATE_BIN_VAL = 2'b00;
    parameter RUN_ALGO = 2'b01;
    parameter OUTPUT_RESULT = 2'b10;
    parameter RESET = 2'b11;
    
    initial begin
        search_state = RESET;
    end
    
    always @(posedge clk100) begin

        case(search_state)
            UPDATE_BIN_VAL: begin
                bin_value <= origin+(current_signed*bin_width_signed);
                search_state <= RUN_ALGO;
            end
            
            RUN_ALGO: begin
                // value falls right on bin boundary
                if(val == bin_value) begin
                    search_state <= OUTPUT_RESULT;
                end
                // value in smaller bin
                else if(val < bin_value) begin
                    // value outside of binning range
                    if(current == min) begin 
                       current <= 6'b111111;
                       search_state <= OUTPUT_RESULT;
                    end
                    // boundaries have converged to bin
                    else if (val > bin_value - bin_width_signed) begin
                        current <= min;
                        search_state <= OUTPUT_RESULT;
                    end
                    // continue search
                    else begin 
                        max <= current; // set new maximum boundary
                        current <= ((current - min) >> 1) + min; // half way between current and min
                        search_state <= UPDATE_BIN_VAL;
                    end
                end
                // value in current or larger bin
                else begin
                    // boundaries have converged to bin
                    if (val < bin_value + bin_width_signed) begin
                        current <= min;
                        search_state <= OUTPUT_RESULT;
                    end
                    // value outside of range
                    else if (current == max-1) begin 
                        current <= 6'b111111;
                        search_state <= OUTPUT_RESULT;
                    end
                    // continue search
                    else begin 
                        min <= current; // set new minimum boundary
                        current <= ((max - current) >> 1) + current; // half way between current and max
                        search_state <= UPDATE_BIN_VAL;
                    end
                end
            end
            
            OUTPUT_RESULT: begin
                binned <= 1;
                search_state <= RESET;
            end
            
            RESET: begin
                binned <= 0;
                max <= num_bins;
                min <= 6'b0;
                current <= num_bins>>1; // start at middle of range
                bin_value <= 32'd0;
                binned <= 0;
                if(data_in) begin
                    val <= value;
                    search_state <= UPDATE_BIN_VAL;
                end
            end
        endcase

    end

endmodule

// keeps running count of streaming bin vals to make 3d histogram
module hist2d_count(
        input clk100,
        input data_in,
        input [5:0] i_bin_coord, q_bin_coord,
        
        input reset_count, // sets all bins to zero
        
        output 
        output [15:0] bin_val 
    );

endmodule

// create 2d histogram of specified # bins, as data comes in
module hist2d(
    // dynamic input
    input clk100,
    input data_in,
    input [31:0] i_val, q_val,
    
    // static input (from config)
    input [4:0] i_bin_num, q_bin_num, // number of bins along each axis (value must be in range 1-63)
    input [15:0] i_bin_width, q_bin_width, // width of a bin along a given axis
    input signed [15:0] i_min, q_min, // bin origin
    input stream_mode, // 1 to output bin coords as they come in, 0 to construct histogram and then stream
    
    output valid_output, // boolean - 1 indicates valid data is on output lines
    output [5:0] i_bin_coord, // can have up to 63 bins along i direction (64th bin counts # outside range) 
    output [5:0] q_bin_coord, // can have up to 63 bins along q direction (64th bin counts # outside range) 
    output [15:0] bin_val); // total number of binnable values is 65536
    
    wire i_bin_found; // boolean: 1 when bin # for i data pt is found
    wire [5:0] i_bin_val;
    reg [5:0] i_bin_store; 
    
    wire q_bin_found; // boolean: 1 when bin # for q data pt is found
    wire [5:0] q_bin_val;
    reg [5:0] q_bin_store;
    
    reg i_q_found; // boolean: indicates when both i and q vals found
    
    reg [1:0] hist_state; // fsm to do 2d hist sequentially
    parameter SEARCHING = 2'b00;
    parameter ONE_FOUND = 2'b01;
    parameter TWO_FOUND = 2'b10;
    parameter RESET = 2'b11

    always @(posedge clk100) begin
        case(hist_state) begin
            SEARCHING: begin
                if(i_bin_found && q_bin_found) begin
                    hist_state <= TWO_FOUND;
                    i_bin_store <= i_bin_val;
                    q_bin_store <= q_bin_val;
                end
                else if(i_bin_found) begin
                    hist_state <= ONE_FOUND;
                    i_bin_store <= i_bin_val;
                end
                else if(q_bin_found) begin
                    hist_state <= ONE_FOUND;
                    q_bin_store <= q_bin_val;
                end
            end
            
            ONE_FOUND: begin
                if(i_bin_found) begin
                    hist_state <= TWO_FOUND;
                    i_bin_store <= i_bin_val;
                end
                else if(q_bin_found) begin
                    hist_state <= TWO_FOUND;
                    q_bin_store <= q_bin_val;
                end
            end
            
            TWO_FOUND: begin
                if(stream_mode) begin
                    i_bin_coord <= i_bin_store;
                    q_bin_coord <= q_bin_store;
                    i_q_found; <= 1;
                    bin_val <= 0;
                    hist_state <= RESET;
                end
                else begin
                    i_q_found; <= 1;
                    hist_state <= RESET;
                end
            end
            
            RESET: begin
                i_bin_coord <= 0;
                q_bin_coord <= 0;
                i_q_found; <= 0;
                bin_val <= 0;
                if(data_in) hist_state <= SEARCHING;
            end
        endcase
        
    end
    
    assign valid_output = i_q_found;
    
    // perform binary search along i axis
    bin_binary_search i_search(.clk100(clk100), .data_in(data_in), .value(i_val), .num_bins(i_bin_num), .bin_width(i_bin_width), .origin(i_min), .binned(i_bin_found), .current(i_bin_val));
    
    // perform binary search along q axis
    bin_binary_search q_search(.clk100(clk100), .data_in(data_in), .value(q_val), .num_bins(q_bin_num), .bin_width(q_bin_width), .origin(q_min), .binned(q_bin_found), .current(q_bin_val));
    
    // make 2d histogram in FPGA
    hist2d_count histogram(.clk100(clk100), .data_in(i_q_found), .i_bin_coord(i_bin_store), .q_bin_coord(q_bin_store), .data_out()) //need to implement memory, timing, and reset of this!
    

endmodule // hist2d

// perform linear classification of data points
module classify(
    // dynamic input
    input clk100,
    input data_in, // indicates if new i,q data is coming in 
    input signed [31:0] i_val, q_val, // pt to be classified
    
    // static input
    input signed [31:0] i_pt_line, q_pt_line, // pt on classification line
    // vector from origin with slope perpendicular to line, pts in direction of excited state
    input signed [31:0] i_vec_perp, q_vec_perp,

    // classified state of input 
    output reg [1:0] state,
    output reg valid_output); // boolean: 1 when there is valid output
    
    reg signed [31:0] i_vec_pt, q_vec_pt; // vector from origin to pt to classify

    reg signed [63:0] dot_product;

    // output state parameters
    parameter GROUND_STATE = 2'b01;
    parameter EXCITED_STATE = 2'b10;
    parameter CLASSIFY_LINE = 2'b11;
    parameter ERROR = 2'b00;
    
    reg [1:0] comp_state; // fsm to sequentially perform computation steps
    parameter DOT_PRODUCT = 2'b00;
    parameter CLASSIFY = 2'b01;
    parameter RESET = 2'b10;
    
    initial begin 
        comp_state <= RESET;
    end
    
    // NOTE: MIGHT NEED TO ADD BUFER STATES TO ACCOUNT FOR OPERATION LAG (IF OPS EXCEED CLOCK CYCLE)
    always @(posedge clk100) begin
        case(comp_state)
            
            DOT_PRODUCT: begin
                dot_product <= i_vec_pt*i_vec_perp + q_vec_pt*q_vec_perp;
                comp_state <= CLASSIFY;
            end
            
            CLASSIFY: begin
                // EXCITED STATE CLASSIFICATION
                if(dot_product>0) begin 
                    state <= EXCITED_STATE;
                    valid_output <= 1;
                end
                // GROUND STATE CLASSIFICATION
                else if (dot_product<0) begin
                    state <= GROUND_STATE;
                    valid_output <= 1;
                end
                // PT ON CLASSIFICATION LINE
                else if (dot_product==0) begin
                    state <= CLASSIFY_LINE;
                    valid_output <= 1;
                end
                // error case
                else begin 
                    state <= ERROR;
                end
                comp_state <= RESET;
            end
            
            RESET: begin 
                valid_output <= 0;
                if(data_in) begin
                    i_vec_pt <= i_val - i_pt_line;
                    q_vec_pt <= q_val - q_pt_line;
                    comp_state <= DOT_PRODUCT;
                end
            end
            
            default: comp_state <= RESET;
        
        endcase

    end

endmodule // classify

module analyze_fsm(
    input clk100,
    input [1:0] analyze_mode, // fsm state
    
    // i-q data parameters
    input data_in,
    input [31:0] i_val, q_val,

    // histogram inputs 
    input [3:0] x_bin, y_bin,

    // classification inputs
    input signed [31:0] i_vec_perp, q_vec_perp,
    input signed [31:0] i_pt_line, q_pt_line, 

    // output data and mode
    output reg [1:0] output_mode,
    output reg [63:0] output_channels);

    wire [1:0] state = analyze_mode;

    // define states
    parameter DATA_DUMP_MODE = 2'b00;
    parameter CLASSIFY_MODE = 2'b01;
    parameter HIST2D_MODE = 2'b11;

    // for reading output of different modules
    wire [63:0] read_classify;
    wire [63:0] read_hist2d;

    // analysis FSM
    always @(posedge clk100) begin
        output_mode <= state;
        case(state)
            DATA_DUMP_MODE: begin
                if (data_in) output_channels <= {i_val, q_val};
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
    //hist2d hist(.clk100(clk100),);

    classify lin_class(.clk100(clk100), .data_in(data_in), .i_val(i_val), .q_val(q_val), 
                   .i_pt_line(i_pt_line), .q_pt_line(q_pt_line), .i_vec_perp(i_vec_perp), 
                   .q_vec_perp(q_vec_perp),.state(read_classify));

endmodule // analyze_fsm


// REDUNDANT data dump module (NOT USED)
module data_dump(
    input clk100, // clock
    input data_in, // indicates if new i,q data is coming in 
    input [31:0] i_val, q_val,

    output reg [63:0] i_q_vals);

    always @(posedge clk100) begin
        if(data_in) begin
            i_q_vals <= {i_val,q_val};
        end
    end

endmodule // data_dump