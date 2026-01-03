module Control_Unit_Top(
    input [6:0] Op, funct7,
    input [2:0] funct3,
    output RegWrite, ALUSrc, MemWrite, ResultSrc, Branch,
    output [1:0] ImmSrc,
    output [2:0] ALUControl
);

    wire [1:0] ALUOp;

    Main_Decoder main_decoder_inst (
        .Op(Op),
        .RegWrite(RegWrite),
        .ImmSrc(ImmSrc),
        .MemWrite(MemWrite),
        .ResultSrc(ResultSrc),
        .Branch(Branch),
        .ALUSrc(ALUSrc),
        .ALUOp(ALUOp)
    );

    
    ALU_Decoder alu_decoder_inst (
        .ALUOp(ALUOp),
        .funct3(funct3),
        .funct7(funct7), 
        .ALUControl(ALUControl)
    );

endmodule