`timescale 1ns / 1ps

// CPU_TB：测试平台
// - 产生时钟 clk（20ns 周期）
// - 产生复位 rst_n（低有效）
// - 打印 CPU_TOP 导出的关键信号
module CPU_TB;

reg clk;
reg rst_n;
wire [31:0] PC_out;
wire [31:0] Inst_out;
wire [31:0] ALU_Out_out;
wire Zero_out;
wire [31:0] R1_out;
wire [31:0] R31_out;

// 例化顶层模块
CPU_TOP cpu(
    .clk(clk),
    .rst_n(rst_n),
    .PC_out(PC_out),
    .Inst_out(Inst_out),
    .ALU_Out_out(ALU_Out_out),
    .Zero_out(Zero_out),
    .R1_out(R1_out),
    .R31_out(R31_out)
);

// 时钟生成（20ns周期）
initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

// 复位信号
initial begin
    rst_n = 0;
    #15 rst_n = 1;
end

// 打印测试结果
// $display：打印一次
// $monitor：信号变化即打印
initial begin
    $display("------------------------实验指令测试------------------------");
    $monitor("Time=%0d | PC=%h | Inst=%h | ALU_Out=%h | Zero=%b | R1=%h | R31=%h",
        $time, PC_out, Inst_out, ALU_Out_out, Zero_out, R1_out, R31_out);
    #1000 $stop;
end

endmodule