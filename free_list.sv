module free_list#
(
    parameter int DEPTH = 128
)(
  input  logic clk,
  input  logic reset,

  input  logic write_en,
  input  logic read_en,
  input  logic spec, 
  input  logic mispredict,
  output logic empty,
  input  logic [7:0] re_ptr,
  output logic [7:0] ptr
);
  logic [7:0]  w_ptr, r_ptr;  
  logic [7:0] ctr;
  
  assign ptr = r_ptr;    
  assign empty = (ctr == 0);
   
  always_ff @(posedge clk) begin
    if (reset) begin
      w_ptr    <= 8'd32;
      r_ptr    <= 8'd0;
      ctr      <= 8'd32;
    end else begin
      automatic logic do_write = write_en;           
      automatic logic do_read  = read_en && (ctr!=0) && ~spec; 
      if (mispredict) begin
        r_ptr <= re_ptr;
      end
      if (do_write && (ctr == 8'd128) && !do_read) begin
        r_ptr <= (r_ptr + 1) % DEPTH;
      end
      if (do_read) begin
        r_ptr    <= (r_ptr + 1) % DEPTH;
      end
      if (do_write) begin
        w_ptr      <= (w_ptr + 1) % DEPTH;
      end

      unique case ({do_write, do_read})
        2'b10: if (ctr < DEPTH) ctr <= ctr + 1'b1;
        2'b01: ctr <= ctr - 1'b1;    
        default: ctr <= ctr;          
      endcase
    end
  end
endmodule
