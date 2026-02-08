module aes_round (
    input  wire [127:0] state_in,   // The 128-bit data entering this round
    input  wire [127:0] key_in,     // The 128-bit key for this specific round
    output wire [127:0] state_out   // The scrambled data leaving this round
);

    // Intermediate wires
    wire [127:0] sub_out;
    wire [127:0] shift_out;
    wire [127:0] mix_out;

    // ============================================================
    // 1. SubBytes Step
    // ============================================================
    // This replaces every byte using the "aes_sbox" module you just made.
    // We use a "generate" loop to create 16 S-Boxes instantly.
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : sbox_loop
            aes_sbox u_sbox (
                .in_byte (state_in[8*i + 7 : 8*i]), 
                .c(sub_out[8*i + 7 : 8*i])
            );
        end
    endgenerate

    // ============================================================
    // 2. ShiftRows Step
    // ============================================================
    // We physically rearrange the wires. No logic gates needed!
    // Row 0 (Bytes 0, 4, 8, 12) - No Shift
    // Row 1 (Bytes 1, 5, 9, 13) - Shift Left by 1
    // Row 2 (Bytes 2, 6, 10, 14) - Shift Left by 2
    // Row 3 (Bytes 3, 7, 11, 15) - Shift Left by 3
    
    // Note: AES uses a column-major order, but for simplicity here 
    // we map the 128-bit linear vector to the standard ShiftRows pattern.
    assign shift_out[127:0] = {
        sub_out[127:120], sub_out[87:80], sub_out[47:40], sub_out[7:0],    // Row 0
        sub_out[95:88],   sub_out[55:48], sub_out[15:8],  sub_out[103:96], // Row 1
        sub_out[63:56],   sub_out[23:16], sub_out[111:104], sub_out[71:64],// Row 2
        sub_out[31:24],   sub_out[119:112], sub_out[79:72], sub_out[39:32] // Row 3
    };

    // ============================================================
    // 3. MixColumns Step
    // ============================================================
    // This is the heavy math part. We need a separate module for this 
    // because it involves matrix multiplication.
    // For now, let's instantiate it (we will build this file next).
    aes_mixcolumns u_mix (
        .state_in (shift_out),
        .state_out(mix_out)
    );

    // ============================================================
    // 4. AddRoundKey Step
    // ============================================================
    // Simple XOR with the Key.
    assign state_out = mix_out ^ key_in;

endmodule