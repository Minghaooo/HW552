lbi r1, 0x02
lbi r2, 0x02

subi r1, r1, 1
addi r2, r2, 1
addi r2, r2, 1
addi r2, r2, 1
addi r2, r2, 1
addi r2, r2, 1
addi r2, r2, 1
addi r2, r2, 1
add r1,r1,r1
add r2,r2,r2
subi r2,r2,1
add r2,r2,r2
add r2,r2,r2
sub r2,r2,r2
add r2,r1,r2
add r1,r2,r2
add r2,r2,r2
addi r2,r2,4
stu r2, r2, 12
st r2, r1, 10
st r2, r1, 10
add r2, r1, r1
xori r2, r2, 10
ld r2, r1, 10
halt