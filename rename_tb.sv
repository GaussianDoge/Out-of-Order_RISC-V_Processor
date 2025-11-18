`timescale 1ns / 1ps

import types_pkg::*;

// types_pkg now has:
// typedef struct packed {
//   logic [31:0] pc;
//   logic [4:0]  rs1, rs2, rd;
//   logic [31:0] imm;
//   logic [2:0]  ALUOp;
//   logic [6:0]  Opcode;
//   logic [1:0]  fu;
// } decode_data;
//
// typedef struct packed {
//   logic [6:0] ps1;
//   logic [6:0] ps2;
//   logic [6:0] pd_new;
//   logic [6:0] pd_old;
//   logic [32:0] imm;
//   logic [4:0] rob_tag;
// } rename_data;

module rename_tb;

  // ---------------- Clock & reset ----------------
  logic clk = 0;
  logic reset = 1;
  always #5 clk = ~clk;  // 100 MHz

  // ---------------- DUT I/O ----------------
  logic        valid_in;
  decode_data  data_in;
  logic        ready_in;

  logic        mispredict;

  rename_data  data_out;
  logic        valid_out;
  logic        ready_out;

  // ---------------- Instantiate DUT ----------------
  rename dut (
    .clk       (clk),
    .reset     (reset),
    .valid_in  (valid_in),
    .data_in   (data_in),
    .ready_in  (ready_in),
    .mispredict(mispredict),
    .data_out  (data_out),
    .valid_out (valid_out),
    .ready_out (ready_out)
  );

  // ---------------- Opcodes (RV32I) ----------------
  localparam [6:0] OP_IMM = 7'b0010011; // I-type ALU
  localparam [6:0] OP     = 7'b0110011; // R-type ALU
  localparam [6:0] LOAD   = 7'b0000011; // Load
  localparam [6:0] STORE  = 7'b0100011; // Store (no rd write)

  // ---------------- Helper macro -------------------
  `define CHECK(MSG, COND) \
    if (!(COND)) begin \
      $error("CHECK FAILED: %s (time=%0t)", MSG, $time); \
    end else begin \
      $display("CHECK OK   : %s (time=%0t)", MSG, $time); \
    end

  // ---------------- Drive one uop ------------------
  // Drives one instruction into rename, waits until it is accepted
  // (valid_in && ready_in && ready_out), then samples outputs
  // one cycle later.
  task automatic drive_uop(
    input logic [6:0] opc,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [4:0] rd,
    input logic [31:0] imm,
    input logic        hold_ready_one_cycle  // 1 = ready_out=0 for one cycle
  );
    begin
      // Present instruction
      valid_in      = 1'b1;
      data_in       = '0;
      data_in.pc    = 32'h0000_1000; // arbitrary, rename doesn't use pc
      data_in.Opcode= opc;
      data_in.rs1   = rs1;
      data_in.rs2   = rs2;
      data_in.rd    = rd;
      data_in.imm   = imm;

      // Choose ALUOp/fu just to keep decode_data consistent.
      // (Rename doesn't actually look at fu.)
      unique case (opc)
        OP_IMM: begin
          data_in.ALUOp = 3'b011;
          data_in.fu    = 2'b01;
        end
        OP: begin
          data_in.ALUOp = 3'b010;
          data_in.fu    = 2'b01;
        end
        LOAD: begin
          data_in.ALUOp = 3'b000;
          data_in.fu    = 2'b11;
        end
        STORE: begin
          data_in.ALUOp = 3'b000;
          data_in.fu    = 2'b11;
        end
        default: begin
          data_in.ALUOp = 3'b000;
          data_in.fu    = 2'b00;
        end
      endcase

      // Downstream ready
      ready_out = ~hold_ready_one_cycle;

      // Wait for handshake
      do @(posedge clk);
      while (!(valid_in && ready_in && ready_out));

      // Drop valid_in so it doesn't re-fire
      valid_in  = 1'b0;
      ready_out = 1'b1;

      // One cycle later, outputs should be valid
      @(posedge clk);
      if (!valid_out)
        $error("valid_out missing on post-fire cycle (time=%0t)", $time);

      // Separate transactions a bit
      @(posedge clk);
    end
  endtask

  // ---------------- Test sequence ------------------
  initial begin
    logic [6:0] pd_new_1;
    logic [6:0] pd_new_2;

    // Init
    valid_in   = 1'b0;
    ready_out  = 1'b1;
    data_in    = '0;
    mispredict = 1'b0;

    // Reset
    repeat (3) @(posedge clk);
    reset = 1'b0;
    @(posedge clk);

    $display("---- Test 1: First writer (ADDI x5, x1, imm) ----");
    // Assume at reset: map[xN] = N (identity), free list gives some non-zero tag.
    drive_uop(OP_IMM, /*rs1*/5'd1, /*rs2*/5'd2, /*rd*/5'd5,
              32'h0000_0001, /*hold_ready_one_cycle*/ 0);

    `CHECK("valid_out==1 after rename", valid_out == 1'b1);
    `CHECK("ps1==map[x1]==1",  data_out.ps1 == 7'd1);
    `CHECK("ps2==map[x2]==2",  data_out.ps2 == 7'd2);
    `CHECK("pd_old==map[x5]==5", data_out.pd_old == 7'd5);

    pd_new_1 = data_out.pd_new;
    `CHECK("pd_new allocated (!= old mapping)",
           (pd_new_1 !== data_out.pd_old));
    // If your free_list never hands out 0, keep this:
    `CHECK("pd_new != 0 (assuming p0 reserved for x0)",
           pd_new_1 != 7'd0);

    $display("---- Test 2: Dependent writer (LOAD x6, 0(x5)) ----");
    // rs1 = x5 should see the new mapping from Test 1.
    drive_uop(LOAD, /*rs1*/5'd5, /*rs2*/5'd0, /*rd*/5'd6,
              32'h0, /*hold_ready_one_cycle*/ 0);

    `CHECK("ps1==new x5 mapping (pd_new_1)",
           data_out.ps1 == pd_new_1);
    `CHECK("pd_old==map[x6]==6", data_out.pd_old == 7'd6);

    pd_new_2 = data_out.pd_new;
    `CHECK("second pd_new allocated and different from first",
           (pd_new_2 != pd_new_1) && (pd_new_2 != 7'd0));

    $display("---- Test 3: Backpressure (stall ready_out) ----");
    // ADD x7, x6, x0; stall one cycle by holding ready_out low.
    valid_in       = 1'b1;
    data_in        = '0;
    data_in.pc     = 32'h0000_2000;
    data_in.Opcode = OP;
    data_in.rs1    = 5'd6;  // should map to pd_new_2
    data_in.rs2    = 5'd0;
    data_in.rd     = 5'd7;
    data_in.imm    = '0;
    data_in.ALUOp  = 3'b010;
    data_in.fu     = 2'b01;

    // Backpressure one cycle
    ready_out = 1'b0;
    @(posedge clk);
    `CHECK("no fire when ready_out=0",
           !(valid_in && ready_in && ready_out));
    `CHECK("valid_out low while stalled", valid_out == 1'b0);

    // Release backpressure
    ready_out = 1'b1;
    // Wait for fire
    do @(posedge clk);
    while (!(valid_in && ready_in && ready_out));

    // One cycle later, sample outputs
    @(posedge clk);
    `CHECK("ps1==mapping of x6 (pd_new_2)",
           data_out.ps1 == pd_new_2);
    `CHECK("pd_old==map[x7]==7", data_out.pd_old == 7'd7);
    `CHECK("pd_new allocated for x7",
           data_out.pd_new != 7'd0);

    valid_in = 1'b0;
    @(posedge clk);

    $display("---- Test 4: Non-writer STORE x2 -> 0(x1) ----");
    // STORE should not allocate a new pd (Opcode == 0100011).
    drive_uop(STORE, /*rs1*/5'd1, /*rs2*/5'd2, /*rd*/5'd0,
              32'h0, /*hold_ready_one_cycle*/ 0);

    `CHECK("STORE ps1==map[x1]==1", data_out.ps1 == 7'd1);
    `CHECK("STORE ps2==map[x2]==2", data_out.ps2 == 7'd2);
    `CHECK("STORE pd_new==0 (no allocation)", data_out.pd_new == 7'd0);
    `CHECK("STORE pd_old==map[x0]==0",        data_out.pd_old == 7'd0);

    $display("---- Test 5: rd==x0 (should not allocate) ----");
    // ADDI x0, x1, imm: should NOT allocate, x0 is hardwired.
    drive_uop(OP_IMM, /*rs1*/5'd1, /*rs2*/5'd0, /*rd*/5'd0,
              32'h1234, /*hold_ready_one_cycle*/ 0);

    `CHECK("x0 write: pd_new==0 (no alloc)", data_out.pd_new == 7'd0);
    `CHECK("x0 write: pd_old==map[x0]==0",    data_out.pd_old == 7'd0);

    $display("---- NOTE: mispredict / checkpoint tests ----");
    $display("Current rename.sv only has a mispredict input; ");
    $display("once you add explicit branch-tag & checkpoint ");
    $display("ports we can extend this TB to exercise recovery.");

    $display("All basic rename tests completed.");
    $finish;
  end

endmodule
