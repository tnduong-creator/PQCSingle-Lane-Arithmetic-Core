module barrett_reducer #(
    parameter integer Q         = 3329,
    parameter integer IN_WIDTH  = 24,
    parameter integer OUT_WIDTH = 12,
    parameter integer K         = 24,
    parameter integer MU        = 5039   // floor(2^24 / 3329)
)(
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     valid_in,
    input  wire [IN_WIDTH-1:0]      in_val,
    output reg                      valid_out,
    output reg  [OUT_WIDTH-1:0]     out_val
);

    // -------------------------
    // Stage 1: register input
    // -------------------------
    reg                 v1;
    reg [IN_WIDTH-1:0]  x1;

    // -------------------------
    // Stage 2: x * MU
    // -------------------------
    reg                 v2;
    reg [IN_WIDTH-1:0]  x2;
    reg [IN_WIDTH+15:0] prod_mu2;

    // -------------------------
    // Stage 3: q_hat = (x * MU) >> K
    // -------------------------
    reg                 v3;
    reg [IN_WIDTH-1:0]  x3;
    reg [IN_WIDTH-1:0]  qhat3;

    // -------------------------
    // Stage 4: r = x - q_hat * Q
    // -------------------------
    reg                 v4;
    reg signed [IN_WIDTH+15:0] r4;

    // -------------------------
    // Stage 5: correction into [0, Q-1]
    // -------------------------
    reg                 v5;
    reg [OUT_WIDTH-1:0] r5;

    reg signed [IN_WIDTH+15:0] temp_r;

    always @(posedge clk) begin
        if (rst) begin
            v1       <= 1'b0;
            v2       <= 1'b0;
            v3       <= 1'b0;
            v4       <= 1'b0;
            v5       <= 1'b0;
            valid_out <= 1'b0;
            out_val   <= {OUT_WIDTH{1'b0}};
            x1        <= {IN_WIDTH{1'b0}};
            x2        <= {IN_WIDTH{1'b0}};
            x3        <= {IN_WIDTH{1'b0}};
            prod_mu2  <= {(IN_WIDTH+16){1'b0}};
            qhat3     <= {IN_WIDTH{1'b0}};
            r4        <= {(IN_WIDTH+16){1'b0}};
            r5        <= {OUT_WIDTH{1'b0}};
        end else begin
            // Stage 1
            v1 <= valid_in;
            x1 <= in_val;

            // Stage 2
            v2      <= v1;
            x2      <= x1;
            prod_mu2 <= x1 * MU;

            // Stage 3
            v3    <= v2;
            x3    <= x2;
            qhat3 <= prod_mu2 >> K;

            // Stage 4
            v4 <= v3;
            r4 <= $signed({1'b0, x3}) - $signed(qhat3 * Q);

            // Stage 5
            v5 <= v4;
            temp_r = r4;

            // Bring negative values upward if needed
            if (temp_r < 0)
                temp_r = temp_r + Q;

            // Subtract Q until in range
            if (temp_r >= Q)
                temp_r = temp_r - Q;
            if (temp_r >= Q)
                temp_r = temp_r - Q;
            if (temp_r >= Q)
                temp_r = temp_r - Q;

            r5 <= temp_r[OUT_WIDTH-1:0];

            // Output register
            valid_out <= v5;
            out_val   <= r5;
        end
    end

endmodule
