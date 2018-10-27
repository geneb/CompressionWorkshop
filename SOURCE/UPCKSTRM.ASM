;*********** UPCKSTRM.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.
;far strings mods by Ethan Winer

;to create the far strings version of this program assemble with /DPDS

OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE UPCKARMV.INC            ;uses same variables
    INCLUDE MISCMACS.INC
    INCLUDE DCMPMACS.INC

IFDEF PDS
    Extrn StringInfo: Proc
ENDIF
    
.CODE
CWUnpackStringM PROC uses ds si di, strng:PTR WORD, ecd:PTR WORD
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

    push    es
    pop     ds
    mov     tmp_var1,ax
    add     ax,15                   ;amount for QB to release
    not     ax
    mov     dx,0FFFFh
    push    dx
    push    ax
    push    ss
    pop     ds
    call    B$SETM		    ;DS must be @data
    push    es
    pop     ds
    mov     ax,tmp_var1
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

    push    ss
    pop     ds

IFNDEF PDS
    mov     bx,strng
    mov     si,[bx+2]
    xor     di,di
    mov     cx,[bx]
    rep     movsb
ELSE
    Mov     SI,strng
    Call    StringInfo          ;returns AX=address, CX=length, DX=segment
    Mov     SI,AX
    Mov     DS,DX
    Sub     DI,DI
    Rep     Movsb
    push    ss
    pop     ds
ENDIF

    mov     ax,es:[0]
    push    ax
    call    B$SPAC
    push    ax                      ;resize original string
    mov     ax,strng
    push    ax
    call    B$SASS

    mov     ax,ary_wseg
    mov     ds,ax
    mov     es,tmem_seg
    mov     ax,es:[0]
    mov     asize_l,ax

IFNDEF PDS
    push    ss
    pop     es
    mov     bx,strng
    mov     ax,ss:[bx+2]
ELSE
    Push    DS
    Push    SS
    Pop     DS
    Mov     SI,strng
    Call    StringInfo          ;returns AX=address, CX=length, DX=segment
    Mov     ES,DX
    Pop     DS
ENDIF

    mov     op_ptr,ax
    mov     nxt_cd_loc,2
    
    invoke adcmp_main2              ;call the decompression routine

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
CWUnpackStringM ENDP
END
