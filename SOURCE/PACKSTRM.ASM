;*********** PACKSTRM.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.
;far strings mods by Ethan Winer

;to create the far strings version of this program assemble with /DPDS

OPTION EXPR16
.MODEL MEDIUM, BASIC
    INCLUDE  PCKARYMV.INC               ;uses the same variables
    INCLUDE  MISCMACS.INC

    Extrn B$ASSN: Proc
    
IFDEF PDS
    Extrn StringInfo: Proc
ENDIF

.CODE
CWPackStringM  PROC uses ds si di, strng:PTR WORD, ecd:PTR WORD

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

    mov     di,vari_loc
    xor     ax,ax                   ;zero out variable work area
    mov     cx,21
    rep     stosw

IFNDEF PDS
    mov     bx,strng
    mov     ax,[bx]		    ;get length
ELSE
    Mov     SI,strng
    Call    StringInfo              ;returns AX=address, CX=length, DX=segment
    Mov     AX,CX
ENDIF

    .IF     ax < 8		    ;must be at least 8 characters
    mov     ax,-14
    jmp     fin_sh
    .ENDIF

    push    es
    pop     ds
    mov     asize_l,ax
    mov     max_outl,ax             ;set max_out value

    add     ax,15                   ;amount for QB to release
    not     ax
    mov     dx,0FFFFh
    push    dx
    push    ax

    push    ss
    pop     ds
    call    B$SETM                  ;DS must be @data
    push    es
    pop     ds
    mov     ax,asize_l
    mov     cx,4
@@:
    shr     ax,1
    .IF     carry?
    inc     ax
    .ENDIF
    loop    @B
    mov     bx,ax
    mov     ah,48H
    int     21h
    .IF     CARRY?
    mov     ax,-1
    jmp     fin_sh
    .ENDIF
    mov     tmem_seg,ax
    mov     es,ax

    mov     total_l,2
    mov     stor_loc,2

IFNDEF PDS
    mov     bx,strng
    mov     ax,ss:[bx]              ;get length
    mov     es:[0],ax               ;save the length
    mov     ax,ss:[bx+2]
    push    ss
    pop     es
ELSE
    Push    DS
    Push    SS
    Pop     DS
    Mov     SI,strng
    Call    StringInfo              ;returns AX=address, CX=length, DX=segment
    Mov     ES:[0],CX
    Pop     DS
    Mov     ES,DX
ENDIF
    mov     i_buff_ptr,ax	    ;set start point

    invoke  acmps_main2

    cmp     ax,0
    jne     fin_sh

    mov     ax,tmem_seg
    mov     cx,total_l

    Push    SS		    ;fix DS for call to B$ASSN below
    Pop     DS
    
    Push    AX              ;source segment
    Sub     AX,AX
    Push    AX              ;source address (zero)
    Push    CX              ;source length

    Push    DS              ;destination segment (of the descriptor)
    Mov     AX,strng
    Push    AX              ;destination address
    Sub     AX,AX           ;show we're assigning to a regular string
    Push    AX              ;by passing a length of zero

    Call    B$ASSN          ;this copies to/from any mix of fixed-length
                            ;  and regular strings

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
    int     21h                     ;release tmp-mem
    push    ss
    pop     ds
    
    xor     ax,ax
    mov     dx,10
    push    dx
    push    ax
    call    B$SETM
    .ENDIF
    ret
CWPackStringM  ENDP
END
