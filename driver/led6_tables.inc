; led6_tables.inc
; 说明：每个表由6个字节组成，按顺序表示缓冲区 [035h, 034h, 033h, 032h, 031h, 030h]
; 即表的第1字节对应主程序中的 MOV 035h, #xx，最后一字节对应 MOV 030h, #xx
; 驱动 `LED6` 可以选择按本顺序把字节写入显示缓冲（写入 030h..035h 时须反向拷贝）。

; 全局：上电/清空显示（全部为占位 0x10）
TABLE_DISPLAY_INIT_BLANK:    DB 010h, 010h, 010h, 010h, 010h, 010h

; RUN 模式初始化（同上）
TABLE_DISPLAY_RUN_BLANK:     DB 010h, 010h, 010h, 010h, 010h, 010h

; 主菜单："1.n 2.r 3.C" （035..030）
TABLE_MENU_MAIN_OPT:         DB 015h, 01Eh, 016h, 012h, 017h, 00Ch

; 错误：Err011（输入不完整）
TABLE_OPT_ERR011:            DB 00Eh, 012h, 012h, 00h, 01h, 01h

; OPT1 提示: "no._d_d__"（035..030）
TABLE_OPT1_PROMPT:          DB 01Eh, 020h, 010h, 010h, 021h, 021h

; OPT2 提示: "rL_d_d__"
TABLE_OPT2_PROMPT:          DB 012h, 013h, 010h, 010h, 010h, 021h

; OPT3 提示: "C._d____" (含 C.)
TABLE_OPT3_PROMPT:          DB 022h, 010h, 021h, 021h, 021h, 021h

; PASS 提示: "P._____'"
TABLE_PASS_PROMPT:          DB 011h, 010h, 010h, 010h, 010h, 010h

; 密码错误显示: "FALSEX"（最后一位由程序写入剩余次数，表中保留 0x00 作为占位）
TABLE_PASS_ERROR_FALSEX:     DB 00Fh, 00Ah, 013h, 005h, 00Eh, 00h

; 锁定/Err011（与 OPT_ERR011 相同字节序，但保留独立名字以便调用）
TABLE_PASS_ERROR_LOCKED:     DB 00Eh, 012h, 012h, 00h, 01h, 01h

; 说明：动态写入场景（使用游标 03Bh / 039h 的 MOV @R0）不在此文件中建表，
; 可使用 LED6 的单格写入接口（例如 LED6_WriteAtCursor）来处理。
