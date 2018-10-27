;*********** FDCPMAIN.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.
;
OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE UPCKFLSV.INC
    INCLUDE MISCMACS.INC
    INCLUDE DCMPMACS.INC
    
.CODE
fdcmp_main  PROC

    .IF     cmp_ind != 13
    jmp     file_stored
    .ENDIF
    mov     t_loc,256               ;set intial values
    mov     o_buff_ptr,o_buff_loc
    mov     di,suf_loc
    xor     al,al
    mov     cx,256                  ;fill in suffix table 0-255
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

    .IF     t_loc >256          ;table loc > 256 ?
    mov     di,t_loc            ;put into suffix table
    mov     [di+16383],al       ;at tloc-1
    .ENDIF
    mov     di,o_buff_ptr
    inc     o_buff_ptr          ;o/p the code
    mov     [di],al
    sub     fsize_l,1
    sbb     fsize_h,0           ;dec total file bytes
    .IF     fsize_l == 0
    cmp     fsize_h,0
    je      dcmps_d
    .ENDIF

    .ELSE                       ;code > 256

    mov     o_stk_count,0
    mov     o_stk_ptr,o_stk_loc ;set intial values
keep_stk:
    mov     di,o_stk_ptr
    add     o_stk_ptr,2         ;put code into a stack
    mov     [di],ax
    inc     o_stk_count
    mov     di,ax
    shl     di,1                ;get value in table
    mov     ax,[di]             ;location of code
    cmp     ax,255              ;if code > 255 keep
    ja      keep_stk            ;stacking them up

    .IF     t_loc >256          ;table loc > 256 ?
    mov     di,t_loc            ;put into suffix table
    mov     [di+16383],al       ;at tloc-1
    .ENDIF
    mov     di,o_stk_ptr
    mov     [di],ax             ;put code into the stack
    inc     o_stk_count

more_stk:
    mov     di,o_stk_ptr
    sub     o_stk_ptr,2
    mov     ax,[di]
    mov     di,ax               ;o/p the stack L.I.F.O.
    mov     al,[di+suf_loc]     ;the stack has table
    mov     di,o_buff_ptr       ;locations the suffix
    inc     o_buff_ptr          ;values at those locations
    mov     [di],al             ;are o/p
    sub     fsize_l,1
    sbb     fsize_h,0           ;dec total file bytes
    .IF     fsize_l == 0
    cmp     fsize_h,0
    je      dcmps_d
    .ENDIF
    dec     o_stk_count
    cmp     o_stk_count,0
    jne     more_stk

    .ENDIF

    .IF     o_buff_ptr > o_buff_max ;check o/p buffer
    mov     ax,o_buff_ptr           ;the maximum o/p from a single
    mov     o_buff_ptr,o_buff_loc   ;code is 8192 bytes (we wish)
    sub     ax,o_buff_loc           ;so must have 8192 available
    mov     bx,d_hand               ;in buffer or consider it full
    write_f ax,o_buff_loc,-4,dcmp_done  ;write buffer to file
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
    read_f  416,96,-4,dcmp_done
    unshfl13
    .ELSEIF t_loc >=  2048
    read_f  384,128,-4,dcmp_done
    unshfl12
    .ELSEIF t_loc >=  1024
    read_f  352,160,-4,dcmp_done
    unshfl11
    .ELSEIF t_loc >=  512
    read_f  320,192,-4,dcmp_done
    unshfl10
    .ELSE
    read_f  288,224,-4,dcmp_done
    unshfl9
    .ENDIF
    mov     i_buff_count,256
    mov     i_buff_ptr,0
    jmp     nxt_code

dcmps_d:

    mov     ax,o_buff_ptr
    sub     ax,o_buff_loc
    mov     bx,d_hand
    write_f ax,o_buff_loc,-4,dcmp_done      ;write o/p buffer

    mov     cx,f_time
    mov     dx,f_date               ;set file date/time
    mov     ax,5701H
    int     21h
    close_f                         ;close file
    mov     d_hand,0
    xor     ax,ax
    jmp     dcmp_done

file_stored:
    .IF     fsize_h == 0
    .IF     fsize_l <= 40000        ;read 40000 at a time
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
    read_f  ax,0,-4,dcmp_done       ;read some in
    mov     bx,d_hand
    write_f ax,0,-4,dcmp_done       ;write some out

    cmp     stor_done,1             ;done?
    jne     file_stored
    mov     stor_done,0

    mov     cx,f_time
    mov     dx,f_date               ;set file date/time
    mov     ax,5701H
    int     21h
    close_f                         ;close file
    mov     d_hand,0

    xor     ax,ax
dcmp_done:
    ret
fdcmp_main  ENDP
END
