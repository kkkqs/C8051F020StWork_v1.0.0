$INCLUDE (config.inc)
$include (C8051F020.inc)
EXTRN CODE(MatrixKey)
EXTRN CODE(Timer1_Init)
EXTRN CODE(Timer0_Init)
EXTRN CODE(TIMER0_ISR)
EXTRN CODE(TIMER1_ISR)
EXTRN CODE(LED6_ApplyTable)
EXTRN CODE(LED6_Refresh)
EXTRN CODE(DELAY_MS)
EXTRN CODE(InputTask_03B)
EXTRN CODE(InputTask_039)
EXTRN CODE(RunningTask_Init)
EXTRN CODE(RunningTask_Handler)
EXTRN CODE(ConfigurationTask_Init)
EXTRN CODE(ConfigurationTask_Handler)
EXTRN CODE(Init_Device)
; DebugTask is implemented inline in this file
	ORG 0000h
	LJMP MAIN

	ORG 000Bh
	LJMP TIMER0_ISR

	ORG 001Bh
	LJMP TIMER1_ISR

	ORG 0200h
MAIN:
	LCALL Init_Device
	
	MOV P0, #0FFh
	MOV P2, #00h

	; 初始化显示缓冲 (6位) => 使用 LED6 表 00 (DISPLAY_INIT_BLANK)
	MOV A, #00h
	LCALL LED6_ApplyTable

	MOV 038h, #00h

	MOV 070h, #00h
	MOV 071h, #00h

	MOV 044h, #0FFh
	MOV 045h, #00h
	MOV 046h, #0FFh
	MOV 047h, #00h
	MOV 048h, #00h
	MOV 03Ah, #03h

	LCALL Timer1_Init
	LCALL Timer0_Init
	SETB EA                ; Enable Global Interrupts
	; Setup debug flag (default 0). If set to 1, jump to debug task.
;	MOV DEBUG_ON, #00h
;	MOV A, DEBUG_ON
;	CJNE A, #01h, SKIP_DEBUG
;	LJMP DebugTask_Handler
SKIP_DEBUG:
	LCALL RunningTask_Init
	LCALL ConfigurationTask_Init

; -----------------------------
; Inline debug task
; -----------------------------
;DebugTask_Handler:
;	; Debug: disable Timer1 and drive LED6 display here
;	CLR TR1
;	CLR ET1
;	CLR TR0
;	CLR ET0

;	; Fill display buffer (028h..02Dh) with 1..6
;	MOV 028h, #01h
;	MOV 029h, #02h
;	MOV 02Ah, #03h
;	MOV 02Bh, #04h
;	MOV 02Ch, #05h
;	MOV 02Dh, #06h

;DebugLoop:
;	LCALL LED6_Refresh
;	MOV R4, #05
;	LCALL DELAY_MS
;	SJMP DebugLoop

LOOP:
	EXTRN CODE(KeyInput_Process)
	LCALL KeyInput_Process

MXK_STATE_CHECK:
	MOV A, 070h
	CJNE A,#RUN_ST, CHECK_ELEV
	LCALL RunningTask_Handler
	SJMP LOOP
CHECK_ELEV:
	CJNE A,#ELEV_ST, CHECK_ELEV2
	LCALL RunningTask_Handler
	SJMP LOOP
CHECK_ELEV2:
	CJNE A,#ELEV_RUN, CHECK_ELEV3
	LCALL RunningTask_Handler
	SJMP LOOP
CHECK_ELEV3:
	CJNE A,#ELEV_ARRIVED, CHECK_ELEV4
	LCALL RunningTask_Handler
	SJMP LOOP
CHECK_ELEV4:
	CJNE A,#ELEV_CLOSE, CHECK_OPT
	LCALL RunningTask_Handler
	SJMP LOOP
CHECK_OPT:
	CJNE A,#OPT_ST, CHECK_OPT1
	LCALL ConfigurationTask_Handler
	AJMP LOOP
CHECK_OPT1:
	CJNE A,#OPT1_ST, CHECK_OPT2
	LCALL ConfigurationTask_Handler
	AJMP LOOP
CHECK_OPT2:
	CJNE A,#OPT2_ST, CHECK_OPT3
	LCALL ConfigurationTask_Handler
	AJMP LOOP
CHECK_OPT3:
	CJNE A,#OPT3_ST, CHECK_PASS
	LCALL ConfigurationTask_Handler
	AJMP LOOP
CHECK_PASS:
	CJNE A,#PASS_ST, SKIP_PASS
	LCALL ConfigurationTask_Handler
	AJMP LOOP
SKIP_PASS:
	AJMP LOOP

END
