module Mux (
    input clk, rst, test_en_in,
    input [31:0] a, b,
    input s,
    output [31:0] c,
    output reg mux_fault_sticky // Permanent fault flag
);
    wire [31:0] primary_out;
    wire [31:0] spare_out;
    reg  [31:0] test_pattern;
    
    // Primary Mux (Unit Under Test)
    assign primary_out = (s == 1'b0) ? a : b;
    
    // Spare Mux (Golden Reference / Fallback)
    // In a BIST-LUT approach, the spare is the healthy alternative.
    assign spare_out = (s == 1'b0) ? a : b; 

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            mux_fault_sticky <= 1'b0;
        end else if (test_en_in) begin
            // Test Case 1: s=0, check if output == a
            // Test Case 2: s=1, check if output == b
            // If at any point primary_out != expected during test:
            if ((s == 1'b0 && primary_out != a) || (s == 1'b1 && primary_out != b))
                mux_fault_sticky <= 1'b1;
        end
    end

    // Result selection: Use spare if BIST failed
    assign c = (mux_fault_sticky) ? spare_out : primary_out;
endmodule



`timescale 1ns / 1ps

module Mux_3_by_1 (
    input clk, rst, test_en_in,
    input [31:0] a, b, c,
    input [1:0]  s,
    output [31:0] d,
    output reg mux_fault_sticky // Latched fault flag
);
    wire [31:0] primary_out;
    wire [31:0] spare_out;

    // --- 1. Primary Mux (Unit Under Test) ---
    // Standard conditional logic
    assign primary_out = (s == 2'b00) ? a :
                         (s == 2'b01) ? b :
                         (s == 2'b10) ? c : 32'h0;

    // --- 2. Spare Mux (Golden Reference / Fallback) ---
    // Using a diverse Boolean-expanded structure for the spare
    assign spare_out = (~{32{s[1]}} & ~{32{s[0]}} & a) |
                       (~{32{s[1]}} &  {32{s[0]}} & b) |
                       ( {32{s[1]}} & ~{32{s[0]}} & c);

    // --- 3. BIST Validation Logic ---
    // During test_en, we compare the primary output against the expected input.
    // If a mismatch occurs, the fault is "sticky" (latched).
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            mux_fault_sticky <= 1'b0;
        end else if (test_en_in) begin
            case (s)
                2'b00: if (primary_out != a) mux_fault_sticky <= 1'b1;
                2'b01: if (primary_out != b) mux_fault_sticky <= 1'b1;
                2'b10: if (primary_out != c) mux_fault_sticky <= 1'b1;
                default: ; // Ignore s=11 for 3x1 mux
            endcase
        end
    end

    // --- 4. Result Selection ---
    // If BIST has ever failed, permanently use the Spare path.
    assign d = (mux_fault_sticky) ? spare_out : primary_out;

endmodule








//// 2-to-1 Mux
//`timescale 1ns / 1ps
//module Mux (input [31:0] a, b, input s, output [31:0] c);
//    assign c = (s == 1'b0) ? a : b;
//endmodule

//// 3-to-1 Mux for Forwarding
//module Mux_3_by_1 (input [31:0] a, b, c, input [1:0] s, output [31:0] d);
//    assign d = (s == 2'b00) ? a : 
//               (s == 2'b01) ? b : 
//               (s == 2'b10) ? c : 32'h00000000;
//endmodule

