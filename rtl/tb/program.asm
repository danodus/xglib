#bits 16

#subruledef register
{
    x0 => 0b00
    x1 => 0b01
    x2 => 0b10
    x3 => 0b11
}

#subruledef memory
{
    [{address}] => address`11
}

#ruledef
{
    add {rd: register}, {rs1: register}, {rs2: register} => 0b00 @ rd         @ rs1 @ rs2 @ 0b00000000

    ld {rd: register}, {ra: register}                    => 0b01 @ rd         @ ra  @ 0b000000000     @ 0b1
    ld {rd: register}, {addr: memory}                    => 0b01 @ rd         @ addr                  @ 0b0

    st {rs: register}, {ra: register}                    => 0b10 @ 0b00       @ ra  @ rs  @ 0b0000000 @ 0b1
    st {rs: register}, {addr: memory}                    => 0b10 @ addr[10:7]       @ rs  @ addr[6:0] @ 0b0

    brz {ra: register}                                   => 0b11 @ 0b00       @ ra  @ 0b000000000     @ 0b1
    brz {addr}                                           => 0b11 @ 0b00       @ (addr - pc)`11        @ 0b0
}

    ld x1,[one]
    ld x2,[two]
    ld x3,[three]
    st x3,[var]
    ld x1,[var]
    add x0,x0,x0    ; set z
loop:
    brz loop

zero:
    #d 0x0000
one:
    #d 0x0001
two:
    #d 0x0002
three:
    #d 0x0003
var:
    #d 0x0000
