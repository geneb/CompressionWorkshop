;********** CWCRITER.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.

OPTION EXPR16

.MODEL MEDIUM ,BASIC
    INCLUDE  MISCMACS.INC
    PUBLIC  old_crit
    PUBLIC  crit_stat
    PUBLIC  crit_er
    
.DATA
    old_crit  WORD 2  dup (0)
    crit_stat WORD 0
    crit_er   WORD 0
    
.CODE
CWCritErr  PROC
    sub     ax,ax
    xchg    ax,crit_er
    ret
CWCritErr  ENDP

CW_crit_hdlr  PROC
    sti
    push    ax
    push    si
    mov     ax,di
    mov     si,OFFSET crit_er
    mov     ss:[si],al          ;save the error code
    pop     si
    pop     ax
    xor     al,al               ;tell dos to ignore error
    iretf
CW_crit_hdlr  ENDP

END
