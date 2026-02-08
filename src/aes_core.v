module aes_core (
    input          clk,
    input          rst,
    input          start,          // Signal to begin encryption
    input  [127:0] plain_text,     // The data to encrypt
    input  [255:0] key,            // The 256-bit Secret Key
    output reg [127:0] cipher_text,// The encrypted result
    output reg     done            // Signal that we are finished
);

    // ============================================================
    // 1. KEY EXPANSION INSTANCE
    // ============================================================
    // We generate all 15 Round Keys (Round 0 to Round 14) at once.
    wire [1919:0] key_schedule; // 15 * 128 bits = 1920 bits

    aes_key_expand u_key_exp (
        .master_key   (key),
        .key_schedule (key_schedule)
    );

    // ============================================================
    // 2. INTERNAL SIGNALS
    // ============================================================
    reg [127:0] state;          // Holds the data as it changes
    reg [3:0]   round_counter;  // Counts from 0 to 14
    
    // Helper to pick the correct key for the current round
    
    
    // Wire to hold the output of the "Main Round" module
    wire [127:0] round_out;

    // ============================================================
    // 3. MAIN ROUND INSTANCE (Rounds 1 to 13)
    // ============================================================
    // We reuse this ONE hardware block 13 times to save space.
    aes_round u_main_round (
        .state_in (state),
        .key_in   (current_round_key),
        .state_out(round_out)
    );

    // ============================================================
    // 4. LAST ROUND LOGIC (Round 14)
    // ============================================================
    // The last round skips MixColumns, so we can't use 'aes_round'.
    // We manually build the SubBytes -> ShiftRows -> AddKey logic here.
    
    wire [127:0] last_sub_out;
    wire [127:0] last_shift_out;
    wire [127:0] last_round_out;

    // 4a. SubBytes (Manually instantiate 16 S-Boxes for the last step)
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : last_sbox_loop
            aes_sbox u_last_sbox (
                .in_byte (state[8*i + 7 : 8*i]), 
                .c       (last_sub_out[8*i + 7 : 8*i]) // Using '.c' as you requested
            );
        end
    endgenerate

    // 4b. ShiftRows (Standard Wiring)
    assign last_shift_out[127:0] = {
        last_sub_out[127:120], last_sub_out[87:80], last_sub_out[47:40], last_sub_out[7:0],
        last_sub_out[95:88],   last_sub_out[55:48], last_sub_out[15:8],  last_sub_out[103:96],
        last_sub_out[63:56],   last_sub_out[23:16], last_sub_out[111:104], last_sub_out[71:64],
        last_sub_out[31:24],   last_sub_out[119:112], last_sub_out[79:72], last_sub_out[39:32]
    };

    // 4c. AddRoundKey (XOR with the 14th Key)
    assign last_round_out = last_shift_out ^ current_round_key;
    // Combinational logic: Update key INSTANTLY when round_counter changes
    wire [127:0] current_round_key;
    assign current_round_key = key_schedule[round_counter * 128 +: 128];

    // ============================================================
    // 5. THE STATE MACHINE (The Chef)
    // ============================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 0;
            round_counter <= 0;
            done <= 0;
            cipher_text <= 0;
        end 
        else begin
            // LOGIC TO SELECT THE CORRECT KEY
            // Key Schedule is one giant wire. We slice out 128 bits based on the counter.
            // Formula: [ (counter * 128) + 127 : (counter * 128) ]
            // Note: In Verilog, we use the "indexed part-select" syntax +:
            

            if (start) begin
                // ROUND 0: Initial Key Whitening (Input XOR Key[0])
                // We do this immediately when 'start' is pressed.
                state <= plain_text ^ key_schedule[0 +: 128];
                round_counter <= 1; // Prepare for Round 1 next clock
                done <= 0;
            end 
            else if (round_counter >= 1 && round_counter <= 13) begin
                // ROUNDS 1-13: Use the 'aes_round' module
                state <= round_out;
                round_counter <= round_counter + 1;
            end 
            else if (round_counter == 14) begin
                // ROUND 14: Use the special 'Last Round' logic
                state <= last_round_out;
                cipher_text <= last_round_out; // Capture final result
                done <= 1;        // Tell the user we are done
                round_counter <= 0; // Reset
            end
        end
    end

endmodule