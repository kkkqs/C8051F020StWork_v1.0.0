; Configuration task: handles OPT, OPT1, OPT2, OPT3 and PASS flows
Configuration SEGMENT CODE
rseg Configuration

$INCLUDE (../user/config.inc)
$INCLUDE (../driver/LCD1602.inc)

EXTRN CODE(LED6_ApplyTable)
EXTRN CODE(InputTask_03B)
EXTRN CODE(InputTask_039)

PUBLIC ConfigurationTask_Init
PUBLIC ConfigurationTask_Handler

LCD_MSG_CONFIG:
    DB 'C','o','n','f','i','g','u','r','a','t','i','n','g',' ',' ',' ', 00h

; Entry: call ConfigurationTask_Init at startup
ConfigurationTask_Init:
    ; 閸掓繂顫愰崠鏍帳缂冾喖寮弫棰佽礋缁岀儤鐖ｇ拋锟� 0x10
    MOV 050h, #010h
    MOV 051h, #010h
    MOV 052h, #010h
    MOV 053h, #010h
    MOV 054h, #010h

    ; Copy Default Password from TABLE to RAM (CURRENT_PASS)
    MOV DPTR, #PASSWORD_TABLE
    MOV R0, #CURRENT_PASS
    MOV R7, #05h
PASS_COPY_LOOP:
    CLR A
    MOVC A, @A+DPTR
    MOV @R0, A
    INC DPTR
    INC R0
    DJNZ R7, PASS_COPY_LOOP

    RET

; Entry: handles any configuration-related state when called from main
ConfigurationTask_Handler:
    MOV A, 070h
    CJNE A, #OPT_ST, CHECK_OPT1
    LCALL CONF_MAIN_HANDLER
    RET
CHECK_OPT1:
    CJNE A, #OPT1_ST, CHECK_OPT2
    LCALL CONF_OPT1_HANDLER
    RET
CHECK_OPT2:
    CJNE A, #OPT2_ST, CHECK_OPT3
    LCALL CONF_OPT2_HANDLER
    RET
CHECK_OPT3:
    CJNE A, #OPT3_ST, CHECK_PASS
    LCALL CONF_OPT3_HANDLER
    RET
CHECK_PASS:
    CJNE A, #PASS_ST, CONF_DEFAULT
    LCALL CONF_PASS_HANDLER
    RET
CONF_DEFAULT:
    ; default: show OPT menu
    LCALL CONF_MAIN_HANDLER
    RET

; OPT handler (show menu)
CONF_MAIN_HANDLER:
    MOV A, 071h
    CJNE A, 070h, CONF_INIT
    SJMP CONF_MODE

CONF_INIT:
    MOV A, 070h
    MOV 071h, A
    LCALL LCD_CLEAR
    MOV DPTR, #LCD_MSG_CONFIG
    LCALL LCD_SHOW_STR
    SJMP CONF_MODE

CONF_MODE:
    MOV A, #02h
    LCALL LED6_ApplyTable
    SJMP CONF_MODE_KEYS

CONF_MODE_KEYS:
    ; 婵″倹鐏夐張澶嬪瘻闁款喕绨ㄦ禒璁圭礉婢跺嫮鎮婇懣婊冨礋闁瀚� 1/2/3/A
    MOV A, 061h
    CJNE A, #00h, CONF_MODE_CHECK_KEY
    RET
CONF_MODE_CHECK_KEY:
    MOV A, 060h
    ANL A, #0Fh
    CJNE A, #01h, CONF_MODE_CHECK_2
    MOV 070h, #OPT1_ST
    MOV 061h, #00h
    RET
CONF_MODE_CHECK_2:
    CJNE A, #02h, CONF_MODE_CHECK_3
    MOV 070h, #OPT2_ST
    MOV 061h, #00h
    RET
CONF_MODE_CHECK_3:
    CJNE A, #03h, CONF_MODE_CHECK_A
    MOV 070h, #OPT3_ST
    MOV 061h, #00h
    RET
CONF_MODE_CHECK_A:
    CJNE A, #0Ah, CONF_MODE_IGNORE
    LCALL CONF_CHECK_COMPLETION
    RET
CONF_MODE_IGNORE:
    MOV 061h, #00h
    RET

CONF_CHECK_COMPLETION:
    MOV 061h, #00h ; Clear key
    ; Check 050h..054h
    MOV A, 050h
    CJNE A, #010h, CCC_51
    SJMP CCC_ERROR
CCC_51:
    MOV A, 051h
    CJNE A, #010h, CCC_52
    SJMP CCC_ERROR
CCC_52:
    MOV A, 052h
    CJNE A, #010h, CCC_53
    SJMP CCC_ERROR
CCC_53:
    MOV A, 053h
    CJNE A, #010h, CCC_54
    SJMP CCC_ERROR
CCC_54:
    MOV A, 054h
    CJNE A, #010h, CCC_OK
    SJMP CCC_ERROR

CCC_OK:
    MOV 070h, #RUN_ST
    RET

CCC_ERROR:
    ; Show Error (Table 03h - Err011)
    MOV A, #03h
    LCALL LED6_ApplyTable
    
    MOV R3, #26h
CCC_DELAY_OUTER:
    MOV R4, #0F0h
CCC_DELAY_LOOP:
    MOV R5, #0FFh
CCC_DELAY_INNER:
    NOP
    NOP
    NOP
    DJNZ R5, CCC_DELAY_INNER
    DJNZ R4, CCC_DELAY_LOOP
    DJNZ R3, CCC_DELAY_OUTER
    RET

; --------------------
; OPT1
; --------------------
CONF_OPT1_HANDLER:
    MOV A, 071h
    CJNE A, 070h, CONF_OPT1_INIT
    MOV A, 061h
    CJNE A, #00h, CONF_OPT1_INPUT_HANDLE_KEY
    SJMP CONF_OPT1_INPUT_MODE

CONF_OPT1_INPUT_MODE:
    RET

CONF_OPT1_INPUT_HANDLE_KEY:
    MOV 020h, #02h
    MOV 021h, #03h
    LCALL InputTask_03B
    CJNE A, #0Ah, CONF_OPT1_INPUT_DONE
    ; fall through to CONF_OPT1_INPUT_CHECK_CONFIRM
    LCALL CONF_OPT1_INPUT_CHECK_CONFIRM
    RET

CONF_OPT1_INPUT_DEC:
    DEC 03Bh

CONF_OPT1_INPUT_DONE:
    MOV 061h, #00h
    RET

CONF_OPT1_INPUT_BACKSPACE_LIMIT:
    MOV 03Bh, #02h
    MOV A, 03Bh
    ADD A, #028h
    MOV R0, A
    MOV @R0, #010h
    MOV 061h, #00h
    RET

CONF_OPT1_INPUT_CHECK_CONFIRM:
    MOV A, 060h
    CJNE A, #0Ah, CONF_OPT1_INPUT_SKIP_CONFIRM
    MOV A, 02Ah
    MOV 050h, A
    MOV A, 02Bh
    MOV 051h, A
    MOV 061h, #00h
    MOV 070h, #OPT_ST
    RET

CONF_OPT1_INPUT_SKIP_CONFIRM:
    MOV 061h, #00h
    RET

CONF_OPT1_INIT:
    MOV A, 070h
    MOV 071h, A
    MOV A, #04h
    LCALL LED6_ApplyTable
    MOV 03Bh, #02h
    RET

; --------------------
; OPT2
; --------------------
CONF_OPT2_HANDLER:
    MOV A, 071h
    CJNE A, 070h, CONF_OPT2_INIT
    MOV A, 061h
    CJNE A, #00h, CONF_OPT2_INPUT_HANDLE_KEY
    SJMP CONF_OPT2_INPUT_MODE

CONF_OPT2_INPUT_MODE:
    RET

CONF_OPT2_INPUT_HANDLE_KEY:
    MOV 020h, #02h
    MOV 021h, #04h
    LCALL InputTask_03B
    CJNE A, #0Ah, CONF_OPT2_INPUT_DONE
    LCALL CONF_OPT2_INPUT_CHECK_CONFIRM
    RET

CONF_OPT2_INPUT_DEC:
    DEC 03Bh

CONF_OPT2_INPUT_DONE:
    MOV 061h, #00h
    RET

CONF_OPT2_INPUT_BACKSPACE_LIMIT:
    MOV 03Bh, #02h
    MOV A, 03Bh
    ADD A, #028h
    MOV R0, A
    MOV @R0, #010h
    MOV 061h, #00h
    RET

CONF_OPT2_INPUT_CHECK_CONFIRM:
    MOV A, 060h
    CJNE A, #0Ah, CONF_OPT2_INPUT_SKIP_CONFIRM
    MOV A, 02Ah
    MOV 052h, A
    MOV A, 02Bh
    MOV 053h, A
    MOV 061h, #00h
    MOV 070h, #OPT_ST
    RET

CONF_OPT2_INPUT_SKIP_CONFIRM:
    MOV 061h, #00h
    RET

CONF_OPT2_INIT:
    MOV A, 070h
    MOV 071h, A
    MOV A, #05h
    LCALL LED6_ApplyTable
    MOV 03Bh, #02h
    RET

; --------------------
; OPT3
; --------------------
CONF_OPT3_HANDLER:
    MOV A, 071h
    CJNE A, 070h, CONF_OPT3_INIT
    MOV A, 061h
    CJNE A, #00h, CONF_OPT3_INPUT_HANDLE_KEY
    SJMP CONF_OPT3_INPUT_MODE

CONF_OPT3_INPUT_MODE:
    RET

CONF_OPT3_INPUT_HANDLE_KEY:
    MOV 020h, #01h
    MOV 021h, #01h
    LCALL InputTask_03B
    CJNE A, #0Ah, CONF_OPT3_INPUT_DONE
    LCALL CONF_OPT3_INPUT_CHECK_CONFIRM
    RET

CONF_OPT3_INPUT_DEC:
    DEC 03Bh

CONF_OPT3_INPUT_DONE:
    MOV 061h, #00h
    RET

CONF_OPT3_INPUT_BACKSPACE_LIMIT:
    MOV 03Bh, #01h
    MOV A, 03Bh
    ADD A, #028h
    MOV R0, A
    MOV @R0, #010h
    MOV 061h, #00h
    RET

CONF_OPT3_INPUT_CHECK_CONFIRM:
    MOV A, 060h
    CJNE A, #0Ah, CONF_OPT3_INPUT_SKIP_CONFIRM
    MOV A, 029h
    MOV 054h, A
    MOV 061h, #00h
    MOV 070h, #OPT_ST
    RET

CONF_OPT3_INPUT_SKIP_CONFIRM:
    MOV 061h, #00h
    RET

CONF_OPT3_INIT:
    MOV A, 070h
    MOV 071h, A
    MOV 028h, #017h
    MOV A, #06h
    LCALL LED6_ApplyTable
    MOV 03Bh, #01h
    RET

; --------------------
; PASS state
; --------------------
CONF_PASS_HANDLER:
    MOV A, 071h
    CJNE A, 070h, CONF_PASS_INIT
    MOV A, 061h
    CJNE A, #00h, CONF_PASS_HANDLE_KEY
    SJMP CONF_PASS_MODE

CONF_PASS_HANDLE_KEY:
    MOV 020h, #01h
    MOV 021h, #05h
    LCALL InputTask_039
    MOV 061h, #00h
    SJMP CONF_PASS_MODE

CONF_PASS_BACKSPACE_LIMIT:
    MOV 039h, #01h
    MOV A, 039h
    ADD A, #028h
    MOV R0, A
    MOV @R0, #010h
    MOV 061h, #00h
    SJMP CONF_PASS_MODE

CONF_PASS_INIT:
    MOV A, 070h
    MOV 071h, A
    MOV 070h, #PASS_ST
    
    ; Apply Table 07 (P._____)
    MOV A, #07h
    LCALL LED6_ApplyTable

    ; LCD Display
    LCALL LCD_CLEAR
    MOV DPTR, #LCD_MSG_CONFIG
    LCALL LCD_SHOW_STR
    
    ; Explicitly FORCE P. at 028h and clear buffers
    ; (Just in case Table Apply failed or was partial)
    MOV 028h, #011h ; 'P.'
    MOV 029h, #010h ; '_'
    MOV 02Ah, #010h
    MOV 02Bh, #010h
    MOV 02Ch, #010h
    MOV 02Dh, #010h

    ; Reset Cursor to 1 (So input starts at 029h)
    MOV 039h, #01h
    
    MOV 061h, #00h
    MOV 060h, #00h
    RET

CONF_PASS_MODE:
    MOV A, 061h
    CJNE A, #00h, CONF_PASS_MODE_CHECK_KEY
    RET

CONF_PASS_MODE_CHECK_KEY:
    MOV A, 060h
    CJNE A, #0Ah, CONF_PASS_MODE_SKIP_CONFIRM
    MOV A, 039h
    CJNE A, #05h, CONF_PASS_CONFIRM_INCOMPLETE
    MOV A, 02Dh
    CJNE A, #010h, CONF_PASS_DO_VERIFY
    SJMP CONF_PASS_CONFIRM_INCOMPLETE

CONF_PASS_DO_VERIFY:
    LCALL PASS_VERIFY_PASSWORD
    MOV 061h, #00h
    RET

CONF_PASS_CONFIRM_INCOMPLETE:
    LCALL PASS_SHOW_ERROR
    MOV 061h, #00h
    RET

CONF_PASS_MODE_SKIP_CONFIRM:
    MOV 061h, #00h
    RET

; Implement PASS verify/show routines (moved from main)
PUBLIC PASS_VERIFY_PASSWORD
PASS_VERIFY_PASSWORD:
    ; Verify 5 digits (029h..02Dh) vs CURRENT_PASS (RAM)
    MOV R0, #029h         ; Input Buffer
    MOV R1, #CURRENT_PASS ; Target RAM
    MOV R3, #05h          ; Count

PASS_VERIFY_LOOP:
    MOV A, @R0
    MOV B, A
    MOV A, @R1
    CJNE A, B, PASS_VERIFY_FAIL
    
    INC R0
    INC R1
    DJNZ R3, PASS_VERIFY_LOOP

    LCALL PASS_SHOW_SUCCESS
    RET

PASS_VERIFY_FAIL:
    LCALL PASS_SHOW_ERROR
    RET

PASS_SHOW_ERROR:
    DEC 03Ah
    MOV A, 03Ah
    JZ PASS_ERROR_LOCKED

    ; Show FALSEX (TABLE_PASS_ERROR_FALSEX id=08)
    MOV A, #08h
    LCALL LED6_ApplyTable
    MOV A, 03Ah
    MOV 02Dh, A

    MOV R3, #26h
PASS_ERROR_DELAY_OUTER:
    MOV R4, #0F0h
PASS_ERROR_DELAY_LOOP:
    MOV R5, #0FFh
PASS_ERROR_DELAY_INNER:
    NOP
    NOP
    NOP
    DJNZ R5, PASS_ERROR_DELAY_INNER
    DJNZ R4, PASS_ERROR_DELAY_LOOP
    DJNZ R3, PASS_ERROR_DELAY_OUTER

    LCALL CONF_PASS_INIT
    
    ; Clear any pending key presses that occurred during delay
    MOV 060h, #00h
    MOV 061h, #00h
    RET

PASS_ERROR_LOCKED:
    MOV A, #09h
    LCALL LED6_ApplyTable
    AJMP PASS_ERROR_LOCKED

PASS_SHOW_SUCCESS:
    MOV 070h, PASS_NEXT_ST ; Jump to requested state
    RET

; End of configuration task
    RET

END
