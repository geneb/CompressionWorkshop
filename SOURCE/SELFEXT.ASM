;*********** SELFEXT.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.
;
;Assemble and link this file using MASM 6.0 as follows:
;
;  masm selfext /W2 /Wx
;  link selfext /noi /stack:1024 /far /packc
;
;Note that the resulting SELFEXT.EXE file must be 2850 bytes.

OPTION EXPR16
.MODEL MEDIUM
INCLUDE UPCKFLSV.INC
INCLUDE MISCMACS.INC
INCLUDE DCMPMACS.INC
typ_l     TEXTEQU <WORD PTR ds:[56000]>
typ_loc   TEXTEQU <56000>
typ_in    TEXTEQU <56002>
crit_err  TEXTEQU <WORD PTR ds:[56012]>
old_critl TEXTEQU <WORD PTR ds:[56014]>
old_crith TEXTEQU <WORD PTR ds:[56016]>
hook_crit    MACRO
    push    ds
    mov     ax,SEG work
    mov     ds,ax
    mov     crit_err,0
    mov     ax,3524h
    int     21h
    mov     old_critl,bx
    mov     old_crith,es
    mov     dx,OFFSET CW_crit_hdlr
    mov     ax,SEG CW_crit_hdlr
    mov     ds,ax
    mov     ax,2524h
    int     21h
    pop     ds
ENDM

;removes critical error handler
unhook_crit  MACRO  ecd_ptr:REQ
    mov     ax,SEG work
    mov     ds,ax
    mov     dx,old_critl
    mov     ax,old_crith
    mov     ds,ax
    mov     ax,2524h
    int     21h
    mov     ax,SEG work
    mov     ds,ax
ENDM

Chek_crit  MACRO
    pushf
    push    ds
    push    ax
    mov     ax,SEG work
    mov     ds,ax
    .IF     crit_err == 0
    pop     ax
    pop     ds
    popf
    .ELSE
    pop     ax
    pop     ds
    popf
    stc
    .ENDIF
ENDM

.STACK
.FARDATA?
work    BYTE  56018 DUP(?)
.CODE
.STARTUP
    hook_crit
    mov     ax,6200H
    int     21h
    mov     ds,bx
    mov     bx,2CH
    mov     ax,[bx]
    mov     es,ax
    xor     di,di
    xor     ax,ax
    mov     cx,32768
kg:
    repne   scasb
    cmp     byte ptr es:[di],0         ;find file name
    jne     kg
    add     di,3

    mov     dx,di
    mov     ax,es
    mov     ds,ax
    mov     ax,3D00H                ;open file
    int     21h
    Chek_crit
    jc      fin_sh
    mov     bx,ax

    mov     ax,SEG work
    mov     ds,ax
    mov     es,ax

    mov     di,vari_loc
    xor     ax,ax               ;zero out variable work area
    mov     cx,42
    rep     stosw

    mov     s_hand,bx               ;save handle
    s_fptr  2850,0,0,0,fin_sh           ;set to end of exe

    read_f  1,typ_loc,-4,fin_sh         ;read len of string to type in
    read_f  9,typ_in,-4,fin_sh          ;read type in string

    read_f  6,hdr_buff_loc,-4,fin_sh        ;read file ID & cmt length
    mov     cx,f_time               ;f_time will have lentgh
    jcxz    g_nxtfile
    read_f  cx,0,-4,fin_sh          ;read comment
    xor     dx,dx
    mov     bx,1
    mov     ah,40H
    int     21h
    Chek_crit
    jc      fin_sh

g_nxtfile:

    mov     bx,s_hand
    read_f  26,hdr_buff_loc,-4,fin_sh   ;read header

    mov     si,fname_loc
    mov     di,si               ;determine length of name
    mov     cx,13
    xor     ax,ax
    repne   scasb
    mov     cx,di
    sub     cx,si
    mov     name_len,cx
    mov     al,[di]
    mov     cmp_ind,ax              ;cmp/stored indicator

    mov     ax,-13
    add     ax,name_len
    cmp     ax,0
    je      fprt_ok
    s_fptr  ax,0FFFFH,1,0,fin_sh        ;reset fptr according to
fprt_ok:                    ;length of name

    create_f  fname_loc,-5,fin_sh       ;create file
    mov     d_hand,bx               ;save handle

    .IF     cmp_ind != 13
    jmp     file_stored
    .ENDIF

    mov     t_loc,256               ;set intial values
    mov     o_buff_ptr,o_buff_loc
    mov     di,suf_loc
    xor     al,al
    mov     cx,256              ;fill in suffix table 0-255
set_it_up:
    stosb
    inc     al
    loop    set_it_up
    jmp     g_codes

nxt_code:
    mov     si,i_buff_ptr
    add     i_buff_ptr,2
    mov     di,t_loc
    shl     di,1
    mov     ax,[si]             ;get a code
    mov     [di],ax             ;put it into code table
    dec     i_buff_count

    .IF    ax < 256             ;code < 256

    .IF     t_loc >256              ;table loc > 256 ?
    mov     di,t_loc                ;put into suffix table
    mov     [di+16383],al           ;at tloc-1
    .ENDIF
    mov     di,o_buff_ptr
    inc     o_buff_ptr              ;o/p the code
    mov     [di],al
    sub     fsize_l,1
    sbb     fsize_h,0               ;dec total file bytes
    .IF     fsize_l == 0
    cmp     fsize_h,0
    je      dcmps_d
    .ENDIF

    .ELSE                   ;code > 256

    mov     o_stk_count,0
    mov     o_stk_ptr,o_stk_loc         ;set intial values
keep_stk:
    mov     di,o_stk_ptr
    add     o_stk_ptr,2             ;put code into a stack
    mov     [di],ax
    inc     o_stk_count
    mov     di,ax
    shl     di,1                ;get value in table
    mov     ax,[di]             ;location of code
    cmp     ax,255              ;if code > 255 keep
    ja      keep_stk                ;stacking them up

    .IF     t_loc >256              ;table loc > 256 ?
    mov     di,t_loc                ;put into suffix table
    mov     [di+16383],al           ;at tloc-1
    .ENDIF
    mov     di,o_stk_ptr
    mov     [di],ax             ;put code into the stack
    inc     o_stk_count

more_stk:
    mov     di,o_stk_ptr
    sub     o_stk_ptr,2
    mov     ax,[di]
    mov     di,ax               ;o/p the stack L.I.F.O.
    mov     al,[di+suf_loc]         ;the stack has table
    mov     di,o_buff_ptr           ;locations the suffix
    inc     o_buff_ptr              ;values at those locations
    mov     [di],al             ;are o/p
    sub     fsize_l,1
    sbb     fsize_h,0               ;dec total file bytes
    .IF     fsize_l == 0
    cmp     fsize_h,0
    je      dcmps_d
    .ENDIF
    dec     o_stk_count
    cmp     o_stk_count,0
    jne     more_stk

    .ENDIF

    .IF     o_buff_ptr > o_buff_max     ;check o/p buffer
    mov     ax,o_buff_ptr           ;the maximum o/p from a single
    mov     o_buff_ptr,o_buff_loc       ;code is 8192 bytes (we wish)
    sub     ax,o_buff_loc           ;so must have 8192 available
    mov     bx,d_hand               ;in buffer or consider it full
    write_f ax,o_buff_loc,-4,fin_sh     ;write buffer to file
    .ENDIF

    inc     t_loc
    .IF     t_loc == 8192
    mov     t_loc,256               ;if table is full reset it's ptr
    .ENDIF
    .IF     i_buff_count != 0
    jmp     nxt_code
    .ENDIF

g_codes:
    mov     bx,s_hand

    .IF     t_loc >=  4096	    ;read in and unshuffle codes
    read_f  416,96,-4,fin_sh
    unshfl13
    .ELSEIF t_loc >=  2048
    read_f  384,128,-4,fin_sh
    unshfl12
    .ELSEIF t_loc >=  1024
    read_f  352,160,-4,fin_sh
    unshfl11
    .ELSEIF t_loc >=  512
    read_f  320,192,-4,fin_sh
    unshfl10
    .ELSE
    read_f  288,224,-4,fin_sh
    unshfl9
    .ENDIF
    mov     i_buff_count,256
    mov     i_buff_ptr,0
    jmp     nxt_code

dcmps_d:

    mov     ax,o_buff_ptr
    sub     ax,o_buff_loc
    mov     bx,d_hand
    write_f ax,o_buff_loc,-4,fin_sh     ;write o/p buffer

    mov     cx,f_time
    mov     dx,f_date               ;set file date/time
    mov     ax,5701H
    int     21h
    close_f                 ;close file
    mov     d_hand,0
    jmp     dcmp_done

file_stored:
    .IF     fsize_h == 0
    .IF     fsize_l <= 40000            ;read 40000 at a time
    mov     ax,fsize_l
    mov     stor_done,1             ;done indicator
    .ELSE
    sub     fsize_l,40000
    mov     ax,40000
    .ENDIF
    .ELSE
    sub     fsize_l,40000
    sbb     fsize_h,0
    mov     ax,40000
    .ENDIF
    mov     bx,s_hand
    read_f  ax,0,-4,fin_sh          ;read some in
    mov     bx,d_hand
    write_f ax,0,-4,fin_sh          ;write some out

    cmp     stor_done,1             ;done?
    jne     file_stored
    mov     stor_done,0

dcmp_done:
    mov     cx,f_time
    mov     dx,f_date               ;set file date/time
    mov     ax,5701H
    int     21h
    close_f                 ;close file
    mov     d_hand,0

    .IF     nxt_hdrl != 0 || nxt_hdrh != 0
    mov     bx,s_hand
    add     nxt_hdrl,2860
    adc     nxt_hdrh,0
    s_fptr  nxt_hdrl,nxt_hdrh,0,0,fin_sh    ;set fptr to next header
    jmp     g_nxtfile
    .ENDIF

    mov     cx,typ_l
    jcxz    fin_sh
    xor     ax,ax
    mov     es,ax
    mov     si,typ_in
    mov     di,41Ah
    mov     al,1Eh
    cli
    stosw
    mov     ax,cx               ;if there is a type in string
    shl     ax,1                ;put into kybd buffer
    add     al,1Eh
    stosw
    xor     ah,ah
n_xt:
    lodsb
    stosw
    loop    n_xt
    sti
    xor     ax,ax

fin_sh:

    .IF     s_hand != 0
    mov     bx,s_hand
    close_f                 ;if source open close it
    .ENDIF
    .IF     d_hand != 0
    mov     bx,d_hand
    close_f                 ;if dest open close it
    .ENDIF
    unhook_crit ax
.EXIT

CW_crit_hdlr  PROC
    sti
    push    ds
    push    ax
    push    si
    mov     ax,di
    mov     si,SEG work
    mov     ds,si
    xor     ah,ah
    mov     crit_err,ax             ;save the error code
    pop     si
    pop     ax
    pop     ds
    xor     al,al               ;tell dos to ignore error
    iretf
CW_crit_hdlr  ENDP


END
