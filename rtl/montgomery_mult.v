module montgomery_mult #(
    parameter integer Q      = 3329,
    parameter integer WIDTH  = 12,
    parameter integer R_MASK = 12'hFFF,
    parameter integer QINV   = 3327
)(
    input  wire                 clk,
    input  wire                 rst,
    input  wire                 valid_in,
    input  wire [WIDTH-1:0]     a,
    input  wire [WIDTH-1:0]     b,
    output reg                  valid_out,
    output reg  [WIDTH-1:0]     result
);

    // Stage 1: register inputs
    reg             v1;
    reg [WIDTH-1:0] a1, b1;

    // Stage 2: t = a*b
    reg             v2;
    reg [2*WIDTH-1:0] t2;

    // Stage 3: m = (t * QINV) mod R
    reg             v3;
    reg [2*WIDTH-1:0] t3;
    reg [WIDTH-1:0] m3;

    // Stage 4: u = (t + m*Q) >> WIDTH
    reg             v4;
    reg [2*WIDTH:0] u4;

    // Stage 5: final conditional subtraction
    reg             v5;
    reg [WIDTH-1:0] r5;

    always @(posedge clk) begin
        if (rst) begin
            v1       <= 1'b0;
            v2       <= 1'b0;
            v3       <= 1'b0;
            v4       <= 1'b0;
            v5       <= 1'b0;
            valid_out <= 1'b0;
            result    <= {WIDTH{1'b0}};
            a1        <= {WIDTH{1'b0}};
            b1        <= {WIDTH{1'b0}};
            t2        <= {(2*WIDTH){1'b0}};
            t3        <= {(2*WIDTH){1'b0}};
            m3        <= {WIDTH{1'b0}};
            u4        <= {(2*WIDTH+1){1'b0}};
            r5        <= {WIDTH{1'b0}};
        end else begin
            // Stage 1
            v1 <= valid_in;
            a1 <= a;
            b1 <= b;

            // Stage 2
            v2 <= v1;
            t2 <= a1 * b1;

            // Stage 3
            v3 <= v2;
            t3 <= t2;
            m3 <= (t2 * QINV) & R_MASK[WIDTH-1:0];

            // Stage 4
            v4 <= v3;
            u4 <= (t3 + (m3 * Q)) >> WIDTH;

            // Stage 5
            v5 <= v4;
            if (u4 >= Q)
                r5 <= u4 - Q;
            else
                r5 <= u4[WIDTH-1:0];

            valid_out <= v5;
            result    <= r5;
        end
    end

endmodule
