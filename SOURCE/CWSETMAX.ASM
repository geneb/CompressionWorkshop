;************ CWSETMAX.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.

OPTION EXPR16
.MODEL MEDIUM ,BASIC
    EXTERN  cgfs_max:WORD
    
.CODE
CWSetMaxSize  PROC, maxv:PTR WORD
    mov     bx,maxv
    mov     ax,[bx]
    mov     cgfs_max,ax              ;requires double word
    mov     ax,[bx+2]
    mov     cgfs_max+2,ax
    ret
CWSetMaxSize ENDP
END
