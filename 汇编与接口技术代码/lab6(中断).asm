assume ds:data, ss:stack, cs:code

; const
    M8259 = 20h
    MIRQ3 = 0bh

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

mask macro port, m
    in  al, port
    and al, m
    out port, al
endm

setint macro intno, handler
    push ds
    mov ax, 0
    mov ds, ax
    mov di, intno * 4
    cli
    mov bx, offset handler
    mov [di], bx
    add di, 2
    mov bx, seg handler
    mov [di], bx
    pop ds
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

; MIRQ3 新的中断程序
a2d proc far
    push ax                 ; AX 入栈保存现场
    cli                     ; 关中断
    out8    AD, 0           ; 进行假写操作，使 AD0809 启动转换
    in8     buf[di], AD     ; 读取 AD0809 转换的数据
    display buf[di]         ; 调用宏，数码管显示读入的数据
    out8    M8259, 20h      ; 8259 主片发送 EOI 命令
    inc di                  ; 计数器 DI++
    sti                     ; 开中断
    pop ax                  ; AX 出栈恢复现场
    iret                    ; 中断返回
endp

start:
    mov ax, data
    mov ds, ax                  ; DS 定位到数据段
    out8   CMD, 10000000b       ; 设置 8255 工作方式
    setint MIRQ3, a2d           ; 设置中断程序为子程序 a2d 
    mask   M8259+1, 11110111b   ; 8259 主片写入中断屏蔽字，开放 IR3
    out8   AD, 0ffh             ; 进行假写操作，AD0809 启动转换
    sti                         ; 开中断
    mov di, 0                   ; 计数器 DI++

  waiting:
    cmp di, 100     ; 判断是否已读入 100 个数据
    jnz waiting

    cli             ; 关中断
    mov ax, 4c00h   ; 返回 DOS 
    int 21h
ends

end start