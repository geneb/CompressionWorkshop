;****** USTRARY.ASM
;** (C) Copyright 1992 Fred Sexton Jr.
;**
;

;to create the far strings version of this program assemble with /DPDS

OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE MISCMACS.INC
    EXTRN B$ERAS: Proc
    CWUnPackArray PROTO
    StringInfo    PROTO
.CODE
CWUnPackStrArray  PROC uses ds si di , dary:PTR WORD, aryid:PTR WORD,
                       sfln:PTR WORD, ecd:PTR WORD
Local ary_hdr [10]:WORD,str_cnt:WORD,nxt_hdr:WORD

    mov     ax,ds              ;zero out the temp array header
    mov     es,ax
    lea     di,ary_hdr
    mov     cx,10
    xor     ax,ax
    rep     stosw

    xor     ax,ax
    push    ax
    push    ax
    mov     ax,2
    push    ax
    mov     ax,513
    push    ax
    lea     ax,ary_hdr
    push    ax
    call    B$RDIM             ;make a temp array

    lea     ax,ary_hdr
    push    ax
    mov     ax,aryid
    push    ax
    mov     ax,sfln
    push    ax
    mov     ax,ecd
    push    ax
    call    CWUnPackArray          ;decompress
    mov     bx,ecd
    mov     ax,[bx]
    cmp     ax,0
    jne     fin_sh

    mov     ax,ds
    mov     es,ax
    mov     ds,ary_hdr+2
    xor     si,si
    lodsw
    mov     str_cnt,ax             ;number of strings
    push    ss
    pop     ds

    mov     bx,dary
    mov     ax,[bx+16]
    push    ax
    add     ax,str_cnt
    push    ax
    mov     ax,[bx+12]
    push    ax
    mov     ax,[bx+8]
    push    ax
    push    bx
    call    B$RDIM             ;redim string array

    mov     ax,[bx+10]
    mov     nxt_hdr,ax
    mov     ds,ary_hdr+2
@@:
    lodsw
    push    ss
    pop     ds
    push    ax
    call    B$SPAC          ;make a string of proper length
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
    mov     ds,ary_hdr+2
    rep     movsb
    dec     str_cnt
    jnz     @B
fin_sh:
    push    ss
    pop     ds
    lea     ax,ary_hdr
    push    ax
    call    B$ERAS
    ret
CWUnPackStrArray  ENDP
END
