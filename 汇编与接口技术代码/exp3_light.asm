ASSUME CS:CODE, DS:DATA

; ��OUT_PORT_BYTE���������ֵ�ĳ�˿� 
OUT_PORT_BYTE MACRO PORT, BYTE1
    MOV  DX, PORT
    MOV  AL, BYTE1   
    OUT  DX, AL
ENDM  

; ��IN_REG_PORT����ĳ�˿����ݶ���AL/AX 
IN_REG_PORT MACRO REG, PORT
    MOV  DX, PORT
    IN   REG, DX
ENDM     
     
DATA  SEGMENT
; 8255������ʽ������      
OP8255  EQU  10000000B  ; ��ͷD7Ϊ1
A0      EQU  00000000B  ; A��0��ʽ
A1      EQU  00100000B  ; A��1��ʽ
A2      EQU  01000000B  ; A��2��ʽ
A_NULL  EQU  01100000B  ; A�ڲ���
A_OUT   EQU  00000000B  ; A�����
A_IN    EQU  00010000B  ; A������ 
CH_OUT  EQU  00000000B  ; C���ϰ벿����� 
CH_IN   EQU  00001000B  ; C���ϰ벿������
B0      EQU  00000000B  ; B��0��ʽ
B1      EQU  00000100B  ; B��1��ʽ  
B_OUT   EQU  00000000B  ; B�����
B_IN    EQU  00000010B  ; B������
CL_OUT  EQU  00000000B  ; C���°벿����� 
CL_IN   EQU  00000001B  ; C���°벿������

; 8255 C�˿���λ������
OP_PORT_C  EQU  00000000B  ; ��ͷD7Ϊ0
PC0        EQU  00000000B  ; ָ���˿�PC0-PC7
PC1        EQU  00000010B 
PC2        EQU  00000100B 
PC3        EQU  00000110B  
PC4        EQU  00001000B 
PC5        EQU  00001010B 
PC6        EQU  00001100B
PC7        EQU  00001110B
SET_HIGH   EQU  00000001B  ; �øߵ�ƽ���
SET_LOW    EQU  00000000B  ; ��λ    

; !!! ��ַ���룬�ӽ�������޸� !!! 
LED_CS    EQU  290H
D8255_CS   EQU  280H

; !!! ��Ҫ�޸ĵĶ˿ڵ�ַ !!!
IO8255_A  EQU  288H
IO8255_B  EQU  289H
IO8255_C  EQU  28AH
IO8255_K  EQU  28BH 
IO_SEG_LED  DW  ?

; ����ܶ�����ʾ
; 3FH=0, 6FH=9 
LED    DB  3FH, 06H, 5BH, 4FH, 66H, 6DH, 7DH, 07H, 7FH, 6FH    
; �ֱ��Ӧ��ʾ    8    2    5    5    -    A
LED_8255_A  DB  7FH, 5BH, 6DH, 6DH, 40H, 77H
 
; ��ʾ����
MESSAGE1 DB "LED MOVING... $"
MESSAGE2 DB "DISPLAY 8255-A... $"   
 
; ??? �����λ�룬û��������ô�� ???
BZ  DW  ?

; �������ص�Ԫ��ֵ��8λ
K   DB  00H 

; LED��ˮ/ѭ����������
CNT  DB  00H  

DATA  ENDS


CODE  SEGMENT
    
START:  
    MOV  AX, DATA    ; DS��λ��DATA��
    MOV  DS, AX    
    
    ; ��8255��ΪA��0��ʽ���룬B��0��ʽ���
    OUT_PORT_BYTE IO8255_K,  10010000B  ; OP8255|A0|A_IN|B0|B_OUT
    
    ; ����õ��ļĴ���         
    XOR  AX, AX
    XOR  BX, BX 
    XOR  CX, CX  
          
    ; ����A�����ӵĲ�������K7-K0����ֵ�������ڱ���K
    IN_REG_PORT AL, IO8255_A
    MOV  K, AL
             
    ; ʹLED��K��ʼ�趨��ֵ����    
    MOV  BH, K
    OUT_PORT_BYTE  IO8255_B, K  
    
    ; �趨ѭ������Ϊ16
    MOV  CNT, 10H 

; LED��K1-K8��ʼ�趨��ֵ����������������
LED_RIGHT_MOV:  
    ; CX������ʱ��������
    MOV  CX, 10
    DELAY:
        NOP
        LOOP DELAY
    
    ; ����INT 21H,AH=09H�ж���ʾ��ʾ���� "LED MOVING...$"
    MOV  DX, OFFSET MESSAGE1
    MOV  AH, 09H
    INT  21H
    
    ; ����LED��BHѭ������һλ�������ƺ����ʾ�����B�˿� 
    ROR  BH, 1 
    OUT_PORT_BYTE  IO8255_B, BH  
    
    DEC  CNT     ; ѭ������CNT--; 
    CMP  CNT, 0
    JNZ  LED_RIGHT_MOV   ; δ�������� LED_RIGHT_MOV
    ; ������ִ����һ���������չʾ
        
; �����������ʾ"8255-A"        
LED_CS_DISPLAY_8255A:
    
    ; ����INT 21H,AH=09H�ж���ʾ��ʾ����"DISPLAY 8255-A...$"     
    MOV  DX, OFFSET MESSAGE2
    MOV  AH, 09H                       
    INT  21H 
    
    MOV  CNT, 00H  
    ; ��SIΪLED�������ʼ��ַ
    MOV  SI, OFFSET LED_8255_A
    FOR_LOOP:
       OUT_PORT_BYTE  IO_SEG_LED, [SI]  
       INC  SI   ; SI++���Ƶ���һλ 
       INC  IO_SEG_LED  ; �Ƶ���һ������ܵĵ�ַ
       INC  CNT
       CMP  CNT, 6
       JZ   END_PROGRAM  ; CNT=6����������
       JMP  FOR_LOOP  ; ��FOR_LOOP����ѭ��

; ����������ر��������ʾ        
END_PROGRAM:        
    OUT_PORT_BYTE  LED_CS, 0       
    MOV  AH, 4CH  ; �˳�����
    INT  21H 
        
CODE  ENDS
    END  START   