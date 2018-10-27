;*********** CWOPEN7.ASM - far strings version of CWOPENIT.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.
;far strings mods by Ethan Winer

;opens CW file
;checks CW ID.
;returns:ecode in AX, handle in BX, comment length in CX
;
OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE   MISCMACS.INC

    Extrn StringInfo: Proc
    
.CODE
cw_opnit7  PROC

LOCAL  t_mem [40]:WORD

    push    ss
    pop     es

;start of far strings addition
    Push    DS
    Call    StringInfo          ;returns AX=address, CX=length, DX=segment
    Mov     SI,AX
    Mov     DS,DX
    Lea     DI,t_mem
    Mov     DX,DI               ;save it while we got it for open_r below
    Rep     Movsb
    Mov     ES:[DI],CL
    Pop     DS
;end of far strings addition


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
cw_opnit7  ENDP

END
