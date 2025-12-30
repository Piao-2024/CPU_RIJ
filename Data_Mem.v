`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Data_Mem：数据存储器（简化 RAM）
//
// 特性：
// - 写：同步写（posedge clk），we=1 时写入
// - 读：组合读（always @(*)），地址变化立即反映到 rd_data
// - addr：字节地址（byte address）
//   内部用 addr[6:2] 作为 word 索引：
//   - [1:0] 被忽略（等价于 word 对齐）
//   - [6:2] 可表示 0~31（32 个 word）
//
// 注意：当前 case 只实现了 0~4 的地址映射：
// - 读：其它地址默认输出 0
// - 写：其它地址默认写到 data_mem[0]
// 这会限制可用地址范围，属于“实验简化版本”的行为
//////////////////////////////////////////////////////////////////////////////////

module Data_Mem(
    input clk,             // 时钟：写在上升沿生效
    input we,              // 写使能（高有效）
    input [31:0] addr,     // 字节地址
    input [31:0] wr_data,  // 写入数据
    output reg [31:0] rd_data // 读出数据（组合输出寄存器）
);

    // 初始化循环用变量：必须声明在模块作用域（Verilog 语法要求）
    integer i;

    // 32 x 32-bit 存储阵列（word addressed）
    reg [31:0] data_mem[0:31];

    // 初始化：仿真时将 RAM 清零（综合到 FPGA 时可能推断成初始化或被忽略，视工具链而定）
    initial begin
        for(i=0; i<=31; i=i+1) begin
            data_mem[i] = 32'h00000000;
        end
    end

    // =========================================================
    // 写操作：同步写（posedge clk）
    // =========================================================
    always @(posedge clk) begin
        if(we) begin
            // 用 addr[6:2] 作为 word 索引（等价 addr/4）
            case(addr[6:2])
                5'b00000: data_mem[0] <= wr_data;
                5'b00001: data_mem[1] <= wr_data;
                5'b00010: data_mem[2] <= wr_data;
                5'b00011: data_mem[3] <= wr_data;
                5'b00100: data_mem[4] <= wr_data;

                // 其它地址：当前实现写入 0 号单元（简化/占位行为）
                default:  data_mem[0] <= wr_data;
            endcase
        end
    end

    // =========================================================
    // 读操作：组合读（地址变化立即更新输出）
    // =========================================================
    always @(*) begin
        case(addr[6:2])
            5'b00000: rd_data = data_mem[0];
            5'b00001: rd_data = data_mem[1];
            5'b00010: rd_data = data_mem[2];
            5'b00011: rd_data = data_mem[3];
            5'b00100: rd_data = data_mem[4];

            // 其它地址：返回 0（简化/占位行为）
            default:  rd_data = 32'h00000000;
        endcase
    end

endmodule