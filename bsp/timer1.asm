; bsp/timer1.asm - TIMER1 ISR moved from main
PUBLIC	TIMER1_ISR
$INCLUDE (config.inc)

; include 切换到了 CONFIG 段，确保后续 ISR 返回到 TMR1 段
TMR1	SEGMENT	CODE
rseg	TMR1

TIMER1_ISR:
	PUSH PSW
	PUSH ACC
	PUSH B
	PUSH DPL
	PUSH DPH
	PUSH 00h
	PUSH 01h

	MOV TH1, #0FCh
	MOV TL1, #018h

	MOV P0, #0FFh
	MOV P2, #00h

	; 0..5 循环
	MOV A, 038h
	MOV R2, A         ; R2 = index
	ADD A, #030h
	MOV R0, A
	MOV A, @R0        ; 读 Buffer
	MOV B, A

	MOV DPTR, #SEG_TABLE
	MOV A, B
	MOVC A, @A+DPTR   
	MOV B, A          

	MOV DPTR, #BITMASK_TABLE
	MOV A, R2         
	MOVC A, @A+DPTR
	MOV R1, A

	MOV A, B
	MOV P0, A
	MOV A, R1
	MOV P2, A

	INC 038h
	MOV A, 038h
	CJNE A, #06, ISR_EXIT ; 6 位数码管
	MOV 038h, #00h

ISR_EXIT:
	POP 01h
	POP 00h
	POP DPH
	POP DPL
	POP B
	POP ACC
	POP PSW
	RETI

END
