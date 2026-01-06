LCD1602 SEGMENT CODE
rseg LCD1602

$INCLUDE (../bsp/Delay.inc)
$include (C8051F020.inc)
PUBLIC LCD_INIT
PUBLIC LCD_WR_CMD
PUBLIC LCD_WR_DAT
PUBLIC LCD_CLEAR
PUBLIC LCD_SHOW_STR

; SFR Page Register (not in standard inc file)
SFRPAGE  DATA 0F1h
P4MDOUT  DATA 0A4h       ; P4MDOUT on SFR Page 0x0F

; Pin Definitions (P4.6=RS, P4.7=E, P3=Data)
; P4 is on SFR Page 0x0F
LCD_RS_MASK  EQU 040h    ; P4.6 bit mask
LCD_E_MASK   EQU 080h    ; P4.7 bit mask
LCD_BUS      EQU P3      

; Macro-like routines for P4 access
LCD_SET_RS:
    PUSH ACC
    MOV SFRPAGE, #0Fh
    ORL P4, #LCD_RS_MASK
    MOV SFRPAGE, #00h
    POP ACC
    RET

LCD_CLR_RS:
    PUSH ACC
    MOV SFRPAGE, #0Fh
    ANL P4, #NOT LCD_RS_MASK
    MOV SFRPAGE, #00h
    POP ACC
    RET

LCD_SET_E:
    PUSH ACC
    MOV SFRPAGE, #0Fh
    ORL P4, #LCD_E_MASK
    MOV SFRPAGE, #00h
    POP ACC
    RET

LCD_CLR_E:
    PUSH ACC
    MOV SFRPAGE, #0Fh
    ANL P4, #NOT LCD_E_MASK   ; Clear E bit (P4.7)
    MOV SFRPAGE, #00h
    POP ACC
    RET

LCD_INIT:
    ; Configure P4MDOUT for P4.6, P4.7 as Push-Pull
    MOV SFRPAGE, #0Fh
    ORL P4MDOUT, #0C0h    ; P4.6, P4.7 Push-Pull
    MOV SFRPAGE, #00h
    
    MOV R4, #50 
    LCALL DELAY_MS 
    MOV A, #38h 
    LCALL LCD_WR_CMD
    MOV R4, #50 
    LCALL DELAY_MS
    MOV A, #38h 
    LCALL LCD_WR_CMD
    MOV A, #0Ch 
    LCALL LCD_WR_CMD
    MOV A, #06h 
    LCALL LCD_WR_CMD
    MOV A, #01h 
    LCALL LCD_WR_CMD
    RET

LCD_WR_CMD:
    PUSH ACC
    LCALL LCD_CLR_RS      ; RS = 0 for command
    POP ACC
    SJMP LCD_WR_COM
LCD_WR_DAT:
    PUSH ACC
    LCALL LCD_SET_RS      ; RS = 1 for data
    POP ACC
LCD_WR_COM:
    MOV LCD_BUS, A 
    LCALL LCD_SET_E       ; E = 1
    NOP 
    NOP 
    LCALL LCD_CLR_E       ; E = 0
    MOV R4, #2 
    LCALL DELAY_MS 
    RET

LCD_CLEAR:
    MOV A, #01h 
    LCALL LCD_WR_CMD 
    RET

LCD_SHOW_STR:
LCD_STR_LOOP:
    CLR A 
    MOVC A, @A+DPTR 
    JZ LCD_STR_END
    LCALL LCD_WR_DAT 
    INC DPTR 
    SJMP LCD_STR_LOOP
LCD_STR_END: 
    RET
END