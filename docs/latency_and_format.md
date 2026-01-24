# Latency and Data Format

## Processing Latency

- Latency: **1 clock cycle**
- Measured from valid AXI-Stream input to valid AXI-Stream output
- Same latency for both Left and Right channels

## Data Format

- Fixed-point: **signed Q1.15**
- AXI-Stream width: 32-bit
  - [31:16] → Left channel
  - [15:0]  → Right channel

## Stereo Behavior

- Left and Right channels are processed synchronously
- No cross-channel interaction
- Shared filter coefficients
