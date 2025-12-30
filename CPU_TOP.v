`timescale 1ns / 1ps

// CPU_TOP：顶层模块（精简单周期 CPU 数据通路）
// 主要连接关系：
//   PC -> Inst_Mem -> (字段拆分) -> Controller/Reg_File/Imm_Ext -> ALU
//   Controller 产生控制信号：PC_s/ALU_OP/imm_s/Write_Reg/w_r_s/wr_data_s*
//   Data_Mem 已实例化并连线，wr_data_s0 可选择其读数据（用于后续扩展 lw）
module CPU_TOP(
    input clk,
    input rst_n,
    // 供TB打印的信号
    output [31:0] PC_out,
    output [31:0] Inst_out,
    output [31:0] ALU_Out_out,
    output Zero_out,
    output [31:0] R1_out,
    output [31:0] R31_out // $31（ra），用于jal指令
);

// -----------------------------
// 内部信号：PC/指令/寄存器/控制/地址等
// -----------------------------
// 内部信号定义（新增Data_Mem相关信号）
wire [31:0] PC;
wire [31:0] PC_new; // PC+4
wire [31:0] Inst;
wire [5:0] op;
wire [5:0] func;
wire [4:0] rs_addr;
wire [4:0] rt_addr;
wire [4:0] rd_addr;
wire [4:0] shamt;
wire [15:0] imm_offset;
wire [25:0] j_addr;
wire [31:0] imm_ext; // 符号扩展后的立即数
wire [31:0] rs_data;
wire [31:0] rt_data;
wire [31:0] wr_data;
wire [31:0] ALU_Out;
wire Zero;
wire [1:0] PC_s; // PC选择信号
wire [1:0] w_r_s; // 写地址选择
wire imm_s;      // ALU源选择
wire wr_data_s1;  // 写数据选择位1
wire wr_data_s0;  // 写数据选择位0（新增：用于选择Data_Mem读数据）
wire [2:0] ALU_OP;
wire Write_Reg;
wire Mem_Write;
wire [31:0] branch_addr; // 分支地址（PC+4 + offset*4）
wire [31:0] jump_addr;   // J型跳转地址（PC[31:28]+address+2'b00）
wire [31:0] jal_addr;    // jal指令写回的$ra值（PC+4）
// Data_Mem新增信号
wire [31:0] data_mem_rd_data; // Data_Mem读数据
wire [31:0] data_mem_wr_data; // Data_Mem写数据（复用rt_data）

// -----------------------------
// 子模块实例化：PC / Inst_Mem / Controller / Reg_File / Imm_Ext / ALU / Data_Mem
// -----------------------------

// 1. PC模块
PC pc_module(
    .clk(clk),
    .rst_n(rst_n),
    .PC_s(PC_s),
    .PC_new(PC_new),
    .R_Data_A(rs_data),
    .branch_addr(branch_addr),
    .jump_addr(jump_addr),
    .PC(PC),
    .PC_new_out(PC_new)
);

// 指令存储器：addr=PC -> inst=Inst
// 2. 指令存储器（Inst_Mem）
Inst_Mem inst_mem(
    .addr(PC),
    .inst(Inst)
);

// 3. 控制器（按教材表14.26生成控制信号）
Controller ctrl(
    .op(op),
    .func(func),
    .Zero(Zero),
    .w_r_s(w_r_s),
    .imm_s(imm_s),
    .wr_data_s1(wr_data_s1),
    .wr_data_s0(wr_data_s0), // 连接控制器的wr_data_s0
    .ALU_OP(ALU_OP),
    .Write_Reg(Write_Reg),
    .Mem_Write(Mem_Write),
    .PC_s(PC_s)
);

// 寄存器堆：读出 rs_data/rt_data；写回由 Write_Reg + w_r_s 决定
// 4. 寄存器堆（支持$31写回）
Reg_File reg_file(
    .clk(clk),
    .rst_n(rst_n),
    .Write_Reg(Write_Reg),
    .rs_addr(rs_addr),
    .rt_addr(rt_addr),
    .rd_addr(rd_addr),
    .w_r_s(w_r_s),
    .wr_data(wr_data),
    .rs_data(rs_data),
    .rt_data(rt_data),
    .R1_out(R1_out),
    .R31_out(R31_out)
);

// 立即数扩展：Inst[15:0] -> imm_ext（符号扩展）
// 5. 立即数符号扩展
Imm_Ext imm_ext_module(
    .imm(imm_offset),
    .imm_ext(imm_ext)
);

// 6. ALU（实现算术/逻辑/移位运算）
ALU alu_module(
    .a(rs_data),
    .b(imm_s ? imm_ext : rt_data),
    .ALU_OP(ALU_OP),
    .ALU_Out(ALU_Out),
    .Zero(Zero)
);

// 数据存储器：addr=ALU_Out；写数据=rt_data；读数据=rd_data（供 lw 预留）
// 7. 数据存储器（Data_Mem，新增）
Data_Mem data_mem_module(
    .clk(clk),
    .we(Mem_Write),       // 写使能：接控制器的Mem_Write
    .addr(ALU_Out),       // 地址：ALU运算结果（lw/sw的地址）
    .wr_data(rt_data),    // 写数据：寄存器堆的rt_data（sw指令源数据）
    .rd_data(data_mem_rd_data) // 读数据：输出到写回选择
);

// -----------------------------
// 组合逻辑：分支/跳转地址计算、写回数据选择、字段拆分
// -----------------------------

// 8. 地址计算（分支/跳转）
assign branch_addr = PC_new + (imm_ext << 2); // PC+4 + offset*4
assign jump_addr = {PC_new[31:28], j_addr, 2'b00}; // J型地址拼接
assign jal_addr = PC_new; // jal指令写回$31的地址（PC+4）

// 写回数据选择：
//   wr_data_s1=1 -> jal_addr(PC+4)
//   wr_data_s0=1 -> data_mem_rd_data（预留给 lw）
//   否则         -> ALU_Out（例如 addi）
// 9. 写数据选择（新增Data_Mem读数据的选择）
assign wr_data = wr_data_s1 ? jal_addr : (wr_data_s0 ? data_mem_rd_data : ALU_Out);

// 指令字段提取
assign op = Inst[31:26];
assign func = Inst[5:0];
assign rs_addr = Inst[25:21];
assign rt_addr = Inst[20:16];
assign rd_addr = Inst[15:11];
assign shamt = Inst[10:6];
assign imm_offset = Inst[15:0];
assign j_addr = Inst[25:0];

// 输出端口（供TB打印）
assign PC_out = PC;
assign Inst_out = Inst;
assign ALU_Out_out = ALU_Out;
assign Zero_out = Zero;

endmodule