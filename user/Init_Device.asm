;------------------------------------
;-  Generated Initialization File  --
;------------------------------------

$include (C8051F020.inc)

public  Init_Device

INIT SEGMENT CODE
    rseg INIT

; Peripheral specific initialization functions,
; Called from the Init_Device label
Reset_Sources_Init:
    mov  WDTCN,     #0DEh
    mov  WDTCN,     #0ADh

    ret

Timer_Init:
    mov  TMOD,      #011h
    ret

Oscillator_Init:
    mov  OSCICN,    #007h
    ret

; Initialization function for device,
; Call Init_Device from your main program

Port_IO_Init:
    ; P0.0  -  Unassigned,  Push-Pull,  Digital
    ; P0.1  -  Unassigned,  Push-Pull,  Digital
    ; P0.2  -  Unassigned,  Push-Pull,  Digital
    ; P0.3  -  Unassigned,  Push-Pull,  Digital
    ; P0.4  -  Unassigned,  Push-Pull,  Digital
    ; P0.5  -  Unassigned,  Push-Pull,  Digital
    ; P0.6  -  Unassigned,  Push-Pull,  Digital
    ; P0.7  -  Unassigned,  Push-Pull,  Digital

    ; P1.0  -  Unassigned,  Push-Pull,  Digital (Column Output)
    ; P1.1  -  Unassigned,  Push-Pull,  Digital (Column Output)
    ; P1.2  -  Unassigned,  Push-Pull,  Digital (Column Output)
    ; P1.3  -  Unassigned,  Push-Pull,  Digital (Column Output)
    ; P1.4  -  Unassigned,  Open-Drain, Digital (Row Input)
    ; P1.5  -  Unassigned,  Open-Drain, Digital (Row Input)
    ; P1.6  -  Unassigned,  Open-Drain, Digital (Row Input)
    ; P1.7  -  Unassigned,  Open-Drain, Digital (Row Input)

    ; P2.0  -  Unassigned,  Push-Pull,  Digital
    ; P2.1  -  Unassigned,  Push-Pull,  Digital
    ; P2.2  -  Unassigned,  Push-Pull,  Digital
    ; P2.3  -  Unassigned,  Push-Pull,  Digital
    ; P2.4  -  Unassigned,  Push-Pull,  Digital
    ; P2.5  -  Unassigned,  Push-Pull,  Digital
    ; P2.6  -  Unassigned,  Push-Pull,  Digital
    ; P2.7  -  Unassigned,  Push-Pull,  Digital

    ; P3.0  -  Unassigned,  Push-Pull,  Digital
    ; P3.1  -  Unassigned,  Push-Pull,  Digital
    ; P3.2  -  Unassigned,  Push-Pull,  Digital
    ; P3.3  -  Unassigned,  Push-Pull,  Digital
    ; P3.4  -  Unassigned,  Push-Pull,  Digital
    ; P3.5  -  Unassigned,  Push-Pull,  Digital
    ; P3.6  -  Unassigned,  Push-Pull,  Digital
    ; P3.7  -  Unassigned,  Push-Pull,  Digital

    mov  P0MDOUT,   #0FFh
    mov  P1MDOUT,   #00Fh  ; P1.3-P1.0 Push-Pull (Column), P1.7-P1.4 Open-Drain (Row Input)
    mov  P2MDOUT,   #0FFh
    mov  P3MDOUT,   #0FFh
	mov  P74OUT,    #0FFh
    mov  XBR2,      #040h
    
    ; Configure External Memory Interface to release P2/P3 for GPIO
    mov  EMI0CF,    #000h  ; Disable EMIF, P2/P3 available as GPIO
    ret

; Initialization function for device,
; Call Init_Device from your main program

Init_Device:
    lcall Reset_Sources_Init
	lcall Port_IO_Init
    lcall Timer_Init
    lcall Oscillator_Init
    ret

end
