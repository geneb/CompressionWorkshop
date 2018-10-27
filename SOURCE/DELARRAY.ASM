;********** DELARRAY.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.
;far strings mods by Ethan Winer

;to create the far strings version of this program assemble with /DPDS

OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE  DELARRYV.INC
    INCLUDE  MISCMACS.INC

IFDEF PDS
    Extrn StringInfo: Proc
ENDIF

.CODE
CWDelArray  PROC uses ds si di, sfln:PTR WORD, daryid:PTR WORD, ecd:PTR WORD
    hook_crit
    mov     ax,ary_wseg
    .IF     ax == 0                 ;if not alredy allocated
    mov     ax,4C40H                ;allocate memory
    mov     dx,0FFFFH
    push    dx
    push    ax
    call    B$SETM
    mov     ah,48H
    mov     bx,2875
    int     21h
    Chek_crit
    .IF     CARRY?
    mov     ax,-1
    jmp     fin_sh
    .ENDIF
    mov     ary_wseg,ax
    .ENDIF
    mov     es,ax

    mov     di,vari_loc
    xor     ax,ax                   ;zero out variable work area
    mov     cx,20
    rep     stosw

IFNDEF PDS
    mov     bx,sfln
    mov     cx,[bx]
    mov     si,[bx+2]               ;make ASCIIZ copy of
    mov     di,cwfn_copy            ;CW file name
    rep     movsb
    xor     al,al
    stosb
ELSE
    Push    DS
    Mov     SI,sfln
    Call    StringInfo
    Mov     SI,AX
    Mov     DS,DX
    Mov     DI,cwfn_copy
    Rep     Movsb
    Mov     ES:[DI],CL
    Pop     DS
ENDIF

    mov     bx,daryid
    mov     dx,[bx]
    mov     ax,es
    mov     ds,ax                   ;change ds to work_seg
    mov     ary_id,dx

    open_rw cwfn_copy,-2,fin_sh     ;open file
    mov     cw_hand,bx              ;save handle
    read_f  4,0,-4,fin_sh           ;read file ID

    .IF  WORD PTR ds:[0] != 5346H  ||  WORD PTR ds:[2] != 724AH
    mov     ax,-5                   ;check ID
    jmp     fin_sh
    .ENDIF

    mov     ax,4
    mov     this_r_hdrl,ax
    mov     this_w_hdrl,ax

nxt_array:
    read_f  6,0,-4,fin_sh

    mov     ax,ds:[0]
    mov     nxt_r_hdrl,ax
    mov     ax,ds:[2]               ;save next fptr
    mov     nxt_r_hdrh,ax

    mov     ax,ds:[4]
    cmp     ax,ary_id
    jne     keep_ary

    .IF     nxt_r_hdrl == 0 && nxt_r_hdrh == 0
    s_fptr  this_r_hdrl,this_r_hdrh,0,-4,fin_sh
    xor     cx,cx
    mov     ah,40h                  ;truncate the file
    int     21h
    s_fptr  prev_r_hdrl,prev_r_hdrh,0,-4,fin_sh
    mov     tmp_var1,0
    mov     tmp_var2,0
    write_f 4,tmpv_loc,-4,fin_sh
    jmp     del_done
    .ENDIF

    s_fptr  nxt_r_hdrl,nxt_r_hdrh,0,-4,fin_sh
    mov     this_r_hdrl,ax
    mov     this_r_hdrh,dx
    jmp     nxt_array

keep_ary:
    mov     ax,this_r_hdrl
    mov     dx,this_r_hdrh
    mov     prev_r_hdrl,ax
    mov     prev_r_hdrh,dx

    .IF     dx == this_w_hdrh && ax == this_w_hdrl
    .IF     nxt_r_hdrl == 0 && nxt_r_hdrh == 0
    jmp     del_done
    .ENDIF
    s_fptr  nxt_r_hdrl,nxt_r_hdrh,0,-4,fin_sh
    mov     this_r_hdrl,ax
    mov     this_w_hdrl,ax
    mov     this_r_hdrh,dx
    mov     this_w_hdrh,dx
    jmp     nxt_array
    .ENDIF

    s_fptr  this_w_hdrl,this_w_hdrh,0,-4,fin_sh
    mov     tmp_var1,0              ;write four zeroes this is where the
    mov     tmp_var2,0              ;fptr to next header will be written
    write_f 4,tmpv_loc,-4,fin_sh    ;if another array is added

    s_fptr  0,0,1,-4,fin_sh
    mov     tmp_var2,ax
    mov     tmp_var3,dx

    add     this_r_hdrl,4
    adc     this_r_hdrh,0
    mov     ax,nxt_r_hdrl
    mov     dx,nxt_r_hdrh
    .IF     ax == 0 && dx == 0
    s_fptr  0,0,2,-4,fin_sh
    .ENDIF

    sub     ax,this_r_hdrl
    sbb     dx,this_r_hdrh
    mov     asize_l,ax
    mov     asize_h,dx
    mov     tmp_var1,0

cpy_cont:
    .IF     asize_h == 0
    .IF     asize_l <= 55800        ;read 55800 at a time
    mov     ax,asize_l
    mov     tmp_var1,1              ;done indicator
    .ELSE
    sub     asize_l,55800
    mov     ax,55800
    .ENDIF
    .ELSE
    sub     asize_l,55800
    sbb     asize_h,0
    mov     ax,55800
    .ENDIF
    mov     tmp_var4,ax

    s_fptr  this_r_hdrl,this_r_hdrh,0,-4,fin_sh
    read_f  tmp_var4,0,-4,fin_sh        ;read some in
    s_fptr  0,0,1,-4,fin_sh
    mov     this_r_hdrl,ax
    mov     this_r_hdrh,dx
    s_fptr  tmp_var2,tmp_var3,0,-4,fin_sh
    write_f tmp_var4,0,-4,fin_sh        ;write some out
    s_fptr  0,0,1,-4,fin_sh
    mov     tmp_var2,ax
    mov     tmp_var3,dx

    cmp     tmp_var1,1                  ;done?
    jne     cpy_cont

    .IF     prev_w_hdrh == 0
    cmp     prev_w_hdrl,0
    je      was_1st
    .ENDIF
    s_fptr  prev_w_hdrl,prev_w_hdrh,0,-4,fin_sh ;set fptr to hdr of previously
                                        ;  processed array
    write_f 4,thdr_loc,-4,fin_sh        ;write location of hdr of
                                        ;array that was added
was_1st:
    mov     ax,this_w_hdrl
    mov     prev_w_hdrl,ax              ;save fptr to hdr of array
    mov     ax,this_w_hdrh              ;just processed
    mov     prev_w_hdrh,ax

    mov     ax,tmp_var2
    mov     this_w_hdrl,ax
    mov     ax,tmp_var3
    mov     this_w_hdrh,ax

    .IF     nxt_r_hdrl != 0 || nxt_r_hdrh != 0
    s_fptr  nxt_r_hdrl,nxt_r_hdrh,0,-4,fin_sh
    mov     this_r_hdrl,ax
    mov     this_r_hdrh,dx
    jmp     nxt_array
    .ENDIF

    s_fptr  this_w_hdrl,this_w_hdrh,0,-4,fin_sh
    xor     cx,cx
    mov     ah,40h                  ;truncate the file
    int     21h

del_done:
    xor     ax,ax                   ;ecd=0
fin_sh:
    push    ss
    pop     ds
    mov     bx,ecd
    mov     [bx],ax                 ;return ecd

    .IF     ax != -1
    mov     ax,ary_wseg
    mov     ds,ax
    .IF     cw_hand != 0
    mov     bx,cw_hand
    close_f                         ;if cwfile open close it
    .ENDIF
    .ENDIF
    unhook_crit  ecd
    ret
CWDelArray  ENDP
END
