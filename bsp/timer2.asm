Timer2_Segment SEGMENT CODE
RSEG Timer2_Segment
NAME TIMER2

$include (C8051F020.inc)

;-----------------------------------------------------------------------------
; Global Definitions
;-----------------------------------------------------------------------------
PUBLIC Timer2_Init
PUBLIC TIMER2_ISR
PUBLIC Timer2_Start
PUBLIC Timer2_Stop
PUBLIC Timer2_Set_Reload

;-----------------------------------------------------------------------------
; Code Segment
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Timer2_Init
;-----------------------------------------------------------------------------
; Description: Configures Timer 2 for Auto-Reload Mode.
;              Currently configured to drive P4.5 (Buzzer) via ISR.
; Note: P4.5 is used for the buzzer output.
;       Interrupts are enabled for Timer 2.
;-----------------------------------------------------------------------------
Timer2_Init:
    ; 1. Disable Timer 2 bits in T2CON
    ; T2CON: TF2 EXF2 RCLK TCLK EXEN2 TR2 C/T2 CP/RL2
    ; We want: CP/RL2 = 0 (Auto-Reload)
    ;          C/T2 = 0 (Timer)
    ;          TR2 = 0 (Stop initially)
    MOV T2CON, #00h

    ; 2. Configure Interrupts
    ; Clear Flag
    CLR TF2 
    ; Enable Timer 2 Interrupt
    SETB ET2 

    ; Note: P4.5 Output Mode is assumed to be Push-Pull (configured in Init_Device)
    ; Ensure P4.5 is low initially
    ANL P4, #0DFh   ; Clear P4.5 (P4 & ~0x20)
    
    RET

;-----------------------------------------------------------------------------
; Timer2_Start
;-----------------------------------------------------------------------------
; Description: Starts Timer 2.
;-----------------------------------------------------------------------------
Timer2_Start:
    SETB TR2
    RET

;-----------------------------------------------------------------------------
; Timer2_Stop
;-----------------------------------------------------------------------------
; Description: Stops Timer 2.
;-----------------------------------------------------------------------------
Timer2_Stop:
    CLR TR2
    ANL P4, #0DFh   ; Force P4.5 Low when stopped
    RET

;-----------------------------------------------------------------------------
; Timer2_Set_Reload
;-----------------------------------------------------------------------------
; Description: Sets the reload value for Timer 2.
; Input: R6 (High Byte of Reload Value -> RCAP2H)
;        R7 (Low Byte of Reload Value -> RCAP2L)
; Use formula: Reload = 65536 - (SYSCLK/12) / (2 * Frequency)
;-----------------------------------------------------------------------------
Timer2_Set_Reload:
    CLR TR2         ; Stop timer while updating to avoid glitches
    
    MOV RCAP2H, R6
    MOV RCAP2L, R7
    
    ; Load current timer registers to restart immediately with new value
    MOV TH2, R6
    MOV TL2, R7
    
    SETB TR2        ; Restart timer
    RET

;-----------------------------------------------------------------------------
; TIMER2_ISR
;-----------------------------------------------------------------------------
; Description: Timer 2 Interrupt Service Routine.
;              Toggles P4.5 to generate square wave.
;-----------------------------------------------------------------------------
TIMER2_ISR:
    ; Hardware does NOT clear TF2 automatically in ISR.
    CLR TF2
    
    ; Toggle P4.5
    ; P4 is usually at 0x84, which is not bit-addressable in standard map.
    ; Use XRL to toggle bit 5 (0x20).
    ; XRL direct, #data does not affect flags.
    XRL P4, #20h
    
    RETI

END
