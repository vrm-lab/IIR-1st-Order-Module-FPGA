# AXI-Lite Address Map

Base address is assigned in Vivado Address Editor.

## Register Layout

| Offset | Name | Description |
|------:|------|-------------|
| 0x00 | CTRL | bit0: enable, bit1: clear_state |
| 0x04 | A0 | Feedforward coefficient (Q1.15) |
| 0x08 | A1 | Feedforward coefficient (Q1.15) |
| 0x0C | B1 | Feedback coefficient (Q1.15) |

## Notes

- All coefficients are **signed 16-bit Q1.15**
- Upper 16 bits of AXI-Lite writes are ignored
- Only a single outstanding AXI-Lite transaction is supported
