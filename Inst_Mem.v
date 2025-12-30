`timescale 1ns / 1ps

// Inst_Mem：指令存储器（只读）
// - addr 为字节地址
// - 内部按字对齐：用 addr[4:2] 选择 8 条指令
module Inst_Mem(
    input [31:0] addr,
    output reg [31:0] inst
);

reg [31:0] inst_mem[0:7];

// initial：仿真初始化固定指令序列
// 目的：验证 addi/beq/bne/jal/jr/j 的控制与跳转
initial begin
    // 修正指令序列：先赋值→beq→bne→jal→jr→j
    inst_mem[0] = 32'h20010005; // addi $1,$0,5 （$1=5）
    inst_mem[1] = 32'h20020006; // addi $2,$0,6 （$2=6，确保bne触发）
    inst_mem[2] = 32'h00010814; // beq $0,$1,4   （$0≠$1，不分支，PC+4到0x10）
    inst_mem[3] = 32'h00410815; // bne $2,$1,4   （$2≠$1，分支到0x1C）
    inst_mem[4] = 32'h0c000007; // jal 0x1C      （跳转并写$31=0x14）
    inst_mem[5] = 32'h00000000; // NOP
    inst_mem[6] = 32'h03e00008; // jr $31        （跳回$31=0x14）
    inst_mem[7] = 32'h08000000; // j 0x0         （最后跳回0x0）
end

// 组合读：根据 addr[4:2] 输出对应指令
always @(*) begin
    case(addr[4:2])
        3'b000: inst = inst_mem[0];
        3'b001: inst = inst_mem[1];
        3'b010: inst = inst_mem[2];
        3'b011: inst = inst_mem[3];
        3'b100: inst = inst_mem[4];
        3'b101: inst = inst_mem[5];
        3'b110: inst = inst_mem[6];
        3'b111: inst = inst_mem[7];
        default: inst = 32'h00000000;
    endcase
end

endmodule