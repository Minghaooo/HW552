lbi r1, 0x01
lbi r2, 0x01

subi r1, r1, 1
addi r2, r2, 1

stu r2, r1, 10

add r2, r1, r1

xori r2, r2, 10

ld r2, r1, 0

halt