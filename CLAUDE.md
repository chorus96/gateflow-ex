# gateflow-ex

Example RTL project wired up to use the
[GateFlow plugin](https://github.com/codejunkie99/Gateflow-Plugin).

The GateFlow plugin is enabled for this repo via `.claude/settings.json`
(marketplace `gateflow` + `gateflow@gateflow`), so its SystemVerilog agents,
skills, and slash commands are available automatically when you open the
project in Claude Code.

## Layout

| Path                       | Purpose                                  |
|----------------------------|------------------------------------------|
| `rtl/`                     | Synthesizable RTL (`counter.sv`)         |
| `tb/`                      | Self-checking testbenches (`tb_counter.sv`) |
| `.claude/gateflow.local.md`| Project-specific GateFlow settings       |
| `.claude/settings.json`    | Enables the GateFlow plugin              |
| `Makefile`                 | `make lint` / `make sim` shortcuts       |

## Conventions

Follow the GateFlow SystemVerilog style: `always_ff` / `always_comb`, `logic`
for all signals, active-low async reset (`rst_n`), non-blocking assignments in
sequential logic, complete case/if to avoid inferred latches. See the plugin's
`CLAUDE.md` for the full reference.
