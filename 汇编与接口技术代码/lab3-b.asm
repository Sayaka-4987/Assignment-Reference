assume ds:data, ss:stack, cs:code

; 数据段，display 分别是 "8" "2" "5" "5" "-" "A" 的数码管字型代码表
data segment
    display db 7fh, 5bh, 6dh, 6dh, 40h, 77h
ends

stack segment
    dw   128  dup(0)
ends

; 常量定义 const
    PA = 280h
    PB = 281h
    PC = 282h
    CMD = 283h
; end const

; 宏定义，输出值到某端口
out16 macro port, val
    mov dx, port
    mov al, val
    out dx, al
endm

; 宏定义，从某端口读入值
in16 macro val, port
    mov dx, port
    in al, dx
    mov val, al
endm

code segment
start:
    mov ax, data
    mov ds, ax

    out16 CMD, 80h

  l0:

  ; 使数码管显示 "8255-A" 的伪代码如下：
  ; for si = 0, bl = 1; si != 6; si++, bl <<= 1 {
  ;     PC <- bl
  ;     PA <- display[si]
  ; }

  ; si 是段码数组下标，初始化为 0，每次自增 1 位
  ; bl 是位码变量，初始化为 1，每次左移 1 位 
    mov si, 0
    mov bl, 1
    jmp l2

  l1:
  ; 输出位码，选择要点亮的数码管
    out16 PC, bl
  ; 输出段码，显示指定的字型  
    out16 PA, display[si]
    shl bl, 1
    inc si

  l2:
    cmp si, 6
    jnz l1
  ; end for
    
    jmp l0
    
  ; 中断退出程序 exit()         
    mov ax, 4c00h ; exit to operating system.
    int 21h    
ends

end start ; set entry point and stop the assembler.
