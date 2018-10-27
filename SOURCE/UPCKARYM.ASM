;*********** UPCKARYM.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.

OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE UPCKARMV.INC
    INCLUDE MISCMACS.INC
    INCLUDE DCMPMACS.INC
    
.CODE
CWUnpackArrayM  PROC uses ds si di, dary:PTR WORD, ecd:PTR WORD
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
    mov     es,ax                   ;ES = work_seg
    mov     ds,ax                   ;DS = work_seg

    mov     di,vari_loc
    xor     ax,ax                   ;zero out variable work area
    mov     cx,21
    rep     stosw

    mov     bx,dary
    mov     al,ss:[bx+9]
    .IF     al > 3
    mov     ax,-15		    ;not dynamic
    jmp     fin_sh
    .ENDIF

    xor     dx,dx
    mov     ax,ss:[bx+6]	    ;# of paragraphs used
    mov     cx,4
@@:
    shl     ax,1
    .IF     CARRY?
    inc     dx
    .ENDIF
    loop    @B
    mov     tmp_var1,ax
    mov     tmp_var2,dx
    add     ax,15
    adc     dx,0                    ;amount for QB to release
    not     ax
    not     dx
    push    dx
    push    ax
    mov     di,ds
    push    ss
    pop     ds
    call    B$SETM		    ;DS must be @data

    mov     bx,dary		    ;# of paragraphs needed
    mov     bx,[bx+6]
    mov     ds,di
    mov     ah,48H
    int     21h
    .IF     CARRY?
    mov     ax,-1
    jmp     fin_sh
    .ENDIF
    mov     tmem_seg,ax
    mov     es,ax

    mov     ax,tmp_var1
    mov     dx,tmp_var2
    mov     bx,dary
    mov     ds,ss:[bx+2]
    xor     bx,bx
@@:
    xor     si,si
    xor     di,di
    .IF     dx == 0
    mov     cx,ax
    mov     bx,1
    .ELSE
    mov     cx,64000
    sub     ax,cx
    sbb     dx,0
    .ENDIF
    rep     movsb
    .IF     bx == 0
    mov     si,ds
    add     si,4000
    mov     ds,si
    mov     si,es
    add     si,4000
    mov     es,si
    jmp     @B
    .ENDIF

    push    ss
    pop     ds
    mov     ax,ary_wseg
    mov     ds,ax
    mov     es,tmem_seg
    push    ss
    mov     di,ds
    pop     ds

    mov     bx,dary		    ;get address of array header
    xor     si,si
    xor     ch,ch
    mov     cl,[bx+8]		    ;# of dims
    mov     ax,cx
    add     bx,10
@@:
    add     bx,4
    add     si,2
    loop    @B
    mov     dx,si
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
    mov     si,dx
    mov     bx,dary
    mov     ax,[bx+12]		     ;bpe
    push    ax
    mov     ax,[bx+8]
    push    ax
    push    bx
    call    B$RDIM

    mov     es,[bx+2]
    xor     dx,dx
    mov     ax,[bx+6]		    ;# of paragraphs used
    mov     cx,4
@@:
    shl     ax,1
    .IF     CARRY?
    inc     dx
    .ENDIF
    loop    @B
    mov     ds,di
    mov     asize_l,ax		    ;# of bytes
    mov     asize_h,dx
    mov     nxt_cd_loc,si

    invoke adcmp_main2		    ;call the decompression routine

    xor     ax,ax
fin_sh:
    push    ss
    pop     ds
    mov     bx,ecd
    mov     [bx],ax                 ;return ecd
    .IF     ax != -1
    mov     ax,ary_wseg
    mov     ds,ax
    mov     ax,tmem_seg
    mov     es,ax
    mov     ah,49H
    int     21h

    push    ss
    pop     ds
    xor     ax,ax
    mov     dx,10
    push    dx
    push    ax
    call    B$SETM
    .ENDIF

    ret
CWUnpackArrayM  ENDP
END
