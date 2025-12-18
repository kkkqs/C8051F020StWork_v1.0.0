; 索引从 0 开始，供 main.ASM 中通过偏移访问 (MOVC @A+DPTR)
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
; 33 - OFF  - 0FFh    ; 熄灭 (全部段关闭)
; 34 - 'C.' - 046h    ; 自定义 C 带小数点

SEG_TABLE:
    DB 0C0h,0F9h,0A4h,0B0h,099h,092h,082h,0F8h,080h,090h,088h,083h,0C6h,0A1h,086h,08Eh,0F7h,00Ch,0AFh,047h
    DB 040h,079h,024h,030h,019h,012h,002h,078h,000h,010h
    DB 0ABh,0A3h,023h,0FFh,046h

BITMASK_TABLE:
    DB 020h,010h,008h,004h,002h,001h

PASSWORD_TABLE:
    DB 01h,02h,03h,04h,05h

; RUN_ST, OPT_ST, PASS_ST, OPT1_ST, OPT2_ST, OPT3_ST
RUN_ST	EQU	00h
OPT_ST	EQU	01h
PASS_ST	EQU	02h
OPT1_ST	EQU	11h
OPT2_ST	EQU	12h
OPT3_ST	EQU	13h
