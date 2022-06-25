; 工作方式2的源程序
assume ds:data, ss:stack, cs:code

; 数据段
data segment
ends

; 堆栈段
stack segment
ends

; 常量定义 const
cn0 equ 280H
cn1 equ 281H
cn2 equ 282H
command_addr equ 283H
; end const

; 宏定义，输出值到某端口
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

; 宏定义，从某端口读入值
in8 macro val, port
    mov dx, port
    in al, dx
    mov val, al
endm

; 宏定义，延迟 t 个机器周期
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
; 定位 ds 到数据段
    mov ax, data
    mov ds, ax
    out8 command_addr, 00110100B ; 写入方式命令，选0号计数器，读写2字节，2方式，二进制计数
    out16 cn0, 1000  ; 写入计数器初值1000D
ends
end start