;********** UPACKARY.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.
;far strings mods by Ethan Winer

;to create the far strings version of this program assemble with /DPDS

OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE UPCKARYV.INC
    INCLUDE MISCMACS.INC
    INCLUDE DCMPMACS.INC

IFDEF PDS
    Extrn StringInfo: Proc
ENDIF
    
.CODE
CWUnpackArray  PROC uses ds si di, dary:PTR WORD, aryid:PTR WORD,
    sfln:PTR WORD, ecd:PTR WORD
    
    hook_crit
    mov     ax,ary_wseg
    .IF     ax == 0                 ;if not already allocated
    mov     ax,4C40H                ;allocate memory
    mov     dx,0FFFFH
    push    dx
    push    ax
    call    B$SETM
    mov     ah,48H
    mov     bx,2875
    int     21h
    .IF     CARRY?
    mov     ax,-1
    jmp     fin_sh
    .ENDIF
    mov     ary_wseg,ax
    .ENDIF
    mov     es,ax

    mov     di,vari_loc
    xor     ax,ax                   ;zero out variable work area
    mov     cx,10
    rep     stosw

IFNDEF PDS
    mov     bx,sfln
    mov     cx,[bx]
    mov     si,[bx+2]               ;make ASCIIZ copy of
    xor     di,di                   ;source file name
    rep     movsb
    xor     al,al
    stosb
ELSE
    Mov     SI,sfln
    Call    StringInfo          ;returns AX=address, CX=length, DX=segment
    Mov     SI,AX
    Mov     DS,DX
    Sub     DI,DI
    Rep     Movsb
    Mov     ES:[DI],CL
ENDIF

    mov     ax,es
    mov     ds,ax                   ;change ds to ary_wseg

    open_r  0,-3,fin_sh             ;open file (R)
    mov     s_hand,bx               ;save handle
    read_f  4,0,-4,fin_sh           ;read file ID
    .IF     WORD PTR ds:[0] != 5346H || WORD PTR ds:[2] != 724AH
    mov     ax,-5                   ;check ID
    jmp     fin_sh
    .ENDIF

    mov     si,aryid
check_nxt:
    read_f  10,0,-4,fin_sh          ;read header
    mov     ax,ds:[4]
    cmp     ax,ss:[si]
    je      this_ary
    cmp     WORD PTR ds:[0],0
    jne     not_last
    cmp     WORD PTR ds:[2],0       ;last header?
    jne     not_last
    mov     ax,-16
    jmp     fin_sh
    
not_last:
    s_fptr  ds:[0],ds:[2],0,-4,fin_sh   ;set fptr to next header
    jmp     check_nxt
    
this_ary:
    push    ss
    pop     ds

    mov     si,dary                 ;get address of array header
    mov     al,[si+9]
    .IF     al > 3
    mov     ax,-15                  ;not dynamic
    jmp     fin_sh
    .ENDIF
    mov     ax,es:[6]
    .IF     ax != [si+12]
    mov     ax,-18                  ;B-P-E mismatch
    jmp     fin_sh
    .ENDIF
    mov     ax,es:[8]
    .IF     al != [si+8]
    mov     ax,-17                  ;dimension mismatch
    jmp     fin_sh
    .ENDIF
    shl     ax,1
    push    es
    pop     ds
    read_f  ax,0,-4,fin_sh          ;read a word/dim
    push    ss
    pop     ds

    mov     bx,dary
    xor     si,si
    xor     ch,ch
    mov     cl,[bx+8]               ;# of dims
    mov     ax,cx
    add     bx,10
@@:
    add     bx,4
    add     si,2
    loop    @B
    mov     cx,ax
@@:
    mov     ax,[bx+2]
    push    ax
    sub     si,2
    add     ax,es:[si]
    dec     ax
    push    ax
    sub     bx,4
    loop    @B

    mov     bx,dary
    mov     ax,[bx+12]
    push    ax
    mov     ax,[bx+8]
    push    ax
    push    bx
    call    B$RDIM

    push    es
    mov     es,[bx+2]
    xor     dx,dx
    mov     ax,[bx+6]               ;# of paragraphs used
    mov     cx,4
@@:
    shl     ax,1
    .IF     CARRY?
    inc     dx
    .ENDIF
    loop    @B
    pop     ds
    mov     asize_l,ax
    mov     asize_h,dx

    invoke adcmp_main               ;call the decompression routine

fin_sh:
    push    ss
    pop     ds
    mov     bx,ecd
    mov     [bx],ax                 ;return ecd
    .IF     ax != -1
    mov     ax,ary_wseg
    mov     ds,ax
    .IF     s_hand != 0
    mov     bx,s_hand
    close_f                         ;if source open close it
    .ENDIF
    .ENDIF
    
    unhook_crit  ecd
    ret
    
CWUnpackArray  ENDP
END
