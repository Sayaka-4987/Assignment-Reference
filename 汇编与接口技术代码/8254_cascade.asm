assume ds:data, ss:stack, cs:code

; ���ݶ�
data segment
ends

; ��ջ��
stack segment
ends

; �������� const
cn0 equ 280H
cn1 equ 281H
cn2 equ 282H
command_addr equ 283H
; end const

; �궨�壬���ֵ��ĳ�˿�
out8 macro port, val
    mov dx, port
    mov al, val
    out dx, al
endm

out16 macro port, val
    mov dx, port
    mov ax, val
    out dx, al
    mov al, ah
    out dx, al
endm

; �궨�壬��ĳ�˿ڶ���ֵ
in8 macro val, port
    mov dx, port
    in al, dx
    mov val, al
endm

; �궨�壬�ӳ� t ����������
delay macro t
local i, o
    mov cx, t
  o:nop
    push cx
        mov cx, 65535
      i:nop
        loop i
    pop cx
    loop o
endm

code segment
start:
; ��λ ds �����ݶ�
    mov ax, data
    mov ds, ax
    out8 command_addr, 00110100B ; ��ʽ���0�ż�����/��д2�ֽ�/2��ʽ/�����Ƽ���
    out16 cn0, 10 ; ������ֵ

    out8 command_addr, 01110110B ; ��ʽ���1�ż�����/��д2�ֽ�/3��ʽ/�����Ƽ���
    out16 cn1, 10

ends
end start