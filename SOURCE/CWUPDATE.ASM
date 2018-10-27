;*********** CWUPDATE.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.
;far strings mods by Ethan Winer

;to create the far strings version of this program assemble with /DPDS

OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE  PACKFLSV.INC
    INCLUDE  MISCMACS.INC
    
    cgfn_copy TEXTEQU <55785>
    tmpf_copy TEXTEQU <55852>
    tmp_var4  TEXTEQU  <WORD PTR ds:[55992]>

IFDEF PDS
    Extrn StringInfo: Proc
ENDIF

.CODE
CWUpdate  PROC uses ds si di, sfln:PTR WORD, tfln:PTR WORD, ecd:PTR WORD
    hook_crit
    mov     ax,work_seg
    .IF     ax == 0                 ;if not alredy allocated
    get_mem  -1,fin_sh              ;allocate memory
    .ENDIF
    mov     es,ax

    mov     di,vari_loc
    xor     ax,ax                   ;zero out variable work area
    mov     cx,40
    rep     stosw

IFNDEF PDS
    mov     bx,sfln
    mov     cx,[bx]
    mov     si,[bx+2]               ;make ASCIIZ copy of
    mov     di,cgfn_copy            ;CW file name
    rep     movsb
    xor     al,al
    stosb
ELSE
    Push    DS
    Mov     SI,sfln
    Call    StringInfo          ;returns AX=address, CX=length, DX=segment
    Mov     SI,AX
    Mov     DS,DX
    Mov     DI,cgfn_copy
    Rep     Movsb
    Mov     ES:[DI],CL
    Pop     DS
ENDIF

IFNDEF PDS
    mov     bx,tfln
    mov     cx,[bx]
    mov     si,[bx+2]           ;make ASCIIZ copy of
    mov     di,tmpf_copy        ;temp file name
    rep     movsb
    xor     al,al
    stosb
ELSE
    Mov     SI,tfln
    Call    StringInfo
    Mov     SI,AX
    Mov     DS,DX
    Mov     DI,tmpf_copy
    Rep     Movsb
    Mov     ES:[DI],CL
ENDIF

    push    es                      ;change ds to work_seg
    pop     ds

    open_rw cgfn_copy,-2,fin_sh     ;open file (R)
    mov     cg_hand,bx              ;save handle
    read_f  6,0,-4,fin_sh           ;read file ID & cmt length

    .IF  WORD PTR ds:[0] != 5346H  ||  WORD PTR ds:[2] != 724AH
    mov     ax,-5                   ;check ID
    jmp     fin_sh
    .ENDIF

    create_f  tmpf_copy,-6,fin_sh   ;create tmp file
    mov     d_hand,bx

    mov     bx,cg_hand
    s_fptr  0,0,0,-4,fin_sh

    mov     ax,ds:[4]
    add     ax,6
    read_f  ax,0,-4,fin_sh

    mov     bx,d_hand
    mov     this_hdrl,ax
    write_f ax,0,-4,fin_sh

nxt_file:
    mov     bx,cg_hand
    s_fptr  0,0,1,-4,fin_sh
    mov     cg_hdrl,ax
    mov     cg_hdrh,dx
    read_f  26,0,-4,fin_sh
    mov     ax,ds:[0]
    mov     dx,ds:[2]               ;save next cg hdr fptr
    mov     nxt_cg_hdrl,ax
    mov     nxt_cg_hdrh,dx

    mov     si,12
    mov     di,si                   ;determine length of name
    mov     cx,13
    xor     al,al
    repne   scasb
    mov     cx,di
    sub     cx,si
    mov     name_len,cx
    mov     ax,-13
    add     ax,name_len
    cmp     ax,0
    je      fprt_ok
    s_fptr  ax,0FFFFH,1,-4,fin_sh   ;reset fptr according to
fprt_ok:                            ;length of name

    mov     total_l,0
    mov     total_h,0
    mov     tmp_var1,0              ;write four zeroes
    mov     tmp_var2,0              ;this is where the fptr
    mov     bx,d_hand               ;to next header will be written
    write_f 4,tmpv_loc,-4,fin_sh    ;if another file is added

    open_r  12,0,cpy_file           ;open source file
    mov     s_hand,bx               ;save handle
    mov     ax,5700H
    int     21h
    .IF     dx < WORD PTR ds:[6]    ;compare dates
    close_f
    jmp     cpy_file
    .ELSEIF dx == WORD PTR ds:[6]
    .IF     cx <= WORD PTR ds:[4]   ;compare times
    close_f
    jmp     cpy_file
    .ENDIF
    .ENDIF

    mov     ds:[4],cx
    mov     ds:[6],dx
    mov     bx,d_hand
    mov     ax,8
    add     ax,name_len
    mov     hdr_len,ax
    write_f ax,4,-4,fin_sh          ;write the file header
    add     hdr_len,4               ;save total length of header


    mov     bx,s_hand
    s_fptr  0,0,2,-4,fin_sh
    mov     fsize_decl,ax
    mov     max_outl,ax
    mov     fsize_dech,dx
    mov     max_outh,dx
    s_fptr  0,0,0,-4,fin_sh

    invoke   fcmp_main

    .IF     ax!=0
    jmp     fin_sh
    .ENDIF
    .IF     nxt_cg_hdrl == 0 && nxt_cg_hdrh == 0
    jmp     update_done
    .ENDIF
    mov     bx,cg_hand
    s_fptr  nxt_cg_hdrl,nxt_cg_hdrh,0,-4,fin_sh
    jmp     nxt_file

cpy_file:
    mov     bx,cg_hand
    mov     dx,cg_hdrl
    mov     cx,cg_hdrh
    add     dx,4
    adc     cx,0
    s_fptr  dx,cx,0,-4,fin_sh
    mov     tmp_var1,ax
    mov     tmp_var2,dx
    mov     ax,nxt_cg_hdrl
    mov     dx,nxt_cg_hdrh
    .IF     ax == 0 && dx == 0
    s_fptr  0,0,2,-4,fin_sh
    mov     tmp_var3,ax
    mov     tmp_var4,dx
    s_fptr  tmp_var1,tmp_var2,0,-4,fin_sh
    mov     ax,tmp_var3
    mov     dx,tmp_var4
    .ENDIF
    sub     ax,cg_hdrl
    sbb     dx,cg_hdrh
    sub     ax,4
    sbb     dx,0
    mov     fsize_decl,ax
    mov     fsize_dech,dx
    mov     tmp_var1,0
cpy_cont:
    .IF     fsize_dech == 0
    .IF     fsize_decl <= 45000     ;read 45000 at a time
    mov     ax,fsize_decl
    mov     tmp_var1,1              ;done indicator
    .ELSE
    sub     fsize_decl,45000
    mov     ax,45000
    .ENDIF
    .ELSE
    sub     fsize_decl,45000
    sbb     fsize_dech,0
    mov     ax,45000
    .ENDIF
    mov     bx,cg_hand
    read_f  ax,0,-4,fin_sh          ;read some in
    mov     bx,d_hand
    write_f ax,0,-4,fin_sh          ;write some out

    cmp     tmp_var1,1              ;done?
    jne     cpy_cont

    .IF     prev_hdrh == 0
    cmp     prev_hdrl,0
    je      was_1st
    .ENDIF
    s_fptr  prev_hdrl,prev_hdrh,0,-4,fin_sh ;set fptr to hdr of previously
                                    ;  processed file
    write_f 4,thdr_loc,-4,fin_sh    ;write location of hdr of
                                    ;  file that was added
was_1st:
    mov     ax,this_hdrl
    mov     prev_hdrl,ax            ;save fptr to hdr of file
    mov     ax,this_hdrh            ;  just processed
    mov     prev_hdrh,ax

    s_fptr  0,0,2,-4,fin_sh
    mov     this_hdrl,ax            ;save fptr to EOF
    mov     this_hdrh,dx

    .IF     nxt_cg_hdrl != 0 || nxt_cg_hdrh != 0
    jmp     nxt_file
    .ENDIF

update_done:
    mov     bx,d_hand
    s_fptr  0,0,2,-4,fin_sh
    mov     fsize_decl,ax
    mov     fsize_dech,dx
    s_fptr  0,0,0,-4,fin_sh
    mov     bx,cg_hand
    s_fptr  0,0,0,-4,fin_sh
    mov     tmp_var1,0
fcpy_cont:
    .IF     fsize_dech == 0
    .IF     fsize_decl <= 45000     ;read 45000 at a time
    mov     ax,fsize_decl
    mov     tmp_var1,1              ;done indicator
    .ELSE
    sub     fsize_decl,45000
    mov     ax,45000
    .ENDIF
    .ELSE
    sub     fsize_decl,45000
    sbb     fsize_dech,0
    mov     ax,45000
    .ENDIF
    mov     bx,d_hand
    read_f  ax,0,-4,fin_sh          ;read some in
    mov     bx,cg_hand
    write_f ax,0,-4,fin_sh          ;write some out

    cmp     tmp_var1,1              ;done?
    jne     fcpy_cont

    write_f 0,0,-4,fin_sh           ;truncate if needed

    mov     bx,d_hand
    close_f
    mov     d_hand,0
    delete_f  tmpf_copy,-7,fin_sh

    xor     ax,ax                   ;ecd=0
fin_sh:
    push    ss                      ;make sure ds=DGROUP
    pop     ds
    mov     bx,ecd
    mov     [bx],ax                 ;return ecd

    .IF     ax != -1
    mov     ax,work_seg
    mov     ds,ax
    .IF     d_hand != 0
    mov     bx,d_hand
    close_f                         ;if dest open close it
    .ENDIF
    .IF     cg_hand != 0
    mov     bx,cg_hand
    close_f                         ;if cgfile open close it
    .ENDIF
    .IF     s_hand != 0
    mov     bx,s_hand
    close_f                         ;if source open close it
    .ENDIF
    .ENDIF
    unhook_crit  ecd
    ret
CWUpdate  ENDP
END
