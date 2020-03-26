//do {
//  i = i+1;
//  sum = sum+i;
//} while (i <= 7 )

// always taken 


lbi r0, 0
lbi r1, 0
lbi r2, 7


addi r0, r0, 1
add r1, r1, r0
sle r3, r0, r2 

bnez r3, -8  

addi r0, r0, 2
addi r0, r0, 3
addi r0, r0, 4
