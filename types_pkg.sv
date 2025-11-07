package types_pkg;
  typedef struct packed {
    logic [31:0] pc;
    logic [31:0] instr;
  } fetch_data;

  typedef struct packed {
    logic [31:0] pc;
    logic [4:0]  rs1, rs2, rd;
    logic [31:0] imm;
    logic [2:0]  ALUOp;
    logic [6:0]  Opcode;
    logic        fu_mem, fu_alu;
  } decode_data;
endpackage