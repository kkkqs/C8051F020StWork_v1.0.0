; 索引�? 0 开始，�? main.ASM 中通过偏移访问 (MOVC @A+DPTR)
; 00 - '0'  - 0C0h
; 01 - '1'  - 0F9h
; 02 - '2'  - 0A4h
; 03 - '3'  - 0B0h
; 04 - '4'  - 099h
; 05 - '5'  - 092h
; 06 - '6'  - 082h
; 07 - '7'  - 0F8h
; 08 - '8'  - 080h
; 09 - '9'  - 090h
; 10 - 'A'  - 088h
; 11 - 'b'  - 083h
; 12 - 'C'  - 0C6h
; 13 - 'd'  - 0A1h
; 14 - 'E'  - 086h
; 15 - 'F'  - 08Eh
; 16 - '_'  - 0F7h
; 17 - 'P.' - 00Ch
; 18 - 'r'  - 0AFh
; 19 - 'L'  - 047h
; 20 - '0.' - 040h
; 21 - '1.' - 079h
; 22 - '2.' - 024h
; 23 - '3.' - 030h
; 24 - '4.' - 019h
; 25 - '5.' - 012h
; 26 - '6.' - 002h
; 27 - '7.' - 078h
; 28 - '8.' - 000h
; 29 - '9.' - 010h
; 30 - 'n'  - 0ABh
; 31 - 'o'  - 0A3h
; 32 - 'o.' - 023h
; 33 - OFF  - 0FFh    ; 熄灭 (全部段关�?)
; 34 - 'C.' - 046h    ; 自定�? C 带小数点
; 35 - 'U'  - 0C1h
; 36 - '-'  - 0BFh
; 37 - ' '  - 0FFh

SEG_TABLE:
    DB 0C0h,0F9h,0A4h,0B0h,099h,092h,082h,0F8h,080h,090h,088h,083h,0C6h,0A1h,086h,08Eh,0F7h,00Ch,0AFh,047h
    DB 040h,079h,024h,030h,019h,012h,002h,078h,000h,010h
    DB 0ABh,0A3h,023h,0FFh,046h,0C1h,0BFh,0FFh

BITMASK_TABLE:
    DB 080h,040h,020h,010h,008h,004h

PASSWORD_TABLE:
    DB 01h,02h,03h,04h,05h

; RUN_ST, OPT_ST, PASS_ST, OPT1_ST, OPT2_ST, OPT3_ST
RUN_ST	EQU	00h
OPT_ST	EQU	01h
PASS_ST	EQU	02h
OPT1_ST	EQU	11h
OPT2_ST	EQU	12h
OPT3_ST	EQU	13h

; Elevator states
ELEV_ST EQU 20h
ELEV_RUN EQU 21h
ELEV_ARRIVED EQU 22h
ELEV_CLOSE EQU 23h

; Elevator variables (RAM)
CUR_FLr      EQU 056h
ELEV_TIMER   EQU 057h
ELEV_TARGET  EQU 058h
ONE_SEC_CNT  EQU 059h
BLINK_TIMER  EQU 05Ah
BLINK_TOGGLE EQU 05Bh

; Queue variables (BITMAP based - 11 floors: -2 to 8)
; Bit 0 = Floor -2, Bit 1 = Floor -1, Bit 2 = Floor 1, ... Bit 10 = Floor 8
; Use 2 bytes: Low byte (bits 0-7), High byte (bits 8-10)
INT_REQ_LO     EQU 05Ch  ; Internal request bitmap low (floors -2 to 5)
INT_REQ_HI     EQU 05Dh  ; Internal request bitmap high (floors 6 to 8)
EXT_UP_LO      EQU 05Eh  ; External UP request bitmap low
EXT_UP_HI      EQU 05Fh  ; External UP request bitmap high
EXT_DN_LO      EQU 062h  ; External DOWN request bitmap low
EXT_DN_HI      EQU 063h  ; External DOWN request bitmap high
ELEV_DIR       EQU 064h  ; Current direction: 0=停止, 1=�?, 2=�?

; Input Mode variables
INPUT_MODE     EQU 065h ; 0=Inside, 1=Outside
OUT_SEL_VAL    EQU 066h ; Temp storage for outside floor selection
DEBUG_ON       EQU 067h ; Global debug flag: 0=normal, 1=jump to debug task

; New variables for Reset Password feature
CURRENT_PASS   EQU 068h ; 5 bytes [068h..06Ch] holding current password in RAM
PASS_NEXT_ST   EQU 06Dh ; State to jump to after PASS_ST success (allows reuse)

; Floor to Bit Index mapping:
; Floor -2 -> Index 0
; Floor -1 -> Index 1
; Floor  1 -> Index 2
; Floor  2 -> Index 3
; ...
; Floor  8 -> Index 10
; Formula: Index = Floor + 2 (if Floor >= 1, Index = Floor + 1)
