    .section .text
    .global _start
    .global main

    .equ CONSTANT, 0xdeadbeef

_start:
    addi x1,x0,1
    addi x2,x0,2
    addi x3,x0,3
    addi x4,x0,4
    addi x5,x2,3
    add x6,x2,x4
    addi x10,x0,%lo(var)
    lw x7,(x10)
    li x8,CONSTANT
    sw x8,(x10)
    lw x9,(x10)
loop:
    beq x0,x0,loop
var:
    .word   42
