`timescale 1ns / 1ps

module tb_montgomery_mult;

    localparam int Q         = 3329;
    localparam int WIDTH     = 12;
    localparam int NUM_TESTS = 1000;

    reg         clk;
    reg         rst;
    reg         valid_in;
    reg [11:0]  a;
    reg [11:0]  b;
    wire        valid_out;
    wire [11:0] out;

    integer errors;
    integer test_count;
    integer expected;

    int expected_queue[$];

    // DUT
    montgomery_mult uut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .a(a),
        .b(b),
        .valid_out(valid_out),
        .out(out)
    );

    // clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Extended Euclidean algorithm for modular inverse
    function automatic integer modinv(input integer x, input integer m);
        integer t, newt;
        integer r, newr;
        integer q, temp;
        begin
            t    = 0;
            newt = 1;
            r    = m;
            newr = x;

            while (newr != 0) begin
                q = r / newr;

                temp = newt;
                newt = t - q * newt;
                t = temp;

                temp = newr;
                newr = r - q * newr;
                r = temp;
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

    // Software reference:
    // Montgomery result = a*b*R^-1 mod Q, where R = 2^12 = 4096
    function automatic integer ref_mont(input integer aa, input integer bb);
        integer R;
        integer R_mod_q;
        integer Rinv;
        integer temp;
        begin
            R       = 1 << WIDTH;
            R_mod_q = R % Q;
            Rinv    = modinv(R_mod_q, Q);

            if (Rinv < 0) begin
                $display("FAIL: could not compute R inverse.");
                $fatal;
            end

            temp = (aa * bb) % Q;
            temp = (temp * Rinv) % Q;
            ref_mont = temp;
        end
    endfunction

    task automatic send_input(input [11:0] aa, input [11:0] bb);
        begin
            @(posedge clk);
            valid_in <= 1'b1;
            a        <= aa;
            b        <= bb;
            expected_queue.push_back(ref_mont(aa, bb));
        end
    endtask

    initial begin
        integer i;
        reg [11:0] rand_a;
        reg [11:0] rand_b;

        errors     = 0;
        test_count = 0;
        rst        = 1'b1;
        valid_in   = 1'b0;
        a          = 12'd0;
        b          = 12'd0;

        $display("========================================");
        $display("Single-Lane Montgomery Multiplier Testbench");
        $display("Q = %0d", Q);
        $display("========================================");

        repeat (3) @(posedge clk);
        rst <= 1'b0;

        // edge cases
        send_input(12'd0, 12'd0);
        send_input(12'd0, 12'd1);
        send_input(12'd1, 12'd0);
        send_input(12'd1, 12'd1);
        send_input(Q-1, 12'd1);
        send_input(12'd1, Q-1);
        send_input(Q-1, Q-1);
        send_input(Q/2, Q/2);
        send_input(Q/2, Q-1);
        send_input(Q-1, Q/2);

        // random tests
        for (i = 0; i < NUM_TESTS; i = i + 1) begin
            rand_a = $urandom_range(0, Q-1);
            rand_b = $urandom_range(0, Q-1);
            send_input(rand_a, rand_b);
        end

        @(posedge clk);
        valid_in <= 1'b0;
        a        <= 12'd0;
        b        <= 12'd0;

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
                $display("FAIL: Montgomery mismatch. got=%0d expected=%0d time=%0t",
                         out, expected, $time);
                errors = errors + 1;
                $fatal;
            end else begin
                $display("PASS: out=%0d expected=%0d", out, expected);
            end
        end
    end

    initial begin
        $dumpfile("tb_montgomery_mult.vcd");
        $dumpvars(0, tb_montgomery_mult);
    end

endmodule
