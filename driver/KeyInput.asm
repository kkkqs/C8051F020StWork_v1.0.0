KBI SEGMENT CODE
rseg KBI
PUBLIC KeyInput_Process

; 需要调用底层矩阵键扫描接口
EXTRN CODE(MatrixKey)

; KeyInput_Process:
;  - 调用 MatrixKey 得到当前键码 (返回在 A)
;  - 对比上一次样本 (存放在 044h)
;  - 使用 045h 做消抖计数 (稳定计数)
;  - 使用 046h 做已确认按键缓存
;  - 使用 047h/048h 与 060h/061h 与原逻辑保持一致（与 Timer0/Timer1 协作）

KeyInput_Process:
    LCALL MatrixKey
    CJNE A,044h, KBI_SAMPLE_CHANGED
    INC 045h
    SJMP KBI_AFTER_STABLE_CHECK

KBI_SAMPLE_CHANGED:
    MOV 044h, A
    MOV 045h, #01

KBI_AFTER_STABLE_CHECK:
    MOV A, 045h
    CJNE A, #03, KBI_RETURN
    MOV A, 046h
    CJNE A, 044h, KBI_CONF_CHANGED
    SJMP KBI_RETURN

KBI_CONF_CHANGED:
    MOV A, 044h
    MOV 046h, A
    MOV A, 048h
    CJNE A, #02h, KBI_CONF_CHECK_RELEASE
    MOV 047h, #00h
    MOV 048h, #00h
    SJMP KBI_RETURN

KBI_CONF_CHECK_RELEASE:
    MOV A, 044h
    CJNE A, #0FFh, KBI_CONF_PRESSED
    MOV A, 047h
    CLR C
    SUBB A, #064h
    JNC KBI_LONG_PRESS
    SJMP KBI_SHORT_PRESS

KBI_LONG_PRESS:
    MOV 047h, #00h
    MOV 048h, #00h
    SJMP KBI_RETURN

KBI_SHORT_PRESS:
    MOV 047h, #00h
    MOV 048h, #00h
    SJMP KBI_RETURN

KBI_CONF_PRESSED:
    MOV A, 044h
    ANL A, #0Fh
    MOV 060h, A
    MOV 061h, #01h
    MOV 047h, #00h
    MOV 048h, #00h

KBI_RETURN:
    RET

END
