; 1.ï¿½Ö¶ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Îªï¿½Ð¶ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Åºï¿½
ASSUME DS:DATA, SS:STACK, CS:CODE

; ï¿½ï¿½ï¿½Ý¶ï¿½
DATA SEGMENT
    ; ï¿½ï¿½Ê¾ï¿½ï¿½ï¿½ï¿½
    MESS_MIRQ3 DB 'MIRQ3!', 0DH, 0AH, '$'
    MESS_SIRQ10 DB 'SIRQ10!', 0DH, 0AH, '$'
    LED_STATUS DB 0
ENDS

; ï¿½ï¿½Õ»ï¿½ï¿½
SSTACK SEGMENT STACK
    DW 128 DUP(?)    
ENDS

; ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
INTA00 EQU 20H     ; ï¿½ï¿½Æ¬ï¿½ï¿½Å¼ï¿½ï¿½Ö·ï¿½ï¿½ï¿½ï¿½ï¿½Ö?
INTA01 EQU 21H   
INTB00 EQU 0A0H    ; ï¿½ï¿½Æ¬ï¿½ï¿½Å¼ï¿½ï¿½Ö·ï¿½ï¿½ï¿½ï¿½ï¿½Ö?
INTB01 EQU 0A1H
MIRQ3  EQU 0BH     ; Òªï¿½Þ¸Äµï¿½ï¿½Ð¶ï¿½ï¿½ï¿½ï¿½Íºï¿½
SIRQ10 EQU 72H   
LED_ADDR EQU 290H  ; LED ï¿½Æµï¿½Ö·ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½!!!ï¿½ï¿½
; END CONST

; ï¿½ê¶¨ï¿½å£ºï¿½ï¿½ï¿½Öµï¿½ï¿½Ä³ï¿½Ë¿ï¿?
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

; ï¿½ê¶¨ï¿½å£ºï¿½ï¿½Ä³ï¿½Ë¿Ú¶ï¿½ï¿½ï¿½Öµ
IN8 MACRO VAL, PORT
    MOV DX, PORT
    IN AL, DX
    MOV VAL, AL
ENDM

; ï¿½ê¶¨ï¿½å£ºï¿½Ó³ï¿½ T*65535 ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
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

; ï¿½ê¶¨ï¿½å£ºï¿½È¶ï¿½ï¿½ï¿½ï¿½ë£¬Ð´ï¿½ï¿½ OCW1 ï¿½ï¿½ï¿½Ð¶ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ï¢
WRITE_MASK_INFO MACRO PORT, VAL
    IN AL, PORT
    AND AL, VAL
    OUT PORT, AL
ENDM


CODE SEGMENT
START:
; ï¿½ï¿½Î» DS ï¿½ï¿½ï¿½ï¿½ï¿½Ý¶ï¿½
    MOV AX, DATA
    MOV DS, AX

; ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ð¶Ï³ï¿½ï¿½ï¿½
    CALL SET_MIRQ3
    CALL SET_SIRQ10
    
; ï¿½ï¿½Æ¬ï¿½ï¿½ï¿½ï¿½ MIRQ3 ï¿½Ð¶Ï£ï¿½ï¿½Í´ï¿½Æ¬ï¿½ï¿½ï¿½Ó£ï¿½ï¿½ï¿½OCW1=11110011B
    WRITE_MASK_INFO 21H, 11110011B

; ï¿½ï¿½Æ¬ï¿½ï¿½ï¿½ï¿½ SIRQ10 ï¿½Ð¶Ï£ï¿½OCW1=11111011B
    WRITE_MASK_INFO 0A1H, 11111011B

    MOV CX, 10 ; ÖÐ¶Ï10´Îºó³ÌÐòÍË³ö
    STI        ; ï¿½ï¿½ï¿½Ð¶ï¿½

; ï¿½ï¿½ï¿½ï¿½ DOS 
    MOV AX, 4C00H
    INT 21H

; MIRQ3 µÄÐÂÖÐ¶Ï³ÌÐò
MIRQ3_NEW_INT PROC FAR             
    PUSH AX    ; ÈëÕ»±£´æÏÖ³¡
    PUSH DX
    CLI        ; ¹ØÖÐ¶Ï

    MOV	DX, OFFSET MESS_MIRQ3    ; Êä³öÌáÊ¾×Ö·û´®
    MOV	AH, 09H                  ; DOS¹¦ÄÜºÅ: ÏÔÊ¾Êä³ö´®
    INT	21H 	                 ; DOSµ÷ÓÃÏÔÊ¾×Ö·û´®
    IN8 LED_STATUS, LED_ADDR     ; ´Ó 290H£¨´ý¶¨!!!£©¶Á»Ø LED µÆ×´Ì¬
    XOR LED_STATUS, 11111111B    ; Òì»òÔËËã£¬1 ±ä 0£¬0 ±ä 1
    OUT8 LED_ADDR, LED_STATUS    ; ·´×ª LED µÆ×´Ì¬
    DELAY 0FFFFH                 ; ÑÓ³Ù³ÌÐò
    DEC CX

    MOV AL, 20H  ; Ö÷Æ¬·¢EOIÃüÁî
  	OUT 20H, AL 

    STI        ; ¿ªÖÐ¶Ï
    POP DX     ; ³öÕ»»Ö¸´ÏÖ³¡
    POP AX     
    IRET       ; ÖÐ¶Ï·µ»Ø
MIRQ3_NEW_INT ENDP


; SIRQ10 µÄÐÂÖÐ¶Ï³ÌÐò
SIRQ10_NEW_INT PROC FAR             
    PUSH AX    ; ÈëÕ»±£´æÏÖ³¡
    PUSH DX
    CLI        ; ¹ØÖÐ¶Ï


    MOV	DX, OFFSET MESS_SIRQ10   ; Êä³öÌáÊ¾×Ö·û´®
    MOV	AH, 09H                  ; DOS¹¦ÄÜºÅ: ÏÔÊ¾Êä³ö´®
    INT	21H 	                 ; DOSµ÷ÓÃÏÔÊ¾×Ö·û´®
    IN8 LED_STATUS, LED_ADDR     ; ´Ó 290H£¨´ý¶¨!!!£©¶Á»Ø LED µÆ×´Ì¬
    XOR LED_STATUS, 11111111B    ; Òì»òÔËËã£¬1 ±ä 0£¬0 ±ä 1
    OUT8 LED_ADDR, LED_STATUS    ; ·´×ª LED µÆ×´Ì¬
    DELAY 0FFFFH                 ; ÑÓ³Ù³ÌÐò
    DEC CX

    MOV AL, 20H   ; Ö÷Æ¬·¢EOIÃüÁî
  	OUT 20H, AL 
    MOV AL, 62H   ; ´ÓÆ¬·¢EOIÃüÁî
    OUT 0A0H, AL

    STI        ; ¿ªÖÐ¶Ï
    POP DX
    POP AX     ; ³öÕ»»Ö¸´ÏÖ³¡
    IRET       ; ÖÐ¶Ï·µ»Ø
SIRQ10_NEW_INT ENDP


; ï¿½Ó³ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ MIRQ3 ï¿½ï¿½ï¿½Ð¶ï¿½ï¿½ï¿½ï¿½ï¿½
SET_MIRQ3 PROC NEAR
    PUSH DS      
    MOV DI, 4*MIRQ3	                 ; 4 * ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Íºï¿½ = Òªï¿½Þ¸Äµï¿½ï¿½Ð¶ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ö·
    CLI

    MOV  BX, OFFSET MIRQ3_NEW_INT    ; ï¿½ï¿½ï¿½ï¿½ï¿½Ð¶ï¿½ï¿½ï¿½ï¿½ï¿½Æ«ï¿½Æµï¿½Ö·
    MOV  [DI], BX
    ADD  DI, 2

    MOV  BX, SEG MIRQ3_NEW_INT       ; ï¿½ï¿½ï¿½ï¿½ï¿½Ð¶ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Î»ï¿½ï¿½ï¿½Ö·
    MOV  [DI], BX
    POP  DS          
    RET
SET_MIRQ3 ENDP


; ï¿½Ó³ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ SIRQ10 ï¿½ï¿½ï¿½Ð¶ï¿½ï¿½ï¿½ï¿½ï¿½
SET_SIRQ10 PROC NEAR
    PUSH DS      
    MOV DI, 4*SIRQ10	              ; 4 * ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Íºï¿½ = Òªï¿½Þ¸Äµï¿½ï¿½Ð¶ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ö·
    CLI

    MOV  BX, OFFSET SIRQ10_NEW_INT    ; ï¿½ï¿½ï¿½ï¿½ï¿½Ð¶ï¿½ï¿½ï¿½ï¿½ï¿½Æ«ï¿½Æµï¿½Ö·
    MOV  [DI], BX
    ADD  DI, 2

    MOV  BX, SEG SIRQ10_NEW_INT       ; ï¿½ï¿½ï¿½ï¿½ï¿½Ð¶ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Î»ï¿½ï¿½ï¿½Ö·
    MOV  [DI], BX
    POP  DS          
    RET
SET_SIRQ10 ENDP

ENDS
END START