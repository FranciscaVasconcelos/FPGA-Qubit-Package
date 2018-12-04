// FRAN STUFF

// recursive algorithm to find bin! :D
module bin_binary_search(
    // dynamic input
    input clk100,
    input data_in,
    input signed [31:0] value,
    // static input
    input [7:0] num_bins, // value must be in range 1-255
    input [15:0] bin_width,    
    input signed [15:0] origin,
    
    output reg binned, // boolean that outputs 1 when value has been binned
    output reg [7:0] current); // contains value bin when binned=1 (in range 0 to num_bins, 63 if out of range)
    
    reg signed [31:0] val; // for storing value when data_in = 1;
    
    reg [7:0] max; // max possible bin value
    reg [7:0] min; // max possible bin value
    reg signed [31:0] bin_value; // current bin value we are comparing to
    
    wire signed [8:0] current_signed;
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
                       current <= 8'b1111_1111;
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
                        current <= 8'b1111_1111;
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

module hist2d_bram (
        //dynamic input
        input clk100,
        input [15:0] address,
        input write, // 1 when writing to memory, 0 when reading from memory
        input [15:0] write_val,
        output reg [15:0] read_val
    );
    
    // store 2d array in 1d bram, by making i LSB and q MSB
    reg [15:0] hist2d [255*255:0]; // bin vals BRAM
    
    integer j;
    
    initial begin
        for (j=0; j < 255*255+1; j=j+1) hist2d[j] = 16'b0; //reset array
    end
    
    always @(posedge clk100) begin
        if(write) hist2d[address] <= write_val;
        else read_val <= hist2d[address];
    end
    
endmodule

// keeps running count of streaming bin vals to make 2d histogram
module hist2d_count(
        // dynamic input
        input clk100,
        input data_in,
        input [7:0] i_bin_coord, q_bin_coord,

        // static input
        input [15:0] num_data_pts, // total number of points to be binned
        input [7:0] i_bin_num, q_bin_num, // number of bins along axis
        
        output reg streaming_out, //denotes that is in output mode
        output reg data_out, // denotes that data pt is being sent
        output reg [15:0] bin_val,
        output [7:0] i_bin_out, q_bin_out 
    );
    
    // store 2d array in 1d bram, by making i LSB and q MSB
    reg [15:0] bin_count [255*255:0]; // bin vals BRAM
    
    reg [15:0] address = 0; // for storing the current memory access address
    
    reg [15:0] data_in_count = 0; 
    reg [7:0] i_out_count = 0, q_out_count = 0;
    
    reg [2:0] data_mode; // use fsm to keep track of mode
    parameter DATA_IN = 3'b000;
    parameter DATA_OUT = 3'b001;
    parameter SEND_OUT = 3'b010;
    parameter STORE_VAL = 3'b011;
    parameter CALC_ADDR = 3'b100;
    parameter RESET = 3'b101;
    
    integer j;
    
    initial begin 
        data_mode <= DATA_IN;
        streaming_out <= 0;
        data_out <= 0;
        for (j=0; j < 255*255+1; j=j+1) bin_count[j] = 16'b0; //reset array
    end
    
    always @(posedge clk100) begin
        
        case(data_mode) 
        
            DATA_IN: begin
                if(data_in) begin
                    // overflow data
                    if(i_bin_coord == 255 && q_bin_coord == 255) address <= 255*255;
                    // normal data
                    else address <= i_bin_coord + q_bin_coord * i_bin_num;
                    data_mode <= STORE_VAL;
                end
                if(data_in_count >= num_data_pts) begin
                    data_mode <= DATA_OUT;
                    streaming_out <= 1;
                    address <= 0;
                end
            end
            
            STORE_VAL: begin
                bin_count[address] <= bin_count[address] + 1;
                data_in_count <= data_in_count + 1;
                data_mode <= DATA_IN;
            end
            
            DATA_OUT: begin
                if(address < i_bin_num*q_bin_num) begin // output value
                    data_out <= 1;
                    bin_val <= bin_count[address];
                    data_mode <= SEND_OUT;
                end
                else begin // end of values, output out_of_bounds bin, reset
                    data_out <= 1;
                    bin_val <= bin_count[16'b1111111000000001]; // over_flow_bin
                    address <= 16'b1111111000000001;
                    i_out_count <= 8'd255;
                    q_out_count <= 8'd255;
                    streaming_out <= 0;
                    data_mode <= RESET;
                end
            end
            
            SEND_OUT: begin
                data_out <= 0;
                // update i and q counts
                if(i_out_count < i_bin_num-1) i_out_count <= i_out_count+1;
                else begin 
                    q_out_count <= q_out_count+1;
                    i_out_count <= 0;
                end
                data_mode <= CALC_ADDR;
            end
            
            CALC_ADDR: begin
                address <= i_out_count + q_out_count*i_bin_num;
                data_mode <= DATA_OUT;
            end
            
            RESET: begin
                for (j=0; j < 255*255+1; j=j+1) bin_count[j] = 16'b0; //reset array
                i_out_count <= 0;
                q_out_count <= 0;
                bin_val <= 0; 
                data_out <= 0;
                data_in_count <= 0;
                data_mode <= DATA_IN;
            end
            
            default: data_mode <= DATA_IN;
            
        endcase  
    end 
    
    assign i_bin_out = i_out_count;
    assign q_bin_out = q_out_count;
endmodule

// create 2d histogram of specified # bins, as data comes in
module hist2d(
    // dynamic input
    input clk100,
    input data_in,
    input signed [31:0] i_val, q_val,
    
    // static input (from config)
    input [7:0] i_bin_num, q_bin_num, // number of bins along each axis (value must be in range 1-63)
    input [15:0] i_bin_width, q_bin_width, // width of a bin along a given axis
    input signed [15:0] i_min, q_min, // bin origin
    input [15:0] num_data_pts, // total number of points to be binned
    input stream_mode, // 1 to output bin coords as they come in, 0 to construct histogram and then stream
    
    output reg i_q_found, // boolean - 1 indicates valid data output for stream mode
    output reg bin_found, // boolean - 1 indicated valid data output for ! stream mode
    output reg [7:0] i_bin_coord, // can have up to 255 bins along i direction (256th bin counts # outside range) 
    output reg [7:0] q_bin_coord, // can have up to 255 bins along q direction (256th bin counts # outside range) 
    output reg [15:0] bin_val); // total number of binnable values is 65536
    
    wire i_bin_found; // boolean: 1 when bin # for i data pt is found
    wire [7:0] i_bin_val;
    reg [7:0] i_bin_store; 
    
    wire q_bin_found; // boolean: 1 when bin # for q data pt is found
    wire [7:0] q_bin_val;
    reg [7:0] q_bin_store;

    
    reg [2:0] hist_state; // fsm to do 2d hist sequentially
    parameter SEARCHING = 3'b000;
    parameter ONE_FOUND = 3'b001;
    parameter TWO_FOUND = 3'b010;
    parameter SEARCH_RESET = 3'b011;
    parameter DATA_OUT = 3'b100;
    parameter DATA_OUT_RESET = 3'b101;
    
    
    wire [15:0] hist2d_count_bin_val;
    wire [7:0] hist2d_count_i_bin_coord;
    wire [7:0] hist2d_count_q_bin_coord;
    
    reg store_data = 0; // for controlling hist2d_count
    wire valid_output; // for when hist2d_count outputs data
    wire output_mode;

    initial begin
        hist_state = SEARCH_RESET;
    end

    always @(posedge clk100) begin
        // move into data_out portion of FSM
        if((!stream_mode) && output_mode && hist_state != DATA_OUT && hist_state != DATA_OUT_RESET) begin
            bin_found <= 1;
            bin_val <= hist2d_count_bin_val;
            i_bin_coord <= hist2d_count_i_bin_coord;
            q_bin_coord <= hist2d_count_q_bin_coord;
            hist_state <= DATA_OUT_RESET;
        end
        
        case(hist_state) 
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
                    i_q_found <= 1;
                    bin_val <= 0;
                    hist_state <= SEARCH_RESET;
                end
                else begin
                    i_bin_coord <= i_bin_store;
                    q_bin_coord <= q_bin_store;
                    store_data <= 1;
                    hist_state <= SEARCH_RESET;
                end
            end
            
            SEARCH_RESET: begin
                i_bin_coord <= 0;
                q_bin_coord <= 0;
                store_data <= 0;
                bin_val <= 0;
                i_q_found <= 0;
                
                if(data_in) hist_state <= SEARCHING;
            end
            
            DATA_OUT: begin
                if(valid_output) begin
                    bin_found <= 1;
                    bin_val <= hist2d_count_bin_val;
                    i_bin_coord <= hist2d_count_i_bin_coord;
                    q_bin_coord <= hist2d_count_q_bin_coord;
                    hist_state <= DATA_OUT_RESET;
                end
            end
            
            DATA_OUT_RESET: begin
                i_bin_coord <= 0;
                q_bin_coord <= 0;
                bin_val <= 0;
                bin_found <= 0;
                if(output_mode) hist_state <= DATA_OUT;
                else hist_state <= SEARCH_RESET;
            end
        endcase
        
    end
    
    // perform binary search along i axis
    bin_binary_search i_search(.clk100(clk100), .data_in(data_in), .value(i_val), .num_bins(i_bin_num), 
                               .bin_width(i_bin_width), .origin(i_min), .binned(i_bin_found), .current(i_bin_val));
    
    // perform binary search along q axis
    bin_binary_search q_search(.clk100(clk100), .data_in(data_in), .value(q_val), .num_bins(q_bin_num), 
                               .bin_width(q_bin_width), .origin(q_min), .binned(q_bin_found), .current(q_bin_val));
    
    // make 2d histogram in FPGA
    hist2d_count histogram(.clk100(clk100), .data_in(store_data), .i_bin_coord(i_bin_store), .q_bin_coord(q_bin_store), 
                           .num_data_pts(num_data_pts), .i_bin_num(i_bin_num), .q_bin_num(q_bin_num), .data_out(valid_output), 
                           .streaming_out(output_mode),.bin_val(hist2d_count_bin_val),.i_bin_out(hist2d_count_i_bin_coord), 
                           .q_bin_out(hist2d_count_g_bin_coord));
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