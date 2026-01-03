// ALU Module
module ALU(
    input [31:0] A, B,
    input [2:0] ALUControl,
    output Carry, OverFlow, Zero, Negative,
    output [31:0] Result
);
    wire [31:0] B_inv;
    wire [32:0] Sum_result;
    wire is_sub;

    assign is_sub = (ALUControl == 3'b001);
    assign B_inv = is_sub ? ~B : B;
    assign Sum_result = A + B_inv + is_sub;

    reg [31:0] Result_reg;
    reg Cout_reg, OverFlow_reg;

    always @(*) begin
        Result_reg = 32'h0;
        Cout_reg = 1'b0;
        OverFlow_reg = 1'b0;
        case (ALUControl)
            3'b000: begin // ADD
                Result_reg = Sum_result[31:0];
                Cout_reg = Sum_result[32];
                OverFlow_reg = (A[31] == B[31]) && (Result_reg[31] != A[31]);
            end
            3'b001: begin // SUB
                Result_reg = Sum_result[31:0];
                Cout_reg = Sum_result[32];
                OverFlow_reg = (A[31] != B[31]) && (Result_reg[31] != A[31]);
            end
            3'b010: Result_reg = A & B;   // AND
            3'b011: Result_reg = A | B;   // OR
            3'b100: Result_reg = A ^ B;   // XOR
            3'b101: Result_reg = ($signed(A) < $signed(B)) ? 32'b1 : 32'b0; // SLT
            3'b110: Result_reg = A << B[4:0]; // SLL
            3'b111: Result_reg = A >> B[4:0]; // SRL
            default: Result_reg = 32'h0;
        endcase
    end

    assign Result   = Result_reg;
    assign Zero     = (Result_reg == 32'b0);
    assign Negative = Result_reg[31];
    assign Carry    = Cout_reg;
    assign OverFlow = OverFlow_reg;
endmodule