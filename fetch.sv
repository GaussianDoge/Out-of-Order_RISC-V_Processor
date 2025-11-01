`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/31/2025 03:30:11 PM
// Design Name: 
// Module Name: Fetch
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


module Fetch(
    input logic clk,
    input logic reset,
        
    input logic ready_in,
    input logic [31:0] PC_in,
    output logic [31:0] instr_out,
    output logic [31:0] PC_out,
    output logic [31:0] PC_4,
    output logic valid_out
);
    logic [31:0] PC_buf;
    logic [31:0] instr_buf;
    logic valid_out_sig;
    
    logic [31:0] instr_icache;
    
    ICache ICache_dut (
        .clk(clk),
        .reset(reset),
        .address(PC_in),
        .instruction(instr_icache)
    );
    
    assign PC_out = PC_buf;
    assign PC_4 = PC_buf + 32'd4;
    assign valid_out = valid_out_sig;
    assign instr_out = instr_buf;
    
    always_ff @(posedge clk) begin
        if (reset) begin
            valid_out_sig <= 1'b0;  
            instr_buf <= 32'b0;
            PC_buf <= 32'b0;
        end else begin
            if (!valid_out_sig || ready_in) begin
                valid_out_sig <= 1'b1;
                PC_buf <= PC_in;
                instr_buf <= instr_icache;
            end
        end
    end
endmodule