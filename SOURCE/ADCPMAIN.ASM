;********** ADCPMAIN.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.

OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE UPCKARYV.INC
    INCLUDE MISCMACS.INC
    INCLUDE DCMPMACS.INC
    
.CODE
adcmp_main  PROC

    mov     bx,s_hand
    read_f  1,0,-4,dcmp_done
    .IF     BYTE PTR ds:[0] != 13
    jmp     ary_stored
    .ENDIF

    mov     t_loc,256           ;set intial values
    mov     di,suf_loc
    mov     dx,es
    mov     ax,ds
    mov     es,ax
    xor     al,al
    mov     cx,256              ;fill in suffix table 0-255
set_it_up:
    stosb
    inc     al
    loop    set_it_up
    mov     es,dx
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
    mov     di,op_ptr
    inc     op_ptr
    mov     es:[di],al          ;o/p the code
    .IF     op_ptr == 0
    mov     dx,es
    add     dx,1000H            ;seg fixup
    mov     es,dx
    .ENDIF
    sub     asize_l,1
    sbb     asize_h,0           ;dec total array bytes
    .IF     asize_l == 0
    cmp     asize_h,0
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
    mov     di,op_ptr           ;locations the suffix
    inc     op_ptr              ;values at those locations
    mov     es:[di],al          ;are o/p
    .IF     op_ptr == 0
    mov     dx,es
    add     dx,1000H            ;seg fixup
    mov     es,dx
    .ENDIF

    sub     asize_l,1
    sbb     asize_h,0           ;dec total array bytes
    .IF     asize_l == 0
    cmp     asize_h,0
    je      dcmps_d
    .ENDIF
    dec     o_stk_count
    cmp     o_stk_count,0
    jne     more_stk

    .ENDIF

    inc     t_loc
    .IF     t_loc == 8192
    mov     t_loc,256           ;if table is full reset it's ptr
    .ENDIF
    .IF     i_buff_count != 0
    jmp     nxt_code
    .ENDIF

g_codes:
    mov     bx,s_hand

    .IF     t_loc >=  4096	;read in and unshuffle codes
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
    xor     ax,ax
    jmp     dcmp_done

ary_stored:
    mov     di,ds
    mov     si,es
more_stored:
    .IF     asize_h == 0
    .IF     asize_l <= 45008    ;read 45008 at a time
    mov     ax,asize_l
    mov     stor_done,1         ;done indicator
    .ELSE
    sub     asize_l,45008
    mov     ax,45008
    .ENDIF
    .ELSE
    sub     asize_l,45008
    sbb     asize_h,0
    mov     ax,45008
    .ENDIF
    mov     ds,si
    read_f  ax,0,-4,dcmp_done
    mov     ds,di
    add     si,0AFDH            ;seg fixup
    cmp     stor_done,1
    jne     more_stored

    xor     ax,ax
dcmp_done:
    ret
adcmp_main  ENDP
END
