assume ds:data, ss:stack, cs:code

; const
    M8259 = 20h
    S8259 = 0a0h

    MIRQ3 = 0bh
    SIRQ10 = 72h

    ; 8255
    PA = 280h
    PB = 281h
    PC = 282h
    CMD = 283h
; end

data segment
    light db 0
ends

stack segment stack
    dw   128  dup(0)
ends

; 宏定义：输出值到某端口
out8 macro port, val
    mov dx, port
    mov al, val
    out dx, al
endm

; 宏定义：从某端口读入值
in8 macro val, port
    mov dx, port
    in al, dx
    mov val, al
endm

; 宏定义：先读再与，写入 8259 中断屏蔽信息
mask macro port, m
    in al, port
    and al, m
    out port, al
endm

; 宏定义：设置中断向量地址
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

code segment
; MIRQ3 的新中断程序
twinkle1 proc far
    push ax
    cli
    xor light, 1
    out8 PA, light
    inc si
    out8 M8259, 20h
    sti
    pop ax
    iret
endp

; SIRQ10 的新中断程序
twinkle2 proc far
    push ax
    cli
    xor light, 1
    out8 PA, light
    inc si
    out8 M8259, 20h
    out8 S8259, 62h
    sti
    pop ax
    iret
endp

start:
; 定位 DS 到数据段
    mov ax, data
    mov ds, ax

; 设置 8255 工作命令     
    out8 cmd, 10000000b

; 设置中断向量指向新中断程序   
    setint MIRQ3, twinkle1
    setint SIRQ10, twinkle2

; 分别设置主片和从片的中断屏蔽字
    mask M8259+1, 11110011b
    mask S8259+1, 11111011b

; 计数变量初始化    
    mov si, 0

; 开中断    
    sti

  l1:
  ; 循环等待中断
    cmp si, 10
    jnz l1

; 关中断      
    cli

    mov ax, 4c00h
    int 21h
ends

end start