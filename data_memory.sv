`timescale 1ns / 1ps

module data_memory(
    input clk,
    input reset,
    
    // From FU Mem
    input logic [31:0] addr,
    input logic issued,
    input logic [6:0] Opcode,
    input logic [2:0] func3,
    
    // Output
    output logic [31:0] data_out,
    output logic valid
);
    logic [7:0] data_mem [0:2047];
    logic valid_2cycles;
    
    initial begin
        $readmemh("data.mem", data_mem);
    end
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            data_out <= '0;
        end else begin
            valid_2cycles <= issued;
            valid <= valid_2cycles;
            if (valid_2cycles) begin
                if (Opcode == 7'b0000011) begin
                    if (func3 == 3'b100) begin // Lbu
                        data_out <= {{24{1'b0}}, data_mem[addr]};
                    end else if (func3 == 3'b010) begin // Lw
                        data_out <= {data_mem[addr+3], data_mem[addr+2], data_mem[addr+1], data_mem[addr]};
                    end
                end
            end else begin
                data_out <= '0;
            end
        end
    end
endmodule
