# Morse Code Decoder: PYNQ-Z2 (Zynq-7020)

A Morse code decoder built in FPGA logic. Tap a push-button, the design times
each press, classifies it as a dot or dash, groups the elements into a
character by gap timing, and decodes the result to ASCII.

**Status:** Bitstream builds cleanly with clean timing (WNS/WHS both positive,
0 failing endpoints). Not yet tested on physical hardware — see Open Issues.

## Architecture

| Module            | Role                                                                                                                                                           |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `tick_gen.v`       | Divides the 125 MHz `sys_clk` into a one-cycle-wide 1 ms tick enable.                                                                                          |
| `synchronizer.v`   | Two-flop metastability chain, then an integrating debounce paced by `tick_1ms`. Outputs `btn_sync`, a clean **level** (not a pulse) held high for the full press. |
| `morse_fsm.v`      | Four states: `IDLE` → `PRESS_ACTIVE` → `RELEASE_EVAL` → `GAP_WAIT`. Presses of 50–150 ms count as a dot, 200–450 ms as a dash. 400 ms of silence commits the element pattern. Outputs `raw_code` (packed count + bit pattern, **not** ASCII) and a one-cycle `char_ready` pulse. |
| `morse_decoder.v`  | Combinational lookup mapping `raw_code` to real ASCII. Covers A–Z and 0–9. Anything unrecognized decodes to `?`.                                                |
| `morse_top.v`      | Board top level. Derives both an active-high and active-low reset from a single raw button input, and wires the four modules above together.                  |

### Signal path
```
btn_in --> synchronizer --> btn_sync (level) --\
                                                 >--> morse_fsm --> raw_code, char_ready --> morse_decoder --> ascii_out, ready_flag
sys_clk --> tick_gen --> tick_1ms -------------/
```

### `raw_code` packing (internal, not exposed as ASCII)
`raw_code = {symbol_count[2:0], symbol_bits[4:0]}`. Each element shifts in as
`(prev << 1) | bit`, dot = 0, dash = 1 — so the *first* element tapped ends up
as the most-significant valid bit. `symbol_bits` is 5 bits wide, which is
exactly enough to cover every standard letter (≤4 elements) and every digit
(exactly 5 elements).

## Board I/O

| Signal            | Pin (PYNQ-Z2)      | Notes                                                                                                     |
| ----------------- | ------------------- | ----------------------------------------------------------------------------------------------------------- |
| `sys_clk`         | H16                  | 125 MHz onboard oscillator.                                                                                |
| `btn_rst`         | D19 (BTN0)           | **Active-high.** Idle = 0, pressed = 1 — matches the board's onboard buttons directly, no external wiring needed. |
| `btn_in`          | Y18 (PmodA, pin 1)   | Elegoo push-button on a breadboard. **Must be wired active-high**: pull-down resistor to GND, switch to 3.3V on press. See warning below. |
| `ascii_out[7:0]`  | PmodB, pins 1–4,7–10 | Decoded ASCII byte. Currently raw GPIO — no UART or AXI output yet (see Open Issues). Probe with a logic analyzer or wire to LEDs for a quick check. |
| `ready_flag`      | R14 (LED0)           | Pulses high for one clock each time a character is decoded.                                                |

### ⚠️ Breadboard wiring — pull-down, not pull-up
`synchronizer.v` expects `btn_in` to behave like the onboard buttons:
**idle = 0 V, pressed = 3.3 V**. Wire the Elegoo button with a **10 kΩ
pull-down resistor to GND**, with the switch connecting the signal pin to
3.3V when pressed. Wiring it the opposite way (pull-up to 3.3V, switch to
GND) will invert every tap — idle will read as "held down" and real presses
will read as brief releases, which silently breaks the FSM's timing.

## Simulation

`sim/tb_input_conditioner.v` is a self-checking testbench for the
synchronizer/debounce path. It checks:
- `tick_1ms` period is exactly 100,000 clocks (adjust for 125 MHz if reused)
- a bouncy press produces exactly one clean rise, after the full debounce window
- a bouncy release produces exactly one clean fall
- a sub-debounce-length glitch on an idle line produces no output edges

Run in Vivado XSim: Run Simulation → Run Behavioral Simulation, then
`run all` in the Tcl console (the default 1000 ns window isn't long enough).

**Open item:** there is not yet a testbench for `morse_decoder.v` itself. The
A–Z/0–9 lookup table was verified by manually tracing the FSM's bit-packing
convention for every letter and digit, not by simulation.

## Build

Open `MorseCode_decoder.xpr`, confirm `morse_top` is set as the top module
(Sources → right-click → Set as Top), then Generate Bitstream. Check that
WNS and WHS are both ≥ 0 in the timing summary before programming hardware.

## Known open items

See the repo's Issues tab for full details. Summary:
- Not yet tested on physical hardware
- No UART or AXI4-Lite output path — `ascii_out` is raw GPIO only, despite
  the repo description mentioning AXI4-Lite
- Project may not be built from the official PYNQ-Z2 board file (cosmetic
  board-part warnings in the Vivado log)
- `morse_decoder`'s lookup table has no dedicated testbench yet

## About

Hardware Morse code temporal FSM on Zynq-7020 SoC (PYNQ-Z2). AXI4-Lite / ARM
integration is a planned next step, not yet implemented — see Open Issues.
