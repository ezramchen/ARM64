// undecided if pre-op shifts should be handled here or earlier

module ALU(
    input [63:0] srcA, // typically Rn
    input [63:0] srcB, // optionally inverted by pre-ALU MUX
    input [63:0] imm, // length set by pre-ALU MUX
    input [4:0] actrl, // ALU control, size temporary (?)
    output reg [63:0] alu_out
) 
    // placeholder
    always @(*) begin 
        case(actrl) 
            5'd0: alu_out = srcA + srcB;
        endcase
    end

endmodule
