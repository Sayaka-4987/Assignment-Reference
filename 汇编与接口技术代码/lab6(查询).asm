assume ds:data, ss:stack, cs:code

; const
    ; 8255
    PA = 280h
    PB = 281h
    PC = 282h
    CMD = 283h

    AD = 298h
; end

data segment
    buf db 128 dup(0)       ; 存放转换后的数据
    dgt db 3FH, 06H, 5BH, 4FH, 66H, 6DH, 7DH, 07H, 7FH, 6FH, 77H, 7CH, 39H, 5EH, 79H, 71H   ; 数码管段码打表
ends

stack segment stack
    dw   128  dup(0)
ends

out8 macro port, val
    mov dx, port
    mov al, val
    out dx, al
endm

in8 macro val, port
    mov dx, port
    in  al, dx
    mov val, al
endm

; 宏定义，将 val 参数的值显示到数码管 
display macro val
    xor  ax, ax
    mov  al, val
    mov  si, ax
    and  si, 1111b      ; 取低 4 位
    out8 PB, 0          ; 此处为了显示效果更加清晰，输出位码前先清零位码
    out8 PA, dgt[si]    ; PA 输出段码，PB 输出位码
    out8 PB, 1b
    xor  ax, ax
    mov  al, val
    mov  si, ax
    shr  si, 4          
    and  si, 1111b      ; 取高 4 位
    out8 PB, 0          ; PA 输出段码，PB 输出位码
    out8 PA, dgt[si]
    out8 PB, 10b
endm

code segment

start:
    mov  ax, data
    mov  ds, ax             ; DS 定位到数据段
    out8 CMD, 10000000b     ; 设置 8255 工作方式
    mov  di, 0              ; 设置计数器 DI 初值为 0

  next:
    out8    AD, 0           ; 进行假写操作，使 AD0809 启动转换
    in8     buf[di], AD     ; 读取 AD0809 转换的数据
    display buf[di]         ; 调用宏，数码管显示读入的数据
    inc  di                 ; 计数器 DI++
    cmp  di, 100            ; 判断是否已读入 100 个数据
    jnz  next

    mov  ax, 4c00h          ; 返回 DOS 
    int  21h
ends

end start