;********** GETDETLS.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.

OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE MISCMACS.INC

IFDEF PDS
    Extrn cw_opnit7:proc
ENDIF

.CODE
CWGetDetails  PROC uses ds si di, sfln:PTR WORD,aryid:PTR WORD,
              dary:PTR WORD, ecd:PTR WORD

LOCAL t_mem [5]:WORD,f_hand:WORD

    hook_crit

IFNDEF PDS
    mov     bx,sfln
    invoke  cw_opnit                ;open file and check ID
ELSE
    Mov     SI,sfln
    Call    cw_opnit7
ENDIF
    
    cmp     ax,-3
    je      fin_sh
    cmp     ax,0
    jl      all_done

    mov     f_hand,bx
    s_fptr  4,0,0,-4,all_done       ;set fptr to first header
                                    ;cw_opnit read two extra bytes
                                    ;(there isn't a comment)
    mov     si,aryid
    mov     si,[si]
    
nxt_hdr:
    lea     dx,t_mem
    read_f  10,dx,-4,all_done       ;read ptr to next header
    cmp     si,t_mem+4
    je      this_ary
    .IF     t_mem == 0
    cmp     t_mem+2,0
    mov     ax,-16                  ;ID not found
    je      all_done
    .ENDIF
    s_fptr  t_mem,t_mem+2,0,-4,all_done ;set fptr to next header
    jmp     nxt_hdr
    
this_ary:
    mov     cx,t_mem+8
    shl     cx,1
    mov     si,dary
    mov     ds,[si+2]
    read_f  cx,0,-4,all_done
    push    ss
    pop     ds
    xor     ax,ax
    
all_done:
    mov     dx,ax
    close_f
    mov     ax,dx
    
fin_sh:
    mov     bx,ecd
    mov     [bx],ax

    unhook_crit  ecd
    ret
    
CWGetDetails  ENDP
END
