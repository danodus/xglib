# Learn CPU

Ref.: https://stackoverflow.com/questions/51592244/implementation-of-simple-microprocessor-using-verilog/51621153#51621153

# ISA

Four basic instructions:
- LD : load data from memory to register
- ST : store data from memory into register
- ADD : add registers together
- BRZ : branch if last operation was equal to zero

4 16-bit general purpose registers
program counter

```
[15 OPCODE 14] | [13 SPECIFIC 0]

ADD: add rd, rs1, rs2       -- rd = rs1 + rs2; z = (rd == 0)
    [15 2'b00 14] | [13 rd 12] | [11 rs1 10] | [9 rs2 8] | [7 RESERVED 0]

LD: ld rd, ra              -- rd = MEM[ra]
    [15 2'b01 14] | [13 rd 12] | [11 ra 10] | [9 RESERVED 1] | [0 1'b1 0]

    ld rd, $addr           -- rd = MEM[$addr]
    [15 2'b01 14] | [13 rd 12] | [11 $addr 1] | [0 1'b0 0]

ST: st rs, ra               -- MEM[ra] = rs
    [15 2'b10 14] | [13 RESERVED 12] | [11 ra 10] | [9 rs 8] | [7 RESERVED 1] | [0 1'b1 0]

    st rs, $addr            -- MEM[$addr] = rs
    [15 2'b10 14] | [13 $addr[10:7] 10] | [9 rs 8] | [7 $addr[6:0] 1] | [0 1'b0 0]

BRZ: brz ra                 -- if (z): pc = ra
    [15 2'b11 14] | [13 RESERVED 12] | [11 ra 10] | [9 RESERVED 1] | [0 1'b1 0]

    brz $addr               -- if (z): pc = pc + $addr
    [15 2'b11 14] | [13 RESERVED 12] | [11 $addr 1] | [0 1'b0 0]

```