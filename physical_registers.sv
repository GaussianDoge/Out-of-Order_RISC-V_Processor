`timescale 1ns / 1ps

module physical_registers(
    input logic clk,
    input logic reset,

    input logic read,
    input logic write,
    input logic check_rdy,
    input logic set_not_rdy,
    input logic [6:0] target_reg,
    
    input logic [31:0] write_data,
    output logic [31:0] read_data,
    output logic reg_ready
    );
    
    reg [127:0][31:0] phy_reg;
    reg [127:0] reg_rdy_table;
    
    always_comb begin
        if (!reset && check_rdy) begin
            reg_ready = reg_rdy_table[target_reg];
        end
    end
    
    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 128; i++) begin
                phy_reg[i] <= 32'b0;
                reg_rdy_table[i] <= 1'b1;
            end
        end else begin
            case ({read, write, set_not_rdy})
                3'b100: begin // read only
                    read_data <= phy_reg[target_reg];
                end
                3'b010: begin // write only => automatically set reg to ready
                    phy_reg[target_reg] <= write_data;
                    reg_rdy_table[target_reg] <= 1'b1;
                end
                3'b001: begin
                    if (target_reg != 7'b0) begin
                        reg_rdy_table[target_reg] <= 1'b0;
                    end
                end
            endcase
        end
    end
    
endmodule
