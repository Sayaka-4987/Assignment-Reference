assume ds:data, ss:stack, cs:code

; 数据段
data segment
ends

; 堆栈段
stack segment
ends

code segment
start:
; 定位 ds 到数据段
    mov ax, data
    mov ds, ax
 ; 写入方式命令
    mov dx, 283H
    mov al, 00110100B
    out dx, al
; 写入计数初值
    mov dx, 280H
    mov ax, 1
    out dx, al
    mov al, ah
    out dx, al   

 ; 写入方式命令
    mov dx, 283H
    mov al, 01110110B
    out dx, al
; 写入计数初值
    mov dx, 281H
    mov ax, 1
    out dx, al
    mov al, ah
    out dx, al   
ends
end start