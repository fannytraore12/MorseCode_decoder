# Morse Code Decoder: PYNQ-Z2 (Zynq-7020)

A Morse code decoder built in FPGA logic. You tap a push-button, the design times each press, classifies it as a dot or dash, groups the elements into characters by gap timing, and outputs the decoded letter.

## Architecture

| Module | Role |
|---|---|
| `tick_gen.v` | Divides the 125 MHz `sysclk` into a one-cycle 1 ms tick (17-bit counter). |
| `synchronizer.v` | Two-flop metastability chain, then a 10 ms debounce. Outputs a clean level (`btn_sync`) and edge strobes. |
| `morse_fsm.v` | Four states: `IDLE` → `PRESS_ACTIVE` → `RELEASE_EVAL` → `GAP_WAIT`. Presses under 30 ms are ignored, under 175 ms count as a dot, and 175 ms or longer count as a dash. 400 ms of silence commits the character. |
| `morse_decoder.v` | Maps `{count, bits}` to ASCII for A–Z and 0–9. Anything else becomes `?`. |
| `uart_tx.v` | Sends each decoded character out on `ja[0]` at 115200 baud, 8N1. |
| `pulse_stretch.v` | Stretches single-cycle strobes long enough to see on the LEDs. |
| `morse_top.v` | Board top level. |

## Board I/O

| Pin | Function |
|---|---|
| BTN0 | Morse key |
| BTN1 | Reset |
| LD0 | Key held (after debounce) |
| LD1 / LD2 | Flashes when a dot / dash is accepted |
| LD3 | Flashes when a character is committed |
| LD5 (RGB) | FSM state: red = `PRESS_ACTIVE`, blue = `GAP_WAIT`, green flash = element accepted, off = `IDLE` |
| JA pin 1 (`ja[0]`) | UART TX. Wire it to the RX pin of a 3.3 V USB-serial adapter and connect GND to GND. Open a terminal at 115200 8N1. |

The on-board USB-UART is connected to the Zynq PS, not the programmable logic, so the fabric can't use it. That's why the output goes through a PMOD pin.

## Simulation

`sim/tb_morse_top.v` is a self-checking testbench. It keys every letter and digit with random human-like timing and contact bounce, then tests these edge cases:
- dot/dash lengths at the edges of their windows
- a 1.5 s hold
- a noise tap
- a 6-element invalid symbol

It decodes the UART output and prints `PASS` or `FAIL`.

- **Vivado:** Run Simulation → Run Behavioral Simulation, then type `run all` in the Tcl console. The default 1000 ns isn't long enough.
- **Verilator:** `verilator --binary --timing -Wno-fatal rtl/*.v sim/tb_morse_top.v --top-module tb_morse_top && ./obj_dir/Vtb_morse_top`

## Build

Open `MorseCode_decoder.xpr` and click Generate Bitstream. Check that WNS and WHS are both ≥ 0 in the timing summary.
