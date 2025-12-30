`timescale 1ns / 1ps

// Controller：控制器/译码器
// - 输入：op/func（指令字段）、Zero（ALU 比较结果）
// - 输出：PC_s / ALU_OP / imm_s / Write_Reg / w_r_s / wr_data_s* / Mem_Write
module Controller(
    input [5:0] op,
    input [5:0] func,
    input Zero,             // ALU零标志（beq/bne判断）
    output reg [1:0] w_r_s, // 写地址选择
    output reg imm_s,       // ALU源选择
    output reg wr_data_s1,  // 写数据选择位1
    output reg wr_data_s0,  // 写数据选择位0
    output reg [2:0] ALU_OP,// ALU操作码
    output reg Write_Reg,   // 寄存器写使能
    output reg Mem_Write,   // 存储器写使能（实验未要求，置0）
    output reg [1:0] PC_s   // PC选择信号
);

always @(*) begin
    // 默认值初始化（未识别指令时的“安全态”）
    // - PC_s=00：顺序执行（PC+4）
    // - Write_Reg/Mem_Write=0：不写寄存器/不写内存
    w_r_s = 2'b00;
    imm_s = 1'b0;
    wr_data_s1 = 1'b0;
    wr_data_s0 = 1'b0;
    ALU_OP = 3'b000;
    Write_Reg = 1'b0;
    Mem_Write = 1'b0;
    PC_s = 2'b00; // 默认PC+4

    // op 译码
    case(op)
        6'b000000: begin // R型指令（仅实现jr）
            // func 进一步译码
            case(func)
                6'b001000: begin // jr rs
                    PC_s = 2'b01; // 选rs_data作为PC
                    Write_Reg = 1'b0;
                end
                default: ;
            endcase
        end
        6'b000100: begin // beq rs,rt,label
            imm_s = 1'b0;
            ALU_OP = 3'b001; // ALU做减法
            PC_s = Zero ? 2'b10 : 2'b00; // Zero=1则分支
            Write_Reg = 1'b0;
        end
        6'b000101: begin // bne rs,rt,label
            imm_s = 1'b0;
            ALU_OP = 3'b001; // ALU做减法
            PC_s = !Zero ? 2'b10 : 2'b00; // Zero=0则分支
            Write_Reg = 1'b0;
        end
        6'b000010: begin // j label
            PC_s = 2'b11; // 选J型跳转地址
            Write_Reg = 1'b0;
        end
        6'b000011: begin // jal label
            PC_s = 2'b11; // 选J型跳转地址
            w_r_s = 2'b11; // 写$31（ra）
            wr_data_s1 = 1'b1; // 写数据为PC+4
            Write_Reg = 1'b1; // 写回$31
        end
        // addi：用于初始化寄存器值，便于分支比较
        6'b001000: begin // addi rt,rs,offset
            imm_s = 1'b1;    // ALU源选立即数
            ALU_OP = 3'b000; // ALU做加法
            w_r_s = 2'b01;   // 写地址选rt
            Write_Reg = 1'b1;// 允许写寄存器
            PC_s = 2'b00;    // PC正常+4
        end
        default: ;
    endcase
end

endmodule