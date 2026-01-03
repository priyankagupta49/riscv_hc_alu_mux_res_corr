module PC_Module(
    input clk,
    input rst, // Active Low Master Reset
    input [31:0] PC_Next, 
    input loader_done_in, // Stall input
    output reg [31:0] PC
);

    // CRITICAL FIX: Change to Asynchronous Reset for consistency
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) // CORRECT: Asynchronous Reset when rst is LOW
            PC <= 32'b0;
        // PC advances only if the loader is done AND rst is high
        else if (loader_done_in == 1'b1) 
            PC <= PC_Next;
        // Else: PC holds its current value (stall)
    end
endmodule