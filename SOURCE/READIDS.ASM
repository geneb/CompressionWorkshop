;********** READIDS.ASM - reads array IDs and sizes from a compressed file
;
;Copyright (c) 1992 Fred Sexton Jr.

OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE MISCMACS.INC

IFDEF PDS
    Extrn cw_opnit7:proc
ENDIF

.CODE
CWReadIDs PROC uses ds si di, sfln:PTR WORD, dary:PTR WORD, ecd:PTR WORD

LOCAL t_mem [5]:WORD,f_hand:WORD,a_cnt:WORD

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
    mov     a_cnt,0
    
nxt_hdr:
    lea     dx,t_mem
    read_f  4,dx,-4,all_done        ;read ptr to next header
    .IF     t_mem == 0
    cmp     t_mem+2,0
    je      count_d
    .ENDIF
    inc     a_cnt                   ;count arrays
    s_fptr  t_mem,t_mem+2,0,-4,all_done ;set fptr to next header
    jmp     nxt_hdr

count_d:
    mov     si,dary
    mov     ax,[si+16]
    push    ax
    add     ax,a_cnt                ;count
    push    ax
    mov     ax,6
    push    ax
    mov     ax,[si+8]
    push    ax
    push    si
    call    B$RDIM                  ;redimension the array

    mov     bx,f_hand
    s_fptr  4,0,0,-4,all_done       ;set fptr to first header
    inc     a_cnt
    mov     es,[si+2]               ;set es to array seg
    xor     di,di
    
more_arys:
    lea     dx,t_mem
    read_f  10,dx,-4,all_done
    lea     si,t_mem+4
    mov     cx,3
    rep     movsw

    dec     a_cnt
    .IF     a_cnt != 0
    s_fptr  t_mem,t_mem+2,0,-4,all_done ;set fptr to next header
    jmp     more_arys
    .ENDIF

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
    
CWReadIDs  ENDP
END
