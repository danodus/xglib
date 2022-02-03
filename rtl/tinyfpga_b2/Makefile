YOSYS := yosys
ICEPACK := icepack
NEXTPNR := nextpnr-ice40
TINYPROG := tinyprog

DEVICE := lp8k
PACKAGE := cm81

PIN_DEF := tinyfpga_b2.pcf
SRC := ../processor.sv \
		../alu.sv \
		../decoder.sv \
		../memory.sv \
		../register_file.sv \
		../uart.sv \
		../soc.sv \
		top.sv

all: top.bin

clean:
	rm -f *.hex *.asc *.json *.bin *.log

top.json: $(SRC) ../tb/program.hex
	cp ../tb/program.hex .
	$(YOSYS) -ql top.log -p 'synth_ice40 -top top -json top.json' $(SRC)

top.asc: top.json $(PIN_DEF)
	$(NEXTPNR) -l top_nextpnr.log --$(DEVICE) --package $(PACKAGE) --json top.json --pcf $(PIN_DEF) --asc top.asc --randomize-seed

top.bin: top.asc
	$(ICEPACK) -s top.asc top.bin

prog: top.bin
	$(TINYPROG) top.bin

.PHONY: all prog
