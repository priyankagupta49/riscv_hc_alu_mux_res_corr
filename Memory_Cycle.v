`timescale 1ns / 1ps

module memory_cycle(
    input clk, rst, 
    input RegWriteM, MemWriteM, ResultSrcM,
    input [4:0] RD_M, 
    input [31:0] PCPlus4M, WriteDataM, ALU_ResultM,
    
    // ECC Error Outputs for reporting
    output s_err, 
    output d_err,

    // Outputs to Writeback Stage
    output RegWriteW, ResultSrcW, 
    output [4:0] RD_W,
    output [31:0] PCPlus4W, ALU_ResultW, ReadDataW
);
    
    wire [31:0] ReadDataM;

    // 1. Data Memory Instantiation
    // ALU_ResultM acts as the effective address (Base + Offset)
    // WriteDataM is the forwarded value of rs2 for Store instructions
    Data_Memory dmem (
        .clk(clk),
        .rst(rst),
        .WE(MemWriteM),      // High for SW, Low for LW
        .WD(WriteDataM),     // Data to be stored
        .A(ALU_ResultM),     // Effective Address
        .RD(ReadDataM),      // Corrected Data output
        .s_err(s_err),       // Single Error Detection/Correction flag
        .d_err(d_err)        // Double Error Detection flag
    );

    // 2. MEM/WB Pipeline Registers
    // These registers hold the data for one clock cycle to align with Writeback
    reg RegWriteM_r, ResultSrcM_r;
    reg [4:0] RD_M_r;
    reg [31:0] PCPlus4M_r, ALU_ResultM_r, ReadDataM_r;

    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            RegWriteM_r   <= 1'b0; 
            ResultSrcM_r  <= 1'b0;
            RD_M_r        <= 5'h00;
            PCPlus4M_r    <= 32'h00000000; 
            ALU_ResultM_r <= 32'h00000000; 
            ReadDataM_r   <= 32'h00000000;
        end
        else begin
            RegWriteM_r   <= RegWriteM;   // Passed to WB for Register File enable
            ResultSrcM_r  <= ResultSrcM;  // Passed to WB to select Result (ALU vs Mem)
            RD_M_r        <= RD_M;        // Destination register address
            PCPlus4M_r    <= PCPlus4M; 
            ALU_ResultM_r <= ALU_ResultM; 
            ReadDataM_r   <= ReadDataM;   // The corrected word from ECC logic
        end
    end 

    // 3. Final Outputs to Writeback Cycle
    assign RegWriteW   = RegWriteM_r;
    assign ResultSrcW  = ResultSrcM_r;
    assign RD_W        = RD_M_r;
    assign PCPlus4W    = PCPlus4M_r;
    assign ALU_ResultW = ALU_ResultM_r;
    assign ReadDataW   = ReadDataM_r;

endmodule