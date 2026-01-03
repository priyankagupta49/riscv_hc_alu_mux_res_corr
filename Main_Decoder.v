module Main_Decoder(
    input [6:0] Op,
    output reg RegWrite, MemWrite, ResultSrc, Branch, ALUSrc,
    output reg [1:0] ImmSrc, ALUOp
);
    always @(*) begin
        case(Op)
            7'b0110011: begin // R-type (ADD, SUB, etc.)
                RegWrite = 1'b1; ImmSrc = 2'bxx; ALUSrc = 1'b0;
                MemWrite = 1'b0; ResultSrc = 1'b0; Branch = 1'b0; ALUOp = 2'b10;
            end
            7'b0010011: begin // I-type (ADDI)
                RegWrite = 1'b1; ImmSrc = 2'b00; ALUSrc = 1'b1;
                MemWrite = 1'b0; ResultSrc = 1'b0; Branch = 1'b0; ALUOp = 2'b10;
            end
            7'b0000011: begin // LW (Load Word)
                RegWrite = 1'b1; ImmSrc = 2'b00; ALUSrc = 1'b1; // ALUSrc High for offset
                MemWrite = 1'b0; ResultSrc = 1'b1; // ResultSrc selects Data Memory
                Branch   = 1'b0; ALUOp = 2'b00;     // ALUOp 00 = Addition
            end
            7'b0100011: begin // SW (Store Word)
                RegWrite = 1'b0; ImmSrc = 2'b01; ALUSrc = 1'b1; // ImmSrc 01 for S-type
                MemWrite = 1'b1; ResultSrc = 1'bx; // MemWrite High
                Branch   = 1'b0; ALUOp = 2'b00;     // ALUOp 00 = Addition
            end
            default: begin
                RegWrite = 1'b0; ImmSrc = 2'b00; ALUSrc = 1'b0;
                MemWrite = 1'b0; ResultSrc = 1'b0; Branch = 1'b0; ALUOp = 2'b00;
            end
        endcase
    end
endmodule