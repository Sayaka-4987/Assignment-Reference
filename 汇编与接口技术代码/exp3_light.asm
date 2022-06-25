ASSUME CS:CODE, DS:DATA

; 宏OUT_PORT_BYTE：送命令字到某端口 
OUT_PORT_BYTE MACRO PORT, BYTE1
    MOV  DX, PORT
    MOV  AL, BYTE1   
    OUT  DX, AL
ENDM  

; 宏IN_REG_PORT：把某端口数据读到AL/AX 
IN_REG_PORT MACRO REG, PORT
    MOV  DX, PORT
    IN   REG, DX
ENDM     
     
DATA  SEGMENT
; 8255工作方式命令打表      
OP8255  EQU  10000000B  ; 开头D7为1
A0      EQU  00000000B  ; A口0方式
A1      EQU  00100000B  ; A口1方式
A2      EQU  01000000B  ; A口2方式
A_NULL  EQU  01100000B  ; A口不用
A_OUT   EQU  00000000B  ; A口输出
A_IN    EQU  00010000B  ; A口输入 
CH_OUT  EQU  00000000B  ; C口上半部分输出 
CH_IN   EQU  00001000B  ; C口上半部分输入
B0      EQU  00000000B  ; B口0方式
B1      EQU  00000100B  ; B口1方式  
B_OUT   EQU  00000000B  ; B口输出
B_IN    EQU  00000010B  ; B口输入
CL_OUT  EQU  00000000B  ; C口下半部分输出 
CL_IN   EQU  00000001B  ; C口下半部分输入

; 8255 C端口置位命令打表
OP_PORT_C  EQU  00000000B  ; 开头D7为0
PC0        EQU  00000000B  ; 指定端口PC0-PC7
PC1        EQU  00000010B 
PC2        EQU  00000100B 
PC3        EQU  00000110B  
PC4        EQU  00001000B 
PC5        EQU  00001010B 
PC6        EQU  00001100B
PC7        EQU  00001110B
SET_HIGH   EQU  00000001B  ; 置高电平输出
SET_LOW    EQU  00000000B  ; 复位    

; !!! 地址译码，视接线情况修改 !!! 
LED_CS    EQU  290H
D8255_CS   EQU  280H

; !!! 需要修改的端口地址 !!!
IO8255_A  EQU  288H
IO8255_B  EQU  289H
IO8255_C  EQU  28AH
IO8255_K  EQU  28BH 
IO_SEG_LED  DW  ?

; 数码管段码显示
; 3FH=0, 6FH=9 
LED    DB  3FH, 06H, 5BH, 4FH, 66H, 6DH, 7DH, 07H, 7FH, 6FH    
; 分别对应显示    8    2    5    5    -    A
LED_8255_A  DB  7FH, 5BH, 6DH, 6DH, 40H, 77H
 
; 提示文字
MESSAGE1 DB "LED MOVING... $"
MESSAGE2 DB "DISPLAY 8255-A... $"   
 
; ??? 数码管位码，没搞明白怎么用 ???
BZ  DW  ?

; 拨动开关单元的值，8位
K   DB  00H 

; LED流水/循环计数变量
CNT  DB  00H  

DATA  ENDS


CODE  SEGMENT
    
START:  
    MOV  AX, DATA    ; DS定位到DATA段
    MOV  DS, AX    
    
    ; 将8255设为A口0方式输入，B口0方式输出
    OUT_PORT_BYTE IO8255_K,  10010000B  ; OP8255|A0|A_IN|B0|B_OUT
    
    ; 清空用到的寄存器         
    XOR  AX, AX
    XOR  BX, BX 
    XOR  CX, CX  
          
    ; 读入A口连接的拨动开关K7-K0的数值，保存在变量K
    IN_REG_PORT AL, IO8255_A
    MOV  K, AL
             
    ; 使LED按K初始设定的值点亮    
    MOV  BH, K
    OUT_PORT_BYTE  IO8255_B, K  
    
    ; 设定循环次数为16
    MOV  CNT, 10H 

; LED按K1-K8初始设定的值点亮，并向右流动
LED_RIGHT_MOV:  
    ; CX计数延时机器周期
    MOV  CX, 10
    DELAY:
        NOP
        LOOP DELAY
    
    ; 调用INT 21H,AH=09H中断显示提示文字 "LED MOVING...$"
    MOV  DX, OFFSET MESSAGE1
    MOV  AH, 09H
    INT  21H
    
    ; 控制LED的BH循环右移一位，把右移后的显示输出到B端口 
    ROR  BH, 1 
    OUT_PORT_BYTE  IO8255_B, BH  
    
    DEC  CNT     ; 循环次数CNT--; 
    CMP  CNT, 0
    JNZ  LED_RIGHT_MOV   ; 未结束，跳 LED_RIGHT_MOV
    ; 结束，执行下一部分数码管展示
        
; 在数码管上显示"8255-A"        
LED_CS_DISPLAY_8255A:
    
    ; 调用INT 21H,AH=09H中断显示提示文字"DISPLAY 8255-A...$"     
    MOV  DX, OFFSET MESSAGE2
    MOV  AH, 09H                       
    INT  21H 
    
    MOV  CNT, 00H  
    ; 置SI为LED数码表起始地址
    MOV  SI, OFFSET LED_8255_A
    FOR_LOOP:
       OUT_PORT_BYTE  IO_SEG_LED, [SI]  
       INC  SI   ; SI++，移到下一位 
       INC  IO_SEG_LED  ; 移到下一个数码管的地址
       INC  CNT
       CMP  CNT, 6
       JZ   END_PROGRAM  ; CNT=6，跳结束段
       JMP  FOR_LOOP  ; 跳FOR_LOOP继续循环

; 程序结束，关闭数码管显示        
END_PROGRAM:        
    OUT_PORT_BYTE  LED_CS, 0       
    MOV  AH, 4CH  ; 退出程序
    INT  21H 
        
CODE  ENDS
    END  START   