assume ds:data, ss:stack, cs:code

; ���ݶ�
data segment
ends

; ��ջ��
stack segment
ends

code segment
start:
; ��λ ds �����ݶ�
    mov ax, data
    mov ds, ax
 ; д�뷽ʽ����
    mov dx, 283H
    mov al, 00110100B
    out dx, al
; д�������ֵ
    mov dx, 280H
    mov ax, 1
    out dx, al
    mov al, ah
    out dx, al   

 ; д�뷽ʽ����
    mov dx, 283H
    mov al, 01110110B
    out dx, al
; д�������ֵ
    mov dx, 281H
    mov ax, 1
    out dx, al
    mov al, ah
    out dx, al   
ends
end start