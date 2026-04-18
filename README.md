# Casino Game

Casino game implementation in Verilog.
Press the button to start, when all LEDs lights up, press the button as soon as possible.
Your response time will be shown on LEDs by binary form, multiply by 32 to calculate exact milliseconds.

## Prerequisites

Install `openFPGALoader`, usually available in Ubuntu repository.
If needed, enable [udev rules](https://trabucayre.github.io/openFPGALoader/guide/install.html#udev-rules).

Install `uv`.

To simulate the design, install `verilator`. The package in Ubuntu repository is relatively old, building your own version of verilator is recommanded.

## Howto

1. `uv sync`
2. `uv run main.py`

## Commandline Options

- `--skip-synthesis` to only flash to device and skip synthesizing/P&L.
- `--write-flash` or `-f` to write to the flash.

## Simulation

Basic simulation by `verilator` is implemented, run `make` in `sim/` and vcd waveform will be created under `sim/logs/`.
Waveform viewers such as GTKWave or vaporview are available.
