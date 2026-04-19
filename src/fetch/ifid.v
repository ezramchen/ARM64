module IF_ID(
    input clk183,
    input rst183,
    input flush183,
    input en183,

    // IF
    input [31:0] instr_if183,
    input [63:0] pc4_if183,

    // ID
    output reg [31:0] instr_id183,
    output reg [63:0] pc4_id183
); // IF/ID pipeline register

    always @(posedge clk183) begin
        if(rst183 || flush183) begin
            instr_id183 <= 32'b0;
            pc4_id183 <= 64'b0;
        end else if(en183) begin
            instr_id183 <= instr_if183;
            pc4_id183 <= pc4_if183;
        end
    end
endmodule
