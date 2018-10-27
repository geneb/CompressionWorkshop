;*********** PACKARYM.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.

OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE  PCKARYMV.INC
    INCLUDE  MISCMACS.INC
    
.CODE
CWPackArrayM  PROC uses ds si di, sary:PTR WORD, ecd:PTR WORD
    mov     ax,ary_wseg
    .IF     ax == 0             ;if not already allocated
    mov     ax,4C40H            ;allocate memory
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
    mov     es,ax               ;ES = work_seg
    mov     ds,ax               ;DS = work_seg

    mov     di,vari_loc
    xor     ax,ax               ;zero out variable work area
    mov     cx,21
    rep     stosw

    mov     bx,sary
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
    mov     asize_l,ax		    ;# of bytes
    mov     asize_h,dx
    mov     max_outl,ax 	    ;set max_out value
    mov     max_outh,dx

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

    mov     bx,sary		    ;# of paragraphs needed
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

    mov     bx,sary
    xor     di,di
    xor     ch,ch
    mov     cl,ss:[bx+8]	     ;# of dimensions
    add     bx,14
@@:
    mov     ax,ss:[bx]		     ;# of elements each dimension
    stosw
    add     bx,4
    loop    @B

    mov     total_l,di
    mov     stor_loc,di
    mov     bx,sary
    mov     es,ss:[bx+2]	      ;set es to array seg-

    invoke  acmps_main2

    cmp     ax,0
    jne     fin_sh

    mov     bx,sary		    ;get address of array header
    xor     ch,ch
    mov     cl,ss:[bx+8]	    ;# of dims
    xor     dx,dx
    mov     ax,ss:[bx+12]	    ;B-P-E
    mul     cx
    mov     cx,ax
    mov     ax,total_l
    mov     dx,total_h
    div     cx
    .IF     dx == 0
    dec     ax
    .ENDIF
    mov     dx,ax		    ;# of elments/dim needed to store
    push    ss
    mov     si,ds
    pop     ds

    xor     ch,ch
    mov     cl,[bx+8]		    ;# of dims
    add     bx,16
@@:
    mov     ax,[bx]
    push    ax			    ;first element #
    add     ax,dx
    push    ax			    ;last element #
    add     bx,4
    loop    @B

    mov     bx,sary
    mov     ax,[bx+12]		    ;B-P-E
    push    ax
    mov     ax,[bx+8]		    ;type and # of dims
    push    ax
    push    bx			    ;addr
    call    B$RDIM

    mov     es,[bx+2]
    mov     ds,si
    mov     ax,total_l
    mov     dx,total_h
    mov     ds,tmem_seg

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
    rep     movsb			;copy the data
    .IF     bx == 0
    mov     si,ds
    add     si,4000
    mov     ds,si
    mov     si,es
    add     si,4000
    mov     es,si
    jmp     @B
    .ENDIF

    xor     ax,ax
fin_sh:
    push    ss
    pop     ds
    mov     bx,ecd
    mov     [bx],ax             ;return ecd
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
CWPackArrayM  ENDP
END
