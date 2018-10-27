;****** USTRARYM.ASM
;** (C) Copyright 1992 Fred Sexton Jr.
;**
;
OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE MISCMACS.INC
    CWUnPackArrayM PROTO
    StringInfo	   PROTO
.CODE
CWUnPackStrArrayM  PROC uses ds si di ,str_ary:PTR WORD,sto_ary:PTR WORD,
				     ecd:PTR WORD
Local sto_seg:WORD,str_cnt:WORD,nxt_hdr:WORD

    mov     ax,sto_ary
    push    ax
    mov     ax,ecd
    push    ax
    call    CWUnPackArrayM
    mov     bx,ecd
    mov     ax,[bx]
    cmp     ax,0
    jne     fin_sh

    mov     ax,ds
    mov     es,ax
    mov     bx,sto_ary
    mov     ds,[bx+2]
    xor     si,si
    lodsw
    mov     str_cnt,ax		       ;number of strings
    push    ss
    pop     ds

    mov     bx,str_ary
    mov     ax,[bx+16]
    push    ax
    add     ax,str_cnt
    push    ax
    mov     ax,[bx+12]
    push    ax
    mov     ax,[bx+8]
    push    ax
    push    bx
    call    B$RDIM		       ;redim str_ary

    mov     ax,[bx+10]
    mov     nxt_hdr,ax
    mov     bx,sto_ary
    mov     ds,[bx+2]
    mov     sto_seg,ds
@@:
    lodsw
    push    ss
    pop     ds
    push    ax
    call    B$SPAC		    ;make a string of proper length
    push    ax
    mov     ax,nxt_hdr
    push    ax
    call    B$SASS
    mov     bx,nxt_hdr
    add     nxt_hdr,4
IFNDEF PDS
    mov     cx,[bx]
    mov     di,[bx+2]
ELSE
    push    si
    mov     si,bx
    call    stringinfo
    mov     di,ax
    mov     es,dx
    pop     si
ENDIF
    mov     ds,sto_seg
    rep     movsb
    dec     str_cnt
    jnz     @B
fin_sh:

    ret
CWUnPackStrArrayM  ENDP
END
