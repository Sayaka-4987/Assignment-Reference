; 2.8255的PC6作为中断源连接到MIRQ3上，每向8259A发出中断请求，使LED指示等交替点亮和熄灭。
; 中断5次后程序退出.
ASSUME DS:DATA, SS:STACK, CS:CODE

; 数据段
DATA SEGMENT
    ; 提示文字
    MESS_MIRQ3 DB 'MIRQ3!', 0DH, 0AH, '$'
    MESS_SIRQ10 DB 'SIRQ10!', 0DH, 0AH, '$'
    LED_STATUS DB 0
ENDS

; 堆栈段
SSTACK SEGMENT STACK
    DW 128 DUP(?)    
ENDS

; 常量定义
PA8255 EQU 280H    ; 8255的地址译码（待定!!!）
PB8255 EQU 281H
PC8255 EQU 282H
CMD8255 EQU 283H

INTA00 EQU 20H     ; 主片8259的偶地址、奇地址
INTA01 EQU 21H   
INTB00 EQU 0A0H    ; 从片8259的偶地址、奇地址
INTB01 EQU 0A1H
MIRQ3  EQU 0BH     ; 要修改的中断类型号
SIRQ10 EQU 72H   
LED_ADDR EQU 290H  ; LED 灯地址（待定!!!）
; END CONST

; 宏定义：输出值到某端口
OUT8 MACRO PORT, VAL
    MOV DX, PORT
    MOV AL, VAL
    OUT DX, AL
ENDM

OUT16 MACRO PORT, VAL
    MOV DX, PORT
    MOV AX, VAL
    OUT DX, AL
    MOV AL, AH
    OUT DX, AL
ENDM

; 宏定义：从某端口读入值
IN8 MACRO VAL, PORT
    MOV DX, PORT
    IN AL, DX
    MOV VAL, AL
ENDM

; 宏定义：延迟 T*65535 个机器周期
DELAY MACRO T
LOCAL I, O
    MOV CX, T
  O:NOP
    PUSH CX
        MOV CX, 65535
      I:NOP
        LOOP I
    POP CX
    LOOP O
ENDM

; 宏定义：先读再与，写入 OCW1 的中断屏蔽信息
WRITE_MASK_INFO MACRO PORT, VAL
    IN AL, PORT
    AND AL, VAL
    OUT PORT, AL
ENDM


CODE SEGMENT
START:
; 定位 DS 到数据段
    MOV AX, DATA
    MOV DS, AX

; 设置新中断程序
    CALL SET_MIRQ3
    CALL SET_SIRQ10
    
; 主片开放 MIRQ3 中断（和从片连接），OCW1=11110011B
    WRITE_MASK_INFO 21H, 11110011B

; 从片开放 SIRQ10 中断，OCW1=11111011B
    WRITE_MASK_INFO 0A1H, 11111011B    
    STI        ; 开中断

; 设置8255的PC6作为中断源，先将PC6置为0
    OUT8 CMD8255, 00001100B
    
    MOV CX, 10 ; 中断10次后程序退出

; 返回 DOS 
    MOV AX, 4C00H
    INT 21H


; MIRQ3 的新中断程序
MIRQ3_NEW_INT PROC FAR             
    PUSH AX    ; 入栈保存现场
    PUSH DX
    CLI        ; 关中断

    MOV	DX, OFFSET MESS_MIRQ3    ; 输出提示字符串
    MOV	AH, 09H                  ; DOS功能号: 显示输出串
    INT	21H 	                 ; DOS调用显示字符串
    IN8 LED_STATUS, LED_ADDR     ; 从 290H（待定!!!）读回 LED 灯状态
    XOR LED_STATUS, 11111111B    ; 异或运算，1 变 0，0 变 1
    OUT8 LED_ADDR, LED_STATUS    ; 反转 LED 灯状态
    DELAY 0FFFFH                 ; 延迟程序
    DEC CX

    MOV AL, 20H  ; 主片发EOI命令
  	OUT 20H, AL 

    STI        ; 开中断
    POP DX     ; 出栈恢复现场
    POP AX     
    IRET       ; 中断返回
MIRQ3_NEW_INT ENDP


; SIRQ10 的新中断程序
SIRQ10_NEW_INT PROC FAR             
    PUSH AX    ; 入栈保存现场
    PUSH DX
    CLI        ; 关中断


    MOV	DX, OFFSET MESS_SIRQ10   ; 输出提示字符串
    MOV	AH, 09H                  ; DOS功能号: 显示输出串
    INT	21H 	                 ; DOS调用显示字符串
    IN8 LED_STATUS, LED_ADDR     ; 从 290H（待定!!!）读回 LED 灯状态
    XOR LED_STATUS, 11111111B    ; 异或运算，1 变 0，0 变 1
    OUT8 LED_ADDR, LED_STATUS    ; 反转 LED 灯状态
    DELAY 0FFFFH                 ; 延迟程序
    DEC CX

    MOV AL, 20H   ; 主片发EOI命令
  	OUT 20H, AL 
    MOV AL, 62H   ; 从片发EOI命令
    OUT 0A1H, AL

    STI        ; 开中断
    POP DX
    POP AX     ; 出栈恢复现场
    IRET       ; 中断返回
SIRQ10_NEW_INT ENDP


; 子程序：设置 MIRQ3 的中断向量
SET_MIRQ3 PROC NEAR
    PUSH DS      
    MOV DI, 4*MIRQ3	                 ; 4 * 向量类型号 = 要修改的中断向量地址
    CLI

    MOV  BX, OFFSET MIRQ3_NEW_INT    ; 置新中断向量偏移地址
    MOV  [DI], BX
    ADD  DI, 2

    MOV  BX, SEG MIRQ3_NEW_INT       ; 置新中断向量段基地址
    MOV  [DI], BX
    POP  DS          
    RET
SET_MIRQ3 ENDP


; 子程序：设置 SIRQ10 的中断向量
SET_SIRQ10 PROC NEAR
    PUSH DS      
    MOV DI, 4*SIRQ10	              ; 4 * 向量类型号 = 要修改的中断向量地址
    CLI

    MOV  BX, OFFSET SIRQ10_NEW_INT    ; 置新中断向量偏移地址
    MOV  [DI], BX
    ADD  DI, 2

    MOV  BX, SEG SIRQ10_NEW_INT       ; 置新中断向量段基地址
    MOV  [DI], BX
    POP  DS          
    RET
SET_SIRQ10 ENDP

ENDS
END START