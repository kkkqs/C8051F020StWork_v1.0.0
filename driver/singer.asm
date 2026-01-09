SINGER_SEGMENT SEGMENT CODE
RSEG SINGER_SEGMENT
$include (C8051F020.inc)

;-----------------------------------------------------------------------------
; External Dependencies
;-----------------------------------------------------------------------------
EXTRN CODE(Buzzer_Init)
EXTRN CODE(Buzzer_Start)
EXTRN CODE(Buzzer_Stop)
EXTRN CODE(Buzzer_Set_Frequency)
EXTRN CODE(DELAY_MS)

;-----------------------------------------------------------------------------
; Public Interface
;-----------------------------------------------------------------------------
PUBLIC Singer_Init
PUBLIC Singer_Play
PUBLIC Singer_PlayNote ; Add new public function

;-----------------------------------------------------------------------------
; Singer_Init
;-----------------------------------------------------------------------------
Singer_Init:
    LCALL Buzzer_Init
    RET

;-----------------------------------------------------------------------------
; Singer_PlayNote
;-----------------------------------------------------------------------------
; Description: Plays a single note based on Floor/Number input.
; Input: R7 = Floor Number (signed byte)
;        -2 -> L6, -1 -> L7, 0..7 -> M1..M7, 8 -> H1
;        Uses F-Major scale as defined in table.
;-----------------------------------------------------------------------------
Singer_PlayNote:
    PUSH Acc
    PUSH PSW
    
    ; Map Floor to Table Index
    ; Floor -2 (FEh) -> Index 10 (L6)
    ; Floor -1 (FFh) -> Index 11 (L7)
    ; Floor 1  (01h) -> Index 1  (M1)
    ; ...
    ; Floor 7  (07h) -> Index 7  (M7)
    ; Floor 8  (08h) -> Index 8  (H1)
    
    MOV A, R7
    CJNE A, #0FEh, SPN_CHECK_NM1
    ; -2
    MOV R2, #10
    SJMP SPN_PLAY
    
SPN_CHECK_NM1:
    CJNE A, #0FFh, SPN_CHECK_POS
    ; -1
    MOV R2, #11
    SJMP SPN_PLAY
    
SPN_CHECK_POS:
    ; Check if > 8 (should not happen, but clamp)
    CJNE A, #09h, SPN_LE8
SPN_LE8:
    JNC SPN_RET ; >= 9, ignore
    
    ; Check if < 1 (0 is not a floor in this system, maybe?)
    JZ SPN_RET  ; 0, ignore
    
    ; 1..8 -> Index = Floor
    MOV R2, A
    
SPN_PLAY:
    ; Calculate Offset: (Index - 1) * 2
    MOV A, R2
    DEC A
    RL A
    MOV R5, A     ; Offset
    
    ; Get Reload Value
    PUSH DPH
    PUSH DPL
    MOV DPTR, #NOTE_RELOAD_TABLE
    
    ; Read High Byte
    MOVC A, @A+DPTR
    MOV R6, A
    
    ; Read Low Byte
    MOV A, R5
    INC A
    MOVC A, @A+DPTR
    MOV R7, A
    
    POP DPL
    POP DPH
    
    ; Play Note for short duration (e.g. 500ms)
    LCALL Buzzer_Set_Frequency
    LCALL Buzzer_Start
    
    MOV R4, #250
    LCALL DELAY_MS
    MOV R4, #250
    LCALL DELAY_MS
    
    LCALL Buzzer_Stop
    
SPN_RET:
    POP PSW
    POP Acc
    RET

;-----------------------------------------------------------------------------
; Singer_Play
;-----------------------------------------------------------------------------
; Description: Plays "Da Dong Bei Wo De Jia Xiang" (Great Northeast My Hometown)
;-----------------------------------------------------------------------------
Singer_Play:
    PUSH DPH
    PUSH DPL
    
    MOV DPTR, #SONG_TABLE
    
SINGER_LOOP:
    ; Read Note Index
    CLR A
    MOVC A, @A+DPTR
    MOV R2, A          ; R2 = Note Index
    
    ; Check for terminator
    CJNE R2, #0FFh, READ_DURATION
    SJMP SINGER_DONE

READ_DURATION:
    INC DPTR
    CLR A
    MOVC A, @A+DPTR
    MOV R3, A          ; R3 = Duration units
    INC DPTR           ; Advance to next note pair
    
    ; Save Song Pointer (DPTR) because we need DPTR for Note Table
    PUSH DPH
    PUSH DPL
    
    ; Check if Rest (0)
    MOV A, R2
    JZ PLAY_NOTE_REST
    
    ; Calculate Offset: (NoteIndex - 1) * 2
    DEC A              ; 1-based to 0-based
    RL A               ; A = A * 2
    MOV R5, A          ; Save offset
    
    MOV DPTR, #NOTE_RELOAD_TABLE
    
    ; Read High Byte
    MOVC A, @A+DPTR
    MOV R6, A
    
    ; Read Low Byte
    MOV A, R5
    INC A
    MOVC A, @A+DPTR
    MOV R7, A
    
    ; Set Frequency and Start Buzzer
    LCALL Buzzer_Set_Frequency
    LCALL Buzzer_Start
    SJMP WAIT_DURATION

PLAY_NOTE_REST:
    LCALL Buzzer_Stop

WAIT_DURATION:
    ; Wait loop based on R3 (Duration units)
    ; Unit = 16th note approx 120ms
    ; Tempo: ~128 BPM
    MOV A, R3
    JZ NO_WAIT 

WAIT_LOOP:
    PUSH Acc
    MOV R4, #15     ; Adjusted: 15ms * 2 = 30ms per unit
    LCALL DELAY_MS
    MOV R4, #15     
    LCALL DELAY_MS
    POP Acc
    DEC A
    JNZ WAIT_LOOP
    
    ; Articulation Gap (Staccato)
    LCALL Buzzer_Stop
    MOV R4, #10     ; 10ms silence
    LCALL DELAY_MS
    
NO_WAIT:
    ; Restore Song Pointer
    POP DPL
    POP DPH
    
    SJMP SINGER_LOOP

SINGER_DONE:
    POP DPL
    POP DPH
    LCALL Buzzer_Stop
    RET

;-----------------------------------------------------------------------------
; Tables
;-----------------------------------------------------------------------------
; Timer 2 Reload Values for SYSCLK = 22.1184 MHz
; Formula: Reload = 65536 - (921600 / Frequency)
; Key: F Major (1=F). Root (1) = F5 (698Hz) to transpose UP from C5.

NOTE_RELOAD_TABLE:
    DB 0FAh, 0D8h ; 1: M1 (F5) 698Hz
    DB 0FBh, 069h ; 2: M2 (G5) 784Hz
    DB 0FBh, 0E9h ; 3: M3 (A5) 880Hz
    DB 0FCh, 024h ; 4: M4 (Bb5) 932Hz
    DB 0FCh, 08Fh ; 5: M5 (C6) 1046Hz
    DB 0FCh, 0F0h ; 6: M6 (D6) 1175Hz
    DB 0FDh, 045h ; 7: M7 (E6) 1318Hz
    DB 0FDh, 06Dh ; 8: H1 (F6) 1397Hz
    DB 0F9h, 01Eh ; 9: L5 (C5) 523Hz
    DB 0F9h, 0DEh ; 10: L6 (D5) 587Hz
    DB 0FAh, 08Ah ; 11: L7 (E5) 659Hz
    DB 0FDh, 0B5h ; 12: H2 (G6) 1568Hz
    DB 0FDh, 0F5h ; 13: H3 (A6) 1760Hz
    DB 0F6h, 0D1h ; 14: L2 (G4) 392Hz
    DB 0F7h, 0D1h ; 15: L3 (A4) 440Hz

; Song: "Da Dong Bei Wo De Jia Xiang" (Intro / First Half)
; Unit: 1 = 16th note (approx 20+10ms ~ 30ms base)
; Quarter note = 4 units
SONG_TABLE:
    ; Line 1, Bar 1
    ; 6(e) 6(e) 6.(e.) 5(s) 6(e) 3(e) 5(q)
    DB 6, 2,  6, 2,  6, 3,  5, 1,  6, 2,  3, 2,  5, 4
    
    ; Bar 2
    ; 3.(e.) 5(s) 3(e) 7(L)(e) 6(h)
    DB 3, 3,  5, 1,  3, 2,  11, 2,  6, 8

    ; Bar 3
    ; 6(q) i.(e.) 6(s) 2(H)(e) i(e) i(e) 6(e)
    ; 2(H) is 12. i is 8.
    DB 6, 4,  8, 3,  6, 1,  12, 2,  8, 2,  8, 2,  6, 2

    ; Bar 4
    ; 6.(e.) 5(s) 2(e) 5(e) 3(h)
    DB 6, 3,  5, 1,  2, 2,  5, 2,  3, 8

    ; Line 2, Bar 5
    ; 6.(e.) 6(s) 6(e) 5(e) 6(s) 6(s) i(e) 6(e) 5(e)
    ; 6.6 -> 6(3) 6(1). 65 -> 6(2) 5(2). 66i -> 6(1) 6(1) 8(2). 65 -> 6(2) 5(2).
    DB 6, 3,  6, 1,  6, 2,  5, 2
    DB 6, 1,  6, 1,  8, 2,  6, 2,  5, 2

    ; Bar 6
    ; 3(s) 3(s) 2(e) 1(s) 5(L)(s) 3(e) 2(h)
    ; 332 -> 3(1) 3(1) 2(2). 153 -> 1(1) 9(1) 3(2). 2 -> 8.
    DB 3, 1,  3, 1,  2, 2
    DB 1, 1,  9, 1,  3, 2,  2, 8

    ; Bar 7
    ; 5.(e.) 3(s) 5(e) 3(e) 5(e) 5(e) 3(e) i(e)
    ; 5.3 -> 5(3) 3(1). 53 -> 5(2) 3(2). 55 -> 5(2) 5(2). 3i -> 3(2) 8(2).
    DB 5, 3,  3, 1,  5, 2,  3, 2
    DB 5, 2,  5, 2,  3, 2,  8, 2

    ; Bar 8
    ; 6(w)
    DB 6, 16

    ; Line 3 (Similar to L1 but start is quarter)
    ; Bar 9
    ; 6(q) 6.(e.) 5(s) 6(e) 3(e) 5(q)
    DB 6, 4,  6, 3,  5, 1,  6, 2,  3, 2,  5, 4

    ; Bar 10 (= Bar 2)
    DB 3, 3,  5, 1,  3, 2,  11, 2,  6, 8

    ; Bar 11 (= Bar 3)
    DB 6, 4,  8, 3,  6, 1,  12, 2,  8, 2,  8, 2,  6, 2

    ; Bar 12 (= Bar 4)
    DB 6, 3,  5, 1,  2, 2,  5, 2,  3, 8

    ; Line 4 (Variation)
    ; Bar 13 (Same as Bar 5)
    DB 6, 3,  6, 1,  6, 2,  5, 2
    DB 6, 1,  6, 1,  8, 2,  6, 2,  5, 2

    ; Bar 14
    ; 3(s) 3(s) 5(e) 1(s) 5(L)(s) 3(e) 2(h)
    ; 335 -> 3(1) 3(1) 5(2). 153 -> 1(1) 9(1) 3(2).
    DB 3, 1,  3, 1,  5, 2
    DB 1, 1,  9, 1,  3, 2,  2, 8

    ; Bar 15
    ; 5.(e.) 3(s) 5(e) 3(e) 5(s) 3(s) 5(e) 5(q) ??
    ; Score: 5.3 53 53(underscored) 5(q)?
    ; Let's parse image: | 5.3(u) 53(u) 53(uu 5) 5 | 55(u) 3i(u) 6 - |
    ; Wait, Last bar of 4th line: | 5 5 3 i | 6 - - - | ? No.
    ; Image Line 4 End: | 5.3 53 53 5 | 55 31 6 - |
    ; Let's go with:
    ; 5(3) 3(1) | 5(2) 3(2) | 5(1) 3(1) 5(2) | 5(4) ???
    ; This fits 4 beats? 1 + 1 + 1 + 1. Yes.
    ; So: 5.3(1) 53(1) 535(1) ?? No 5s3s5e.
    ; Last 5 is quarter? No, looking at next bar pickup.
    ; Let's assume:
    ; 5.3 -> 5(3) 3(1)
    ; 53 -> 5(2) 3(2)
    ; 535 -> 5(1) 3(1) 5(2)
    ; 5 -> 5(4)
    DB 5, 3,  3, 1,  5, 2,  3, 2,  5, 1,  3, 1,  5, 2,  5, 4

    ; Bar 16
    ; 5 5 3 i 6 -
    ; 5(2) 5(2) 3(2) 8(2) 6(8)
    DB 5, 2,  5, 2,  3, 2,  8, 2,  6, 8

    DB 0FFh ; Terminator

END
