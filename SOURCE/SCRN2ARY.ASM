;*********** SCRN2ARY.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.

OPTION EXPR16
.MODEL MEDIUM ,BASIC
.CODE
CWScrn2Array PROC uses ds si di, sseg:PTR WORD, sofs:PTR WORD, byts:PTR WORD,
    ary:PTR WORD
    
    mov     bx,sofs
    mov     si,[bx]             ;source offset
    mov     bx,byts
    mov     cx,[bx]             ;# of bytes to copy
    xor     di,di               ;dynamic array starts at 0
    mov     bx,ary
    mov     es,[bx+2]           ;array's seg
    mov     bx,sseg
    mov     ds,[bx]             ;source seg
    rep     movsb               ;copy it
    ret
CWScrn2Array  ENDP
END
