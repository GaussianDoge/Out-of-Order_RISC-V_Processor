`timescale 1ns / 1ps

module decode(
    input logic clk,
    input logic reset,
    // upstream
    input logic [31:0] instr,
    input logic [31:0] pc_in,
    input logic valid_in,
    output logic ready_in,
    // downstream
    input logic ready_out,
    output logic [31:0] pc_out,
    output logic valid_out,
    // decoded signal
    output logic [4:0] rs1,
    output logic[4:0] rs2,
    output logic [4:0] rd,
    output logic [31:0] imm,
    output logic ALUOp,
    output logic [6:0] OpCode
    // harzard detect signal?
    );
    
    logic [31:0] instr_buf;
    logic [31:0] pc_buf;
    logic ready_in_buf;
    logic valid_out_buf;
    
    // decoded signal
    logic [4:0] rs1_buf;
    logic[4:0] rs2_buf;
    logic [4:0] rd_buf;
    logic imm_buf;
    logic ALUOp_buf;
    logic [6:0] OpCode_buf;
    
    assign pc_out = pc_buf;
    assign ready_in = ready_in_buf;
    assign valid_out = valid_out_buf;
    assign rs1 = rs1_buf;
    assign rs2 = rs2_buf;
    assign rd = rd_buf;
    assign imm = imm_buf;
    assign ALUOp = ALUOp_buf;
    assign OpCode = OpCode_buf;
    
    
    always @ (*) begin
        if (reset) begin
            instr_buf <= 32'b0;
            pc_buf <= 32'b0;
            ready_in_buf <= 1'b0;
            valid_out_buf <= 1'b0;
            
            rs1_buf <= 5'b0;
            rs2_buf <= 5'b0;
            rd_buf <= 5'b0;
            OpCode_buf <= 7'b0;
            imm_buf <= 32'b0;
        end else begin
            // handle upstream
            if (valid_in && ready_in) begin
                instr_buf <= instr;
                pc_buf <= pc_in;
                ready_in_buf <= 1'b0;
                valid_out_buf <= 1'b1;
                
                rs1_buf <= instr[19:15];
                rs2_buf <= instr[24:20];
                rd_buf <= instr[11:7];
                OpCode_buf <= instr[6:0];
                imm_buf <= instr;
                ALUOp_buf <= {instr[30], instr[14:12]};
            end else if (ready_out && valid_out) begin
            // handle downstream
                ready_in_buf <= 1'b1;
                valid_out_buf <= 1'b0;
                
                pc_buf <= pc_in;
                rs1_buf <= instr[19:15];
                rs2_buf <= instr[24:20];
                rd_buf <= instr[11:7];
                OpCode_buf <= instr[6:0];
                imm_buf <= instr;
                ALUOp_buf <= {instr[30], instr[14:12]};
            end else begin
            end
        end
    end
    
endmodule
