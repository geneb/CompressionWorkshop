;*********** CWOPENIT.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.

;opens CW file
;checks CW ID.
;returns:ecode in AX, handle in BX, comment length in CX
;
OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE   MISCMACS.INC
    
.CODE
cw_opnit  PROC

LOCAL  t_mem [40]:WORD

    push    ss
    pop     es

    mov     cx,[bx]             ;bx will have addr of a QB
    mov     si,[bx+2]           ;string header
    lea     di,t_mem            ;make ASCIIZ copy of
    rep     movsb               ;source file name
    xor     al,al
    stosb
    lea     dx,t_mem
    open_r  dx,-3,fin_sh        ;open file
    read_f  6,dx,-4,fin_sh      ;read file ID and comment length
    xor     cx,cx
    mov     ax,t_mem
    .IF     ax != 5346H         ;check ID
    mov     cx,-5               ;ecd= -5 file not correct type
    .ENDIF
    mov     ax,t_mem+2
    .IF     ax != 724AH         ;check ID
    mov     cx,-5               ;ecd= -5 file not correct type
    .ENDIF
    mov     ax,cx
    mov     cx,t_mem+4
fin_sh:
    ret
cw_opnit  ENDP

END
