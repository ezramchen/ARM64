module PC(
    input clk183,
    input rst183,
    input en183,
    input [63:0] npc183, // next program counter from control flow logic
    output reg [63:0] pc183 // current program counter
);

    always @(posedge clk183) begin
        if (rst183) begin
            pc183 <= 64'b0; // on reset, set PC to 0
        end else if(en183) begin
            pc183 <= npc183; // update PC to next PC on each clock cycle
        end
    end
endmodule
