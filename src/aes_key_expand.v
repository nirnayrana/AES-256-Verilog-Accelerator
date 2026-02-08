module aes_key_expand (
    input  wire [255:0] master_key,
    output wire [1919:0] key_schedule // 15 Round Keys * 128 bits = 1920 bits
);

    // AES-256 needs 60 words of 32-bits each (Total 240 bytes)
    wire [31:0] w [0:59]; 
    
    // First 8 words are just the Master Key copy-pasted
    assign w[0] = master_key[255:224];
    assign w[1] = master_key[223:192];
    assign w[2] = master_key[191:160];
    assign w[3] = master_key[159:128];
    assign w[4] = master_key[127:96];
    assign w[5] = master_key[95:64];
    assign w[6] = master_key[63:32];
    assign w[7] = master_key[31:0];

    genvar i;
    generate
        for (i = 8; i < 60; i = i + 1) begin : key_loop
            
            wire [31:0] temp_w;
            wire [31:0] prev_w = w[i-1];
            wire [31:0] old_w  = w[i-8];
            
            // Determine Rcon (Round Constant) manually for safety
            // This replaces the function that was causing errors.
            wire [7:0] rcon_byte;
            assign rcon_byte = (i/8 == 1) ? 8'h01 :
                               (i/8 == 2) ? 8'h02 :
                               (i/8 == 3) ? 8'h04 :
                               (i/8 == 4) ? 8'h08 :
                               (i/8 == 5) ? 8'h10 :
                               (i/8 == 6) ? 8'h20 :
                               (i/8 == 7) ? 8'h40 : 
                               (i/8 == 8) ? 8'h80 : 8'h1B; // 1B is fallback

            // Rules for AES-256 Key Expansion
            if (i % 8 == 0) begin
                // 1. RotWord: [a0, a1, a2, a3] -> [a1, a2, a3, a0]
                wire [31:0] rot_w = {prev_w[23:0], prev_w[31:24]};
                
                // 2. SubWord: Run through S-Box
                // NOTE: We use '.c' here because you renamed it in your S-Box file!
                wire [31:0] sub_w;
                aes_sbox s0(.in_byte(rot_w[31:24]), .c(sub_w[31:24]));
                aes_sbox s1(.in_byte(rot_w[23:16]), .c(sub_w[23:16]));
                aes_sbox s2(.in_byte(rot_w[15:8]),  .c(sub_w[15:8]));
                aes_sbox s3(.in_byte(rot_w[7:0]),   .c(sub_w[7:0]));

                // 3. XOR with Rcon
                assign w[i] = old_w ^ sub_w ^ {rcon_byte, 24'h000000};
            end
            else if (i % 8 == 4) begin
                // Special Rule for 256-bit keys: SubWord ONLY (No Rot, No Rcon)
                wire [31:0] sub_w;
                aes_sbox s4(.in_byte(prev_w[31:24]), .c(sub_w[31:24]));
                aes_sbox s5(.in_byte(prev_w[23:16]), .c(sub_w[23:16]));
                aes_sbox s6(.in_byte(prev_w[15:8]),  .c(sub_w[15:8]));
                aes_sbox s7(.in_byte(prev_w[7:0]),   .c(sub_w[7:0]));
                
                assign w[i] = old_w ^ sub_w;
            end
            else begin
                // Normal case: Just XOR with 8 words ago
                assign w[i] = old_w ^ prev_w;
            end
        end
    endgenerate

    // Output Mapping
    genvar k;
    generate
        for (k = 0; k < 15; k = k + 1) begin : out_map
            assign key_schedule[128*k + 127 : 128*k] = {w[4*k], w[4*k+1], w[4*k+2], w[4*k+3]};
        end
    endgenerate

endmodule