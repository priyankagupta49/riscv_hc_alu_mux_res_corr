module hamming_ecc_unit (
    input [31:0] data_in,   // Used for Encoding
    input [38:0] code_in,   // Used for Decoding
    output [38:0] code_out, // Packed {pG, p32...p1, data}
    output [31:0] data_out, // Corrected Data
    output s_err, d_err
);

    // --- 1. ENCODING LOGIC (Generating Parity for Storage) ---
    wire [38:1] p_mapped;
    // Map 32 data bits to their standard Hamming positions
    assign p_mapped[3] = data_in[0];   assign p_mapped[5] = data_in[1];
    assign p_mapped[6] = data_in[2];   assign p_mapped[7] = data_in[3];
    assign p_mapped[9] = data_in[4];   assign p_mapped[10] = data_in[5];
    assign p_mapped[11] = data_in[6];  assign p_mapped[12] = data_in[7];
    assign p_mapped[13] = data_in[8];  assign p_mapped[14] = data_in[9];
    assign p_mapped[15] = data_in[10]; assign p_mapped[17] = data_in[11];
    assign p_mapped[18] = data_in[12]; assign p_mapped[19] = data_in[13];
    assign p_mapped[20] = data_in[14]; assign p_mapped[21] = data_in[15];
    assign p_mapped[22] = data_in[16]; assign p_mapped[23] = data_in[17];
    assign p_mapped[24] = data_in[18]; assign p_mapped[25] = data_in[19];
    assign p_mapped[26] = data_in[20]; assign p_mapped[27] = data_in[21];
    assign p_mapped[28] = data_in[22]; assign p_mapped[29] = data_in[23];
    assign p_mapped[30] = data_in[24]; assign p_mapped[31] = data_in[25];
    assign p_mapped[33] = data_in[26]; assign p_mapped[34] = data_in[27];
    assign p_mapped[35] = data_in[28]; assign p_mapped[36] = data_in[29];
    assign p_mapped[37] = data_in[30]; assign p_mapped[38] = data_in[31];

    wire p1_gen, p2_gen, p4_gen, p8_gen, p16_gen, p32_gen, pG_gen;

    assign p1_gen  = p_mapped[3]^p_mapped[5]^p_mapped[7]^p_mapped[9]^p_mapped[11]^p_mapped[13]^p_mapped[15]^p_mapped[17]^p_mapped[19]^p_mapped[21]^p_mapped[23]^p_mapped[25]^p_mapped[27]^p_mapped[29]^p_mapped[31]^p_mapped[33]^p_mapped[35]^p_mapped[37];
    assign p2_gen  = p_mapped[3]^p_mapped[6]^p_mapped[7]^p_mapped[10]^p_mapped[11]^p_mapped[14]^p_mapped[15]^p_mapped[18]^p_mapped[19]^p_mapped[22]^p_mapped[23]^p_mapped[26]^p_mapped[27]^p_mapped[30]^p_mapped[31]^p_mapped[34]^p_mapped[35]^p_mapped[38];
    assign p4_gen  = p_mapped[5]^p_mapped[6]^p_mapped[7]^p_mapped[12]^p_mapped[13]^p_mapped[14]^p_mapped[15]^p_mapped[20]^p_mapped[21]^p_mapped[22]^p_mapped[23]^p_mapped[28]^p_mapped[29]^p_mapped[30]^p_mapped[31]^p_mapped[36]^p_mapped[37]^p_mapped[38];
    assign p8_gen  = p_mapped[9]^p_mapped[10]^p_mapped[11]^p_mapped[12]^p_mapped[13]^p_mapped[14]^p_mapped[15]^p_mapped[24]^p_mapped[25]^p_mapped[26]^p_mapped[27]^p_mapped[28]^p_mapped[29]^p_mapped[30]^p_mapped[31];
    assign p16_gen = p_mapped[17]^p_mapped[18]^p_mapped[19]^p_mapped[20]^p_mapped[21]^p_mapped[22]^p_mapped[23]^p_mapped[24]^p_mapped[25]^p_mapped[26]^p_mapped[27]^p_mapped[28]^p_mapped[29]^p_mapped[30]^p_mapped[31];
    assign p32_gen = p_mapped[33]^p_mapped[34]^p_mapped[35]^p_mapped[36]^p_mapped[37]^p_mapped[38];
// Replace your current pG_gen line with this:
assign pG_gen = ^data_in ^ p1_gen ^ p2_gen ^ p4_gen ^ p8_gen ^ p16_gen ^ p32_gen;

    assign code_out = {pG_gen, p32_gen, p16_gen, p8_gen, p4_gen, p2_gen, p1_gen, data_in};

    // --- 2. DECODING LOGIC (Checking for Errors) ---
    wire [31:0] d_read = code_in[31:0];
    wire [38:1] r_mapped; // Re-mapping the read data
    assign r_mapped[3]=d_read[0];   assign r_mapped[5]=d_read[1];
    assign r_mapped[6]=d_read[2];   assign r_mapped[7]=d_read[3];
    assign r_mapped[9]=d_read[4];   assign r_mapped[10]=d_read[5];
    assign r_mapped[11]=d_read[6];  assign r_mapped[12]=d_read[7];
    assign r_mapped[13]=d_read[8];  assign r_mapped[14]=d_read[9];
    assign r_mapped[15]=d_read[10]; assign r_mapped[17]=d_read[11];
    assign r_mapped[18]=d_read[12]; assign r_mapped[19]=d_read[13];
    assign r_mapped[20]=d_read[14]; assign r_mapped[21]=d_read[15];
    assign r_mapped[22]=d_read[16]; assign r_mapped[23]=d_read[17];
    assign r_mapped[24]=d_read[18]; assign r_mapped[25]=d_read[19];
    assign r_mapped[26]=d_read[20]; assign r_mapped[27]=d_read[21];
    assign r_mapped[28]=d_read[22]; assign r_mapped[29]=d_read[23];
    assign r_mapped[30]=d_read[24]; assign r_mapped[31]=d_read[25];
    assign r_mapped[33]=d_read[26]; assign r_mapped[34]=d_read[27];
    assign r_mapped[35]=d_read[28]; assign r_mapped[36]=d_read[29];
    assign r_mapped[37]=d_read[30]; assign r_mapped[38]=d_read[31];

    // Recalculate parity bits from the read data
    wire c1, c2, c4, c8, c16, c32;
    assign c1  = r_mapped[3]^r_mapped[5]^r_mapped[7]^r_mapped[9]^r_mapped[11]^r_mapped[13]^r_mapped[15]^r_mapped[17]^r_mapped[19]^r_mapped[21]^r_mapped[23]^r_mapped[25]^r_mapped[27]^r_mapped[29]^r_mapped[31]^r_mapped[33]^r_mapped[35]^r_mapped[37];
    assign c2  = r_mapped[3]^r_mapped[6]^r_mapped[7]^r_mapped[10]^r_mapped[11]^r_mapped[14]^r_mapped[15]^r_mapped[18]^r_mapped[19]^r_mapped[22]^r_mapped[23]^r_mapped[26]^r_mapped[27]^r_mapped[30]^r_mapped[31]^r_mapped[34]^r_mapped[35]^r_mapped[38];
    assign c4  = r_mapped[5]^r_mapped[6]^r_mapped[7]^r_mapped[12]^r_mapped[13]^r_mapped[14]^r_mapped[15]^r_mapped[20]^r_mapped[21]^r_mapped[22]^r_mapped[23]^r_mapped[28]^r_mapped[29]^r_mapped[30]^r_mapped[31]^r_mapped[36]^r_mapped[37]^r_mapped[38];
    assign c8  = r_mapped[9]^r_mapped[10]^r_mapped[11]^r_mapped[12]^r_mapped[13]^r_mapped[14]^r_mapped[15]^r_mapped[24]^r_mapped[25]^r_mapped[26]^r_mapped[27]^r_mapped[28]^r_mapped[29]^r_mapped[30]^r_mapped[31];
    assign c16 = r_mapped[17]^r_mapped[18]^r_mapped[19]^r_mapped[20]^r_mapped[21]^r_mapped[22]^r_mapped[23]^r_mapped[24]^r_mapped[25]^r_mapped[26]^r_mapped[27]^r_mapped[28]^r_mapped[29]^r_mapped[30]^r_mapped[31];
    assign c32 = r_mapped[33]^r_mapped[34]^r_mapped[35]^r_mapped[36]^r_mapped[37]^r_mapped[38];

    // Syndrome = Recalculated Parity XOR Stored Parity
    wire [5:0] syn;
    assign syn[0] = c1  ^ code_in[32]; // stored p1
    assign syn[1] = c2  ^ code_in[33]; // stored p2
    assign syn[2] = c4  ^ code_in[34]; // stored p4
    assign syn[3] = c8  ^ code_in[35]; // stored p8
    assign syn[4] = c16 ^ code_in[36]; // stored p16
    assign syn[5] = c32 ^ code_in[37]; // stored p32

    // Overall Parity Check (pG)
    wire syn_G = ^code_in; // Includes data, p1-p32, and pG

    // SECDED Logic
 // Use logical operators to handle potential 'x' bits safely
assign s_err = (syn != 6'b0) && (syn_G === 1'b1);
assign d_err = (syn != 6'b0) && (syn_G === 1'b0);
    // --- 3. CORRECTION LOGIC ---
    // Mapping Syndrome back to Data Bit index
    reg [31:0] correction_mask;
    always @(*) begin
        correction_mask = 32'b0;
        if (s_err) begin
            case (syn)
                6'd3:  correction_mask[0] = 1;
                6'd5:  correction_mask[1] = 1;
                6'd6:  correction_mask[2] = 1;
                6'd7:  correction_mask[3] = 1;
                6'd9:  correction_mask[4] = 1;
                6'd10: correction_mask[5] = 1;
                6'd11: correction_mask[6] = 1;
                6'd12: correction_mask[7] = 1;
                6'd13: correction_mask[8] = 1;
                6'd14: correction_mask[9] = 1;
                6'd15: correction_mask[10] = 1;
                6'd17: correction_mask[11] = 1;
                6'd18: correction_mask[12] = 1;
                6'd19: correction_mask[13] = 1;
                6'd20: correction_mask[14] = 1;
                6'd21: correction_mask[15] = 1;
                6'd22: correction_mask[16] = 1;
                6'd23: correction_mask[17] = 1;
                6'd24: correction_mask[18] = 1;
                6'd25: correction_mask[19] = 1;
                6'd26: correction_mask[20] = 1;
                6'd27: correction_mask[21] = 1;
                6'd28: correction_mask[22] = 1;
                6'd29: correction_mask[23] = 1;
                6'd30: correction_mask[24] = 1;
                6'd31: correction_mask[25] = 1;
                6'd33: correction_mask[26] = 1;
                6'd34: correction_mask[27] = 1;
                6'd35: correction_mask[28] = 1;
                6'd36: correction_mask[29] = 1;
                6'd37: correction_mask[30] = 1;
                6'd38: correction_mask[31] = 1;
                default: correction_mask = 32'b0;
            endcase
        end
    end

    assign data_out = code_in[31:0] ^ correction_mask;

endmodule