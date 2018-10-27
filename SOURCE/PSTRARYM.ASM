;****** PSTRARYM.ASM
;** (C) Copyright 1992 Fred Sexton Jr.
;**
;
OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE MISCMACS.INC
    CWPackArrayM PROTO
    StringInfo   PROTO
    stringlength PROTO
.CODE
CWPackStrArrayM  PROC uses ds si di ,str_ary:PTR WORD,sto_ary:PTR WORD,
                     ecd:PTR WORD

    mov     bx,str_ary
    mov     cx,[bx+14]          ;get number of strings
    mov     si,[bx+10]          ;and first string element's address
    mov     ax,4
    mul     Word Ptr [bx+10h]
    add     si,ax
    xor     dx,dx
    
@@:
IFNDEF PDS
    lodsw
ELSE
    push    cx
    push    dx
    push    si
    call    stringlength
    pop     dx
    pop     cx
    inc     si
    inc     si
ENDIF
    add     dx,ax               ;add up total bytes needed
    inc     dx
    inc     dx                  ;add a word for each string's length
    inc     si                  ;bump past the second descriptor word
    inc     si
    loop    @B
    inc     dx                  ;in case it's odd
    shr     dx,1                ;get word count

    push    cx                  ;start at 0 -
    push    dx                  ;get's us an extra word
    mov     bx,sto_ary
    mov     ax,[bx+12]
    push    ax
    mov     ax,[bx+8]
    push    ax
    push    bx
    call    B$RDIM              ;make sto_ary the right size

    mov     es,[bx+2]
    xor     di,di
    mov     bx,str_ary
    mov     ax,[bx+14]

    stosw
    push    ax
    mov     ax,4
    mul     Word Ptr [bx+10h]
    mov     bx,[bx+10]
    add     bx,ax
    pop     ax

@@:
    mov     si,bx
IFNDEF PDS
    mov     cx,[si]
    movsw
    mov     si,[si]
ELSE
    push    ss
    pop     ds
    push    ax
    call    stringinfo
    mov     si,ax
    mov     ax,cx
    stosw
    mov     ds,dx
    pop     ax
ENDIF
    rep     movsb               ;copy string to integer array
    add     bx,4
    dec     ax
    jnz     @B

IFDEF PDS
    push    ss
    pop     ds
ENDIF

    mov     ax,sto_ary
    push    ax
    mov     ax,ecd
    push    ax
    call    CWPackArrayM

    ret
CWPackStrArrayM  ENDP
END
