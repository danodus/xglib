IVERILOG = iverilog
PYTHON = python3

RISCV_TOOLCHAIN_PATH = /opt/riscv32i/bin/
RISVC_TOOLCHAIN_PREFIX = riscv32-unknown-elf-
AS = ${RISCV_TOOLCHAIN_PATH}${RISVC_TOOLCHAIN_PREFIX}as
OBJCOPY = ${RISCV_TOOLCHAIN_PATH}${RISVC_TOOLCHAIN_PREFIX}objcopy
CC = ${RISCV_TOOLCHAIN_PATH}${RISVC_TOOLCHAIN_PREFIX}gcc

PROGRAM_SOURCE = start.s program.c
PROCESSOR_TB_SOURCE = ../alu.sv ../register_file.sv ../memory.sv ../decoder.sv ../processor.sv processor_tb.sv

all: program.hex processor_tb.out

firmware: program.hex

clean:
	rm -f *.out *.vcd *.hex *.elf *.bin *.lst

program.hex: program.bin
	$(PYTHON) makehex.py program.bin 1024 > program.hex

program.bin: program.elf
	${OBJCOPY} -O binary program.elf program.bin

program.elf: $(PROGRAM_SOURCE)
	${CC} -Wa,-adhln -nostdlib -O3 -T riscv.ld start.s program.c -o program.elf > program.lst

processor_tb.out: $(PROCESSOR_TB_SOURCE)
	$(IVERILOG) -g2012 -o processor_tb.out $(PROCESSOR_TB_SOURCE)

run: program.hex processor_tb.out
	vvp processor_tb.out

.PHONY: all clean run firmware
