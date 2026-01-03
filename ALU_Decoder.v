module ALU_Decoder(
    input [1:0] ALUOp,       
    input [2:0] funct3,      
    input [6:0] funct7,      
    output reg [2:0] ALUControl
);

   
    // 3'b000: ADD
    // 3'b001: SUB
    // 3'b010: AND
    // 3'b011: OR
    // 3'b100: XOR
    // 3'b101: SLT (Set Less Than)
    // 3'b110: SLL (Shift Left Logical)
    // 3'b111: SRL/SRA (Shift Right Logical/Arithmetic)

    always @(*) begin
        case(ALUOp)
           
            // 2'b00: Address Calculation (Load, Store)          
            2'b00: ALUControl = 3'b000; // ADD
    
            // 2'b01: B-Type (Branch)          
            2'b01: ALUControl = 3'b001; // SUB 

            // 2'b10: R-Type (Register-Register)
            2'b10: begin 
                case(funct3)
                    // Funct3=000: ADD (funct7[5]=0) or SUB (funct7[5]=1)
                    3'b000: ALUControl = (funct7[5]) ? 3'b001 : 3'b000;                  
                    3'b001: ALUControl = 3'b110; // SLL
                    3'b010: ALUControl = 3'b101; // SLT
                    3'b011: ALUControl = 3'b101; // SLTU 
                    3'b100: ALUControl = 3'b100; // XOR
                    3'b101: ALUControl = 3'b111; // SRL                    
                    3'b110: ALUControl = 3'b011; // OR
                    3'b111: ALUControl = 3'b010; // AND                   
                    default: ALUControl = 3'b000; // Default to ADD
                endcase
            end

            // 2'b11: I-Type (ALU Imm)          
            2'b11: begin
                 case(funct3)
                    3'b000: ALUControl = 3'b000; // ADDI 
                    3'b001: ALUControl = 3'b110; // SLLI
                    3'b010: ALUControl = 3'b101; // SLTI
                    3'b011: ALUControl = 3'b101; // SLTIU
                    3'b100: ALUControl = 3'b100; // XORI                    
                    3'b101: ALUControl = 3'b111; // SRLI                   
                    3'b110: ALUControl = 3'b011; // ORI
                    3'b111: ALUControl = 3'b010; // ANDI                  
                    default: ALUControl = 3'b000;
                endcase
            end
            
            default: ALUControl = 3'b000; // Default to ADD
        endcase
    end

endmodule