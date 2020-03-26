// always not taken  

lbi r0, 0
lbi r1, 0
lbi r2, 7


addi r0, r0, 1
add r1, r1, r0
sle r3, r2, r0 //

bnez r3, 2
j -10

addi r0, r0, 2
addi r0, r0, 3
addi r0, r0, 4