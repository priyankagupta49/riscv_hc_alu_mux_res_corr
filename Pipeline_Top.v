`timescale 1ns / 1ns

module Pipeline_top(
    input clk, rst,
    input imem_we,
    input [31:0] imem_waddr, imem_wdata,
  
    input loader_done_in, test_en_in,
    output [31:0] ResultW_out,
    output s_err_imem, d_err_imem, s_err_dmem, d_err_dmem,
    output hardware_fault_flag ,
    mux_error_flag
);

    // --- Internal Wires ---
    wire PCSrcE, RegWriteW, RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE;
    wire RegWriteM, MemWriteM, ResultSrcM, ResultSrcW;
    wire [2:0] ALUControlE;
    wire [4:0] RD_E, RD_M, RDW, RS1_E, RS2_E, RS1_D, RS2_D;
    wire [31:0] PC_Next, PCTargetE, InstrD, PCD, PCPlus4D, ResultW;
    wire [31:0] RD1_E, RD2_E, Imm_Ext_E, PCE, PCPlus4E, PCPlus4M;
    wire [31:0] WriteDataM, ALU_ResultM, PCPlus4W, ALU_ResultW, ReadDataW;
    wire [1:0] ForwardAE, ForwardBE;
    //wire err_pc_sel,err_wb_mux;
    //wire [31:0] PCPlus4D_raw, PCTargetE_raw;
    
    // Control Signals from Hazard Unit
    wire StallF, StallD, FlushE;
    
    // Time Redundancy Stall Signal
    wire ALU_Busy_Stall;

    // Output Assignments
    assign ResultW_out = ResultW;

    // --- 1. PC Selector ---
//    Mux PC_Selector (
//        .a(PCPlus4D), .b(PCTargetE), .s(PCSrcE), .c(PC_Next)
//    );

        Mux PC_Selector (
        .clk(clk), 
        .rst(rst), 
        .test_en_in(test_en_in),
        .a(PCPlus4D), 
        .b(PCTargetE), 
        .s(PCSrcE),
         
        .c(PC_Next), 
        .mux_fault_sticky(err_pc_sel)
    );
    // --- 2. Fetch Stage ---
    // StallF prevents the PC from incrementing
    fetch_cycle fetch (
        .clk(clk), .rst(rst),
        .PC_Next_In(PC_Next), .imem_we(imem_we), 
        .imem_waddr(imem_waddr), .imem_wdata(imem_wdata),
        .loader_done_in(loader_done_in & !StallF), // Stalls PC when Hazard Unit says so
        .s_err(s_err_imem), .d_err(d_err_imem),
        .InstrD(InstrD), .PCPlus4D(PCPlus4D), .PCD(PCD)
    );

    // --- 3. Decode Stage ---
    // StallD prevents the IF/ID pipeline register from updating
    decode_cycle decode (
        .clk(clk), .rst(rst),
        .InstrD(InstrD), .PCD(PCD), .PCPlus4D(PCPlus4D), 
        .RegWriteW(RegWriteW), .RDW(RDW), .ResultW(ResultW), 
        .RegWriteE(RegWriteE), .ALUSrcE(ALUSrcE), .MemWriteE(MemWriteE), 
        .ResultSrcE(ResultSrcE), .BranchE(BranchE), .ALUControlE(ALUControlE), 
        .RD1_E(RD1_E), .RD2_E(RD2_E), .Imm_Ext_E(Imm_Ext_E), 
        .RD_E(RD_E), .PCE(PCE), .PCPlus4E(PCPlus4E),
        .RS1_E(RS1_E), .RS2_E(RS2_E), .RS1_D(RS1_D), .RS2_D(RS2_D)
        // Inside decode_cycle, ensure the registers only update if !StallD
    );

    // --- 4. Execute Stage ---
    execute_cycle execute (
        .clk(clk), .rst(rst),
        .RegWriteE(RegWriteE), .ALUSrcE(ALUSrcE), .MemWriteE(MemWriteE), 
        .ResultSrcE(ResultSrcE), .BranchE(BranchE), .ALUControlE(ALUControlE), 
        .RD1_E(RD1_E), .RD2_E(RD2_E), .Imm_Ext_E(Imm_Ext_E), .RD_E(RD_E), 
        .PCE(PCE), .PCPlus4E(PCPlus4E), .PCSrcE(PCSrcE), .PCTargetE(PCTargetE), 
        .RegWriteM(RegWriteM), .MemWriteM(MemWriteM), .ResultSrcM(ResultSrcM), 
        .RD_M(RD_M), .PCPlus4M(PCPlus4M), .WriteDataM(WriteDataM), 
        .ALU_ResultM(ALU_ResultM), .ResultW(ResultW), 
        .ForwardA_E(ForwardAE), .ForwardB_E(ForwardBE),
        .ALU_ResultM_In(ALU_ResultM), .test_en_in(test_en_in),
        .fault_detected_out(hardware_fault_flag)
    );

    // Extract ALU Status for the Hazard Unit
    assign ALU_Busy_Stall = (execute.time_redundant_alu.state != 2'b00);

    // --- 5. Memory & Writeback Stage (Remaining same) ---
    memory_cycle memory (
        .clk(clk), .rst(rst), .RegWriteM(RegWriteM), .MemWriteM(MemWriteM), 
        .ResultSrcM(ResultSrcM), .RD_M(RD_M), .PCPlus4M(PCPlus4M), 
        .WriteDataM(WriteDataM), .ALU_ResultM(ALU_ResultM), .RegWriteW(RegWriteW), 
        .ResultSrcW(ResultSrcW), .RD_W(RDW), .PCPlus4W(PCPlus4W), 
        .ALU_ResultW(ALU_ResultW), .ReadDataW(ReadDataW),
        .s_err(s_err_dmem), .d_err(d_err_dmem)
    );

    writeback_cycle writeBack (
        .clk(clk), .rst(rst), .ResultSrcW(ResultSrcW), .PCPlus4W(PCPlus4W), 
        .ALU_ResultW(ALU_ResultW), .test_en_in(test_en_in), .ReadDataW(ReadDataW), .ResultW(ResultW)
    );

    // --- 6. Updated Hazard Unit ---
    // Now receives the ALU_Busy_Stall to manage pipeline flow
    hazard_unit Forwarding_Block (
        .rst(rst), 
        .RegWriteM(RegWriteM), .RegWriteW(RegWriteW), 
        .ResultSrcM(ResultSrcM), 
        .RD_M(RD_M), .RD_W(RDW), 
        .Rs1_E(RS1_E), .Rs2_E(RS2_E), .Rs1_D(RS1_D), .Rs2_D(RS2_D), 
        .ALU_Busy_Stall(ALU_Busy_Stall), // Added port
        .ForwardAE(ForwardAE), .ForwardBE(ForwardBE),
        .StallF(StallF), .StallD(StallD), .FlushE(FlushE)
    );
// Add this near the bottom of Pipeline_top
    assign mux_error_flag = err_pc_sel | execute.err_srca | execute.err_srcb | writeBack.mux_fault_sticky;
endmodule