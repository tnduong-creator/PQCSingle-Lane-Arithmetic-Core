// mod_sub.sv
// Combinational modular subtraction: (a - b) mod MOD
module mod_sub #(
  parameter int unsigned MOD   = 3329,
  parameter int unsigned WIDTH = $clog2(MOD)
)(
  input  logic [WIDTH-1:0] a,
  input  logic [WIDTH-1:0] b,
  output logic [WIDTH-1:0] y
);

  logic [WIDTH:0] diff;

  always_comb begin
    if (a >= b) begin
      diff = a - b;
      y    = diff[WIDTH-1:0];
    end else begin
      // wrap: add MOD before subtracting to stay non-negative
      diff = a + MOD - b;
      y    = diff[WIDTH-1:0];
    end
  end

endmodule
