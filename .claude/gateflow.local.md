---
verilator_flags: ["-Wall"]
top_module: counter
sim_top: tb_counter
rtl_dir: rtl
tb_dir: tb
clock_freq: 100MHz
---

# Project Notes

`gateflow-ex` is a minimal example project that demonstrates the
[GateFlow plugin](https://github.com/codejunkie99/Gateflow-Plugin) workflow:
design → lint → simulate.

- RTL sources live in `rtl/`, testbenches in `tb/`.
- The reference design is a parameterized `counter` with enable + async reset.
- Use `make lint` and `make sim` (or the GateFlow slash commands) to verify.

## Try it

- `/gf-doctor` — check your toolchain (Verilator, Verible, Yosys, ...)
- `/gf-lint` — lint the RTL
- `/gf-sim` — build and run the self-checking testbench
- "Create a FIFO and test it" — let GateFlow generate more RTL
