// Registers
// W ~ 32-bit instruction (will clear top bits), X ~ 64-bit instruction, R ~ non-descript
// r0-r30 GPR (not all treated like GPRs by compiler but this isn't a compiler)
// r31 = stack pointer or NULL write (hardcoded 0)

module RF(
    input clk,
    input rst,
    input sprd,
    input [4:0] rga1, // read address 1 (rs183)
    input [4:0] rga2, // read address 2 (rt183)
    input [4:0] wra, // write address (rd183 or rt183 or $ra)
    input [63:0] wrd, // write data
    input [1:0] wre, // write enable
    output [63:0] rgd1, // read data 1
    output [63:0] rgd2 // read data 2
);
    // declare registers
    reg [63:0] regs[0:31]; // ordered from r0-r31

    // if reading SP, return 0 (unless enabled for RN), else return register value
    assign rgd1 = ((rga1 == 5'd31) && !sprd) ? 64'b0 : regs[rga1]; // RN
    assign rgd2 = (rga2 == 5'd31) ? 64'b0 : regs[rga2]; // RM

    // for loops
    integer i;

    // write logic
    always @(posedge clk) begin
        if (rst) begin // on reset, clear all registers to 0
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 64'b0;
            end
        end else begin
            if(wre[0]) begin // regFile write enable (RD, SP)
                if (wra != 5'd31) begin 
                    regs[wra] <= wrd; // update if not SP (RD)
                end else if (wre[1]) begin 
                    regs[31] <= wrd; // update SP w/ access
                end
            end
        end
    end
endmodule
