`timescale 1ns / 1ps

module fetch_cycle (
    input clk, rst,
    input [31:0] PC_Next_In,
    input imem_we,
    input [31:0] imem_waddr, imem_wdata,
    input loader_done_in, // Added stall signal
    output s_err, d_err,
    output [31:0] InstrD, PCPlus4D, PCD 
);
    wire [31:0] PCF, PCPlus4F, InstrF;

    PC_Module pc_inst (
        .clk(clk),
        .rst(rst),
        .PC_Next(PC_Next_In),
        .loader_done_in(loader_done_in),
        .PC(PCF)
    );

    assign PCPlus4F = PCF + 32'd4;

    Instruction_Memory imem (
        .clk(clk), .we(imem_we), .waddr(imem_waddr), .wdata(imem_wdata),
        .raddr(PCF), .rdata(InstrF), .s_err(s_err), .d_err(d_err)
    );

    assign InstrD = InstrF;     
    assign PCPlus4D = PCPlus4F;   
    assign PCD = PCF;        
endmodule