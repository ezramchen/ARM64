// ARM64
// mctrl = [ F | WB | MEM | EX | ID | SP ]

module MCU(
    input [31:0] instr,
    output reg [31:0] mctrl
);

    // [31] FlagWr: 1 = update flags, 0 = no update 

    // [30:29] RegWr: Register write enable
    localparam [1:0] NOWR = 2'b00; // no write
    localparam [1:0] RDWR = 2'b01; // write to RD
    localparam [1:0] VDWR = 2'b10; // write to VD
    localparam [1:0] SPWR = 2'b11; // write to SP

    // [28:27] ResSrc: Register sources for writeback
    localparam [1:0] ALU = 2'b00; // ALU path
    localparam [1:0] MEM = 2'b01; // MEM path
    localparam [1:0] MUL = 2'b10; // MDU path
    localparam [1:0] FPU = 2'b11; // FPU path

    // [26] RegDst: 1 = write to SP, 0 = write to RD

    // [25] MemRd: 1 = read from memory (load instruction), 0 = no memory read
    // [24] MemWr: 1 = write to memory (store instruction), 0 = no memory write

    // [23:22] Memory Sizes (MemSz)
    localparam [1:0] BYTE = 2'b00;
    localparam [1:0] HALF = 2'b01;
    localparam [1:0] WORD = 2'b10;
    localparam [1:0] DBLE = 2'b11;
    
    // [21] OpSz: 1 = 64-bit, 0 = 32-bit

    // [20:17] Imm Type
    localparam [3:0] INONE = 4'b0000; // reg-type or other
    localparam [3:0] I2210 = 4'b0001; // arithmetic, logic, bitfield ops
    localparam [3:0] I2012 = 4'b0010; // unscaled load, store
    localparam [3:0] I2115 = 4'b0011; // pair-wise load, store
    localparam [3:0] I2305 = 4'b0100; // conditional branch, compare & branch
    localparam [3:0] I2500 = 4'b0101; // branch, branch w/ link
    localparam [3:0] I1805 = 4'b0110; // test & branch
    localparam [3:0] I2005 = 4'b0111; // misc. branching/exceptions, move-wide
    localparam [3:0] I1510 = 4'b1000; // extract, rotate right, fp-conversion
    localparam [3:0] I1710 = 4'b1001; // min/max
    localparam [3:0] I2016 = 4'b1010; // conditional compare
    localparam [3:0] I2013 = 4'b1011; // FP move
    localparam [3:0] I2216 = 4'b1100; // vector shift by immediate
    localparam [3:0] I1411 = 4'b1101; // extract vector
    localparam [3:0] ISIMD = 4'b1110; // vector immediate instructions; [29] | [18:12] | [9:5]
    localparam [3:0] IPCRL = 4'b1111; // PC relative addressing; [30:29] | [23:5]
    
    // [16:13] Constants for Opcodes (ALUOp)
    localparam [3:0] ADD = 4'b0000; // add(s), load, store
    localparam [3:0] SUB = 4'b0001; // sub(s), cmp, cmn
    localparam [3:0] AND = 4'b0010; // and(s)
    localparam [3:0] ORR = 4'b0011; // orr
    localparam [3:0] EOR = 4'b0100; // eor
    localparam [3:0] UBM = 4'b0101; // ubfm
    localparam [3:0] SBM = 4'b0110; // sbfm
    localparam [3:0] BFM = 4'b0111; // bfm
    localparam [3:0] MVZ = 4'b1000; // movz
    localparam [3:0] MVN = 4'b1001; // movn
    localparam [3:0] MVK = 4'b1010; // movk
    localparam [3:0] EXT = 4'b1011; // extr
    localparam [3:0] MUL = 4'b1100; // mul
    localparam [3:0] UML = 4'b1101; // umul

    // [12] ImmSL: 1 = shift imm left n bits, 0 = no shift
    // [11] InvOp: 1 = invert 2nd operand, 0 = non

    // [10:8] Branch Types (BT)
    localparam [2:0] NOB = 3'b000; // no branch
    localparam [2:0] UCI = 3'b001; // unconditional branch imm (b, bl)
    localparam [2:0] UCR = 3'b010; // unconditional branch reg (br, blr, RET)
    localparam [2:0] ZER = 3'b011; // check against zero (cbz, cbnz)
    localparam [2:0] BIT = 3'b100; // test bit (tbz, tbnz)
    localparam [2:0] CND = 3'b101; // conditional branch (b.cond)

    // [7] BranchInv: 1 = invert condition (cbnz, tbnz), 0 = normal (cbz, tbz)
    // [6] Link: 1 = NPC -> LR (r30), 0 = nol
    // [5] SPRd: 1 = SP -> RN, 0 = nox

    always @(*) begin 
        mctrl[31:0] = 32'b0; // effectively includes nop
        casez(instr[28:25])
            4'b100?: begin // Data Processing w/ Imm
                casez(instr[25:22]) 
                    4'b00??: begin 
                        mctrl[21:13] = {1'b1, IPCRL, ADD}; // adr, adrp
                        mctrl[12] = instr[31] ? 1'b1 : 1'b0; // imm << 12 if adrp
                    end
                    4'b010?: begin // add(s), sub(s)
                        mctrl[31] = instr[29] ? 1'b1 : 1'b0; // set flags (adds, subs)
                        mctrl[21:17] = {instr[31], I2210}; // imm for add/sub
                        mctrl[16:13] = instr[30] ? SUB : ADD; // add vs sub
                        mctrl[12] = (instr[31] && instr[22]) ? 1'b1 : 1'b0; // imm << 12 cond for 64-bit
                    end
                    4'b100?: begin // and(s), orr, eor
                        mctrl[31] = (instr[30:29] == 2'b11) ? 1'b1 : 1'b0; // set flags (ands)
                        mctrl[21:17] = {instr[31], I2210}; // imm for logic
                        case(instr[30:29]) 
                            2'b00: mctrl[16:13] = AND; // and
                            2'b01: mctrl[16:13] = ORR; // orr
                            2'b10: mctrl[16:13] = EOR; // eor
                            2'b11: mctrl[16:13] = AND; // ands
                        endcase
                    end
                    4'b101?: begin // mov
                        mctrl[21:17] = {instr[31], I2005};
                        case(instr[30:29]) 
                            2'b00: mctrl[16:13] = MVN; // movn
                            2'b10: mctrl[16:13] = MVZ; // movz
                            2'b11: mctrl[16:13] = MVK; // movk 
                        endcase
                    end
                    4'b110?: begin // bfm
                        mctrl[21:17] = {instr[31], I2210};
                        case(instr[30:29]) 
                            2'b00: mctrl[16:13] = SBM; // sbfm
                            2'b01: mctrl[16:13] = BFM; // bfm
                            2'b10: mctrl[16:13] = UBM; // ubfm 
                        endcase
                    end
                    4'b111?: begin // extr
                        if (instr[30:29] == 2'b0) begin 
                            mctrl[21:13] = {instr[31], I1510, EXT};
                        end
                    end
                endcase
            end
            4'b101?: begin // Branching
                casez(instr[31:29]) 
                    3'b010: begin // b.cond
                        if (instr[25:24] == 2'b0) begin 
                            mctrl[21:17] = {1'b1, I2305};
                            mctrl[12:6] = {1'b1, 1'b0, CND, 2'b0};
                        end
                    end
                    3'b110: begin // br, blr
                        if ((instr[20:10] == 11'd1984) && (instr[4:0] == 5'b0)) begin // 1984 = 31 * 2^6
                            mctrl[21:17] = {1'b1, INONE};
                            case(instr[24:21]) 
                                4'b00?0: mctrl[12:6] = {2'b0, UCR, 2'b0}; // br, ret
                                4'b0001: mctrl[12:6] = {2'b0, UCR, 1'b0, 1'b1}; // blr
                            endcase
                        end
                    end
                    3'b?00: begin // b, bl
                        mctrl[21:17] = {1'b1, I2500};
                        case(instr[31]) 
                            1'b0: mctrl[12:6] = {1'b1, 1'b0, UCI, 2'b0}; // b
                            1'b1: mctrl[12:6] = {1'b1, 1'b0, UCI, 1'b0, 1'b1}; // bl
                        endcase
                    end
                    3'b?01: begin // compare-branch
                        case(instr[25])
                            1'b0: begin // cbz, cbnz
                                mctrl[21:17] = {instr[31], I2305};
                                mctrl[12] = instr[31] ? 1'b1 : 1'b0;
                                mctrl[10:7] = instr[24] ? {ZER, 1'b1} : {ZER, 1'b0};
                            end
                            1'b1: begin // tbz, tbnz
                                mctrl[21:17] = {instr[31], I1805};
                                mctrl[12:7] = instr[24] ? {1'b1, 1'b0, BIT, 1'b1} : {1'b1, 1'b0, BIT, 1'b0};
                            end
                        endcase
                    end
                endcase
                4'b?101: begin // Data Processing w/ Reg

                end
            end
        endcase
    end
endmodule
