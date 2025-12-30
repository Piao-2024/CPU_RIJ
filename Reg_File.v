`timescale 1ns / 1ps

// Reg_File：寄存器堆（32×32）
// - 写：posedge clk 且 Write_Reg=1 时写入
// - 读：组合读（always @(*)）
// - 约定：$0 恒为 0（读地址为 0 时强制输出 0）
module Reg_File(
    input clk,
    input rst_n,
    input Write_Reg,
    input [4:0] rs_addr,
    input [4:0] rt_addr,
    input [4:0] rd_addr,
    input [1:0] w_r_s,      // 写地址选择（教材w_r_s）
    input [31:0] wr_data,
    output reg [31:0] rs_data,
    output reg [31:0] rt_data,
    output [31:0] R1_out,   // 导出$1供顶层读取
    output [31:0] R31_out   // 导出$31供顶层读取
);

reg [31:0] regs[0:31]; // 内部寄存器数组（reg类型）
integer i;

// 复位与写寄存器
// - rst_n=0：清零全部寄存器
// - Write_Reg=1：根据 w_r_s 选择写 rd/rt/$31
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0; i<=31; i=i+1) regs[i] <= 32'h00000000;
    end else if(Write_Reg) begin
        case(w_r_s)
            2'b11: regs[31] <= wr_data; // jal写$31
            2'b01: regs[rt_addr] <= wr_data;
            2'b00: regs[rd_addr] <= wr_data;
            default: ;
        endcase
    end
end

// 读寄存器
// - 若读 $0（地址 0）则输出常数 0
always @(*) begin
    rs_data = (rs_addr == 5'd0) ? 32'h00000000 : regs[rs_addr];
    rt_data = (rt_addr == 5'd0) ? 32'h00000000 : regs[rt_addr];
end

// 导出指定寄存器值（用wire中转，避免直接assign reg数组）
wire [31:0] R1;
wire [31:0] R31;
assign R1 = regs[1];       // reg数组值赋给wire（合法）
assign R31 = regs[31];
assign R1_out = R1;        // 端口导出wire值
assign R31_out = R31;

endmodule