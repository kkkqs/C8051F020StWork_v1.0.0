TMR0 SEGMENT CODE
rseg TMR0
PUBLIC Timer0_Init
PUBLIC TIMER0_ISR

Timer0_Init:
    ; 设置 Timer0 初始值（与 original main.ASM 保持一致）
    MOV TH0, #0D8h
    MOV TL0, #0F0h
    SETB TR0
    RET

TIMER0_ISR:
    PUSH PSW
    PUSH ACC
    PUSH B

    MOV TH0, #0D8h
    MOV TL0, #0F0h

    MOV A, 046h
    CJNE A, #0FFh, T0_KEY_HELD
    SJMP T0_EXIT

T0_KEY_HELD:
    MOV A, 047h
    CJNE A, #0FFh, T0_INC
    SJMP T0_EXIT
T0_INC:
    INC 047h
    MOV A, 047h
    CLR C
    SUBB A, #064h
    JNC T0_LONG_REACHED
    SJMP T0_EXIT

T0_LONG_REACHED:
    MOV A, 048h
    CJNE A, #00h, T0_EXIT
    MOV A, 060h
    ANL A, #0Fh
    ORL A, #080h
    MOV 060h, A
    MOV 061h, #01h
    MOV 048h, #02h
    MOV 047h, #064h
    SJMP T0_EXIT

T0_EXIT:
    POP B
    POP ACC
    POP PSW
    RETI

END
