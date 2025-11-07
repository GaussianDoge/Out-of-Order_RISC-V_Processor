`timescale 1ns / 1ps

module phase1_tb;
    // --- Clock ---
    parameter CLK_PERIOD = 10; // 10ns = 100MHz

    // --- DUT Signals ---
    logic clk;
    logic reset;
    
    // Inputs to fetch
    logic [31:0] PC_in;
    logic        ready_out; // From Decode
    
    // Outputs from fetch
    logic [31:0] instr_out;
    logic [31:0] PC_out;
    logic [31:0] PC_4;
    logic        valid_out;
    
    fetch fetch_dut (
        .clk(clk),
        .reset(reset),
        .pc_in(PC_in),
        .ready_out(ready_out),
        .instr_out(instr_out),
        .pc_out(PC_out),
        .pc_4(PC_4),
        .valid_out(valid_out)
    );
    
    
    
    
    
endmodule
