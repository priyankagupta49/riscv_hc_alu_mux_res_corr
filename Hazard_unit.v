module hazard_unit(
    input rst,
    input RegWriteM, RegWriteW,
    input ResultSrcM,
    input [4:0] RD_M, RD_W, Rs1_E, Rs2_E, Rs1_D, Rs2_D,
    input ALU_Busy_Stall,       // From Time Redundancy FSM
    output [1:0] ForwardAE, ForwardBE,
    output StallF, StallD, FlushE
);
    // Forwarding logic remains standard
    assign ForwardAE = (rst == 1'b0) ? 2'b00 :
        ((RegWriteM && (RD_M != 0) && (RD_M == Rs1_E))) ? 2'b10 :
        ((RegWriteW && (RD_W != 0) && (RD_W == Rs1_E))) ? 2'b01 : 2'b00;

   // Ensure rs2 for Store instructions is forwarded
// Forward B (for Src_B and for Store Data)
assign ForwardBE = (rst == 1'b0) ? 2'b00 :
    ((RegWriteM && (RD_M != 0) && (RD_M == Rs2_E))) ? 2'b10 : // From Memory Stage
    ((RegWriteW && (RD_W != 0) && (RD_W == Rs2_E))) ? 2'b01 : 2'b00; // From Writeback Stage

    // Load-Use Hazard Stall logic
    wire lwStall;
    assign lwStall = ResultSrcM && ((RD_M == Rs1_D) || (RD_M == Rs2_D));

    // Time Redundancy Logic Integration:
    // We stall Fetch (StallF) and Decode (StallD) for BOTH LW hazards and ALU re-execution.
   // Inside hazard_unit.v
// Only flush for Load-Use, and only if the ALU isn't currently busy re-calculating
assign FlushE = lwStall && !ALU_Busy_Stall; 

// Ensure Stall signals are clean
assign StallF = lwStall || ALU_Busy_Stall;
assign StallD = lwStall || ALU_Busy_Stall;

  

endmodule