MOV R0, X
LDR R1, [R0] //load X from memory
MOV R3, Y
STR R1, [R3] //store X to memory (in address 7)
HALT
X:
.word 0x4321
Y:
.word 0xFAFA
