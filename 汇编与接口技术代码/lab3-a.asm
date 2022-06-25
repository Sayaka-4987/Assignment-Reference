assume ds:data, ss:stack, cs:code

; 数据段，mask 是实现流水效果的数组
data segment
    mask db 10000000b, 11000000b, 11100000b, 11110000b, 11111000b, 11111100b, 11111110b, 11111111b
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
  
    out16 CMD, 90h

  l0:  
  ; 读入与开关 K7-K0 相连的 A 口数据
    in16 ah, PA

  ; LED 流水的伪代码如下，其中 mask 是亮灯数据的打表数组，高电平有效 : 
  ; for si = 0; si != 8; si++ {
  ;     PB <- (ah & mask[si])
  ;     delay(10)
  ; }

  ; si 初始化为0
    mov si, 0
    jmp l2

  l1:
  ; 把 LED 灯的设定值输出到 B 口点亮
    mov al, ah
    and al, mask[si]
    out16 PB, al
    delay 10
    inc si

  l2:
  ; 判断循环终止条件
    cmp si, 8
    jnz l1
  ; end for
    
    jmp l0
    
  ; 中断退出程序 exit()         
    mov ax, 4c00h
    int 21h    
ends

end start