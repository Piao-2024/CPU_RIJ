`timescale 1ns / 1ps

// Imm_Ext：立即数符号扩展
// - 把 16 位 imm 扩展成 32 位 imm_ext
// - 若 imm[15]=1（负数），高 16 位填 1；否则填 0
module Imm_Ext(
    input [15:0] imm,
    output reg [31:0] imm_ext
);

// 组合逻辑：立即数变化立即更新扩展结果
always @(*) begin
    imm_ext[15:0] = imm;
    imm_ext[31:16] = imm[15] ? 16'hFFFF : 16'h0000;
end

endmodule