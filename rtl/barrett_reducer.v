`timescale 1ns / 1ps

module barrett_reducer (
    input  wire        clk,
    input  wire        rst,
    input  wire        valid_in,

    input  wire [23:0] in,      // input value
    output reg         valid_out,
    output reg  [11:0] out      // reduced output = in mod 3329
);

    // q = 3329
    localparam [11:0] Q  = 12'd3329;

    // Barrett parameters:
    // k = 24
    // mu = floor(2^24 / 3329) = 5039
    localparam [4:0]  K  = 5'd24;
    localparam [15:0] MU = 16'd5039;

    // -------------------------
    // Pipeline stage 1: register input
    // -------------------------
    reg        v1;
    reg [23:0] in_1;

    // -------------------------
    // Pipeline stage 2: t1 = in * MU
    // -------------------------
    reg        v2;
    reg [23:0] in_2;
    reg [39:0] t1_2;

    // -------------------------
    // Pipeline stage 3: t2 = t1 >> K
    // -------------------------
    reg        v3;
    reg [23:0] in_3;
    reg [23:0] t2_3;

    // -------------------------
    // Pipeline stage 4: t3 = t2 * Q, r = in - t3
    // -------------------------
    reg        v4;
    reg signed [40:0] r_4;

    // -------------------------
    // Pipeline stage 5: correction
    // -------------------------
    reg        v5;
    reg [11:0] out_5;

    reg signed [40:0] temp_r;

    always @(posedge clk) begin
        if (rst) begin
            v1        <= 1'b0;
            v2        <= 1'b0;
            v3        <= 1'b0;
            v4        <= 1'b0;
            v5        <= 1'b0;
            valid_out <= 1'b0;
            out       <= 12'd0;

            in_1      <= 24'd0;
            in_2      <= 24'd0;
            in_3      <= 24'd0;
            t1_2      <= 40'd0;
            t2_3      <= 24'd0;
            r_4       <= 41'd0;
            out_5     <= 12'd0;
        end else begin
            // Stage 1
            v1   <= valid_in;
            in_1 <= in;

            // Stage 2
            v2   <= v1;
            in_2 <= in_1;

            // t1 = in * 5039
            t1_2 <= ({4'd0,  in_1, 12'd0}) +   // in << 12
                    ({7'd0,  in_1,  9'd0}) +   // in << 9
                    ({8'd0,  in_1,  8'd0}) +   // in << 8
                    ({9'd0,  in_1,  7'd0}) +   // in << 7
                    ({11'd0, in_1,  5'd0}) +   // in << 5
                    ({13'd0, in_1,  3'd0}) +   // in << 3
                    ({14'd0, in_1,  2'd0}) +   // in << 2
                    ({15'd0, in_1,  1'd0}) +   // in << 1
                    ({16'd0, in_1});           // in

            // Stage 3
            v3   <= v2;
            in_3 <= in_2;

            // t2 = t1 >> 24
            t2_3 <= t1_2 >> K;

            // Stage 4
            v4 <= v3;

            // t3 = t2 * Q = t2 * 3329 = (t2<<11) + (t2<<10) + (t2<<8) + t2
            r_4 <= $signed({1'b0, in_3}) -
                   $signed((({t2_3, 11'd0}) + ({t2_3, 10'd0}) + ({t2_3, 8'd0}) + t2_3));

            // Stage 5
            v5 <= v4;
            temp_r = r_4;

            // bring up if negative
            if (temp_r < 0)
                temp_r = temp_r + Q;

            // subtract Q until result is in [0, Q-1]
            if (temp_r >= Q)
                temp_r = temp_r - Q;
            if (temp_r >= Q)
                temp_r = temp_r - Q;
            if (temp_r >= Q)
                temp_r = temp_r - Q;

            out_5 <= temp_r[11:0];

            // output stage
            valid_out <= v5;
            out       <= out_5;
        end
    end

endmodule
