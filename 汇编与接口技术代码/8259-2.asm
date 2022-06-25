; 2.8255��PC6��Ϊ�ж�Դ���ӵ�MIRQ3�ϣ�ÿ��8259A�����ж�����ʹLEDָʾ�Ƚ��������Ϩ��
; �ж�5�κ�����˳�.
ASSUME DS:DATA, SS:STACK, CS:CODE

; ���ݶ�
DATA SEGMENT
    ; ��ʾ����
    MESS_MIRQ3 DB 'MIRQ3!', 0DH, 0AH, '$'
    MESS_SIRQ10 DB 'SIRQ10!', 0DH, 0AH, '$'
    LED_STATUS DB 0
ENDS

; ��ջ��
SSTACK SEGMENT STACK
    DW 128 DUP(?)    
ENDS

; ��������
PA8255 EQU 280H    ; 8255�ĵ�ַ���루����!!!��
PB8255 EQU 281H
PC8255 EQU 282H
CMD8255 EQU 283H

INTA00 EQU 20H     ; ��Ƭ8259��ż��ַ�����ַ
INTA01 EQU 21H   
INTB00 EQU 0A0H    ; ��Ƭ8259��ż��ַ�����ַ
INTB01 EQU 0A1H
MIRQ3  EQU 0BH     ; Ҫ�޸ĵ��ж����ͺ�
SIRQ10 EQU 72H   
LED_ADDR EQU 290H  ; LED �Ƶ�ַ������!!!��
; END CONST

; �궨�壺���ֵ��ĳ�˿�
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

; �궨�壺��ĳ�˿ڶ���ֵ
IN8 MACRO VAL, PORT
    MOV DX, PORT
    IN AL, DX
    MOV VAL, AL
ENDM

; �궨�壺�ӳ� T*65535 ����������
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

; �궨�壺�ȶ����룬д�� OCW1 ���ж�������Ϣ
WRITE_MASK_INFO MACRO PORT, VAL
    IN AL, PORT
    AND AL, VAL
    OUT PORT, AL
ENDM


CODE SEGMENT
START:
; ��λ DS �����ݶ�
    MOV AX, DATA
    MOV DS, AX

; �������жϳ���
    CALL SET_MIRQ3
    CALL SET_SIRQ10
    
; ��Ƭ���� MIRQ3 �жϣ��ʹ�Ƭ���ӣ���OCW1=11110011B
    WRITE_MASK_INFO 21H, 11110011B

; ��Ƭ���� SIRQ10 �жϣ�OCW1=11111011B
    WRITE_MASK_INFO 0A1H, 11111011B    
    STI        ; ���ж�

; ����8255��PC6��Ϊ�ж�Դ���Ƚ�PC6��Ϊ0
    OUT8 CMD8255, 00001100B
    
    MOV CX, 10 ; �ж�10�κ�����˳�

; ���� DOS 
    MOV AX, 4C00H
    INT 21H


; MIRQ3 �����жϳ���
MIRQ3_NEW_INT PROC FAR             
    PUSH AX    ; ��ջ�����ֳ�
    PUSH DX
    CLI        ; ���ж�

    MOV	DX, OFFSET MESS_MIRQ3    ; �����ʾ�ַ���
    MOV	AH, 09H                  ; DOS���ܺ�: ��ʾ�����
    INT	21H 	                 ; DOS������ʾ�ַ���
    IN8 LED_STATUS, LED_ADDR     ; �� 290H������!!!������ LED ��״̬
    XOR LED_STATUS, 11111111B    ; ������㣬1 �� 0��0 �� 1
    OUT8 LED_ADDR, LED_STATUS    ; ��ת LED ��״̬
    DELAY 0FFFFH                 ; �ӳٳ���
    DEC CX

    MOV AL, 20H  ; ��Ƭ��EOI����
  	OUT 20H, AL 

    STI        ; ���ж�
    POP DX     ; ��ջ�ָ��ֳ�
    POP AX     
    IRET       ; �жϷ���
MIRQ3_NEW_INT ENDP


; SIRQ10 �����жϳ���
SIRQ10_NEW_INT PROC FAR             
    PUSH AX    ; ��ջ�����ֳ�
    PUSH DX
    CLI        ; ���ж�


    MOV	DX, OFFSET MESS_SIRQ10   ; �����ʾ�ַ���
    MOV	AH, 09H                  ; DOS���ܺ�: ��ʾ�����
    INT	21H 	                 ; DOS������ʾ�ַ���
    IN8 LED_STATUS, LED_ADDR     ; �� 290H������!!!������ LED ��״̬
    XOR LED_STATUS, 11111111B    ; ������㣬1 �� 0��0 �� 1
    OUT8 LED_ADDR, LED_STATUS    ; ��ת LED ��״̬
    DELAY 0FFFFH                 ; �ӳٳ���
    DEC CX

    MOV AL, 20H   ; ��Ƭ��EOI����
  	OUT 20H, AL 
    MOV AL, 62H   ; ��Ƭ��EOI����
    OUT 0A1H, AL

    STI        ; ���ж�
    POP DX
    POP AX     ; ��ջ�ָ��ֳ�
    IRET       ; �жϷ���
SIRQ10_NEW_INT ENDP


; �ӳ������� MIRQ3 ���ж�����
SET_MIRQ3 PROC NEAR
    PUSH DS      
    MOV DI, 4*MIRQ3	                 ; 4 * �������ͺ� = Ҫ�޸ĵ��ж�������ַ
    CLI

    MOV  BX, OFFSET MIRQ3_NEW_INT    ; �����ж�����ƫ�Ƶ�ַ
    MOV  [DI], BX
    ADD  DI, 2

    MOV  BX, SEG MIRQ3_NEW_INT       ; �����ж������λ���ַ
    MOV  [DI], BX
    POP  DS          
    RET
SET_MIRQ3 ENDP


; �ӳ������� SIRQ10 ���ж�����
SET_SIRQ10 PROC NEAR
    PUSH DS      
    MOV DI, 4*SIRQ10	              ; 4 * �������ͺ� = Ҫ�޸ĵ��ж�������ַ
    CLI

    MOV  BX, OFFSET SIRQ10_NEW_INT    ; �����ж�����ƫ�Ƶ�ַ
    MOV  [DI], BX
    ADD  DI, 2

    MOV  BX, SEG SIRQ10_NEW_INT       ; �����ж������λ���ַ
    MOV  [DI], BX
    POP  DS          
    RET
SET_SIRQ10 ENDP

ENDS
END START