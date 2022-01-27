YOSYS := yosys
ICEPACK := icepack
NEXTPNR := nextpnr-ice40
ICEPROG := iceprog

DEVICE := up5k
PACKAGE := sg48

PIN_DEF := icebreaker.pcf
SRC := ../processor.sv \
		../alu.sv \
		../decoder.sv \
		../memory.sv \
		../register_file.sv \
		top.sv

all: top.bin

top.json: $(SRC) ../tb/program.hex
	cp ../tb/program.hex .
	$(YOSYS) -ql top.log -p 'synth_ice40 -top top -json top.json' $(SRC)

top.asc: top.json $(PIN_DEF)
	$(NEXTPNR) -l top_nextpnr.log --$(DEVICE) --package $(PACKAGE) --json top.json --pcf $(PIN_DEF) --asc top.asc

top.bin: top.asc
	$(ICEPACK) -s top.asc top.bin

prog: top.bin
	$(ICEPROG) top.bin

.PHONY: all prog
