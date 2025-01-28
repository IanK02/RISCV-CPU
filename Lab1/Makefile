#

#include /app/rv32sim/site-config.sh
RISCV_PREFIX = riscv32-unknown-elf
VERILATOR = verilator
IVERILOG = iverilog
goal: result-iverilog
CC=$(RISCV_PREFIX)-gcc
AS=$(RISCV_PREFIX)-as
LD=$(RISCV_PREFIX)-ld

SSFLAGS=-march=rv32i
CCFLAGS=-march=rv32i -Wno-builtin-declaration-mismatch -Ilibmc
#SSFLAGS=-march=rv64i -mabi=lp64
#CCFLAGS=-march=rv64i -mabi=lp64 -Wno-builtin-declaration-mismatch -Ilibmc
LDFLAGS=--script ld.script
#LDFLAGS=-A elf64-littleriscv -m elf64lriscv --script ld.script
#LDPOSTFLAGS= -Llibmc -lmc  -Llibmc -lmc -L$(RISCV_LIB) -lgcc
LDPOSTFLAGS= -Llibmc -lmc  -Llibmc -lmc -L$(RISCV_LIB) -lgcc


libmc/libmc.a:
	 cd libmc; make clean; make; cd ..

result-verilator: top.sv verilator_top.cpp lab1.sv
	 $(VERILATOR) -O0 --cc --build --top-module top top.sv verilator_top.cpp --exe
	 cp obj_dir/Vtop ./result-verilator
	 rm -rf obj_dir
	 ./result-verilator

result-iverilog: itop.sv top.sv lab1.sv
	 $(IVERILOG) -g2012 -o result-iverilog itop.sv
	 ./result-iverilog

clean:
	rm -rf obj_dir/ *.o result-verilator result-iverilog

