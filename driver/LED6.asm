; driver/LED6.asm
; Utility routines to update 6-digit 7-seg display buffer (0x30..0x35)
; Usage:
; 1) Caller sets DPTR to the pattern label (6 bytes: buffer 0x30..0x35 order),
;    then LCALL LED6_CopyFromDPTR
; 2) Or call the convenience LCALL LED6_Show_ERR011 to display Err011

	PUBLIC	LED6_CopyFromDPTR
	PUBLIC	LED6_Show_ERR011
	PUBLIC	LED6_Show_MENU
	PUBLIC	LED6_Show_NO_INPUT
	PUBLIC	LED6_Clear
	PUBLIC	LED6_Show_PASS_INIT
	PUBLIC	LED6_Show_OPT2_INIT
	PUBLIC	LED6_Show_OPT3_INIT
	PUBLIC	LED6_Show_FALSEX

LED6	SEGMENT	CODE
rseg	LED6

LED6_CopyFromDPTR:
	PUSH PSW
	PUSH ACC
	PUSH B
	PUSH 00h    ; save R0
	PUSH 02h    ; save R2
	PUSH 03h    ; save R3
	PUSH DPL
	PUSH DPH

	MOV R0, #030h    ; dest addr (buffer start)
	MOV R2, #00h     ; offset into code data
	MOV R3, #06      ; 6 bytes to copy

LED6_COPY_LOOP:
	MOV A, R2
	MOVC A, @A+DPTR
	MOV @R0, A
	INC R0
	INC R2
	DJNZ R3, LED6_COPY_LOOP

	POP DPH
	POP DPL
	POP 03h
	POP 02h
	POP 00h
	POP B
	POP ACC
	POP PSW
	RET

LED6_Show_ERR011:
	PUSH DPL
	PUSH DPH
	MOV DPTR, #ERR011
	LCALL LED6_CopyFromDPTR
	POP DPH
	POP DPL
	RET

; Patterns (6 bytes per pattern), stored in order corresponding to buffer addresses 0x30..0x35
; Example: ERR011 (matches the manual sequence used previously in main.ASM)
ERR011:
	DB 01h,01h,00h,012h,012h,00Eh

; MENU pattern: 6 bytes for buffer 0x30..0x35 (right->left = 30..35)
; according to OPT_MODE: 35:1.(0x15),34:n(0x1E),33:2.(0x16),32:r(0x12),31:3.(0x17),30:C(0x0C)
MENU:
	DB 00Ch,017h,012h,016h,01Eh,015h

; NO_INPUT pattern: "no._d_d__" example from OPT1_INIT
NO_INPUT:
	DB 021h,021h,010h,010h,020h,01Eh

; CLEAR pattern: all blanks (0x10)
CLEAR:
	DB 010h,010h,010h,010h,010h,010h

; PASS_INIT: buffer 30..35 = [010,010,010,010,010,011]
PASS_INIT:
	DB 010h,010h,010h,010h,010h,011h

; OPT2_INIT: buffer 30..35 = [021,010,010,010,013,012]
OPT2_INIT:
	DB 021h,010h,010h,010h,013h,012h

; OPT3_INIT: buffer 30..35 = [021,021,021,021,010,022]
OPT3_INIT:
	DB 021h,021h,021h,021h,010h,022h

LED6_Show_MENU:
	PUSH DPL
	PUSH DPH
	MOV DPTR,#MENU
	LCALL LED6_CopyFromDPTR
	POP DPH
	POP DPL
	RET

LED6_Show_NO_INPUT:
	PUSH DPL
	PUSH DPH
	MOV DPTR,#NO_INPUT
	LCALL LED6_CopyFromDPTR
	POP DPH
	POP DPL
	RET

LED6_Show_PASS_INIT:
	PUSH DPL
	PUSH DPH
	MOV DPTR,#PASS_INIT
	LCALL LED6_CopyFromDPTR
	POP DPH
	POP DPL
	RET

LED6_Show_OPT2_INIT:
	PUSH DPL
	PUSH DPH
	MOV DPTR,#OPT2_INIT
	LCALL LED6_CopyFromDPTR
	POP DPH
	POP DPL
	RET

LED6_Show_OPT3_INIT:
	PUSH DPL
	PUSH DPH
	MOV DPTR,#OPT3_INIT
	LCALL LED6_CopyFromDPTR
	POP DPH
	POP DPL
	RET

LED6_Clear:
	PUSH DPL
	PUSH DPH
	MOV DPTR,#CLEAR
	LCALL LED6_CopyFromDPTR
	POP DPH
	POP DPL
	RET

; FALSEX: dynamic last digit from RAM 03Ah
LED6_Show_FALSEX:
	MOV 035h, #00Fh
	MOV 034h, #00Ah
	MOV 033h, #013h
	MOV 032h, #005h
	MOV 031h, #00Eh
	MOV A, 03Ah
	MOV 030h, A
	RET

END
