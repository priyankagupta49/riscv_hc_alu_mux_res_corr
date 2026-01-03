`timescale 1ns / 1ps

module Data_Memory(
    input clk, rst, WE,
    input [31:0] A, WD,
    output reg [31:0] RD,
    output s_err, d_err
);
    // 1024 words, each 39 bits wide (32 data + 7 Hamming bits)
    reg [38:0] mem [0:1023]; 
    
    // --- 1. Memory Initialization ---
    // Critical: Ensures parity bits aren't 'x', which breaks XOR logic
    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            mem[i] = 39'b0; 
        end
    end

    wire [38:0] encoded_wd;
    wire [31:0] corrected_rd;
    
    // --- 2. Separate Read Data Path ---
    // Explicitly pull the data from memory into a dedicated wire for decoding
    wire [38:0] raw_data_from_mem = mem[A[11:2]];

    // --- 3. ECC Unit Integration ---
    hamming_ecc_unit ecc_unit (
        .data_in(WD),                // Input used for ENCODING (Store)
        .code_in(raw_data_from_mem), // Input used for DECODING (Load)
        .code_out(encoded_wd),       // Result of encoding WD
        .data_out(corrected_rd),     // Result of decoding/correcting mem access
        .s_err(s_err),
        .d_err(d_err)
    );

    // --- 4. Synchronous Write Logic ---
    always @(posedge clk) begin
        if (WE)
            mem[A[11:2]] <= encoded_wd;
    end

    // --- 5. Hardened Asynchronous/Combinational Read Logic ---
    // This logic ensures that if a double-bit error is detected, 
    // the CPU receives a unique "poison" value instead of corrupted data.
    
    always @(*) begin
        if (!rst) 
            RD = 32'd0;
        else if (d_err) 
            RD = 32'hBAAD_FEED; // Poisoned data value for non-correctable double error
        else 
            RD = corrected_rd;  // Corrected single-bit or clean data
    end
endmodule