# gateflow-ex — convenience targets for lint and simulation.
# Requires Verilator (https://verilator.org/). Install:
#   macOS: brew install verilator
#   Linux: sudo apt install verilator

RTL_DIR   := rtl
TB_DIR    := tb
TOP       := counter
SIM_TOP   := tb_counter
RTL_SRCS  := $(wildcard $(RTL_DIR)/*.sv)
TB_SRCS   := $(wildcard $(TB_DIR)/*.sv)

.PHONY: all lint sim clean

all: lint sim

lint:
	verilator --lint-only -Wall -I$(RTL_DIR) $(RTL_SRCS)

sim:
	verilator --binary -j 0 --trace -Wall \
		--top-module $(SIM_TOP) \
		-I$(RTL_DIR) $(TB_SRCS) $(RTL_SRCS) -o $(SIM_TOP)
	./obj_dir/$(SIM_TOP)

clean:
	rm -rf obj_dir dump.vcd
