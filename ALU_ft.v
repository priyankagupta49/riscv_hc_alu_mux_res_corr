`timescale 1ns / 1ps

module ALU_ft (
    input              clk,
    input              rst,
    input      [31:0]  A,
    input      [31:0]  B,
    input      [2:0]   ALUControl,

    output reg [31:0]  Result,
    output reg         Zero,
    output reg         Carry,
    output reg         OverFlow,
    output reg         Negative,

    output reg         fault_detected_out
);

    // ALU (TB forces u_alu.Result)
    wire [31:0] alu_res;
    wire alu_z, alu_c, alu_v, alu_n;

    ALU u_alu (
        .A(A),
        .B(B),
        .ALUControl(ALUControl),
        .Result(alu_res),
        .Zero(alu_z),
        .Carry(alu_c),
        .OverFlow(alu_v),
        .Negative(alu_n)
    );

    // Stage registers (TB-visible)
    reg [31:0] res_t1;
    reg [31:0] res_t2;

    // FSM
    localparam STAGE1 = 2'b00;
    localparam STAGE2 = 2'b01;
    localparam STAGE3 = 2'b10;

    reg [1:0] state;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state              <= STAGE1;
            fault_detected_out <= 1'b0;
            res_t1             <= 32'b0;
            res_t2             <= 32'b0;
            Result             <= 32'b0;
            Zero               <= 1'b0;
            Carry              <= 1'b0;
            OverFlow           <= 1'b0;
            Negative           <= 1'b0;
        end
        else begin
            case (state)

                // ---------- STAGE-1 ----------
                STAGE1: begin
                    res_t1 <= alu_res;          // may be faulty
                    fault_detected_out <= 1'b0;
                    state <= STAGE2;
                end

                // ---------- STAGE-2 ----------
                STAGE2: begin
                    res_t2 <= alu_res;          // may be faulty or clean

                    if (res_t2 == res_t1) begin
                        // both executions match → accept
                        Result   <= alu_res;
                        Zero     <= alu_z;
                        Carry    <= alu_c;
                        OverFlow <= alu_v;
                        Negative <= alu_n;
                        state    <= STAGE1;
                    end
                    else begin
                        // mismatch → fault → Stage-3
                        fault_detected_out <= 1'b1;
                        state <= STAGE3;
                    end
                end

                // ---------- STAGE-3 ----------
                STAGE3: begin
                    // assumed clean recomputation
                    Result   <= alu_res;
                    Zero     <= alu_z;
                    Carry    <= alu_c;
                    OverFlow <= alu_v;
                    Negative <= alu_n;
                    state <= STAGE1;
                end

            endcase
        end
    end

endmodule