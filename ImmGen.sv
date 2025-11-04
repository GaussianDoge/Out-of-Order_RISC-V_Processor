`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/01/2025 06:20:16 PM
// Design Name: 
// Module Name: ImmGen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ImmGen(
    input logic [31:0] instruction,
    output logic [31:0] imm    
);
    logic [11:0] imm_12bits;
    logic [19:0] imm_20bits;
    always_comb begin
        automatic logic [6:0] opcode = instruction[6:0];
        if (opcode == 7'b0010011 || opcode == 7'b1100111 || opcode == 7'b0000011) begin
            imm_12bits = instruction[31:20];
            imm = {{20{imm_12bits[11]}}, imm_12bits};
        end else if (opcode == 7'b0110111) begin
            imm_20bits = instruction[31:12];
            imm = {{12{imm_20bits[19]}}, imm_20bits};
        end else if (opcode == 7'b1100011) begin
            imm_12bits = {instruction[31], instruction[7], instruction[29:24], instruction[11:8]};
            imm = {{20{imm_12bits[11]}}, imm_12bits};
        end else if (opcode == 7'b0100011) begin
            imm_12bits = {instruction[31:25], instruction[11:7]};
            imm = {{20{imm_12bits[11]}}, imm_12bits};
        end
    end
endmodule
