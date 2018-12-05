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


// histogram memory (for storing bin_counts)
module hist2d_bram (
        //dynamic input
        input clk100,
        input [15:0] address,
        input write, // 1 when writing to memory, 0 when reading from memory
        input reset, // set all values in array to zero
        input [15:0] write_val,
        output reg [15:0] read_val,
        output reg [127:0] extended_read_val
    );
    
    // store 2d array in 1d bram, by making i LSB and q MSB
    reg [15:0] hist2d [255*255:0]; // bin vals BRAM
    
    integer j;
    
    initial begin
        for (j=0; j < 255*255+1; j=j+1) hist2d[j] = 16'b0; //reset array
    end
    
    always @(posedge clk100) begin
        if(reset) for (j=0; j < 255*255+1; j=j+1) hist2d[j] = 16'b0; //reset array
        else if(write) hist2d[address] <= write_val;
        else begin
            read_val <= hist2d[address];
            extended_read_val <= {hist2d[address], hist2d[address+1], hist2d[address+2], hist2d[address+3], hist2d[address+4]};
        end 
    end
    
endmodule

// output bin number for given data point
// increment bin_count in memory as well
module hist2d_store_bin(
        // dynamic input
        input clk100,
        input data_in,
        input [7:0] i_bin_coord, q_bin_coord,
        
        // for accessing histogram memory
        input [15:0] mem_read_val;
        output [15:0] mem_address; 
        output mem_write;
        output mem_reset;
        output [15:0] mem_write_val;

        // static input
        input [7:0] i_bin_num, q_bin_num // number of bins along axis
    );
    
    reg data_mode; // use fsm to keep track of mode
    parameter DATA_IN = 1;
    parameter STORE_VAL = 0;
    
    initial begin
        data_mode = DATA_IN;
        mem_read_val = 0;
        mem_address = 0; 
        omem_write = 0;
        mem_reset = 0;
        mem_write_val = 0;
    end
    
    always @(posedge clk100) begin
        case(data_mode) 
            DATA_IN: begin
                mem_write <= 0;
                if(data_in) begin
                    // overflow data
                    //if(i_bin_coord == 255 && q_bin_coord == 255) mem_address <= 255*255;
                    // normal data
                    mem_address <= i_bin_coord + q_bin_coord * i_bin_num;
                    data_mode <= STORE_VAL;
                end
            end
            
            STORE_VAL: begin
                mem_write <= 1;
                mem_write_val <= mem_read_val + 1;
                data_mode <= DATA_IN;
            end
        endcase  
    end
    
    // write values to memory
    //hist2d_bram hist_memory(.clk100(clk100), .address(mem_address), .write(mem_write), .reset(mem_reset), .write_val(mem_write_val), .read_val(mem_read_val), .extended_read_val());

endmodule

// streams out bin values with bin coordinates (one by one)
module hist2d_bin_out_stream(
        // dynamic input
        input clk100,
        input start_data_out,

        // static input
        input [15:0] num_data_pts, // total number of points to be binned
        input [7:0] i_bin_num, q_bin_num, // number of bins along axis
        
        // block ram ports
        input [15:0] mem_read_val;
        output [15:0] mem_address;  
        output mem_write;           
        output mem_reset;           
        output [15:0] mem_write_val;
        
        output reg data_out, // denotes that data pt is being sent
        output reg [15:0] bin_val,
        output [7:0] i_bin_out, q_bin_out 
    );

    reg [7:0] i_out_count = 0, q_out_count = 0;
    
    reg [2:0] data_mode; // use fsm to keep track of mode
    parameter DATA_OUT = 3'b001;
    parameter SEND_OUT = 3'b010;
    parameter CALC_ADDR = 3'b100;
    parameter RESET = 3'b101;
    parameter OVERFLOW = 3'b110;
    
    integer j;
    
    initial begin 
        data_mode = RESET;
        data_out = 0;
        mem_address = 0;  
        mem_write = 0;           
        mem_reset = 0;           
        mem_write_val = 0;
    end
    
    always @(posedge clk100) begin
        
        case(data_mode) 
            
            DATA_OUT: begin
                if(mem_address < i_bin_num*q_bin_num) begin // output value
                    data_out <= 1;
                    bin_val <= mem_read_val;
                    data_mode <= SEND_OUT;
                end
                else begin // end of values, output out_of_bounds bin, reset
                    mem_address <= 16'b1111111000000001;
                    mem_write <= 0;
                    data_mode <= OVERFLOW;
                end
            end
            
            OVERFLOW: begin
                data_out <= 1;
                bin_val <= mem_read_val; // over_flow_bin
                i_out_count <= 8'd255;
                q_out_count <= 8'd255;
                data_finished <= 1;
                data_mode <= RESET;
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
                mem_address <= i_out_count + q_out_count*i_bin_num;
                data_mode <= DATA_OUT;
            end
            
            RESET: begin
                i_out_count <= 0;
                q_out_count <= 0;
                bin_val <= 0; 
                data_out <= 0;
                if(start_data_out) data_mode <= DATA_OUT; 
            end
            
            default: data_mode <= RESET;
            
        endcase  
    end 
    
    assign i_bin_out = i_out_count;
    assign q_bin_out = q_out_count;
    
    //hist2d_bram hist_memory(.clk100(clk100), .address(mem_address), .write(mem_write), .reset(mem_reset), .write_val(mem_write_val), .read_val(mem_read_val), .extended_read_val());

endmodule

// streams out bin values 5 at a time (more efficient)
module hist2d_bin_out_multiple(
    // dynamic input
        input clk100,
        input start_data_out,

        // static input
        input [15:0] num_data_pts, // total number of points to be binned
        input [7:0] i_bin_num, q_bin_num, // number of bins along axis
        
        // for accessing histogram memory
        input [127:0] mem_extended_read_val;
        input [15:0] mem_read_val;
        output [15:0] mem_address; 
        output mem_write;
        output mem_reset;
        output [15:0] mem_write_val;

        output reg data_out, // denotes that data pt is being sent
        output reg [79:0] bins_out
    );
    
    reg [7:0] i_out_count = 0, q_out_count = 0;
    
    reg [1:0] data_mode; // use fsm to keep track of mode
    parameter DATA_OUT = 2'b00;
    parameter SEND_OUT = 2'b01;
    parameter RESET = 2'b10;
    
    initial begin 
        data_mode = RESET;
        data_out = 0;
        mem_address = 0;  
        mem_write = 0;           
        mem_reset = 0;           
        mem_write_val = 0;
    end
    
    always @(posedge clk100) begin
        
        case(data_mode) 
            
            DATA_OUT: begin
                if(mem_address < 255*255) begin // output value
                    data_out <= 1;
                    bins_out <= mem_extended_read_val[127:47];
                    data_mode <= SEND_OUT;
                end
                else begin // end of values, output out_of_bounds bin, reset
                    data_mode <= RESET;
                end
            end
            
            SEND_OUT: begin
                data_out <= 0;
                mem_address = mem_address + 5;
                data_mode <= DATA_OUT;
            end
            
            RESET: begin
                i_out_count <= 0;
                q_out_count <= 0; 
                data_out <= 0;
                if(start_data_out) data_mode <= DATA_OUT; 
            end
            
            default: data_mode <= RESET;
            
        endcase  
    end 
    
    //hist2d_bram hist_memory(.clk100(clk100), .address(mem_address), .write(mem_write), .reset(mem_reset), .write_val(mem_write_val), .read_val(mem_read_val), .extended_read_val(extended_read_val));
    
endmodule

// takes in i,q point and finds bin
// outputs bin and saves to hist_2d_memory
module hist2d_pt_to_bin(
        // dynamic input
        input clk100,
        input data_in,
        input signed [31:0] i_val, q_val,
        
        // static input (from config)
        input [7:0] i_bin_num, q_bin_num, // number of bins along each axis (value must be in range 1-63)
        input [15:0] i_bin_width, q_bin_width, // width of a bin along a given axis
        input signed [15:0] i_min, q_min, // bin origin
        
        // for accessing histogram memory
        input [15:0] mem_read_val;
        output reg [15:0] mem_address; 
        output reg mem_write;
        output reg mem_reset;
        output reg [15:0] mem_write_val;
        
        output reg i_q_found, // boolean - 1 indicated valid data output for ! stream mode
        output reg [7:0] i_bin_coord, // can have up to 255 bins along i direction (256th bin counts # outside range) 
        output reg [7:0] q_bin_coord // can have up to 255 bins along q direction (256th bin counts # outside range) 
    );
    
    wire i_bin_found; // boolean: 1 when bin # for i data pt is found
    wire [7:0] i_bin_val;
    reg [7:0] i_bin_store; 
    
    wire q_bin_found; // boolean: 1 when bin # for q data pt is found
    wire [7:0] q_bin_val;
    reg [7:0] q_bin_store;

    reg [1:0] hist_state; // fsm to do 2d hist sequentially
    parameter SEARCHING = 2'b00;
    parameter ONE_FOUND = 2'b01;
    parameter TWO_FOUND = 2'b10;
    parameter SEARCH_RESET = 2'b11;
    
    reg store_data = 0;

    initial begin
        hist_state = SEARCH_RESET;
    end

    always @(posedge clk100) begin
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
                i_bin_coord <= i_bin_store;
                q_bin_coord <= q_bin_store;
                i_q_found <= 1;
                store_data <= 1;
                hist_state <= SEARCH_RESET;
            end
            
            SEARCH_RESET: begin
                i_bin_coord <= 0;
                q_bin_coord <= 0;
                store_data <= 0;
                i_q_found <= 0;
                if(data_in) hist_state <= SEARCHING;
            end
            
        endcase
        
    end
    
    // perform binary search along i axis
    bin_binary_search i_search(.clk100(clk100), .data_in(data_in), .value(i_val), .num_bins(i_bin_num), 
                               .bin_width(i_bin_width), .origin(i_min), .binned(i_bin_found), .current(i_bin_val));
    
    // perform binary search along q axis
    bin_binary_search q_search(.clk100(clk100), .data_in(data_in), .value(q_val), .num_bins(q_bin_num), 
                               .bin_width(q_bin_width), .origin(q_min), .binned(q_bin_found), .current(q_bin_val));
    
    // save values to histogram memory                           
    hist2d_store_bin(.clk100(clk100),.data_in(store_data),.i_bin_coord(i_bin_coord), .q_bin_coord(q_bin_coord),
                     .i_bin_num(i_bin_num), .q_bin_num(q_bin_num), .mem_read_val(mem_read_val), .mem_address(mem_address),
                     .mem_write(mem_write), .mem_reset(mem_reset), .mem_write_val(mem_write_val));
    
endmodule // hist2d

module hist2d_master(
        // dynamic input
        input clk100,
        input data_in,
        input signed [31:0] i_val, q_val,
        input output_mode, // 1 -> stream, 0 -> multiple
            
        // static input (from config)
        input [15:0] num_data_pts, // total number of data points to be binned
        input [7:0] i_bin_num, q_bin_num, // number of bins along each axis (value must be in range 1-254, 255 used for overflow)
        input [15:0] i_bin_width, q_bin_width, // width of a bin along a given axis
        input signed [15:0] i_min, q_min, // bin origin
        
        output reg data_out, // 1 when data is being sent out
        output reg [79:0] fpga_output // FPGA has 5 16bit wire outputs (80 total bits)
    );
    
    reg start_data_out = 0; // begins data output from histogram memory
    
    // hist2d_pt_to_bin output
    wire i_q_found; // boolean - 1 indicated valid data output for ! stream mode
    wire [7:0] i_bin_coord; // can have up to 255 bins along i direction (256th bin counts # outside range) 
    wire [7:0] q_bin_coord; // can have up to 255 bins along q direction (256th bin counts # outside range)
    reg [15:0] pt_bin_mem_read_val;
    wire [15:0] pt_bin_mem_address; 
    wire pt_bin_mem_write;
    wire pt_bin_mem_reset;
    wire [15:0] pt_bin_mem_write_val;
    
    // hist2d_bin_out_multiple
    wire multi_data_out;
    wire [79:0] multi_bins_out;
    reg [127:0] multi_mem_extended_read_val;
    reg [15:0] multi_mem_read_val;
    wire [15:0] multi_mem_address; 
    wire multi_mem_write;
    wire multi_mem_reset;
    wire [15:0] multi_mem_write_val;
    
    // hist2d_bin_out_stream
    wire stream_data_out;
    wire [15:0] stream_bin_val;
    wire [7:0] stream_i_bin_out;
    wire [7:0] stream_q_bin_out;
    reg [15:0] pt_bin_mem_read_val;
    wire [15:0] pt_bin_mem_address; 
    wire pt_bin_mem_write;
    wire pt_bin_mem_reset;
    wire [15:0] pt_bin_mem_write_val;
    
    // for accessing histogram memory
    wire [127:0] mem_extended_read_val;
    wire [15:0] mem_read_val;
    reg [15:0] mem_address; 
    reg mem_write;
    reg mem_reset;
    reg [15:0] mem_write_val;
    
    // stream output FSM
    reg stream_state = 0;
    reg multi_state = 0;
    parameter PT_TO_BIN = 0;
    parameter STREAM_OUT = 1;
    parameter MULTI_OUT = 1;
    
    
    always @(posedge clk100) begin
        // memory access controls
        
        // stream output mode
        if(output_mode) begin
            data_out <= stream_data_out;
            fpga_output <= {80'd0, stream_bin_val, 8'd0, stream_i_bin_out, 8'd0, stream_q_bin_out};
        
            case(stream_state) begin
                PT_TO_BIN: begin
                    if(i_q_found) begin
                        mem_address <= stream_mem_address; 
                        mem_write <= stream_mem_write;
                        mem_reset <= stream_mem_reset;
                        mem_write_val <= stream_mem_write_val;
                        stream_mem_read_val <= mem_read_val;
                        
                        stream_state <= STREAM_OUT;
                        start_data_out <= 1;
                    end
                    else begin
                        mem_address <= pt_bin_mem_address; 
                        mem_write <= pt_bin_mem_write;
                        mem_reset <= pt_bin_mem_reset;
                        mem_write_val <= pt_bin_mem_write_val;
                        pt_bin_mem_read_val <= mem_read_val;
                    end
                end
                
                STREAM_OUT: begin

                    if(stream_i_bin_out == 8'd255 && stream_q_bin_out == 8'd255) begin
                        mem_address <= pt_bin_mem_address; 
                        mem_write <= pt_bin_mem_write;
                        mem_reset <= pt_bin_stream_mem_reset;
                        mem_write_val <= pt_bin_mem_write_val;
                        pt_bin_read_val <= mem_read_val;
                        
                        stream_state <= PT_TO_BIN;
                    end
                    else begin
                        start_data_out <= 0;
                        mem_address <= stream_mem_address; 
                        mem_write <= stream_mem_write;
                        mem_reset <= stream_mem_reset;
                        mem_write_val <= stream_mem_write_val;
                        stream_mem_read_val <= mem_read_val;
                    end
                
                end
            end
            
        end
        // multi output mode
        else begin
            data_out <= multi_data_out;
            
            case(multi_state) begin
                PT_TO_BIN: begin
                    if(i_q_found) begin
                        mem_address <= multi_mem_address; 
                        mem_write <= multi_mem_write;
                        mem_reset <= multi_mem_reset;
                        mem_write_val <= multi_mem_write_val;
                        multi_mem_read_val <= mem_read_val;
                        
                        multi_state <= MULTI_OUT;
                        start_data_out <= 1;
                    end
                    else begin
                        mem_address <= pt_bin_mem_address; 
                        mem_write <= pt_bin_mem_write;
                        mem_reset <= pt_bin_mem_reset;
                        mem_write_val <= pt_bin_mem_write_val;
                        pt_bin_mem_read_val <= mem_read_val; 
                    end
                end
                
                MULTI_OUT: begin
                    if(mem_address == 255*255) begin
                        mem_address <= pt_bin_mem_address; 
                        mem_write <= pt_bin_mem_write;
                        mem_reset <= pt_bin_stream_mem_reset;
                        mem_write_val <= pt_bin_mem_write_val;
                        pt_bin_read_val <= mem_read_val;
                        
                        multi_state <= PT_TO_BIN;
                    end
                    else begin 
                        start_data_out <= 0;
                        mem_address <= multi_mem_address; 
                        mem_write <= multi_mem_write;
                        mem_reset <= multi_mem_reset;
                        mem_write_val <= multi_mem_write_val;
                        multi_mem_read_val <= mem_read_val;
                        multi_mem_extended_read_val <= muem_extended_read_val;
                    end
                end
                
            end
        end
    end
    
    hist2d_pt_to_bin conv(.clk100(clk100), .data_in(data_in), .i_val(i_val), .q_val(q_val), .i_bin_num(i_bin_num), 
                          .q_bin_num(q_bin_num), .i_bin_width(i_bin_width), .q_bin_width(q_bin_width), .i_min(i_min), 
                          .q_min(q_min), .i_q_found(i_q_found), .i_bin_coord(i_bin_coord), .q_bin_coord(q_bin_coord),
                          .mem_read_val(pt_bin_mem_read_val), .mem_address(pt_bin_mem_address), .mem_write(pt_bin_mem_write), 
                          .mem_reset(pt_bin_mem_reset), .mem_write_val(pt_bin_mem_write_val));
                     
    hist2d_bin_out_multiple multi(.clk100(clk100), .start_data_out(start_data_out), .num_data_pts(num_data_pts), 
                                  .i_bin_num(i_bin_num), .q_bin_num(q_bin_num), .data_out(multi_data_out), .bins_out(multi_bins_out),
                                  .mem_read_val(multi_mem_read_val), .mem_address(multi_mem_address), .mem_write(multi_mem_write), 
                                  .mem_reset(multi_mem_reset), .mem_write_val(multi_mem_write_val), .mem_extended_read_val(multi_mem_extended_read_val));
                            
    hist2d_bin_out_stream stream(.clk100(clk100), .start_data_out(start_data_out), .num_data_pts(num_data_pts), 
                                 .i_bin_num(i_bin_num), .q_bin_num(q_bin_num), .data_out(stream_data_out), 
                                 .bin_val(stream_bin_val), .i_bin_out(stream_i_bin_out), .q_bin_out(stream_q_bin_out),
                                 .mem_read_val(stream_mem_read_val), .mem_address(stream_mem_address), .mem_write(stream_mem_write), 
                                 .mem_reset(stream_mem_reset), .mem_write_val(stream_mem_write_val));
    
    // central bram!                             
    hist2d_bram hist_memory(.clk100(clk100), .address(mem_address), .write(mem_write), .reset(mem_reset), .write_val(mem_write_val), .read_val(mem_read_val), .extended_read_val(extended_read_val));

endmodule


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

// keeps running count of number of points in each of classification states
module classify_count(
        // dynamic input
        input clk100,
        input reset,
        input data_in,
        input [1:0] state,
        
        output reg [15:0] excited_count, ground_count, line_count
    );
    
    parameter GROUND_STATE = 2'b01;
    parameter EXCITED_STATE = 2'b10;
    parameter CLASSIFY_LINE = 2'b11;
    parameter ERROR = 2'b00;
    
    initial begin
        excited_count = 0;
        ground_count = 0;
        line_count = 0;
    end

    always @(posedge clk100) begin
        if(reset) begin
            excited_count <= 16'b0;
            ground_count <= 16'b0;
            line_count <= 16'b0;
        end
        else begin
            if(data_in) begin
                case(state)
                
                    GROUND_STATE: ground_count <= ground_count + 1;
                    
                    EXCITED_STATE: excited_count <= excited_count + 1;
                    
                    CLASSIFY_LINE: line_count <= line_count + 1;
                    
                    ERROR: begin ; end 
                
                endcase
            end
        end
    end 
endmodule

module classify_master(
        input clk100,
        input [15:0] num_data_pts,
        
        input data_in, // indicates if new i,q data is coming in 
        input signed [31:0] i_val, q_val, // pt to be classified
        
        input stream_mode, // 1 to stream classifications as they come in, 0 to report counts at end
        
        // static input
        input signed [31:0] i_pt_line, q_pt_line, // pt on classification line
        // vector from origin with slope perpendicular to line, pts in direction of excited state
        input signed [31:0] i_vec_perp, q_vec_perp,
        
        output reg [127:0] fpga_output
    );
    
    // classify output
    wire [1:0] state;
    wire valid_class_pt;
    parameter GROUND_STATE = 2'b01;
    parameter EXCITED_STATE = 2'b10;
    parameter CLASSIFY_LINE = 2'b11;
    parameter ERROR = 2'b00;
    
    // classify_count input/output
    reg reset;
    reg [15:0] data_pt_count = 0;
    wire [15:0] excited_count;
    wire [15:0] ground_count;
    wire [15:0] line_count;
    
    reg [2:0] count_mode;
    parameter COUNT = 2'b00; 
    parameter OUTPUT_FINAL = 2'b01;
    parameter RESET = 2'b10;
    
    initial begin 
        count_mode = COUNT;
        fpga_output = 0;
    end
    
    always @(posedge clk100) begin
        // output values as they come in
        if(stream_mode) begin
            fpga_output <= {112'b0, valid_class_pt, 13'b0, state};
        end
        
        // output values while updating and signal when finished
        else begin
            case(count_mode)
            
                COUNT: begin
                    reset <= 0;
                    if(data_pt_count < num_data_pts-1) begin
                        fpga_output <= {16'b0, data_pt_count, excited_count, ground_count, line_count};
                        reset <= 0;
                        if(valid_class_pt) data_pt_count <= data_pt_count + 1;
                    end
                    else count_mode <= OUTPUT_FINAL;
                end
                
                OUTPUT_FINAL: begin
                    fpga_output <= {16'd1, data_pt_count, excited_count, ground_count, line_count};
                    count_mode <= RESET;
                end
                
                RESET: begin
                    reset <= 1;
                    data_pt_count <= 0;
                    fpga_output <= 0;
                    count_mode <= COUNT;
                end
                
                default count_mode <= RESET;
                
            endcase
        end
    end
    
    classify lin_class(.clk100(clk100), .data_in(data_in), .i_val(i_val), .q_val(q_val), 
                       .i_pt_line(i_pt_line), .q_pt_line(q_pt_line), .i_vec_perp(i_vec_perp), 
                       .q_vec_perp(q_vec_perp), .state(state), .valid_output(valid_class_pt));
    
    classify_count bin(.clk100(clk100), .reset(reset),.data_in(valid_class_pt), .state(state),
                       .excited_count(excited_count), .ground_count(ground_count), .line_count(line_count));
    
endmodule


// FSM to tie it all together
module analyze_fsm(
    input clk100,
    
    //config params
    input [1:0] analyze_mode, // fsm state
    input [15:0] num_data_pts, // total number of points
    input [1:0] ouput_mode, // stream or no stream?    
    
    // i-q data parameters
    input data_in,
    input signed [31:0] i_val, q_val,

    // histogram inputs 
    input [3:0] x_bin, y_bin,

    // classification inputs
    input signed [31:0] i_vec_perp, q_vec_perp,
    input signed [31:0] i_pt_line, q_pt_line, 

    // output data
    output reg [127:0] output_channels);

    wire [1:0] state = analyze_mode;

    // define states
    parameter DATA_DUMP_MODE = 2'b00;
    parameter CLASSIFY_MODE = 2'b01;
    parameter HIST2D_MODE = 2'b11;

    // for reading output of different modules
    wire [127:0] classify_output;
    wire [127:0] hist2d_output;

    // analysis FSM
    always @(posedge clk100) begin
        case(state)

            DATA_DUMP_MODE: begin
                if (data_in) output_channels <= {64'd0, i_val, q_val};
            end 

            CLASSIFY_MODE: begin
                output_channels <= classify_output;
            end 

            HIST2D_MODE: begin
                output_channels <= hist2d_output;
            end

            default: output_channels <= 64'b0; 

        endcase
    end
    
    // linear classification control module
    classify_master lin_class(.clk100(clk100), .num_data_pts(num_data_pts), .data_in(data_in), .i_val(i_val), 
                              .q_val(q_val), .stream_mode(output_mode), .i_pt_line(i_pt_line), .q_pt_line(q_pt_line), 
                              .i_vec_perp(i_vec_perp), .q_vec_perp(q_vec_perp), .fpga_output(classify_output));
    
    // 2D histogram control module
    hist2d_master hist2d(.clk100(clk100), .data_in(data_in), .i_val(i_val), .q_val(q_val), .output_mode(output_mode),
                         .num_data_pts(num_data_pts), .i_bin_num(i_bin_num), .q_bin_num(q_bin_num), .i_bin_width(i_bin_width), 
                         .q_bin_width(q_bin_width), .i_min(i_min), .q_min(q_min), .data_out(), .fpga_output(hist2d_output));
    
endmodule // analyze_fsm



// MODULE GRAVEYARD: WHERE BAD VERILOG GOES TO DIE

// keeps running count of streaming bin vals to make 2d histogram
/*module hist2d_count(
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
    
    // for accessing histogram memory
    reg [15:0] mem_address = 0; 
    reg mem_write;
    reg mem_reset;
    reg [15:0] mem_write_val;
    wire [15:0] mem_read_val;
    
    reg [15:0] data_in_count = 0; 
    reg [7:0] i_out_count = 0, q_out_count = 0;
    
    reg [2:0] data_mode; // use fsm to keep track of mode
    parameter DATA_IN = 3'b000;
    parameter DATA_OUT = 3'b001;
    parameter SEND_OUT = 3'b010;
    parameter STORE_VAL = 3'b011;
    parameter CALC_ADDR = 3'b100;
    parameter RESET = 3'b101;
    parameter OVERFLOW = 3'b110;
    
    integer j;
    
    initial begin 
        data_mode <= RESET;
        streaming_out <= 0;
        data_out <= 0;
    end
    
    always @(posedge clk100) begin
        
        case(data_mode) 
        
            DATA_IN: begin
                mem_write <= 0;
                if(data_in) begin
                    // overflow data
                    if(i_bin_coord == 255 && q_bin_coord == 255) mem_address <= 255*255;
                    // normal data
                    else mem_address <= i_bin_coord + q_bin_coord * i_bin_num;
                    data_mode <= STORE_VAL;
                end
                if(data_in_count >= num_data_pts) begin
                    data_mode <= DATA_OUT;
                    streaming_out <= 1;
                    mem_address <= 0;
                end
            end
            
            STORE_VAL: begin
                mem_write <= 1;
                mem_write_val <= mem_read_val + 1;
                data_in_count <= data_in_count + 1;
                data_mode <= DATA_IN;
            end
            
            DATA_OUT: begin
                if(mem_address < i_bin_num*q_bin_num) begin // output value
                    data_out <= 1;
                    bin_val <= mem_read_val;
                    data_mode <= SEND_OUT;
                end
                else begin // end of values, output out_of_bounds bin, reset
                    mem_address <= 16'b1111111000000001;
                    mem_write <= 0;
                    data_mode <= OVERFLOW;
                end
            end
            
            OVERFLOW: begin
                data_out <= 1;
                bin_val <= mem_read_val; // over_flow_bin
                i_out_count <= 8'd255;
                q_out_count <= 8'd255;
                streaming_out <= 0;
                data_mode <= RESET;
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
                mem_address <= i_out_count + q_out_count*i_bin_num;
                data_mode <= DATA_OUT;
            end
            
            RESET: begin
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
    
    hist2d_bram hist_memory(.clk100(clk100), .address(mem_address), .write(mem_write), .reset(mem_reset), .write_val(mem_write_val), .read_val(mem_read_val));
    
endmodule*/

// REDUNDANT data dump module (NOT USED)
/*module data_dump(
    input clk100, // clock
    input data_in, // indicates if new i,q data is coming in 
    input [31:0] i_val, q_val,

    output reg [63:0] i_q_vals);

    always @(posedge clk100) begin
        if(data_in) begin
            i_q_vals <= {i_val,q_val};
        end
    end

endmodule // data_dump*/

// create 2d histogram of specified # bins, as data comes in
/*module hist2d(
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
endmodule // hist2d */