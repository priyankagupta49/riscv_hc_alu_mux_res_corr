`timescale 1ns / 1ps
module Register_File(
    input clk,
    input rst,        // Active-Low Reset
    input WE3,        // Write Enable
    input [4:0] A1,   // Address for Read Port 1 (RS1)
    input [4:0] A2,   // Address for Read Port 2 (RS2)
    input [4:0] A3,   // Address for Write Port (RD)
    input [31:0] WD3, // 32-bit Write Data (Corrected from 39-bit)
    output [31:0] RD1,// 32-bit Read Data 1
    output [31:0] RD2 // 32-bit Read Data 2
);

    reg [31:0] Register [31:0];
    integer i;
    
    // --- Synchronous Write Logic ---
    always @ (posedge clk)
    begin
        if (rst == 1'b0) begin 
            // Reset all registers to zero on Active-Low reset
            for (i = 0; i < 32; i = i + 1)
                Register[i] <= 32'h00000000;
        end
        else if(WE3 && (A3 != 5'h00)) begin
            // Write data to register A3, ensuring x0 remains 0
            Register[A3] <= WD3;
        end
    end

    // --- Asynchronous Read Logic ---
    // Register x0 is hardwired to 0
    assign RD1 = (A1 == 5'h00) ? 32'h00000000 : Register[A1];
    assign RD2 = (A2 == 5'h00) ? 32'h00000000 : Register[A2];

endmodule