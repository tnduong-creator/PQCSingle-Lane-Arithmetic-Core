// mod_add.sv
// Combinational modular addition: (a + b) mod MOD
module mod_add #(
  parameter int unsigned MOD   = 3329,
  parameter int unsigned WIDTH = $clog2(MOD)  // enough bits for 0..MOD-1
)(
  input  logic [WIDTH-1:0] a,
  input  logic [WIDTH-1:0] b,
  output logic [WIDTH-1:0] y
);

  logic [WIDTH:0] sum;  // one extra bit for carry

  always_comb begin
    sum = a + b;
    if (sum >= MOD)
      y = sum - MOD;
    else
      y = sum[WIDTH-1:0];
  end

endmodule
