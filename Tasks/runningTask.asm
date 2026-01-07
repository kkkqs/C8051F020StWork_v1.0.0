; Running task: handles RUN state logic moved from main.ASM
Running SEGMENT CODE
rseg Running

$INCLUDE (../user/config.inc)
$INCLUDE (../driver/LCD1602.inc)

EXTRN CODE(LED6_ApplyTable)

PUBLIC RunningTask_Init
PUBLIC RunningTask_Handler

; LCD Strings
LCD_MSG_INSIDE:
    DB 'I','n','s','i','d','e',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ', 00h
    LCD_MSG_WELCOME:
    DB 'W','e','l','c','o','m','e',' ',' ',' ',' ',' ',' ',' ',' ',' ', 00h
LCD_STR_OUT_PREFIX:
    DB 'O','u','t',':',' ', 00h
LCD_STR_UP:
    DB 'U','p',' ',' ', 00h
LCD_STR_DOWN:
    DB 'D','o','w','n', 00h
LCD_STR_EMPTY:
    DB ' ',' ',' ',' ', 00h

LCD_MSG_OPEN:
    DB ' ',' ',' ','o','p','e','n',' ','d','o','o','r',' ',' ',' ',' ', 00h
LCD_MSG_CLOSE:
    DB ' ',' ',' ','c','l','o','s','e',' ','d','o','o','r',' ',' ',' ', 00h
LCD_MSG_RUN:
    DB ' ',' ',' ','R','u','n','n','i','n','g','.','.','.',' ',' ',' ', 00h
LCD_MSG_FL:
    DB 'F','L',':',' ', 00h

; Initialize running task: set up elevator defaults
RunningTask_Init:
    MOV CUR_FLr, #01h      ; 默认 1楼
    MOV ONE_SEC_CNT, #00h
    MOV ELEV_TIMER, #00h
    MOV ELEV_TARGET, #01h
    
    ; Init Request Bitmaps (all clear)
    MOV INT_REQ_LO, #00h
    MOV INT_REQ_HI, #00h
    MOV EXT_UP_LO, #00h
    MOV EXT_UP_HI, #00h
    MOV EXT_DN_LO, #00h
    MOV EXT_DN_HI, #00h
    MOV ELEV_DIR, #00h     ; Stopped
    
    ; Init Input Mode
    MOV INPUT_MODE, #00h   ; Default Inside
    MOV OUT_SEL_VAL, #01h  ; Default selection
    
    ; Init LCD
    LCALL LCD_INIT
    LCALL LCD_CLEAR
    MOV DPTR, #LCD_MSG_WELCOME
    LCALL LCD_SHOW_STR
    RET

; Handler implements the RUN_HANDLER logic from main.ASM
RunningTask_Handler:
    ; Dispatcher: RUN or ELEV states
    MOV A, 070h
    CJNE A, #RUN_ST, CHECK_ELEV_RUN
    ; RUN state
    MOV A, 071h
    CJNE A, 070h, RT_INIT

    MOV A, 061h
    CJNE A, #00h, RT_HANDLE_KEY
    SJMP RT_MODE

RT_HANDLE_KEY:
    MOV A, 060h
    CJNE A, #08Ah, RT_HANDLE_OTHER
    MOV 070h, #PASS_ST
    MOV 061h, #00h
    SJMP RT_MODE

RT_HANDLE_OTHER:
    MOV 061h, #00h
    SJMP RT_MODE

RT_INIT:
    MOV A, 070h
    MOV 071h, A
    SJMP RT_MODE

RT_MODE:
    ; 检查配置是否完成 (050h!=10h 表示 OPT1 已设置)
    MOV A, 050h
    CJNE A, #010h, RT_CONFIG_DONE
    ; 未完成配置，显示空白等待
    MOV A, #01h
    LCALL LED6_ApplyTable
    MOV 039h, #04h
    RET
RT_CONFIG_DONE:
    ; 配置完成，切换到电梯待机状态
    MOV 070h, #ELEV_ST
    MOV 071h, #0FFh        ; 强制刷新
    RET

CHECK_ELEV_RUN:
    CJNE A, #ELEV_ST, CHECK_ELEV_RUN2
    LCALL ELEV_HANDLER
    RET
CHECK_ELEV_RUN2:
    CJNE A, #ELEV_RUN, CHECK_ELEV_ARR
    LCALL ELEV_RUN_HANDLER
    RET
CHECK_ELEV_ARR:
    CJNE A, #ELEV_ARRIVED, CHECK_ELEV_CLOSE
    LCALL ELEV_ARRIVED_HANDLER
    RET
CHECK_ELEV_CLOSE:
    CJNE A, #ELEV_CLOSE, RT_RETURN
    LCALL ELEV_CLOSE_HANDLER
    RET
RT_RETURN:
    RET

; --------------------
; Elevator handlers (ported from teammate code)
; Uses variables: CUR_FLr (056h), ELEV_TIMER (057h), ELEV_TARGET (058h), ONE_SEC_CNT (059h)
; --------------------

ELEV_HANDLER:
    MOV A, 071h
    CJNE A, 070h, ELEV_INIT
    
    ; 1. Check for new key input and set bitmap
    LCALL CHECK_AND_SET_REQUEST

    ; --- Added: Idle Open Logic ---
    ; Check Internal Open Key ('C')
    MOV A, 061h
    JZ EH_CHECK_CUR_FL
    MOV A, 060h
    ANL A, #0Fh
    CJNE A, #0Ch, EH_CHECK_CUR_FL
    ; 'C' pressed -> Open
    SJMP EH_OPEN_NOW

EH_CHECK_CUR_FL:
    ; Check request at current floor (Int/Ext)
    MOV R6, CUR_FLr
    LCALL CHECK_FLOOR_REQUEST
    JNC EH_SCAN
    ; Request at current floor -> Open
    LCALL CLEAR_FLOOR_REQUEST
    SJMP EH_OPEN_NOW
    ; ------------------------------

EH_OPEN_NOW:
    MOV 070h, #ELEV_ARRIVED
    MOV ELEV_TIMER, #05h
    MOV ONE_SEC_CNT, #00h
    MOV 071h, #0FFh
    RET

EH_SCAN:
    ; 2. Find next target using SCAN algorithm
    LCALL SCAN_FIND_NEXT_TARGET
    JNC ELEV_NO_REQ        ; No request, check wait/park
    
    ; R6 has target floor
    MOV A, R6
    
    ; Check if target == current
    CJNE A, CUR_FLr, ELEV_START_MOVE
    
    ; Target == Current -> Clear request and Open Door
    LCALL CLEAR_FLOOR_REQUEST  ; Clear request for R6
    SJMP EH_OPEN_NOW

ELEV_NO_REQ:
    ; No requests found. Check 5s Wait.
    MOV A, ELEV_TIMER
    JZ ELEV_CHECK_PARK     ; Timer expired (0) -> Check Parking
    MOV ELEV_DIR, #00h     ; Stay Idle
    RET

ELEV_START_MOVE:
    ; Target != Current -> Start Moving
    SJMP ELEV_DIFF

ELEV_CHECK_PARK:
    ; No requests: Decide Parking Floor (1 or 8) based on proximity
    ; Index 2 (Flr 1) vs Index 9 (Flr 8). Split at Floor 4/5.
    MOV R6, CUR_FLr
    LCALL FLOOR_TO_INDEX  ; R4 = Current Index
    MOV A, R4
    CJNE A, #06h, ECP_TEST
ECP_TEST:
    JNC ECP_GO_8          ; If A >= 6 (Floor 5+), Go Floor 8
    
    MOV R6, #01h          ; Else Go Floor 1
    SJMP ECP_EXEC
    
ECP_GO_8:
    MOV R6, #08h

ECP_EXEC:
    MOV A, R6
    CJNE A, CUR_FLr, ECP_MOVE
    ; Already at parking floor -> Idle
    MOV ELEV_DIR, #00h
    RET
ECP_MOVE:
    ; Not at parking floor -> Move to target (R6)
    SJMP ELEV_DIFF

ELEV_INIT:
    MOV A, 070h
    MOV 071h, A
    LCALL LCD_CLEAR
    LCALL SHOW_OPEN_FLOOR
    RET

ELEV_DIFF:
    MOV ELEV_TARGET, R6
    
    ; Determine direction using Index comparison (avoids signed number issues)
    ; Convert Target to Index
    PUSH 06h              ; Save R6
    LCALL FLOOR_TO_INDEX
    MOV A, R4
    MOV R3, A             ; R3 = Target Index
    
    ; Convert Current to Index
    MOV R6, CUR_FLr
    LCALL FLOOR_TO_INDEX  ; R4 = Current Index
    POP 06h               ; Restore R6 (Target Floor)
    
    ; Compare: if Target Index > Current Index, go up
    MOV A, R3
    CLR C
    SUBB A, R4            ; A = Target Index - Current Index
    JC E_GO_DOWN
    JZ E_GO_DOWN          ; Should not happen, but safety
    ; Go Up
    MOV ELEV_DIR, #01h
    MOV R5, #35           ; 'U'
    MOV ELEV_TIMER, A     ; Travel time = index difference
    SJMP E_START
E_GO_DOWN:
    MOV ELEV_DIR, #02h
    MOV R5, #13           ; 'd'
    ; Calculate travel time = Current Index - Target Index
    MOV A, R4
    CLR C
    SUBB A, R3
    MOV ELEV_TIMER, A
    
E_START:
    MOV 070h, #ELEV_RUN
    MOV 061h, #00h
    
    ; LCD Update
    LCALL LCD_CLEAR
    MOV DPTR, #LCD_MSG_RUN
    LCALL LCD_SHOW_STR
    
    MOV 028h, R5           ; Dir
    MOV 029h, #37          ; Space
    
    LCALL UPDATE_CUR_DISPLAY
    LCALL UPDATE_TGT_DISPLAY
    
    RET

ELEV_RUN_HANDLER:
    ; Running display handled by buffer written in E_START
    MOV A, 071h
    CJNE A, 070h, ER_INIT
    
    ; Update Display with CUR_FLr (Dynamic Update)
    LCALL UPDATE_CUR_DISPLAY

    ; Check if we should stop at current floor (途中停靠)
    MOV R6, CUR_FLr
    LCALL CHECK_FLOOR_REQUEST
    JNC ER_CHK_INT_KEY     ; No request at current floor
    
    ; There's a request at current floor!
    ; Clear the request
    MOV R6, CUR_FLr
    LCALL CLEAR_FLOOR_REQUEST
    
    ; Transition to Arrived
    MOV 070h, #ELEV_ARRIVED
    MOV ELEV_TIMER, #05h
    MOV ONE_SEC_CNT, #00h
    MOV 071h, #0FFh
    RET

ER_CHK_INT_KEY:
    ; Listen for new keys
    LCALL CHECK_AND_SET_REQUEST
    RET

ER_INIT:
    MOV A, 070h
    MOV 071h, A
    RET

ELEV_ARRIVED_HANDLER:
    MOV A, 071h
    CJNE A, 070h, EA_INIT
    
    ; Check D key (Close)
    MOV A, 061h
    JZ EA_CHECK_REQ
    MOV A, 060h
    ANL A, #0Fh
    CJNE A, #0Dh, EA_CHECK_REQ
    ; D pressed -> Close
    MOV 070h, #ELEV_CLOSE
    MOV ELEV_TIMER, #02h
    MOV ONE_SEC_CNT, #00h
    MOV 071h, #0FFh
    MOV 061h, #00h
    RET

EA_CHECK_REQ:
    ; Check for floor keys to set bitmap
    LCALL CHECK_AND_SET_REQUEST
    SJMP EA_BLINK_LOGIC

EA_BLINK_LOGIC:
    MOV A, ONE_SEC_CNT
    CLR C
    SUBB A, #50
    JNC EA_OFF
    ; ON
    MOV 028h, #20          ; '0.'
    MOV 029h, #17          ; 'P.'
    SJMP EA_TAIL
EA_OFF:
    ; OFF
    MOV 028h, #37          ; ' '
    MOV 029h, #37          ; ' '
EA_TAIL:
    MOV 02Ah, #37          ; ' '
    MOV 02Bh, #37          ; ' '
    MOV A, CUR_FLr
    JB ACC.7, ARR_NEG
    MOV 02Ch, #37          ; ' '
    MOV 02Dh, CUR_FLr
    RET
ARR_NEG:
    MOV 02Ch, #36          ; '-'
    MOV A, CUR_FLr
    CPL A
    INC A
    MOV 02Dh, A
    RET
EA_INIT:
    MOV A, 070h
    MOV 071h, A
    
    ; Clear request for current floor (arrived at target)
    MOV R6, CUR_FLr
    LCALL CLEAR_FLOOR_REQUEST
    
    ; LCD Update
    LCALL LCD_CLEAR
    MOV DPTR, #LCD_MSG_OPEN
    LCALL LCD_SHOW_STR
    
    RET

ELEV_CLOSE_HANDLER:
    MOV A, 071h
    CJNE A, 070h, EC_INIT
    
    ; Check C key (Reopen) or Current Floor Key
    MOV A, 061h
    JZ EC_CHECK_REQ
    MOV A, 060h
    ANL A, #0Fh
    CJNE A, #0Ch, EC_CHECK_CUR
    ; C pressed -> Reopen
    SJMP EC_REOPEN
EC_CHECK_CUR:
    CJNE A, CUR_FLr, EC_CHECK_REQ
    ; Current Floor pressed -> Reopen
EC_REOPEN:
    MOV 070h, #ELEV_ARRIVED
    MOV ELEV_TIMER, #05h
    MOV ONE_SEC_CNT, #00h
    MOV 071h, #0FFh
    MOV 061h, #00h
    RET

EC_CHECK_REQ:
    LCALL CHECK_AND_SET_REQUEST
    SJMP EC_BLINK_LOGIC

EC_BLINK_LOGIC:
    MOV A, ONE_SEC_CNT
    CLR C
    SUBB A, #50
    JNC EC_OFF
    ; ON
    MOV 028h, #12          ; 'C'
    MOV 029h, #19          ; 'L'
    SJMP EC_TAIL
EC_OFF:
    MOV 028h, #37
    MOV 029h, #37
EC_TAIL:
    MOV 02Ah, #37
    MOV 02Bh, #37
    MOV 02Ch, #37
    MOV 02Dh, #37
    RET
EC_INIT:
    MOV A, 070h
    MOV 071h, A
    ; MOV P2, #00h           ; Closing: LEDs ON (Removed for LCD compatibility)
    
    ; LCD Update
    LCALL LCD_CLEAR
    MOV DPTR, #LCD_MSG_CLOSE
    LCALL LCD_SHOW_STR
    
    RET

; Show open floor helper (Now shows FL + Floor for Idle)
SHOW_OPEN_FLOOR:
    LCALL LCD_CLEAR ; Ensure clear
    
    ; Line 1: Welcome
    MOV A, #80h
    LCALL LCD_WR_CMD
    MOV DPTR, #LCD_MSG_WELCOME
    LCALL LCD_SHOW_STR

    ; Line 2: FL: [Floor]
    MOV A, #0C0h
    LCALL LCD_WR_CMD
    MOV DPTR, #LCD_MSG_FL
    LCALL LCD_SHOW_STR
    MOV R6, CUR_FLr
    LCALL LCD_PRINT_FLOOR
    
    ; LED6 Update
    MOV 028h, #15          ; 'F'
    MOV 029h, #19          ; 'L'
    MOV 02Ah, #37          ; ' '
    MOV 02Bh, #37          ; ' '
    MOV A, CUR_FLr
    JB ACC.7, SOF_NEG
    MOV 02Ch, #37          ; ' '
    MOV 02Dh, CUR_FLr
    RET
SOF_NEG:
    MOV 02Ch, #36          ; '-'
    MOV A, CUR_FLr
    CPL A
    INC A
    MOV 02Dh, A
    RET

; ---------------------------------------------------------
; Queue Helper Functions
; ---------------------------------------------------------

; Check if key is floor key (0-9), if so push to queue
; Mapping:
; Key 0 -> Floor -2 (FEh)
; Key 1 -> Floor -1 (FFh)
; Key 2 -> Floor 1  (01h)
; ...
; Key 9 -> Floor 8  (08h)
; Key E (14) -> External Up (Push CUR_FLr to EXT_Q)
; Key F (15) -> External Down (Push CUR_FLr to EXT_Q)
; Helper to map Key (R7) to Floor (R6). CY=1 if valid.
GET_FLOOR_FROM_KEY:
    MOV A, R7
    CLR C
    SUBB A, #0Ah
    JNC GFK_INVALID      ; If Key >= 10, return CY=0

    ; Key is 0-9
    MOV A, R7
    JZ GFK_KEY_0     ; If Key == 0
    
    DEC A            ; A = Key - 1
    JZ GFK_KEY_1     ; If Key == 1 (A became 0)
    
    ; Key >= 2, Target = Key - 1
    MOV R6, A
    SETB C
    RET

GFK_KEY_0:
    MOV R6, #0FEh    ; -2
    SETB C
    RET

GFK_KEY_1:
    MOV R6, #0FFh    ; -1
    SETB C
    RET

GFK_INVALID:
    CLR C
    RET

; Helper to print Floor Number (R6) to LCD at current cursor
LCD_PRINT_FLOOR:
    MOV A, R6
    JB ACC.7, LPF_NEG
    ; Positive
    MOV A, #' '
    LCALL LCD_WR_DAT
    MOV A, R6
    ADD A, #'0'
    LCALL LCD_WR_DAT
    RET
LPF_NEG:
    MOV A, #'-'
    LCALL LCD_WR_DAT
    MOV A, R6
    CPL A
    INC A
    ADD A, #'0'
    LCALL LCD_WR_DAT
    RET

; Helper to show Outside Status
; R6 = Floor, R5 = Action (0=None, 1=Up, 2=Down)
SHOW_OUTSIDE_STATUS:
    MOV A, #80h
    LCALL LCD_WR_CMD
    
    MOV DPTR, #LCD_STR_OUT_PREFIX
    LCALL LCD_SHOW_STR
    
    LCALL LCD_PRINT_FLOOR
    
    MOV A, #' '
    LCALL LCD_WR_DAT
    
    MOV A, R5
    JZ SOS_NONE
    DEC A
    JZ SOS_UP
    ; Down
    MOV DPTR, #LCD_STR_DOWN
    LCALL LCD_SHOW_STR
    RET
SOS_UP:
    MOV DPTR, #LCD_STR_UP
    LCALL LCD_SHOW_STR
    RET
SOS_NONE:
    MOV DPTR, #LCD_STR_EMPTY
    LCALL LCD_SHOW_STR
    RET

CHECK_AND_SET_REQUEST:
    MOV A, 061h
    JZ CASR_RET
    MOV A, 060h
    ANL A, #0Fh
    MOV R7, A
    
    ; Check for 'A' (Mode Switch)
    CJNE R7, #0Ah, CASR_CHK_MODE
    
    ; Toggle Mode
    MOV A, INPUT_MODE
    XRL A, #01h
    MOV INPUT_MODE, A
    
    ; Update LCD
    MOV A, INPUT_MODE
    JZ CASR_SHOW_INSIDE
    
    ; Show Outside (Default Select)
    MOV R6, OUT_SEL_VAL
    MOV R5, #00h
    LCALL SHOW_OUTSIDE_STATUS
    SJMP CASR_CONSUME
    
CASR_SHOW_INSIDE:
    MOV A, #80h
    LCALL LCD_WR_CMD
    MOV DPTR, #LCD_MSG_INSIDE
    LCALL LCD_SHOW_STR
    SJMP CASR_CONSUME

CASR_CHK_MODE:
    MOV A, INPUT_MODE
    JNZ CASR_OUTSIDE_MODE
    
    ; --- INSIDE MODE ---
    ; Check 0-9
    LCALL GET_FLOOR_FROM_KEY
    JNC CASR_IN_CHK_OTHER
    ; Valid Floor in R6 -> Set Internal Bitmap
    LCALL SET_INT_REQUEST
    SJMP CASR_CONSUME
    
CASR_IN_CHK_OTHER:
    ; Check E/F -> Ignore
    CJNE R7, #0Eh, CASR_IN_CHK_F
    SJMP CASR_CONSUME
CASR_IN_CHK_F:
    CJNE R7, #0Fh, CASR_RET
    SJMP CASR_CONSUME

    ; --- OUTSIDE MODE ---
CASR_OUTSIDE_MODE:
    ; Check 0-9
    LCALL GET_FLOOR_FROM_KEY
    JNC CASR_OUT_CHK_OTHER
    ; Valid Floor -> Store selection
    MOV OUT_SEL_VAL, R6
    ; Update Display
    MOV R5, #00h
    LCALL SHOW_OUTSIDE_STATUS
    SJMP CASR_CONSUME

CASR_OUT_CHK_OTHER:
    ; Check E/F -> Set External Bitmap
    CJNE R7, #0Eh, CASR_OUT_CHK_F
    ; Key E (Up)
    MOV R6, OUT_SEL_VAL
    LCALL SET_EXT_UP_REQUEST
    MOV R5, #01h
    SJMP CASR_OUT_SHOW
CASR_OUT_CHK_F:
    CJNE R7, #0Fh, CASR_OUT_CHK_CD
    ; Key F (Down)
    MOV R6, OUT_SEL_VAL
    LCALL SET_EXT_DN_REQUEST
    MOV R5, #02h
    
CASR_OUT_SHOW:
    MOV R6, OUT_SEL_VAL
    LCALL SHOW_OUTSIDE_STATUS
    SJMP CASR_CONSUME

CASR_OUT_CHK_CD:
    ; Check C/D -> Consume (Ignore)
    CJNE R7, #0Ch, CASR_OUT_CHK_D
    SJMP CASR_CONSUME
CASR_OUT_CHK_D:
    CJNE R7, #0Dh, CASR_RET
    SJMP CASR_CONSUME

CASR_CONSUME:
    MOV 061h, #00h
CASR_RET:
    RET

; ---------------------------------------------------------
; Bitmap Helper Functions
; ---------------------------------------------------------

; Convert Floor (R6) to Bit Index (R4)
; Floor -2 -> Index 0, Floor -1 -> Index 1
; Floor 1 -> Index 2, Floor 2 -> Index 3, ... Floor 8 -> Index 10
; Returns: R4 = bit index (0-10)
FLOOR_TO_INDEX:
    MOV A, R6
    JB ACC.7, FTI_NEG
    ; Positive floor (1-8) -> Index = Floor + 1
    INC A
    MOV R4, A
    RET
FTI_NEG:
    ; Negative floor: -2 (FEh) -> 0, -1 (FFh) -> 1
    ; Index = Floor + 2
    ADD A, #02h
    MOV R4, A
    RET

; Convert Bit Index (R4) to Floor (R6)
INDEX_TO_FLOOR:
    MOV A, R4
    CJNE A, #00h, ITF_CHK1
    MOV R6, #0FEh   ; -2
    RET
ITF_CHK1:
    CJNE A, #01h, ITF_POS
    MOV R6, #0FFh   ; -1
    RET
ITF_POS:
    ; Index >= 2: Floor = Index - 1
    DEC A
    MOV R6, A
    RET

; Set bit for floor R6 in Internal Request bitmap
SET_INT_REQUEST:
    LCALL FLOOR_TO_INDEX
    ; R4 = bit index
    MOV A, R4
    CLR C
    SUBB A, #08h
    JNC SIR_HI
    ; Low byte (index 0-7)
    LCALL GET_BIT_MASK   ; R3 = mask for bit R4
    MOV A, INT_REQ_LO
    ORL A, R3
    MOV INT_REQ_LO, A
    RET
SIR_HI:
    ; High byte (index 8-10)
    MOV A, R4
    CLR C
    SUBB A, #08h
    MOV R4, A
    LCALL GET_BIT_MASK
    MOV A, INT_REQ_HI
    ORL A, R3
    MOV INT_REQ_HI, A
    RET

; Set bit for floor R6 in External UP Request bitmap
SET_EXT_UP_REQUEST:
    LCALL FLOOR_TO_INDEX
    MOV A, R4
    CLR C
    SUBB A, #08h
    JNC SEUR_HI
    LCALL GET_BIT_MASK
    MOV A, EXT_UP_LO
    ORL A, R3
    MOV EXT_UP_LO, A
    RET
SEUR_HI:
    MOV A, R4
    CLR C
    SUBB A, #08h
    MOV R4, A
    LCALL GET_BIT_MASK
    MOV A, EXT_UP_HI
    ORL A, R3
    MOV EXT_UP_HI, A
    RET

; Set bit for floor R6 in External DOWN Request bitmap
SET_EXT_DN_REQUEST:
    LCALL FLOOR_TO_INDEX
    MOV A, R4
    CLR C
    SUBB A, #08h
    JNC SEDR_HI
    LCALL GET_BIT_MASK
    MOV A, EXT_DN_LO
    ORL A, R3
    MOV EXT_DN_LO, A
    RET
SEDR_HI:
    MOV A, R4
    CLR C
    SUBB A, #08h
    MOV R4, A
    LCALL GET_BIT_MASK
    MOV A, EXT_DN_HI
    ORL A, R3
    MOV EXT_DN_HI, A
    RET

; Get bit mask for bit index R4 (0-7), return in R3
GET_BIT_MASK:
    MOV A, R4
    MOV DPTR, #BIT_MASK_TBL
    MOVC A, @A+DPTR
    MOV R3, A
    RET

BIT_MASK_TBL:
    DB 001h, 002h, 004h, 008h, 010h, 020h, 040h, 080h

; Clear request for floor R6 from all bitmaps
CLEAR_FLOOR_REQUEST:
    LCALL FLOOR_TO_INDEX
    MOV A, R4
    CLR C
    SUBB A, #08h
    JNC CFR_HI
    ; Low byte
    LCALL GET_BIT_MASK
    MOV A, R3
    CPL A           ; Invert mask
    MOV R3, A
    MOV A, INT_REQ_LO
    ANL A, R3
    MOV INT_REQ_LO, A
    MOV A, EXT_UP_LO
    ANL A, R3
    MOV EXT_UP_LO, A
    MOV A, EXT_DN_LO
    ANL A, R3
    MOV EXT_DN_LO, A
    RET
CFR_HI:
    MOV A, R4
    CLR C
    SUBB A, #08h
    MOV R4, A
    LCALL GET_BIT_MASK
    MOV A, R3
    CPL A
    MOV R3, A
    MOV A, INT_REQ_HI
    ANL A, R3
    MOV INT_REQ_HI, A
    MOV A, EXT_UP_HI
    ANL A, R3
    MOV EXT_UP_HI, A
    MOV A, EXT_DN_HI
    ANL A, R3
    MOV EXT_DN_HI, A
    RET

; Check if there's any request at floor R6
; Returns CY=1 if request exists
CHECK_FLOOR_REQUEST:
    LCALL FLOOR_TO_INDEX
    MOV A, R4
    CLR C
    SUBB A, #08h
    JNC CHKFR_HI
    
    ; Low Byte
    LCALL GET_BIT_MASK
    ; Check Internal
    MOV A, INT_REQ_LO
    ANL A, R3
    JNZ CHKFR_FOUND
    
    ; Check External - Dir dependent
    MOV A, ELEV_DIR
    CJNE A, #02h, CFR_LO_CHK_UP  ; If Dir != 2 (0 or 1), check UP
    SJMP CFR_LO_CHK_DN           ; If Dir == 2, check DOWN only
    
CFR_LO_CHK_UP:
    MOV A, EXT_UP_LO
    ANL A, R3
    JNZ CHKFR_FOUND
    
    ; If Dir=1 (Up), we are done (don't check down)
    MOV A, ELEV_DIR
    CJNE A, #00h, CHKFR_NOTFOUND ; If Dir != 0 (i.e. 1), Ret Not Found
    
    ; If Dir=0, Fall through to check DOWN
    
CFR_LO_CHK_DN:
    MOV A, EXT_DN_LO
    ANL A, R3
    JNZ CHKFR_FOUND
    SJMP CHKFR_NOTFOUND
    
CHKFR_HI:
    ; High Byte adjustment logic
    MOV A, R4
    CLR C
    SUBB A, #08h
    MOV R4, A
    LCALL GET_BIT_MASK
    
    ; Check Internal
    MOV A, INT_REQ_HI
    ANL A, R3
    JNZ CHKFR_FOUND
    
    ; Check External
    MOV A, ELEV_DIR
    CJNE A, #02h, CFR_HI_CHK_UP
    SJMP CFR_HI_CHK_DN
    
CFR_HI_CHK_UP:
    MOV A, EXT_UP_HI
    ANL A, R3
    JNZ CHKFR_FOUND
    
    MOV A, ELEV_DIR
    CJNE A, #00h, CHKFR_NOTFOUND
    
CFR_HI_CHK_DN:
    MOV A, EXT_DN_HI
    ANL A, R3
    JNZ CHKFR_FOUND
    SJMP CHKFR_NOTFOUND
    
CHKFR_NOTFOUND:
    CLR C
    RET
CHKFR_FOUND:
    SETB C
    RET

; ---------------------------------------------------------
; SCAN Algorithm: Find next target floor
; Returns: R6 = target floor, CY=1 if found, CY=0 if no request
; ---------------------------------------------------------
SCAN_FIND_NEXT_TARGET:
    ; First check if any request exists
    MOV A, INT_REQ_LO
    ORL A, INT_REQ_HI
    ORL A, EXT_UP_LO
    ORL A, EXT_UP_HI
    ORL A, EXT_DN_LO
    ORL A, EXT_DN_HI
    JNZ SCAN_HAS_REQ
    CLR C
    RET

SCAN_HAS_REQ:
    ; Get current floor index
    MOV R6, CUR_FLr
    LCALL FLOOR_TO_INDEX
    MOV A, R4
    MOV R5, A         ; R5 = current index
    
    ; R2 = tried flags: bit0=tried up, bit1=tried down
    MOV R2, #00h
    
    ; Check direction: if stopped (0), default to up (1)
    MOV A, ELEV_DIR
    JZ SCAN_DEFAULT_UP
    CJNE A, #02h, SCAN_TRY_UP
    SJMP SCAN_TRY_DOWN
    
SCAN_DEFAULT_UP:
    MOV ELEV_DIR, #01h   ; Default direction up

SCAN_TRY_UP:
    ; Mark that we tried up
    MOV A, R2
    ORL A, #01h
    MOV R2, A
    
    ; Try to find request above or at current floor
    MOV A, R5
    MOV R4, A         ; Start from current index
SCAN_UP_LOOP:
    ; Check if there's request at R4
    LCALL INDEX_TO_FLOOR
    MOV A, R6
    CJNE A, CUR_FLr, SCAN_UP_CHK
    SJMP SCAN_UP_NEXT  ; Skip current floor
SCAN_UP_CHK:
    LCALL SCAN_CHECK_UP_REQUEST
    JC SCAN_FOUND
SCAN_UP_NEXT:
    INC R4
    MOV A, R4
    CJNE A, #11, SCAN_UP_LOOP
    
    ; No request above, check if we already tried down
    MOV A, R2
    ANL A, #02h
    JNZ SCAN_FAIL       ; Already tried down
    
    ; Switch to down
    MOV ELEV_DIR, #02h
    ; Fall through to SCAN_TRY_DOWN

SCAN_TRY_DOWN:
    ; Mark that we tried down
    MOV A, R2
    ORL A, #02h
    MOV R2, A
    
    ; Try to find request below current floor
    MOV A, R5
    MOV R4, A         ; Start from current index
SCAN_DN_LOOP:
    MOV A, R4
    JZ SCAN_DN_DONE   ; Reached bottom
    DEC R4
    LCALL INDEX_TO_FLOOR
    LCALL SCAN_CHECK_DN_REQUEST
    JC SCAN_FOUND
    SJMP SCAN_DN_LOOP

SCAN_DN_DONE:
    ; No request below, check if we already tried up
    MOV A, R2
    ANL A, #01h
    JNZ SCAN_FAIL       ; Already tried up
    
    ; Switch to up
    MOV ELEV_DIR, #01h
    SJMP SCAN_TRY_UP

SCAN_FAIL:
    MOV ELEV_DIR, #00h   ; Reset direction
    CLR C
    RET

SCAN_FOUND:
    ; R6 has the target floor
    SETB C
    RET

; Check if floor R6 has request for UP direction
; (Internal or External UP)
SCAN_CHECK_UP_REQUEST:
    PUSH 04h
    LCALL FLOOR_TO_INDEX
    MOV A, R4
    CLR C
    SUBB A, #08h
    JNC SCUR_HI
    LCALL GET_BIT_MASK
    ; Always check Internal
    MOV A, INT_REQ_LO
    ANL A, R3
    JNZ SCUR_FOUND
    ; Also check External UP
    MOV A, EXT_UP_LO
    ANL A, R3
    JNZ SCUR_FOUND
    SJMP SCUR_NOTFOUND
SCUR_HI:
    MOV A, R4
    CLR C
    SUBB A, #08h
    MOV R4, A
    LCALL GET_BIT_MASK
    MOV A, INT_REQ_HI
    ANL A, R3
    JNZ SCUR_FOUND
    MOV A, EXT_UP_HI
    ANL A, R3
    JNZ SCUR_FOUND
SCUR_NOTFOUND:
    POP 04h
    CLR C
    RET
SCUR_FOUND:
    POP 04h
    SETB C
    RET

; Check if floor R6 has request for DOWN direction
; (Internal or External DOWN)
SCAN_CHECK_DN_REQUEST:
    PUSH 04h
    LCALL FLOOR_TO_INDEX
    MOV A, R4
    CLR C
    SUBB A, #08h
    JNC SCDR_HI
    LCALL GET_BIT_MASK
    ; Always check Internal
    MOV A, INT_REQ_LO
    ANL A, R3
    JNZ SCDR_FOUND
    ; Also check External DOWN
    MOV A, EXT_DN_LO
    ANL A, R3
    JNZ SCDR_FOUND
    SJMP SCDR_NOTFOUND
SCDR_HI:
    MOV A, R4
    CLR C
    SUBB A, #08h
    MOV R4, A
    LCALL GET_BIT_MASK
    MOV A, INT_REQ_HI
    ANL A, R3
    JNZ SCDR_FOUND
    MOV A, EXT_DN_HI
    ANL A, R3
    JNZ SCDR_FOUND
SCDR_NOTFOUND:
    POP 04h
    CLR C
    RET
SCDR_FOUND:
    POP 04h
    SETB C
    RET

; ---------------------------------------------------------
; Display Helpers
; ---------------------------------------------------------

; Update Current Floor at 02Ah/02Bh
UPDATE_CUR_DISPLAY:
    MOV A, CUR_FLr
    JB ACC.7, UCD_NEG
    MOV 02Ah, #37      ; Space
    MOV 02Bh, CUR_FLr
    RET
UCD_NEG:
    MOV 02Ah, #36      ; '-'
    MOV A, CUR_FLr
    CPL A
    INC A
    MOV 02Bh, A
    RET

; Update Target Floor at 02Ch/02Dh
UPDATE_TGT_DISPLAY:
    MOV A, ELEV_TARGET
    JB ACC.7, UTD_NEG
    MOV 02Ch, #37      ; Space
    MOV 02Dh, ELEV_TARGET
    RET
UTD_NEG:
    MOV 02Ch, #36      ; '-'
    MOV A, ELEV_TARGET
    CPL A
    INC A
    MOV 02Dh, A
    RET

END
