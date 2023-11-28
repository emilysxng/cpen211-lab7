MOV R0, X
LDR R1, [R0] //load X from memory
MOV R3, Y
STR R1, [R3] //store X to memory (in address 7)
ADD R5, R1,R3;
HALT
X:
.word 0x0001
Y:
.word 0x0008