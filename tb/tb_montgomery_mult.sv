`timescale 1ns/1ps

module tb_montgomery_mult;

  localparam int unsigned Q          = 3329;
  localparam int unsigned WIDTH      = 12;
  localparam int unsigned LATENCY    = 5;
  localparam int unsigned NUM_TESTS  = 1000;

  logic                 clk;
  logic                 rst;
  logic                 valid_in;
  logic [WIDTH-1:0]     a;
  logic [WIDTH-1:0]     b;
  logic                 valid_out;
  logic [WIDTH-1:0]     result;

  // DUT
  montgomery_mult dut (
    .clk      (clk),
    .rst      (rst),
    .valid_in (valid_in),
    .a        (a),
    .b        (b),
    .valid_out(valid_out),
    .result   (result)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;

  // Queue for expected outputs
  int unsigned expected_queue[$];

  // Modular inverse helper for software reference
  function automatic int signed modinv(input int signed x, input int signed m);
    int signed t, newt;
    int signed r, newr;
    int signed q, temp;
    begin
      t    = 0;
      newt = 1;
      r    = m;
      newr = x;

      while (newr != 0) begin
        q    = r / newr;

        temp = newt;
        newt = t - q * newt;
        t    = temp;

        temp = newr;
        newr = r - q * newr;
        r    = temp;
      end

      if (r > 1)
        modinv = -1;
      else begin
        if (t < 0)
          t = t + m;
        modinv = t;
      end
    end
  endfunction

  // Montgomery software golden model:
  // result = a*b*R^-1 mod Q, where R = 2^WIDTH
  function automatic int unsigned ref_montgomery(
    input int unsigned aa,
    input int unsigned bb
  );
    int unsigned R;
    int signed   Rinv;
    int unsigned temp;
    begin
      R    = (1 << WIDTH);
      Rinv = modinv(R % Q, Q);

      if (Rinv < 0) begin
        $display("ERROR: Could not compute modular inverse for Montgomery reference.");
        $fatal;
      end

      temp = (aa * bb) % Q;
      temp = (temp * Rinv) % Q;
      ref_montgomery = temp;
    end
  endfunction

  task automatic send_input(input int unsigned aa, input int unsigned bb);
    begin
      @(posedge clk);
      valid_in <= 1'b1;
      a        <= aa[WIDTH-1:0];
      b        <= bb[WIDTH-1:0];
      expected_queue.push_back(ref_montgomery(aa, bb));
    end
  endtask

  initial begin
    int unsigned ra, rb;
    int unsigned expected;
    int i;

    rst      = 1'b1;
    valid_in = 1'b0;
    a        = '0;
    b        = '0;

    repeat (3) @(posedge clk);
    rst = 1'b0;

    // -------------------------
    // Edge cases
    // -------------------------
    send_input(0, 0);
    send_input(0, 1);
    send_input(1, 0);
    send_input(1, 1);
    send_input(Q-1, 1);
    send_input(1, Q-1);
    send_input(Q-1, Q-1);
    send_input(Q/2, Q/2);
    send_input(Q/2, Q-1);
    send_input(Q-1, Q/2);

    // -------------------------
    // Random cases
    // -------------------------
    for (i = 0; i < NUM_TESTS; i++) begin
      ra = $urandom_range(0, Q-1);
      rb = $urandom_range(0, Q-1);
      send_input(ra, rb);
    end

    // Stop sending
    @(posedge clk);
    valid_in <= 1'b0;
    a        <= '0;
    b        <= '0;

    // Wait until all expected outputs are checked
    wait(expected_queue.size() == 0);

    $display("PASS: Montgomery multiplier passed all tests.");
    $finish;
  end

  // Output checker
  always @(posedge clk) begin
    int unsigned expected;
    if (!rst && valid_out) begin
      if (expected_queue.size() == 0) begin
        $display("ERROR: valid_out asserted with no expected value queued.");
        $fatal;
      end

      expected = expected_queue.pop_front();

      if (result !== expected[WIDTH-1:0]) begin
        $display("ERROR: Montgomery mismatch. expected=%0d, got=%0d, time=%0t",
                 expected, result, $time);
        $fatal;
      end
    end
  end

endmodule
