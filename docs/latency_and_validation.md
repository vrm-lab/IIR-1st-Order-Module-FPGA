# Validation Notes

## RTL Simulation

- DSP core verified using:
  - Step response
  - Low-frequency sine wave
- AXI wrapper verified using:
  - AXI-Lite register writes
  - AXI-Stream backpressure
  - Stereo interleaved data

## Hardware Validation

- Bare-metal test application performs:
  - Stereo impulse input
  - DMA loopback through IIR filter
  - Console output of first samples

Simulation results are considered the primary reference.
Hardware execution serves as integration proof.
