`timescale 1ns / 1ps

// PC：程序计数器（Program Counter）
// 功能：在每个时钟上升沿，根据控制信号 PC_s 选择下一条指令地址
//
// PC_s 编码（你在注释里已定义）：
// - 2'b00：顺序执行（PC = PC + 4）
// - 2'b01：jr（PC = R_Data_A）
// - 2'b10：分支（PC = branch_addr）
// - 2'b11：跳转（PC = jump_addr）
//
// 接口说明：
// - clk：时钟，上升沿更新 PC
// - rst_n：低有效异步复位（negedge rst_n 触发）
// - PC_new：输入端口名写的是 PC+4，但当前实现并未使用该输入（PC+4在模块内部计算）
// - R_Data_A：寄存器 rs 的读数据，用于 jr
// - branch_addr：分支目标地址（beq/bne 已由外部计算好）
// - jump_addr：j/jal 目标地址（已由外部拼接/计算好）
// - PC：当前 PC（寄存器）
// - PC_new_out：输出“PC+4”（当前实现为寄存器输出）
module PC(
    input clk,
    input rst_n,
    input [1:0] PC_s,          // PC 选择信号
    input [31:0] R_Data_A,     // jr：PC = rs_data
    input [31:0] branch_addr,  // 分支目标地址
    input [31:0] jump_addr,    // 跳转目标地址
    output reg [31:0] PC,      // 当前 PC（寄存器）
    output [31:0] PC_new_out   // 输出 PC+4（组合逻辑，始终等于 PC+4）
);

    // 组合输出：PC_new_out 永远反映“当前 PC + 4”
    // 这样 CPU_TOP 在计算 branch/jump/jal 相关地址时，不会出现“上一拍 PC+4”的时序错位。
    assign PC_new_out = PC + 32'h0000_0004;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            // 复位：PC 从 0 开始取指
            PC <= 32'h00000000;
        end else begin
            // 根据 PC_s 选择下一拍 PC 的来源
            case(PC_s)
                2'b00: PC <= PC + 32'h0000_0004; // 顺序执行：PC = PC + 4
                2'b01: PC <= R_Data_A;    // jr：PC = rs_data
                2'b10: PC <= branch_addr; // 分支：PC = branch_addr
                2'b11: PC <= jump_addr;   // 跳转：PC = jump_addr
                default: PC <= PC + 32'h0000_0004;
            endcase
        end
    end

endmodule