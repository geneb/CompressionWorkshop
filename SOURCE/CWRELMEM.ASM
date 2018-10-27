;*********** CWRELMEM.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.
;
OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE MISCMACS.INC
    
.CODE
CWReleaseMem  PROC uses ds, mde:PTR WORD
    mov     bx,mde
    mov     ax,[bx]
    .IF     ax == 0
    mov     ax,work_seg
    mov     work_seg,0
    .ELSE
    mov     ax,ary_wseg
    mov     ary_wseg,0
    .ENDIF
    .IF     ax != 0
    mov     es,ax
    mov     ah,49H
    int     21h
    xor     ax,ax
    mov     dx,10
    push    dx
    push    ax
    call    B$SETM
    .ENDIF
    ret
CWReleaseMem  ENDP
END
