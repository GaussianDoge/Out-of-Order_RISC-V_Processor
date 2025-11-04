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
    output logic [2:0] ALUOp,
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
    logic [31:0] imm_buf;
    logic [2:0] ALUOp_buf;
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

    ImmGen immgen_dut (
        .instruction(instruction),
        .imm(imm_buf)
    );

    always_comb begin
        Opcode_now = instruction[6:0];
        case (Opcode_now) 
            // imm_buf is already calculated
            7'b0010011: begin
                rs1_buf = instruction[19:15];
                rs2_buf = 5'b0;
                rd_buf = instruction[11:7];
                ALUOp_buf = 3'b000;
            end
            7'b0110111: begin
                rs1_buf = 5'b0;
                rs2_buf = 5'b0;
                rd_buf = instruction[11:7];
                ALUOp_buf = 3'b101;
            end
            7'b0110011: begin
                rs1_buf = instruction[19:15];
                rs2_buf = instruction[24:20];
                rd_buf = instruction[11:7];
                ALUOp_buf = 3'b001;
            end 
            7'b0000011: begin
                rs1_buf = instruction[19:15];
                rs2_buf = 5'b0;
                rd_buf = instruction[11:7];
                ALUOp_buf = 3'b010;
            end
            7'b0100011: begin
                rs1_buf = instruction[19:15];
                rs2_buf = instruction[24:20];
                rd_buf = 5'b0;
                ALUOp_buf = 3'b011;
            end
            7'b1100011: begin
                rs1_buf = instruction[19:15];
                rs2_buf = instruction[24:20];
                rd_buf = 5'b0;
                ALUOp_buf = 3'b100;
            end
            7'b1100111: begin
                rs1_buf = instruction[19:15];
                rs2_buf = 5'b0;
                rd_buf = instruction[11:7];
                ALUOp_buf = 3'b110;
            end
        endcase
    end

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
