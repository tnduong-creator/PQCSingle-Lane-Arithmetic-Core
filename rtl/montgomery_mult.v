`timescale 1ns / 1ps

module montgomery_mult (
    input  wire        clk,
    input  wire        rst,
    input  wire        valid_in,

    input  wire [11:0] a,       // input operand a
    input  wire [11:0] b,       // input operand b

    output reg         valid_out,
    output reg  [11:0] out      // output = a*b*R^-1 mod 3329
);

    // Modulus
    localparam [11:0] Q = 12'd3329;

    // For WIDTH = 12:
    // R    = 2^12 = 4096
    // QINV = -Q^-1 mod R = 3327
    localparam [11:0] QINV = 12'd3327;

    // -------------------------
    // Stage 1: register inputs
    // -------------------------
    reg        v1;
    reg [11:0] a_1;
    reg [11:0] b_1;

    // -------------------------
    // Stage 2: t = a * b
    // -------------------------
    reg        v2;
    reg [23:0] t_2;

    // -------------------------
    // Stage 3: m = (t * QINV) mod R
    // Since R = 2^12, mod R = keep low 12 bits
    // -------------------------
    reg        v3;
    reg [23:0] t_3;
    reg [11:0] m_3;

    // -------------------------
    // Stage 4: u = (t + m*Q) >> 12
    // -------------------------
    reg        v4;
    reg [24:0] u_4;

    // -------------------------
    // Stage 5: correction
    // -------------------------
    reg        v5;
    reg [11:0] out_5;

    always @(posedge clk) begin
        if (rst) begin
            v1        <= 1'b0;
            v2        <= 1'b0;
            v3        <= 1'b0;
            v4        <= 1'b0;
            v5        <= 1'b0;
            valid_out <= 1'b0;
            out       <= 12'd0;

            a_1       <= 12'd0;
            b_1       <= 12'd0;
            t_2       <= 24'd0;
            t_3       <= 24'd0;
            m_3       <= 12'd0;
            u_4       <= 25'd0;
            out_5     <= 12'd0;
        end else begin
            // Stage 1
            v1  <= valid_in;
            a_1 <= a;
            b_1 <= b;

            // Stage 2
            v2  <= v1;
            t_2 <= a_1 * b_1;

            // Stage 3
            v3  <= v2;
            t_3 <= t_2;
            m_3 <= (t_2 * QINV) [11:0];

            // Stage 4
            v4  <= v3;
            u_4 <= (t_3 + (m_3 * Q)) >> 12;

            // Stage 5
            v5 <= v4;
            if (u_4 >= Q)
                out_5 <= u_4 - Q;
            else
                out_5 <= u_4[11:0];

            // Output stage
            valid_out <= v5;
            out       <= out_5;
        end
    end

endmodule
