`timescale 1ns / 1ps

module execute_cycle(
    input clk, rst,
    input RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE,
    input [2:0] ALUControlE,
    input [31:0] RD1_E, RD2_E, Imm_Ext_E, PCE, PCPlus4E,
    input [4:0] RD_E,
    input [31:0] ResultW,
    input [1:0] ForwardA_E, ForwardB_E,
    input [31:0] ALU_ResultM_In, 
    input test_en_in,
    
    output PCSrcE, RegWriteM, MemWriteM, ResultSrcM,
    output [4:0] RD_M,
    output [31:0] ALU_ResultM, WriteDataM, PCPlus4M,
    output [31:0] PCTargetE,
    output fault_detected_out,
    output mux_fault_detected // Aggregated mux fault output
);

    // --- Internal Wires ---
    wire [31:0] Src_A, Src_B_interim, Src_B;
    wire [31:0] ResultE;
    wire ZeroE, CarryE, OverflowE, NegativeE;
    wire err_srca, err_srcb; // DECLARE THESE TO FIX ELABORATION

    // 1. FORWARDING & OPERAND SELECTION
    // Forwarding for RS1
    Mux_3_by_1 srca_mux (
        .clk(clk), .rst(rst), .test_en_in(test_en_in),
        .a(RD1_E), .b(ResultW), .c(ALU_ResultM_In), 
        .s(ForwardA_E), .d(Src_A), 
        .mux_fault_sticky(err_srca)
    );

    // Forwarding for RS2 (Also serves as data for SW instruction)
    Mux_3_by_1 srcb_mux (
        .clk(clk), .rst(rst), .test_en_in(test_en_in),
        .a(RD2_E), .b(ResultW), .c(ALU_ResultM_In), 
        .s(ForwardB_E), .d(Src_B_interim), 
        .mux_fault_sticky(err_srcb)
    );

    // Operand B Selection (Register vs Immediate)
    Mux alu_src_mux (
        .clk(clk), .rst(rst), .test_en_in(test_en_in),
        .a(Src_B_interim), .b(Imm_Ext_E), 
        .s(ALUSrcE), .c(Src_B),
        .mux_fault_sticky() // 2:1 mux fault not monitored here
    );

    // 2. TIME REDUNDANT ALU
    ALU_ft time_redundant_alu (
        .clk(clk), .rst(rst),
        .A(Src_A), .B(Src_B),
        .ALUControl(ALUControlE),
        .Result(ResultE),
        .Zero(ZeroE),
        .Carry(CarryE),
        .OverFlow(OverflowE),
        .Negative(NegativeE),
        .fault_detected_out(fault_detected_out)
    );

    // 3. EX/MEM PIPELINE REGISTERS
    reg RegWriteM_r, MemWriteM_r, ResultSrcM_r;
    reg [4:0] RD_M_r;
    reg [31:0] ALU_ResultM_r, WriteDataM_r, PCPlus4M_r;
    reg ZeroM_r;

    // Gate Condition for Time Redundancy
    wire update_en;
    assign update_en = (time_redundant_alu.state == 2'b01 && ResultE == time_redundant_alu.res_t1) || 
                       (time_redundant_alu.state == 2'b10);

    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            RegWriteM_r   <= 1'b0; MemWriteM_r   <= 1'b0; ResultSrcM_r  <= 1'b0;
            RD_M_r        <= 5'b0; ALU_ResultM_r <= 32'b0; WriteDataM_r  <= 32'b0; 
            PCPlus4M_r    <= 32'b0; ZeroM_r       <= 1'b0;
        end 
        else if (update_en) begin
            RegWriteM_r   <= RegWriteE; MemWriteM_r   <= MemWriteE; 
            ResultSrcM_r  <= ResultSrcE; RD_M_r        <= RD_E; 
            ALU_ResultM_r <= ResultE; 
            WriteDataM_r  <= Src_B_interim; // This captures the forwarded RS2
            PCPlus4M_r    <= PCPlus4E; ZeroM_r       <= ZeroE;
        end
    end

    // 4. BRANCH & OUTPUTS
    PC_Adder branch_adder (.a(PCE), .b(Imm_Ext_E), .c(PCTargetE));
    
    assign PCSrcE = ZeroM_r & BranchE;
    assign mux_fault_detected = err_srca | err_srcb;

    assign RegWriteM   = RegWriteM_r; 
    assign MemWriteM   = MemWriteM_r; 
    assign ResultSrcM  = ResultSrcM_r;
    assign RD_M        = RD_M_r; 
    assign ALU_ResultM = ALU_ResultM_r;
    assign WriteDataM  = WriteDataM_r; 
    assign PCPlus4M    = PCPlus4M_r;

endmodule