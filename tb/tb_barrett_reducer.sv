`timescale 1ns / 1ps

module tb_barrett_reducer;

    localparam int Q         = 3329;
    localparam int LATENCY   = 5;
    localparam int NUM_TESTS = 1000;

    reg         clk;
    reg         rst;
    reg         valid_in;
    reg [23:0]  in;
    wire        valid_out;
    wire [11:0] out;

    integer errors;
    integer test_count;
    integer expected;

    int expected_queue[$];

    // DUT
    barrett_reducer uut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .in(in),
        .valid_out(valid_out),
        .out(out)
    );

    // clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // software reference
    function automatic int ref_mod(input int x);
        begin
            ref_mod = x % Q;
        end
    endfunction

    task automatic send_input(input [23:0] x);
        begin
            @(posedge clk);
            valid_in <= 1'b1;
            in       <= x;
            expected_queue.push_back(ref_mod(x));
        end
    endtask

    initial begin
        integer i;
        reg [23:0] rand_val;

        errors     = 0;
        test_count = 0;
        rst        = 1'b1;
        valid_in   = 1'b0;
        in         = 24'd0;

        $display("========================================");
        $display("Synchronous Barrett Reducer Testbench");
        $display("Q = %0d", Q);
        $display("========================================");

        repeat (3) @(posedge clk);
        rst <= 1'b0;

        // edge cases
        send_input(24'd0);
        send_input(24'd1);
        send_input(Q-1);
        send_input(Q);
        send_input(Q+1);
        send_input((2*Q)-1);
        send_input(2*Q);
        send_input((2*Q)+1);
        send_input(24'd1000000);
        send_input(24'hFFFFFF);

        // random tests
        for (i = 0; i < NUM_TESTS; i = i + 1) begin
            rand_val = $random & 24'hFFFFFF;
            send_input(rand_val);
        end

        @(posedge clk);
        valid_in <= 1'b0;
        in       <= 24'd0;

        wait(expected_queue.size() == 0);

        $display("========================================");
        $display("Total tests: %0d", test_count);
        $display("Failed: %0d", errors);
        if (errors == 0)
            $display("*** ALL TESTS PASSED ***");
        else
            $display("*** SOME TESTS FAILED ***");
        $display("========================================");

        $finish;
    end

    // checker
    always @(posedge clk) begin
        if (!rst && valid_out) begin
            if (expected_queue.size() == 0) begin
                $display("FAIL: valid_out asserted with no expected result.");
                $fatal;
            end

            expected = expected_queue.pop_front();
            test_count = test_count + 1;

            if (out !== expected[11:0]) begin
                $display("FAIL: in mod Q mismatch. got=%0d expected=%0d time=%0t",
                         out, expected, $time);
                errors = errors + 1;
                $fatal;
            end else begin
                $display("PASS: out=%0d expected=%0d", out, expected);
            end
        end
    end

    initial begin
        $dumpfile("tb_barrett_reducer.vcd");
        $dumpvars(0, tb_barrett_reducer);
    end

endmodule
