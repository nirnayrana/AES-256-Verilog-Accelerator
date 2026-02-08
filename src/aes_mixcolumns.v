module aes_mixcolumns (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);

    // --------------------------------------------------------
    // Helper Function: Galois Field Multiply by 2 (xtime)
    // Formula: (x << 1) ^ (if MSB is 1, then 0x1B, else 0)
    // --------------------------------------------------------
    function [7:0] gm2;
        input [7:0] x;
        begin
            gm2 = {x[6:0], 1'b0} ^ (x[7] ? 8'h1b : 8'h00);
        end
    endfunction

    // --------------------------------------------------------
    // Helper Function: Galois Field Multiply by 3
    // Formula: gm2(x) XOR x
    // --------------------------------------------------------
    function [7:0] gm3;
        input [7:0] x;
        begin
            gm3 = gm2(x) ^ x;
        end
    endfunction

    // --------------------------------------------------------
    // The Mixing Logic
    // We process the 128-bit state as 4 separate Columns.
    // Each column is 32 bits (4 bytes).
    // --------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : col_loop
            
            // Extract the 4 bytes of the current column
            wire [7:0] s0 = state_in[32*i + 31 : 32*i + 24]; // Top byte
            wire [7:0] s1 = state_in[32*i + 23 : 32*i + 16];
            wire [7:0] s2 = state_in[32*i + 15 : 32*i + 8];
            wire [7:0] s3 = state_in[32*i + 7  : 32*i + 0];  // Bottom byte

            // Matrix Multiplication in GF(2^8)
            // Row 0: 2*s0 + 3*s1 + 1*s2 + 1*s3
            assign state_out[32*i + 31 : 32*i + 24] = gm2(s0) ^ gm3(s1) ^ s2      ^ s3;
            
            // Row 1: 1*s0 + 2*s1 + 3*s2 + 1*s3
            assign state_out[32*i + 23 : 32*i + 16] = s0      ^ gm2(s1) ^ gm3(s2) ^ s3;
            
            // Row 2: 1*s0 + 1*s1 + 2*s2 + 3*s3
            assign state_out[32*i + 15 : 32*i + 8]  = s0      ^ s1      ^ gm2(s2) ^ gm3(s3);
            
            // Row 3: 3*s0 + 1*s1 + 1*s2 + 2*s3
            assign state_out[32*i + 7  : 32*i + 0]  = gm3(s0) ^ s1      ^ s2      ^ gm2(s3);
            
        end
    endgenerate

endmodule