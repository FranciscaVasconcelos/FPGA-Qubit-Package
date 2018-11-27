// FRAN STUFF

module data_dump(
    input clk100,
    input [31:0] i_val, q_val,
    output [63:0] i_q_vals
    );
    

endmodule // data_dump

module hist2d(
    input clk100,
    input [31:0] i_val, q_val,
    input [3:0] x_bin, y_bin,
    input [] x_min, y_min, x_max, y_max  
    );
    

endmodule // data_dump

module classify(
    input clk100,
    input signed [31:0] i_val, q_val, // pt to be classified
    input signed [31:0] i_pt_line, q_pt_line, // pt #1 on classification line
    // vector from origin with slope perpendicular to line, pts in direction of excited state
    input signed [31:0] i_vec_perp, q_vec_perp 
    output 
    );
    
    reg signed [31:0] i_vec_pt, q_vec_pt; // vector from origin to pt to classify

    reg signed [63:0] dot_product;

    always @(posedge clk100) begin
        i_vec_pt <= i_val - i_pt_line;
        q_vec_pt <= q_val - q_pt_line;

        // basic implementation, can be improved by looking just at signs/with tricks
        dot_product = i_vec_pt*i_vec_perp + q_vec_pt*q_vec_perp;

        // EXCITED STATE CLASSIFICATION
        if(dot_product>1'b0) begin
        end 
        // GROUND STATE CLASSIFICATION
        else if (dot_product<1'b0) begin
        end
        // PT ON CLASSIFIER
        else begin 
        end
    end

endmodule // data_dump

module analyze_fsm(
    input clk100,
    input [1:0] analyze_mode,
    input [31:0] i_val, q_val
    input [3:0] x_bin, y_bin 

    output [63:0] output_channels
    );

    wire [1:0] state = analyze_mode;

    // define states
    parameter DATA_DUMP_MODE = 2'b00;
    parameter CLASSIFY_MODE = 2'b01
    parameter HIST2D_MODE = 2'b11;
    

    // analysis FSM
    always @(posedge clk100) begin
        case(state)
            DATA_DUMP_MODE: begin

            end // DATA_DUMP_MODE

            CLASSIFY_MODE: begin

            end // DATA_DUMP_MODE

            HIST2D_MODE: begin

            end // DATA_DUMP_MODE

            default: output_channels <= 64'b0; 

        endcase
    end
    
    // instantiate analysis modules
    data_dump dump(.clk100(clk100),);

    hist2d hist(.clk100(clk100),);

    classify class(.clk100(clk100),);

endmodule // data_dump