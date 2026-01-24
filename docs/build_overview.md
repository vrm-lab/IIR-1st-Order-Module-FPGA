# Build Overview

This document describes the high-level build flow for the reference design.

## Vivado

1. Add RTL sources (IIR core and AXI wrapper)
2. Package as custom AXI IP
3. Create block design:
   - Zynq MPSoC (KV260)
   - AXI DMA (MM2S + S2MM)
   - Stereo IIR AXI IP
4. Assign AXI-Lite base addresses
5. Generate bitstream
6. Export hardware (XSA, include bitstream)

## Vitis (Bare-Metal)

1. Create platform project from XSA
2. Create bare-metal application
3. Initialize AXI DMA in polling mode
4. Configure IIR coefficients via AXI-Lite
5. Transfer stereo buffers using AXI DMA
6. Read back and verify output samples
