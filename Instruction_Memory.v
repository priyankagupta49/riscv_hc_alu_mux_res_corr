`timescale 1ns / 1ps

module Instruction_Memory (
    input clk,
    input we,
    input [31:0] waddr,
    input [31:0] wdata,
    input [31:0] raddr,
    output [31:0] rdata,
    output s_err, // Single error detected and corrected
    output d_err  // Double error detected
);
    // 1024 words, each 39 bits wide (32 data + 7 Hamming bits)
    reg [38:0] mem [0:1023]; 
    
    // --- 1. CRITICAL FIX: Memory Initialization ---
    // This prevents 'x' bits in the parity fields from ruining the XOR logic.
    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            mem[i] = 39'b0; 
        end
    end

    wire [38:0] encoded_instr;
    wire [31:0] corrected_instr;

    // Instance for encoding instructions being written by the loader
    hamming_ecc_unit ecc_encoder (
        .data_in(wdata),
        .code_in(39'b0), // Not used for encoding
        .code_out(encoded_instr),
        .data_out(), 
        .s_err(), 
        .d_err()
    );

    // --- 2. IMPROVED READ LOGIC ---
    // Capture the current code from memory safely.
    // Address [31:2] assumes 4-byte (word) alignment.
    wire [38:0] current_code = mem[raddr[11:2]]; 

    // Instance for decoding/correcting instructions being read by the CPU
    hamming_ecc_unit ecc_decoder (
        .data_in(32'b0), // Not used for decoding
        .code_in(current_code),
        .code_out(),
        .data_out(corrected_instr),
        .s_err(s_err),
        .d_err(d_err)
    );

    // Synchronous Write (for Loader)
    always @(posedge clk) begin
        if (we)
            mem[waddr[11:2]] <= encoded_instr;
    end

    // Combinational Read (standard for most simple Instruction Memories)
    assign rdata = corrected_instr;

endmodule