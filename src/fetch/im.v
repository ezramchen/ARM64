module IM(
    input [63:0] addr183, // address from PC
    output [31:0] instr183 // instruction at that address
);

    // declare memory
    reg [31:0] mem183[0:1023]; // 4KB of memory (1024 words), can change

    // configure instructions
    assign instr183 = mem183[addr183[11:2]]; // word-aligned address (not fixed), ignore byte offset

    // load instructions
    initial begin 
        $readmemh("program.mem", mem183); // load instructions from hex file
    end
endmodule
