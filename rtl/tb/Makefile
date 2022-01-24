IVERILOG = iverilog

PROCESSOR_TB_SOURCE = ../alu.sv ../register_file.sv ../memory.sv ../decoder.sv ../processor.sv processor_tb.sv

all: processor_tb.out

clean:
	rm -f *.out *.vcd

processor_tb.out: $(PROCESSOR_TB_SOURCE)
	$(IVERILOG) -g2012 -o processor_tb.out $(PROCESSOR_TB_SOURCE)

run: processor_tb.out
	vvp processor_tb.out

.PHONY: all clean run
