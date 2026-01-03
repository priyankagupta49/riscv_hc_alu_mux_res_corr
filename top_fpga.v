module top_fpga (
    input           clk,
    input           rst,       // Active Low Master Reset (RST=0 to Reset)
    input  [2:0]    sw,        
    output [31:0]   result,
    output         s_err_imem ,
    output        d_err_dmem  ,
    output     s_err_dmem,
    output     d_err_imem
);

    wire [31:0] ResultW_wire; 
    wire imem_we;
    wire loader_done;
    wire [31:0] imem_waddr, imem_wdata;
    wire cpu_rst;

    assign cpu_rst = rst; 

    // Instantiate Instruction Loader
    instr_loader loader (
        .clk(clk),
        .rst(cpu_rst), 
        .op1(8'd10), .op2(8'd5), .alu_op(sw),        
        .imem_we(imem_we),
        .imem_addr(imem_waddr),
        .imem_wdata(imem_wdata),
        .done(loader_done)
    );

    // Instantiate Pipelined CPU with error monitoring
    Pipeline_top cpu (
        .clk(clk),
        .rst(cpu_rst),
        .loader_done_in(loader_done),
        .imem_we(imem_we),
        .imem_waddr(imem_waddr),
        .imem_wdata(imem_wdata),
        .ResultW_out(ResultW_wire),
        .s_err_imem(s_err_imem),
        .d_err_imem(d_err_imem),
        .s_err_dmem(s_err_dmem),
        .d_err_dmem(d_err_dmem)
    );
    
    assign result = ResultW_wire;
    
endmodule