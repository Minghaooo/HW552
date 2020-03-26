//register bypassing r3 -> r3

lbi r1 , 0
lbi r2,  3

st  r2 , r1, 0
ld  r3 , r1, 0
add r4 , r1, r2
add r4 , r4, r2
add r4 , r4, r3
halt
