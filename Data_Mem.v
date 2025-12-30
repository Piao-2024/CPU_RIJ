`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Data_Mem：数据存储器（RAM 风格）
// - 写：posedge clk 同步写，we=1 时写入
// - 读：组合读 always @(*)
// - addr 使用字节地址，内部通过 addr[6:2] 映射为 word 索引
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:53:23 12/02/2025 
// Design Name: 
// Module Name:    Data_Mem 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
// Data_Mem模块修正版
`timescale 1ns / 1ps

module Data_Mem(
    input clk,          // 时钟
    input we,           // 写使能（高有效）
    input [31:0] addr,  // 32位地址输入
    input [31:0] wr_data, // 32位写数据
    output reg [31:0] rd_data // 32位读数据
);
    // 1. 模块级声明变量（关键：移出所有块）
    integer i; // 初始化用的整数变量，放在模块开头
    // 定义数据存储器：32个32位存储单元
    reg [31:0] data_mem[0:31]; 

    // 2. 初始化数据存储器（全0，无块内变量声明）
    initial begin
        for(i=0; i<=31; i=i+1) begin
            data_mem[i] = 32'h00000000;
        end
    end

    // 3. 写操作（时序逻辑：时钟上升沿）
    //    - we=1 时写入
    //    - addr[6:2] 作为 word 索引
    always @(posedge clk) begin
        if(we) begin
            case(addr[6:2]) // 5位地址匹配存储单元
                5'b00000: data_mem[0] = wr_data;
                5'b00001: data_mem[1] = wr_data;
                5'b00010: data_mem[2] = wr_data;
                5'b00011: data_mem[3] = wr_data;
                5'b00100: data_mem[4] = wr_data;
                default: data_mem[0] = wr_data; // 默认写第一个单元
            endcase
        end
    end

    // 4. 读操作（组合逻辑：无动态索引）
    //    - 直接按 addr[6:2] 输出对应 data_mem 项
    always @(*) begin
        case(addr[6:2])
            5'b00000: rd_data = data_mem[0];
            5'b00001: rd_data = data_mem[1];
            5'b00010: rd_data = data_mem[2];
            5'b00011: rd_data = data_mem[3];
            5'b00100: rd_data = data_mem[4];
            default: rd_data = 32'h00000000; // 其余地址返回0
        endcase
    end

endmodule