;********** ARY2SCRN.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.


OPTION EXPR16
.MODEL MEDIUM ,BASIC
.CODE
CWArray2Scrn PROC uses ds si di, tseg:PTR WORD, tofs:PTR WORD, byts:PTR WORD,
    ary:PTR WORD
    
    mov     bx,tofs
    mov     di,[bx]             ;target offset
    mov     bx,byts
    mov     cx,[bx]             ;# of bytes to copy
    xor     si,si               ;dynamic array starts at 0
    mov     bx,tseg
    mov     es,[bx]             ;target seg
    mov     bx,ary
    mov     ds,[bx+2]           ;array's seg
    rep     movsb               ;copy it
    ret
CWArray2Scrn  ENDP
END
