// FRAN STUFF

// recursive algorithm to find bin! :D
module bin_binary_search(
    input clk100,
    input data_in,
    input [31:0] value,
    input [5:0] num_bins, // value must be in range 1-63 
    input [15:0] bin_width,    
    
    output reg binned, // boolean that outputs 1 when value has been binned
    output reg [5:0] current); // contains value bin when binned=1 (in range 0 to num_bins, 63 if out of range)
    
    reg [5:0] max; // max possible bin value
    reg [5:0] min; // max possible bin value
    reg [31:0] bin_value; // current bin value we are comparing to
    
    always @(posedge clk100) begin
        if(data_in) begin //
            max <= num_bins;
            min <= 6'b0;
            current <= num_bins>>1; // start at middle of range
            binned <= 0;
            
            while(!binned) begin
                bin_value <= current*bin_width;
                
                // value falls right on bin boundary
                if(value == bin_value) begin
                    binned <= 1;
                end
                // boundaries have converged to bin
                else if(max == min + 1) begin
                    binned <= 1;
                    current <= min;
                end
                // value in smaller bin
                else if(value < bin_value) begin
                    if(current == min) begin // value outside of binning range
                        current <= 6'b111111;
                        binned <= 1;
                    end
                    else begin 
                        max <= current; // set new maximum boundary
                        current <= current >> 1; // divide current by 2
                    end
                end
                // value in current or larger bin
                else begin
                    if(current == max) begin // value outside of binning range
                        current <= 6'b111111;
                        binned <= 1;
                    end
                    else begin 
                        min <= current; // set new minimum boundary
                        current <= (max - current) >> 1;
                    end
                end
            end 
        end
    end

endmodule

// counts streaming bin vals to output constructed histogram to computer
module hist2d_construct(

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
    
    output reg valid_output, // boolean - 1 indicates valid data is on output lines
    output reg [5:0] i_bin_coord, // can have up to 63 bins along i direction (64th bin counts # outside range) 
    output reg [5:0] q_bin_coord, // can have up to 63 bins along q direction (64th bin counts # outside range) 
    output reg [15:0] bin_val); // total number of binnable values is 65536
    
    wire i_bin_found; // boolean: 1 when bin # for i data pt is found
    wire [5:0] i_bin_val;
    
    reg i_val_stored; // boolean: 1 when i bin val for current data point is saved
    reg q_val_stored; // boolean: 1 when q bin val for current data point is saved 
    
    wire q_bin_found; // boolean: 1 when bin # for q data pt is found
    wire [5:0] q_bin_val;

    always @(posedge clk100) begin
        if(data_in) begin // reset values for new data input
            
        end
        
        if(i_bin_found) begin
            if(stream_mode) begin
                i_bin_coord <= i_bin_val;
                i_val_stored <= 1;
            end
        end
        if(q_bin_found) begin
            if(stream_mode) begin
                q_bin_coord <= q_bin_val;
                q_val_stored <= 1;
            end
        end
        if(i_val_stored && q_val_stored) valid_output <= 1;
        
    end
    
    // perform binary search along i axis
    bin_binary_search i_search(.clk100(clk100), .data_in(data_in), .value(i_val), .num_bins(i_bin_num), .bin_width(i_bin_width), .binned(i_bin_found), .current(i_bin_val));
    
    // perform binary search along i axis
    bin_binary_search q_search(.clk100(clk100), .data_in(data_in), .value(q_val), .num_bins(q_bin_num), .bin_width(q_bin_width), .binned(q_bin_found), .current(q_bin_val));
    

endmodule // hist2d

// perform linear classification of data points
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
    output [1:0] output_mode,
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
    hist2d hist(.clk100(clk100),);

    classify lin_class(.clk100(clk100), .data_in(data_in), .i_val(i_val), .q_val(q_val), 
                   .i_pt_line(i_pt_line), .q_pt_line(q_pt_line), .i_vec_perp(i_vec_perp), 
                   .q_vec_perp(q_vec_perp),.state(read_classify));

endmodule // analyze_fsm


// REDUNDANT data dump module (NOT USED)
module data_dump(
    input clk100, // clock
    input data_in, // indicates if new i,q data is coming in 
    input [31:0] i_val, q_val,

    output [63:0] i_q_vals);

    always @(posedge clk100) begin
        if(data_in) begin
            i_q_vals <= {i_val,q_val};
        end
    end

endmodule // data_dump