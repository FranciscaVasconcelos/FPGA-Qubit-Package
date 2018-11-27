// FRAN STUFF

module data_dump(
    input clk100,
    input [31:0] i_val, q_val,
    output [63:0] i_q_vals
    );
    

endmodule // data_dump

module binner(
    input clk100,
    input [31:0] i_val, q_val,
    input [3:0] x_bin, y_bin  
    );
    

endmodule // data_dump

module classify(
    input [31:0] i_val, q_val
    input [31:0] i_pt_1, q_pt_1
    input [31:0] i_pt_2, q_pt_2
    );
    

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
    parameter BIN_MODE = 2'b11;
    

    // analysis FSM
    always @(posedge clk100)
        case(state)
            DATA_DUMP_MODE: begin

            end // DATA_DUMP_MODE

            CLASSIFY_MODE: begin

            end // DATA_DUMP_MODE

            BIN_MODE: begin

            end // DATA_DUMP_MODE

            default: output_channels <= 64'b0; 

        endcase
    end
    
    // instantiate analysis modules
    data_dump dump();

    binner bin();

    classify class();

endmodule // data_dump