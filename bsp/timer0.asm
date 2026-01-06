TMR0 SEGMENT CODE
rseg TMR0
$include (C8051F020.inc)	
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
    SJMP T0_ELEV_TIMING

T0_KEY_HELD:
    MOV A, 047h
    CJNE A, #0FFh, T0_INC
    SJMP T0_ELEV_TIMING
T0_INC:
    INC 047h
    MOV A, 047h
    CLR C
    SUBB A, #064h
    JNC T0_LONG_REACHED
    SJMP T0_ELEV_TIMING

T0_LONG_REACHED:
    MOV A, 048h
    CJNE A, #00h, T0_ELEV_TIMING
    MOV A, 060h
    ANL A, #0Fh
    ORL A, #080h
    MOV 060h, A
    MOV 061h, #01h
    MOV 048h, #02h
    MOV 047h, #064h
    SJMP T0_ELEV_TIMING

T0_ELEV_TIMING:
    ; 电梯计时：仅在 ELEV_RUN/ELEV_ARRIVED/ELEV_CLOSE 状态下执行
    MOV A, 070h
    CJNE A, #021h, T0_CHK_ARR    ; ELEV_RUN = 21h
    SJMP T0_DO_TIMING
T0_CHK_ARR:
    CJNE A, #022h, T0_CHK_CLS    ; ELEV_ARRIVED = 22h
    SJMP T0_DO_TIMING
T0_CHK_CLS:
    CJNE A, #023h, T0_EXIT       ; ELEV_CLOSE = 23h

T0_DO_TIMING:
    INC 059h                     ; ONE_SEC_CNT++
    MOV A, 059h
    CJNE A, #100, T0_EXIT        ; 100 * 10ms = 1s
    MOV 059h, #00h
    MOV A, 057h                  ; ELEV_TIMER
    JZ T0_TIME_UP_HANDLE
    DEC 057h
    
    ; --- Update CUR_FLr if in RUN state ---
    MOV A, 070h
    CJNE A, #021h, T0_CHK_TIMER_NZ ; Only update floor in ELEV_RUN
    
    ; Check Direction (028h stores Index: 'U'=35, 'd'=13)
    MOV A, 028h
    CJNE A, #35, T0_CHK_DOWN
    ; UP
    MOV A, 056h ; CUR_FLr
    INC A
    CJNE A, #00h, T0_UPD_FLR
    MOV A, #01h ; Skip 0
    SJMP T0_UPD_FLR
    
T0_CHK_DOWN:
    CJNE A, #13, T0_CHK_TIMER_NZ
    ; DOWN
    MOV A, 056h ; CUR_FLr
    DEC A
    CJNE A, #00h, T0_UPD_FLR
    MOV A, #0FFh ; Skip 0

T0_UPD_FLR:
    MOV 056h, A ; Update CUR_FLr

T0_CHK_TIMER_NZ:
    MOV A, 057h
    JNZ T0_EXIT

T0_TIME_UP_HANDLE:
    MOV A, 070h
    CJNE A, #021h, T0_CHK_END_ARR  ; ELEV_RUN
    ; 运行结束 -> 开门 (5s)
    MOV 070h, #022h              ; ELEV_ARRIVED
    MOV 057h, #05h               ; ELEV_TIMER = 5
    MOV 059h, #00h
    MOV A, 058h                  ; ELEV_TARGET
    MOV 056h, A                  ; CUR_FLr = TARGET
    MOV 071h, #0FFh              ; 强制刷新
    SJMP T0_EXIT

T0_CHK_END_ARR:
    CJNE A, #022h, T0_CHK_END_CLS  ; ELEV_ARRIVED
    ; 开门结束 -> 关门 (2s)
    MOV 070h, #023h              ; ELEV_CLOSE
    MOV 057h, #02h
    MOV 059h, #00h
    MOV 071h, #0FFh
    SJMP T0_EXIT

T0_CHK_END_CLS:
    ; 关门结束 -> 待机
    MOV 070h, #020h              ; ELEV_ST
    MOV 071h, #0FFh
    SJMP T0_EXIT

T0_EXIT:
    POP B
    POP ACC
    POP PSW
    RETI

END
