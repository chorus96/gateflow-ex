# gateflow-ex

A minimal example project that demonstrates the
[GateFlow plugin](https://github.com/codejunkie99/Gateflow-Plugin) for
Claude Code — AI-powered SystemVerilog development: **design → lint → simulate**.

The reference design is a parameterized up-counter with an enable and an
active-low asynchronous reset, plus a self-checking testbench.

## Getting started

### 1. Open in Claude Code

The GateFlow plugin is already enabled for this repo through
`.claude/settings.json`. When you open the project in Claude Code, the plugin's
marketplace is added and the plugin is loaded automatically — giving you the
GateFlow agents, skills, and slash commands (`/gf-doctor`, `/gf-lint`,
`/gf-sim`, `/gf-gen`, ...).

If you use Claude Code elsewhere and want the plugin globally:

```bash
claude plugin marketplace add codejunkie99/Gateflow-Plugin
claude plugin install gateflow
```

### 2. Verify your toolchain

```bash
/gf-doctor          # inside Claude Code
```

Install [Verilator](https://verilator.org/) to run lint and simulation locally:

- macOS: `brew install verilator`
- Linux: `sudo apt install verilator`

### 3. Lint and simulate

Using the provided `Makefile`:

```bash
make lint    # verilator --lint-only -Wall
make sim     # build + run the self-checking testbench
make clean   # remove obj_dir/ and *.vcd
```

Or ask GateFlow directly: `/gf-lint`, `/gf-sim`.

Expected simulation output ends with:

```
  Results: 6 passed, 0 failed
ALL TESTS PASSED
```

## Project structure

```
gateflow-ex/
├── .claude/
│   ├── settings.json         # enables the GateFlow plugin
│   └── gateflow.local.md      # project-specific GateFlow settings
├── rtl/
│   └── counter.sv            # parameterized counter (DUT)
├── tb/
│   └── tb_counter.sv         # self-checking testbench (6 checks)
├── Makefile                  # make lint / make sim
├── CLAUDE.md                 # project guidance for Claude Code
└── README.md
```

## Next steps

- `"Create a FIFO and test it"` — generate a more complex design
- `"Plan a UART controller"` — see GateFlow's design planning
- `/gf-gen` — generate new RTL from a description
- `/gf-formal` — formally verify a module

## License

See the [GateFlow plugin repository](https://github.com/codejunkie99/Gateflow-Plugin)
for plugin licensing (BSL-1.1). This example scaffold is provided as-is.
