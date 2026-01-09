; Input task routines
; Provides InputTask_03B and InputTask_039 to handle cursor-based input
; Calling convention:
; - Caller must set RAM[020h] = startIndex (lowest allowed index)
; - Caller must set RAM[021h] = endIndex   (highest allowed index)
; - Key code is read from 060h (low nibble). Routine clears 061h when consumed.
; - Return in A: 0x0A = confirm pressed, 0x0B = backspace handled, 0x01 = digit written

; include system constants (RUN_ST, PASS_ST, etc.)
Input SEGMENT CODE
rseg Input


$INCLUDE (../user/config.inc)

EXTRN CODE(LED6_ApplyTable)
EXTRN CODE(PASS_VERIFY_PASSWORD)

PUBLIC InputTask_03B
PUBLIC InputTask_039

; Handle input where cursor is stored at 03Bh
InputTask_03B:
    PUSH B

    MOV A, 060h
    ANL A, #0Fh
    MOV R7, A       ; save key

    CJNE A, #0Ah, L_CHECK_BK
    ; confirm: return A=0x0A, do NOT clear 061h here (caller handles)
    POP B
    RET

L_CHECK_BK:
    CJNE A, #0Bh, L_DIGIT
    ; backspace with empty-check logic (left-to-right input)
    MOV A, 03Bh
    ADD A, #028h
    MOV R0, A
    MOV A, @R0
    CJNE A, #010h, L_BACK_CLEAR_CURRENT ; if current has data, clear here

    ; current is empty, attempt to move back one position if not at startIndex
    MOV A, 03Bh
    CJNE A, 020h, L_BACK_DEC
    SJMP L_BACK_DONE

L_BACK_DEC:
    DEC 03Bh
    MOV A, 03Bh
    ADD A, #028h
    MOV R0, A
    ; fall through to clear

L_BACK_CLEAR_CURRENT:
    MOV @R0, #010h

L_BACK_DONE:
    MOV 061h, #00h
    MOV A, #0Bh
    POP B
    RET

L_DIGIT:
    ; write digit only if current position empty (0x10); otherwise ignore to avoid overwrite
    MOV A, 03Bh
    ADD A, #028h
    MOV R0, A
    MOV A, @R0
    CJNE A, #010h, L_DIGIT_IGNORED

    MOV A, R7
    MOV @R0, A
    ; if cursor == endIndex then done else INC cursor (left-to-right)
    MOV A, 03Bh
    CJNE A, 021h, L_INC_CURSOR
    SJMP L_DIGIT_DONE
L_INC_CURSOR:
    INC 03Bh
L_DIGIT_DONE:
    MOV 061h, #00h
    MOV A, #01h
    POP B
    RET
L_DIGIT_IGNORED:
    MOV 061h, #00h
    MOV A, #00h
    POP B
    RET

; Handle input where cursor is stored at 039h (password)
InputTask_039:
    PUSH B

    MOV A, 060h
    ANL A, #0Fh
    MOV R7, A       ; save key

    CJNE A, #0Ah, L2_CHECK_BK
    ; confirm: if system in PASS state, invoke password verify directly
    MOV A, 070h
    CJNE A, #PASS_ST, L2_RETURN_CONFIRM
    ; call PASS_VERIFY_PASSWORD
    PUSH ACC
    PUSH B
    PUSH DPL
    PUSH DPH
    LCALL PASS_VERIFY_PASSWORD
    POP DPH
    POP DPL
    POP B
    POP ACC
    ; ensure key consumed; return non-confirm so caller won't decrement cursor
    MOV 061h, #00h
    MOV A, #00h
    POP B
    RET
L2_RETURN_CONFIRM:
    ; not PASS state: return confirm to caller (do not clear 061h here)
    MOV A, #0Ah  ; Restore A = key code (0Ah)
    POP B
    RET

L2_CHECK_BK:
    CJNE A, #0Bh, L2_DIGIT
    ; Backspace Logic (left-to-right input: backspace moves left)
    ; Check if current cursor position has a digit (Full case)
    MOV A, 039h
    ADD A, #028h
    MOV R0, A
    MOV A, @R0
    CJNE A, #010h, L2_BK_CLEAR_CURRENT ; If not empty (0x10), clear it

    ; Current is empty, try to move back (DEC because we fill left-to-right)
    MOV A, 039h
    CJNE A, 020h, L2_BK_DEC ; If not at StartIndex, DEC
    ; At StartIndex and Empty -> Nothing to do
    SJMP L2_BK_DONE

L2_BK_DEC:
    DEC 039h
    MOV A, 039h
    ADD A, #028h
    MOV R0, A
    ; Fall through to clear

L2_BK_CLEAR_CURRENT:
    MOV @R0, #010h

L2_BK_DONE:
    MOV 061h, #00h
    MOV A, #0Bh
    POP B
    RET

L2_DIGIT:
    ; Check if current position is empty. If not (Full), ignore input.
    MOV A, 039h
    ADD A, #028h
    MOV R0, A
    MOV A, @R0
    CJNE A, #010h, L2_DIGIT_IGNORED

    ; Write digit
    MOV A, R7
    MOV @R0, A
    
    ; Move cursor (INC) if not at EndIndex (left-to-right)
    MOV A, 039h
    CJNE A, 021h, L2_INC_CURSOR
    SJMP L2_DIGIT_DONE

L2_INC_CURSOR:
    INC 039h

L2_DIGIT_DONE:
    MOV 061h, #00h
    MOV A, #01h
    POP B
    RET

L2_DIGIT_IGNORED:
    MOV 061h, #00h
    MOV A, #00h
    POP B
    RET

END
