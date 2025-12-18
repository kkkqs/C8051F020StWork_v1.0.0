TMR1 SEGMENT CODE
rseg TMR1

EXTRN CODE(LED6_Refresh)

PUBLIC Timer1_Init
PUBLIC TIMER1_ISR

Timer1_Init:
    ; 设置 Timer1 及通用定时器配置（与原 main.ASM 的配置一致）
    MOV TMOD, #011h
    MOV TH1, #0FCh
    MOV TL1, #018h
    ; 配置中断使能（保留原设置）
    MOV IE,  #08Ah
    SETB TR1
    RET

TIMER1_ISR:
    PUSH PSW
    PUSH ACC
    PUSH B
    PUSH DPL
    PUSH DPH
    PUSH 00h
    PUSH 01h

    MOV TH1, #0FCh
    MOV TL1, #018h

    ; 调用驱动中的显示刷新例程（在 driver/LED6.asm 中实现）
    LCALL LED6_Refresh

T1_ISR_EXIT:
    POP 01h
    POP 00h
    POP DPH
    POP DPL
    POP B
    POP ACC
    POP PSW
    RETI

END
