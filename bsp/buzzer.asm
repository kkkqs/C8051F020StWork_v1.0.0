Buzzer_Segment SEGMENT CODE
RSEG Buzzer_Segment
$include (C8051F020.inc)

EXTRN CODE(Timer2_Init)
EXTRN CODE(Timer2_Start)
EXTRN CODE(Timer2_Stop)
EXTRN CODE(Timer2_Set_Reload)
PUBLIC Buzzer_Init
PUBLIC Buzzer_Start
PUBLIC Buzzer_Stop
PUBLIC Buzzer_Set_Frequency

Buzzer_Init:
    LCALL Timer2_Init
    RET

Buzzer_Start:
    LCALL Timer2_Start
    RET

Buzzer_Stop:
    LCALL Timer2_Stop
    RET

Buzzer_Set_Frequency:
    LCALL Timer2_Set_Reload
    RET

END
