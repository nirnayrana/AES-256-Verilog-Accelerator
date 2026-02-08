`timescale 1ns / 1ps

module aes_tb_sv;

    // =========================================================================
    // 1. SIGNALS & CONSTANTS
    // =========================================================================
    // SystemVerilog uses 'logic' for both drivers and wires (easier than reg/wire)
    logic clk;
    logic rst;
    logic start;
    logic [127:0] plain_text;
    logic [255:0] key;
    logic [127:0] cipher_text;
    logic done;

    // Benchmarking Variables
    integer start_time;
    integer end_time;
    integer cycle_count;
    real throughput_mbps;
    
    // Simulation Constants
    localparam CLK_PERIOD = 20; // 20ns = 50 MHz Clock (Standard for DE10-Lite)
    localparam FREQ_MHZ   = 50.0;

    // =========================================================================
    // 2. INSTANTIATE THE DUT (Device Under Test)
    // =========================================================================
    aes_core dut (
        .clk(clk), 
        .rst(rst), 
        .start(start), 
        .plain_text(plain_text), 
        .key(key), 
        .cipher_text(cipher_text), 
        .done(done)
    );

    // =========================================================================
    // 3. CLOCK GENERATION
    // =========================================================================
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // =========================================================================
    // 4. MAIN TEST PROCESS
    // =========================================================================
    initial begin
        // Setup Waveform Dump for GTKWave
        $dumpfile("aes_waves.vcd");
        $dumpvars(0, aes_tb_sv);

        // Initialize
        init_signals();
        reset_dut();

        // -------------------------------------------------------
        // TEST CASE 1: NIST FIPS-197 APPENDIX C (Golden Vector)
        // -------------------------------------------------------
        print_header("TEST CASE 1: NIST FIPS-197 Standard Vector");
        
        // Define Inputs
        key        = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
        plain_text = 128'h00112233445566778899aabbccddeeff;
        
        // Run the Encryption Task
        run_encryption(key, plain_text);

        // Verify Results
        check_result(128'h8ea2b7ca516745bfeaFC49904b496089);

        // -------------------------------------------------------
        // PERFORMANCE REPORT
        // -------------------------------------------------------
        print_performance_report();

        $display("\n[INFO] Simulation Finished Successfully.");
        $finish;
    end

    // =========================================================================
    // 5. TASKS (Helper Functions)
    // =========================================================================
    
    // Task: Initialize Signals
    task init_signals();
        rst = 1;
        start = 0;
        plain_text = 0;
        key = 0;
    endtask

    // Task: Reset the Core
    task reset_dut();
        $display("[INFO] Applying Reset...");
        rst = 1;
        repeat (5) @(posedge clk); // Hold reset for 5 clocks
        rst = 0;
        @(posedge clk);
        $display("[INFO] Reset Complete.");
    endtask

    // Task: Run Encryption Transaction
    task run_encryption(input [255:0] k, input [127:0] pt);
        $display("[INFO] Starting Encryption...");
        $display("       Key:        %h", k);
        $display("       Plaintext:  %h", pt);
        
        // Capture start time
        start_time = $time;
        cycle_count = 0;

        // Drive Inputs
        @(posedge clk);
        start = 1;
        key = k;
        plain_text = pt;
        
        @(posedge clk);
        start = 0;

        // Wait for Done Signal and count cycles
        while (!done) begin
            @(posedge clk);
            cycle_count++;
        end
        
        end_time = $time;
    endtask

    // Task: Check Result against Expected Golden Value
    task check_result(input [127:0] expected);
        $display("       Ciphertext: %h", cipher_text);
        if (cipher_text === expected) begin
            $display("\n\033[1;32m[PASS] RESULT MATCHES EXPECTED VALUE \033[0m"); // Green Text
        end else begin
            $display("\n\033[1;31m[FAIL] MISMATCH! \033[0m"); // Red Text
            $display("       Expected:   %h", expected);
            $display("       Actual:     %h", cipher_text);
            $stop; // Stop simulation on error
        end
    endtask

    // Task: Print a nice Header
    task print_header(string title);
        $display("\n============================================================");
        $display("%s", title);
        $display("============================================================");
    endtask

    // Task: Calculate and Print Performance
    task print_performance_report();
        // Calculations
        // Latency = Cycles taken
        // Throughput = (Bits Processed / Time in Seconds)
        // At 50MHz, 1 cycle = 20ns.
        real total_time_ns;
        total_time_ns = cycle_count * 20.0; // 20ns period
        
        // Throughput (Mbps) = 128 bits / (Cycles * Period_in_Seconds)
        // = 128 / (Cycles * 20e-9)
        // = (128 / Cycles) * 50 MHz
        throughput_mbps = (128.0 / cycle_count) * FREQ_MHZ; 

        $display("\n============================================================");
        $display("                PERFORMANCE ANALYSIS REPORT                 ");
        $display("============================================================");
        $display("| Metric                | Value                            |");
        $display("|-----------------------|----------------------------------|");
        $display("| Clock Frequency       | %0.2f MHz                        |", FREQ_MHZ);
        $display("| Data Block Size       | 128 Bits                         |");
        $display("| Key Size              | 256 Bits                         |");
        $display("| Latency (Cycles)      | %0d Cycles                        |", cycle_count);
        $display("| Latency (Time)        | %0.2f ns (@ 50MHz)              |", total_time_ns);
        $display("|-----------------------|----------------------------------|");
        $display("| THROUGHPUT            | \033[1;33m%0.2f Mbps\033[0m                       |", throughput_mbps);
        $display("============================================================");
        $display("Note: Throughput > 100 Mbps is sufficient for 4K Video.");
    endtask

endmodule