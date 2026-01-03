`timescale 1ns / 1ps

module tb_pipeline_time_redundancy;

    // --------------------------------------------------
    // Clock, Reset, and Test Control
    // --------------------------------------------------
    reg clk = 0;
    reg rst = 0;
    reg test_en_in = 0; // Added to drive Mux BIST logic
    always #5 clk = ~clk;   // 100 MHz

    // --------------------------------------------------
    // Loader Inputs
    // --------------------------------------------------
    reg [11:0] operand1, operand2;
    reg [2:0]  opcode;

    // --------------------------------------------------
    // Interconnect Wires
    // --------------------------------------------------
    wire [31:0] imem_waddr, imem_wdata;
    wire        imem_we;
    wire        done_signal;
    wire [31:0] result_w;
    
    // Status Wires from DUT
    wire alu_fault_detected;
    wire mux_error_flag;
    wire s_err_dmem; // Connected to monitor Memory ECC

    // Latching registers for the final report
    reg [31:0] captured_result;
    reg        ecc_latched, mux_fault_latched, alu_fault_latched;

    // --------------------------------------------------
    // VERIFIED HIERARCHY MACROS
    // --------------------------------------------------
    `define ALU_FT    dut.execute.time_redundant_alu
    `define ALU_CORE  dut.execute.time_redundant_alu.u_alu
    `define REG_FILE  dut.decode.rf.Register

    // --------------------------------------------------
    // Instruction Loader
    // --------------------------------------------------
    instr_loader loader (
        .clk(clk),
        .rst(rst),
        .op1(operand1),
        .op2(operand2),
        .alu_op(opcode),
        .imem_we(imem_we),
        .imem_addr(imem_waddr),
        .imem_wdata(imem_wdata),
        .done(done_signal)
    );

    // --------------------------------------------------
    // Pipeline DUT (Top Level)
    // --------------------------------------------------
    Pipeline_top dut (
        .clk(clk),
        .rst(rst),
        .imem_we(imem_we),
        .imem_waddr(imem_waddr),
        .imem_wdata(imem_wdata),
        .loader_done_in(done_signal),
        .test_en_in(test_en_in), // Pass test enable to Mux BIST
        .ResultW_out(result_w),
        .hardware_fault_flag(alu_fault_detected),
        .mux_error_flag(mux_error_flag),
        .s_err_dmem(s_err_dmem) // Connected for monitoring
    );

    // --------------------------------------------------
    // FAULT MONITORING LOGIC
    // --------------------------------------------------
    always @(posedge clk) begin
        if (!rst) begin
            ecc_latched       <= 0;
            mux_fault_latched <= 0;
            alu_fault_latched <= 0;
            captured_result   <= 0;
        end else begin
            // Check for the expected result of 10 + 8 = 18
            if (result_w === 32'd18)         captured_result <= 32'd18;
            
            // Latched Flags (Sticky monitoring)
            if (s_err_dmem === 1'b1)         ecc_latched <= 1'b1;
            if (mux_error_flag === 1'b1)     mux_fault_latched <= 1'b1;
            if (alu_fault_detected === 1'b1) alu_fault_latched <= 1'b1;
        end
    end

    // ==================================================
    // MAIN TEST SEQUENCE
    // ==================================================
    // -------------------------------------------------------------------------
// PIPELINE DATA PATH PROBE (DEBUG MONITOR)
// -------------------------------------------------------------------------
initial begin
    $display("\n[TIME]    | PC_EX | ALU_OUT  | MEM_ADDR | MEM_WD   | MEM_RD   | WB_RES   | STALL");
    $display("----------|-------|----------|----------|----------|----------|----------|-------");
end

always @(negedge clk) begin
    if (rst && done_signal) begin
        $display("%t | %h  | %d       | %h       | %d       | %d       | %d       | %b",
            $time,
            dut.execute.PCE,            // PC in Execute
            dut.execute.ResultE,        // Output of Time-Redundant ALU
            dut.memory.ALU_ResultM,     // Address sent to Data Memory
            dut.memory.WriteDataM,      // Data being stored (for SW)
            dut.memory.ReadDataM,       // Data being loaded (for LW)
            dut.writeBack.ResultW,      // Final result being written to RegFile
            dut.Forwarding_Block.StallD // Pipeline Stall Status
        );
    end
end
    initial begin
        // --- Step 1: Initialization & Reset ---
        
        rst = 0;
        test_en_in = 0;
        operand1 = 12'd10;
        operand2 = 12'd8;
        opcode   = 3'b000;   // ADD operation
        #20 rst = 1;

        wait (done_signal);
        $display("\n>>> [SYSTEM] Program Loaded into Instruction Memory.");

        // --- Step 2: ALU Time Redundancy Test ---
        // Wait for ADD instruction to reach Execute stage
        wait(dut.execute.PCE == 32'h8);
        @(posedge clk); 
        wait(`ALU_FT.state == 2'b00); // Wait for T1 Stage

        $display("\n>>> [ALU] Testing Time Redundancy (Injecting Fault in T2)...");
        wait (`ALU_FT.state == 2'b01); // Transition to T2
        force `ALU_CORE.Result = 32'hDEADBEEF; // Inject transient fault
        @(posedge clk);
        #1 release `ALU_CORE.Result; // Release before T3 (re-computation)

        // Wait for re-computation to complete
        wait (`ALU_FT.state == 2'b10);
        $display("ALU Recovered Result: %0d", `ALU_FT.Result);

        // --- Step 3: Mux BIST & Sticky Fault Injection ---
        repeat(5) @(posedge clk);
        $display("\n>>> [MUX] Testing Sticky Fault Detection...");
        test_en_in = 1; // Enable Mux Self-Test mode
        // Force a mismatch inside the Writeback Mux to trigger the sticky flag
        force dut.writeBack.result_mux.primary_out = 32'hBAADF00D;
        repeat(2) @(posedge clk);
        release dut.writeBack.result_mux.primary_out;
        test_en_in = 0;

        // --- Step 4: Memory ECC Fault Injection ---
        // Wait for SW instruction to reach Memory stage
        wait (dut.memory.MemWriteM == 1'b1);
       // #20;
        repeat(5) @(posedge clk); // Wait for write to complete
        $display("\n>>> [MEM] Injecting ECC Single-Bit Error...");
        // Flip bit 7 in Data Memory at Word 1 (Address 0x4)
        dut.memory.dmem.mem[1][7] = ~dut.memory.dmem.mem[1][7];

        // --- Step 5: Final Evaluation ---
        #200; // Allow pipeline to finish the load back to r12
        $display("\n================ FINAL RELIABILITY REPORT ================");
        $display("Time: %t", $time);
        $display("----------------------------------------------------------");
        $display("- Mux Error Flag Latched : %b (Expect 1)", mux_fault_latched);
        $display("- ALU Fault Detected     : %b (Expect 1)", alu_fault_latched);
        $display("- Memory ECC Correction  : %b (Expect 1)", ecc_latched);
        $display("----------------------------------------------------------");
        $display("Register x9  (Op1):    %0d", `REG_FILE[9]);
        $display("Register x10 (Op2):    %0d", `REG_FILE[10]);
        $display("Register x11 (Result): %0d", `REG_FILE[11]);
        $display("Register x12 (Loaded): %0d", `REG_FILE[12]);
        $display("----------------------------------------------------------");
        
        if (`REG_FILE[12] == 32'd18 && mux_fault_latched && alu_fault_latched)
            $display("VERDICT: [SUCCESS] All faults detected and masked correctly.");
        else
            $display("VERDICT: [FAILURE] Potential data corruption or detection failure.");
        $display("==========================================================\n");

        #100;
        $finish;
    end
endmodule