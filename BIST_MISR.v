module BIST_MISR(
    input clk, rst,
    input test_en,
    input test_done,
    input [31:0] primary_res,   
    input primary_carry,        
    output reg fault_detected,   
    output reg mux_sel          
);

    reg [31:0] signature;
    
   // parameter GOLDEN_SIGNATURE = 32'h0000ace1;
   // Update this to match your NEW healthy result
    parameter GOLDEN_SIGNATURE = 32'h81c6f051;
    

    always @(posedge clk) begin
        if (rst == 1'b0) begin
            signature <= 32'hACE1; // The Seed
            fault_detected <= 1'b0;
            mux_sel <= 1'b0;
        end else if (test_en) begin
            // Standard LFSR/MISR feedback (Galois Style)
          
            signature <= {signature[30:0], signature[31] ^ signature[21] ^ signature[1] ^ signature[0]} 
                         ^ primary_res 
                         ^ {31'b0, primary_carry};
        end
        
        // ... inside the always @(posedge clk) ...
    
    // Instead of a simple IF, use a Latching Comparator
    if (test_done) begin
        if (signature != GOLDEN_SIGNATURE) begin
            fault_detected <= 1'b1;
            mux_sel <= 1'b1;
        end else begin
            // Optional: ensuring it stays 0 if healthy
            fault_detected <= 1'b0;
            mux_sel <= 1'b0;
        end
    end
    // Add this to make the flag "Sticky" so it doesn't reset when test_done drops
    else if (fault_detected) begin
        fault_detected <= 1'b1;
        mux_sel <= 1'b1;
    end
        
        
        
     
        
    end
endmodule