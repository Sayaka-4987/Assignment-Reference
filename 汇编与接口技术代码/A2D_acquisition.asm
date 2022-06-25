ASSUME DS:DATA, SS:STACK, CS:CODE

; CONST
    M8259 EQU 20H
    MIRQ3 EQU 0BH

    ; 8255 CS 接地址译码 280H
    PA8255 EQU 280H
    PB8255 EQU 281H
    PC8255 EQU 282H
    CMD8255 EQU 283H

    ; 使用 ADC0809 的通道 0, CS 接地址译码 298H
    ; A0-A2 都接地 GND
    CS0809 EQU 298H
; END

DATA SEGMENT
    ; 数码管字型段码，分别从 0(3FH) 到 A(77H) 到 F(71H)
    DISPLAY_DIGIT DB 3FH, 06H, 5BH, 4FH, 66H, 6DH, 7DH, 07H, 7FH, 6FH, 77H, 7CH, 39H, 5EH, 79H, 71H
    ; 保存当前数据的临时变量
    DIGIT_TEMP DB 0
    ; 共计 100 个数据 
    DIGIT_ARR DB 108 DUP(0)
ENDS

STACK SEGMENT STACK
    DW  128  DUP(0)
ENDS

; 宏定义：输出值到某端口
OUT8 MACRO PORT, VAL
    MOV DX, PORT
    MOV AL, VAL
    OUT DX, AL
ENDM

; 宏定义：从某端口读入值
IN8 MACRO VAL, PORT
    MOV DX, PORT
    IN AL, DX
    MOV VAL, AL
ENDM

; 宏定义：延时 T*65535 个机器周期
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

; 宏定义：先读再与，写入 8259 中断屏蔽信息
MASK MACRO PORT, M
    IN AL, PORT
    AND AL, M
    OUT PORT, AL
ENDM

; 宏定义：设置中断向量地址
SETINT MACRO INTNO, HANDLER
    PUSH DS
    MOV AX, 0
    MOV DS, AX
    MOV DI, INTNO * 4
    CLI
    MOV BX, OFFSET HANDLER
    MOV [DI], BX
    ADD DI, 2
    MOV BX, SEG HANDLER
    MOV [DI], BX
    POP DS
ENDM

CODE SEGMENT

; MIRQ3 的新中断程序
COLLECT PROC FAR
    PUSH AX
    PUSH DI
    CLI

    DELAY 10

    XOR AX, AX
    ; 读取采集的数据
    IN8 DIGIT_TEMP, CS0809+1 

    ; PB <- 位码, PA <- 段码
    ; 显示高4位
    OUT8 PB8255, 00000010B
    MOV AL, DIGIT_TEMP
    SHR AL, 4    
    CALL DISPLAY_ASCII
    MOV BX, OFFSET DISPLAY_ASCII
    XLAT
    OUT8 PA8255, AL

    DELAY 10

    ; 显示低4位
    OUT8 PB8255, 00000001B
    MOV AL, DIGIT_TEMP
    AND AL, 0FH    
    CALL DISPLAY_ASCII
    MOV BX, OFFSET DISPLAY_ASCII
    XLAT
    OUT8 PA8255, AL

    ; 屏幕输出换个行
    MOV AL, 0DH
    CALL DISPLAY_ASCII
    MOV AL, 0AH
    CALL DISPLAY_ASCII

    ; 保存读取的数据       
    MOV AL, DIGIT_TEMP
    MOV DIGIT_ARR[SI], AL
    
    ; 计数器 SI++
    INC SI    

    ; 启动下一次 ADC 转换
    OUT8 CS0809, 0FFH

    ; EOI 命令
    OUT8 20H, 20H

    STI
    POP DI
    POP AX
    IRET
ENDP

; ASCII 显示到屏幕上的子程序
DISPLAY_ASCII PROC NEAR
    MOV DL, AL
    CMP DL, 10
    JL DL_SMALLER
    ADD DL, 7    ; if DL >= 10

    DL_SMALLER:  ; if DL < 10
        ADD DL, 30H

    MOV AH, 02H       ; 调用中断在屏幕上显示 DL 对应字符
    INT 21H
ENDP

; 主程序
START:
    ; 定位 DS 到数据段
    MOV AX, DATA
    MOV DS, AX

    ; 设置中断向量指向新中断程序    
    SETINT MIRQ3, COLLECT

    ; 设置主片中断屏蔽字，开放 MIRQ3
    MASK M8259+1, 11110111B

    ; 8255 初始化
    OUT8 CMD8255, 10000000B  

    ; 产生 START 启动信号 
    OUT8 CS0809, 0FFH
    ; NOP     ; 指导书说不用这样，存疑?
    ; NOP     ; 适当延时脉宽
    ; NOP 
    ; OUT8 CS0809, 00H  

    ; 开中断    
    STI

    ; 计数变量初始化    
    MOV SI, 0

  LOOP1: 
    ; 循环等中断
    CMP SI, 100
    JNZ LOOP1

    ; 关中断  
    CLI
    
    ; 返回 DOS 
    MOV AX, 4C00H
    INT 21H
ENDS

END START