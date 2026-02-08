# AES-256 Hardware Accelerator (Verilog)

![License](https://img.shields.io/badge/license-MIT-blue.svg) ![Verilog](https://img.shields.io/badge/language-Verilog%20%7C%20SystemVerilog-green.svg)

## 📌 Overview
This repository contains a fully synthesized **AES-256 Encryption Core** designed in Verilog HDL. 
The core is designed for high-performance embedded systems (like FPGA-based Li-Fi communication), offering a hardware-accelerated alternative to slow software encryption.

It implements the NIST FIPS-197 Advanced Encryption Standard (AES) with a 256-bit key, executing all 14 rounds of encryption in just **14 clock cycles**.

## 🚀 Features
- **Algorithm:** AES-256 (Rijndael).
- **Architecture:** 128-bit Pipelined Data Path.
- **Latency:** 14 Clock Cycles (Deterministic).
- **Throughput:** ~450 Mbps @ 50MHz Clock.
- **Verification:** Self-checking SystemVerilog testbench matching NIST Golden Vectors.

## 📂 Directory Structure
```text
├── src/          # RTL Source Code (Verilog)
│   ├── aes_core.v        # Top-level Module
│   ├── aes_round.v       # Single Round Logic
│   ├── aes_key_expand.v  # Key Expansion Schedule
│   ├── aes_mixcolumns.v  # MixColumns Transformation
│   └── aes_sbox.v        # Substitution Box (S-Box)
├── tb/           # Verification Environment
│   └── aes_tb.sv         # SystemVerilog Testbench with Performance Reporting