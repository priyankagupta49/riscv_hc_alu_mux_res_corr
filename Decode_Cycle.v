`timescale 1ns / 1ps
module decode_cycle(
    input clk, rst,
    
    // Data inputs from IF stage and WB stage
    input [31:0] InstrD, PCD, PCPlus4D, ResultW,
    input RegWriteW,
    input [4:0] RDW,

    // Outputs to EX stage (ID/EX Register Outputs)
    output reg RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE,
    output reg [2:0] ALUControlE,
    output reg [31:0] RD1_E, RD2_E, Imm_Ext_E,
    output reg [4:0] RS1_E, RS2_E, RD_E,
    output reg [31:0] PCE, PCPlus4E,
   
    output [4:0] RS1_D, RS2_D // ADD THESE TWO PORTS HERE
);

    // Internal wires for control signals
    wire RegWriteD, ALUSrcD, MemWriteD, ResultSrcD, BranchD;
    wire [1:0] ImmSrcD;
    wire [2:0] ALUControlD;
    wire [31:0] RD1_D, RD2_D;
    
    // Data wires - Explicitly 32-bit to fix VRFC 10-3091 warnings
    wire [31:0] Imm_Ext_D;
assign RS1_D = InstrD[19:15];
    assign RS2_D = InstrD[24:20];
    // Control Unit
    Control_Unit_Top control (
        .Op(InstrD[6:0]),
        .RegWrite(RegWriteD),
        .ImmSrc(ImmSrcD),
        .ALUSrc(ALUSrcD),
        .MemWrite(MemWriteD),
        .ResultSrc(ResultSrcD),
        .Branch(BranchD),
        .funct3(InstrD[14:12]),
        .funct7(InstrD[31:25]),
        .ALUControl(ALUControlD)
    );

    // Register File (32-bit interface for CPU logic)
    Register_File rf (
        .clk(clk),
        .rst(rst),
        .WE3(RegWriteW),
        .WD3(ResultW),      // WD3 is now strictly 32-bit
        .A1(InstrD[19:15]), // RS1
        .A2(InstrD[24:20]), // RS2
        .A3(RDW),
        .RD1(RD1_D),        // RD1 is strictly 32-bit
        .RD2(RD2_D)         // RD2 is strictly 32-bit
    );

    // Sign Extension Unit
    Sign_Extend extension (
        .In(InstrD),
        .Imm_Ext(Imm_Ext_D),
        .ImmSrc(ImmSrcD)
    );

    // ID/EX Pipeline Registers 
    always @(posedge clk) begin
        if (rst == 1'b0) begin // Active-Low Reset
            RegWriteE     <= 1'b0;
            ALUSrcE        <= 1'b0;
            MemWriteE      <= 1'b0;
            ResultSrcE     <= 1'b0;
            BranchE        <= 1'b0;
            ALUControlE    <= 3'b000;
            RD1_E          <= 32'h00000000;
            RD2_E          <= 32'h00000000;
            Imm_Ext_E      <= 32'h00000000;
            RD_E           <= 5'h00;
            PCE            <= 32'h00000000;
            PCPlus4E       <= 32'h00000000;
            RS1_E          <= 5'h00;
            RS2_E          <= 5'h00;
        end else begin
            RegWriteE      <= RegWriteD;
            ALUSrcE        <= ALUSrcD;
            MemWriteE      <= MemWriteD;
            ResultSrcE     <= ResultSrcD;
            BranchE        <= BranchD;
            ALUControlE    <= ALUControlD;
            RD1_E          <= RD1_D;
            RD2_E          <= RD2_D;
            Imm_Ext_E      <= Imm_Ext_D;
            RD_E           <= InstrD[11:7];  // Destination Register (RD)
            PCE            <= PCD;
            PCPlus4E       <= PCPlus4D;
            RS1_E          <= InstrD[19:15]; // Source Register 1 (RS1)
            RS2_E          <= InstrD[24:20]; // Source Register 2 (RS2)
        end
    end

endmodule