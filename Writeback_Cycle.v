module writeback_cycle(
    input clk, rst, test_en_in,
    input ResultSrcW,
   // input [38:0] PCPlus4W_ECC, ALU_ResultW_ECC, ReadDataW_ECC,
   input [31:0] PCPlus4W, ALU_ResultW, ReadDataW,
    output [31:0] ResultW,
    output mux_fault_sticky
);
   // wire [31:0] PCPlus4W, ALU_ResultW, ReadDataW;

    // ECC Decoders
//    hamming_ecc_unit dec_alu (.code_in(ALU_ResultW_ECC), .data_out(ALU_ResultW));
//    hamming_ecc_unit dec_mem (.code_in(ReadDataW_ECC),  .data_out(ReadDataW));
//    hamming_ecc_unit dec_pc4 (.code_in(PCPlus4W_ECC),   .data_out(PCPlus4W));

    // BIST-Hardened Result Mux
    Mux result_mux (
        .clk(clk), 
        .rst(rst), 
        .test_en_in(test_en_in),
        .a(ALU_ResultW), 
        .b(ReadDataW), 
        .s(ResultSrcW),
        .c(ResultW), 
        .mux_fault_sticky(mux_fault_sticky)
    );
endmodule