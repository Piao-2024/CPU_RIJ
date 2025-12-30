`timescale 1ns / 1ps

// PC：程序计数器
// - PC_s=00：顺序执行（PC+4）
// - PC_s=01：jr（PC=rs_data）
// - PC_s=10：分支（PC=branch_addr）
// - PC_s=11：跳转（PC=jump_addr）
module PC(
    input clk,
    input rst_n,
    input [1:0] PC_s,       // 教材表14.26的PC_s
    input [31:0] PC_new,    // PC+4
    input [31:0] R_Data_A,  // rs_data（jr指令）
    input [31:0] branch_addr, // 分支地址（beq/bne）
    input [31:0] jump_addr,  // J型跳转地址（j/jal）
    output reg [31:0] PC,   // 当前PC
    output reg [31:0] PC_new_out // PC+4输出（改为reg）
);

// 时序逻辑：在时钟沿更新 PC，并输出 PC+4
// 复位：rst_n=0 时 PC 置 0
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        PC <= 32'h00000000;
        PC_new_out <= 32'h00000004;
    end else begin
        PC_new_out <= PC + 32'h00000004; // 时钟沿更新PC+4
        case(PC_s)
            2'b00: PC <= PC_new_out;        // 正常+4
            2'b01: PC <= R_Data_A;          // jr指令（rs_data）
            2'b10: PC <= branch_addr;       // beq/bne分支
            2'b11: PC <= jump_addr;         // j/jal跳转
        endcase
    end
end

endmodule