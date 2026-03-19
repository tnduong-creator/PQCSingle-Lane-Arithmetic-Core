`timescale 1ns/1ps

module tb_barrett_reducer;

  localparam int unsigned Q          = 3329;
  localparam int unsigned IN_WIDTH   = 24;
  localparam int unsigned OUT_WIDTH  = 12;
  localparam int unsigned LATENCY    = 5;
  localparam int unsigned NUM_TESTS  = 1000;

  logic                   clk;
  logic                   rst;
  logic                   valid_in;
  logic [IN_WIDTH-1:0]    in_val;
  logic                   valid_out;
  logic [OUT_WIDTH-1:0]   out_val;

  // DUT
 barrett_reducer dut (
    .clk      (clk),
    .rst      (rst),
    .valid_in (valid_in),
    .in_val   (in_val),
    .valid_out(valid_out),
    .out_val  (out_val)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;

  // Queue for expected outputs
  int unsigned expected_queue[$];

  // Software reference
  function automatic int unsigned ref_barrett(input int unsigned x);
    begin
      ref_barrett = x % Q;
    end
  endfunction

  task automatic send_input(input int unsigned x);
    begin
      @(posedge clk);
      valid_in <= 1'b1;
      in_val   <= x[IN_WIDTH-1:0];
      expected_queue.push_back(ref_barrett(x));
    end
  endtask

  initial begin
    int unsigned rand_val;
    int unsigned expected;
    int i;

    rst      = 1'b1;
    valid_in = 1'b0;
    in_val   = '0;

    repeat (3) @(posedge clk);
    rst = 1'b0;

    // -------------------------
    // Edge cases
    // -------------------------
    send_input(0);
    send_input(1);
    send_input(Q-1);
    send_input(Q);
    send_input(Q+1);
    send_input(2*Q-1);
    send_input(2*Q);
    send_input(2*Q+1);
    send_input(24'd1000000);
    send_input(24'hFFFFFF);

    // -------------------------
    // Random cases
    // -------------------------
    for (i = 0; i < NUM_TESTS; i++) begin
      rand_val = $urandom;
      rand_val = rand_val & 24'hFFFFFF;
      send_input(rand_val);
    end

    // Stop sending
    @(posedge clk);
    valid_in <= 1'b0;
    in_val   <= '0;

    // Wait until all expected outputs are checked
    wait(expected_queue.size() == 0);

    $display("PASS: Barrett reducer passed all tests.");
    $finish;
  end

  // Output checker
  always @(posedge clk) begin
    if (!rst && valid_out) begin
      if (expected_queue.size() == 0) begin
        $display("ERROR: valid_out asserted with no expected value queued.");
        $fatal;
      end

      expected = expected_queue.pop_front();

      if (out_val !== expected[OUT_WIDTH-1:0]) begin
        $display("ERROR: Barrett mismatch. in expected=%0d, got=%0d, time=%0t",
                 expected, out_val, $time);
        $fatal;
      end
    end
  end

endmodule
