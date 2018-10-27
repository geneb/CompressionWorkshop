;******** PACKSIZE.ASM - tells how small a file will become after compression

;Copyright (c) 1992 Fred Sexton Jr.
;far strings mods by Ethan Winer

;to create the far strings version of this program assemble with /DPDS

OPTION EXPR16
.MODEL MEDIUM, BASIC
    INCLUDE  PACKFLSV.INC
    INCLUDE  MISCMACS.INC

IFDEF PDS
    Extrn StringInfo: Proc
ENDIF
    
.CODE
CWPackedSize PROC uses ds si di,fln:PTR WORD,ecd:PTR WORD

    hook_crit
    mov     ax,work_seg
    .IF     ax == 0                 ;if not already allocated
    get_mem  -1,fin_sh              ;allocate memory
    .ENDIF
    mov     es,ax

    mov     di,vari_loc
    xor     ax,ax                   ;zero out variable work area
    mov     cx,40
    rep     stosw

    mov     ax,es
    mov     ds,ax                   ;set DS to work_seg

    push    ss
    pop     ds

IFNDEF PDS
    mov     bx,fln
    mov     cx,[bx]
    mov     dx,cx
    mov     si,[bx+2]
    mov     di,spec_copy
    rep     movsb           ;make ASCIIZ copy of filename
    xor     al,al
    stosb
ELSE
    Push    DS
    Mov     SI,fln
    Call    StringInfo          ;returns AX=address, CX=length, DX=segment
    Mov     SI,AX
    Mov     DS,DX
    Mov     DI,spec_copy
    Mov     DX,CX
    Rep     Movsb
    Mov     ES:[DI],CL
    Pop     DS
ENDIF

    mov     ax,es
    mov     ds,ax
    mov     tmp_var1,dx

    open_r   spec_copy,-3,fin_sh    ;open source file
    mov      s_hand,bx          ;save handle

    s_fptr   0,0,2,-4,fin_sh
    mov     fsize_decl,ax
    mov     max_outl,ax
    mov     fsize_dech,dx
    mov     max_outh,dx
    s_fptr   0,0,0,-4,fin_sh

    mov     i_buff_ptr,i_buff_loc   ;i/p buffer ptr
    read_f  10000,i_buff_loc,-4,fin_sh
    mov     i_buff_count,ax             ;i/p buffer count
    sub     fsize_decl,ax               ;subtract from total
    sbb     fsize_dech,0                ;source bytes

    mov     o_buff_ptr,o_buff_loc       ;initial o/p buffer loc ptr
    mov     si,i_buff_ptr
    xor     ah,ah
    mov     al,[si]                     ;get a byte
    dec     i_buff_count
    inc     i_buff_ptr
    mov     hold_val,ax                 ;initial hold value
    mov     t_loc,256                   ;initial table location
    xor     di,di
    xor     ax,ax
    mov     cx,22572                    ;clear hash table
    rep     stosw
    stosb                               ;45145 bytes

nxt_byte:
    mov     si,i_buff_ptr

    mov     al,[si]     ;get a byte
    dec     i_buff_count
    inc     i_buff_ptr
    mov     in_val,al

    mov     dx,hold_val
    mov     ah,dl
    xor     dh,dh               ;create code/suffix
    mov     bx,9028             ;determine hash table location
    div     bx
    mov     si,dx
    shl     dx,1
    shl     dx,1                ;multiply by 5 because
    add     si,dx               ;each entry is 5 bytes

    cmp     WORD PTR [si],0     ;check if location is used
    je      not_found
    mov     ax,[si+2]           ;check for match in table
    .IF     ax == hold_val
    mov     al,[si+4]
    cmp     al,in_val
    je      match_d
    .ENDIF

    mov     al,in_val
    mov     dx,hold_val
    mov     ah,dl
    xor     dh,dh
    mov     bx,4078             ;determine hash value
    div     bx
    inc     dx
    mov     bx,dx
    shl     dx,1
    shl     dx,1                ;multiply by 5 because
    add     bx,dx               ;each entry is 5 bytes

not_match:
    add     si,bx               ;search table for match or
                                ;unused location
    .IF     si >= dta_loc
    sub     si,dta_loc          ;hash table wrap
    .ENDIF

    cmp     WORD PTR [si],0     ;check if location is used
    je      not_found

    mov     ax,[si+2]
    cmp     ax,hold_val
    jne     not_match           ;check for match in table
    mov     al,[si+4]
    cmp     al,in_val
    jne     not_match

match_d:
    mov     ax,[si]             ;make hold the actual table
    mov     hold_val,ax         ;where match was found

    .IF     i_buff_count == 0
    .IF     fsize_decl == 0 && fsize_dech == 0  ;check if source is exhausted
    add     o_buff_ptr,2
    jmp     wrt_file
    .ENDIF
    mov     bx,s_hand       ;refill i/p buffer
    mov     i_buff_ptr,i_buff_loc
    read_f  10000,i_buff_loc,-4,fin_sh
    mov     i_buff_count,ax
    sub     fsize_decl,ax
    sbb     fsize_dech,0
    .ENDIF

    jmp     nxt_byte

not_found:
    mov     ax,t_loc
    mov     [si],ax
    mov     ax,hold_val
    mov     [si+2],ax
    mov     al,in_val
    mov     [si+4],al           ;put 5 byte entry into hash table

    xor     ah,ah
    xchg    ax,hold_val         ;new hold = the i/p byte
    add     o_buff_ptr,2

    .IF     i_buff_count == 0
    .IF     fsize_decl == 0 && fsize_dech == 0  ;check if source is exhausted
    add     o_buff_ptr,2
    jmp     wrt_file
    .ENDIF
    mov     bx,s_hand           ;refill i/p buffer
    mov     i_buff_ptr,i_buff_loc
    read_f  10000,i_buff_loc,-4,fin_sh
    mov     i_buff_count,ax
    sub     fsize_decl,ax
    sbb     fsize_dech,0
    .ENDIF

    inc     t_loc               ;next table location
    .IF     t_loc == 8192
    mov     t_loc,256           ;if table is full
    xor     di,di               ;clear it (45145 bytes)
    xor     ax,ax
    mov     cx,22572
    rep     stosw
    stosb
    .ENDIF
    .IF     o_buff_ptr < i_buff_loc
    jmp     nxt_byte
    .ENDIF

wrt_file:
    mov     ax,o_buff_ptr
    sub     ax,o_buff_loc
    shr     ax,1
    mov     cx,ax     ;;code count
    xor     ax,ax
    mov     o_buff_ptr,ax
    cmp     t_loc,256       ;table was just cleared
    je      smore13
    .IF     t_loc < 4097
    jmp     not_13
    .ENDIF
smore13:
    inc     ax
    inc     ax
    dec     cx
    jcxz    rdy13
    inc     ax
    inc     ax
    dec     cx
    jcxz    rdy13
    inc     ax
    dec     cx
    jcxz    rdy13
    inc     ax
    inc     ax
    dec     cx
    jcxz    rdy13
    inc     ax
    inc     ax
    dec     cx
    jcxz    rdy13
    inc     ax
    dec     cx
    jcxz    rdy13
    inc     ax
    inc     ax
    dec     cx
    jcxz    rdy13
    inc     ax
    dec     cx
    cmp     cx,0
    jne     smore13
rdy13:
    jmp     shfl_d13
not_13:
    .IF t_loc > 2048
smore12:
    inc     ax
    inc     ax
    dec     cx
    jcxz    rdy12
    inc     ax
    dec     cx
    cmp     cx,0
    jne     smore12
rdy12:
    .ELSEIF t_loc > 1024
smore11:
    inc     ax
    inc     ax
    dec     cx
    jcxz    rdy11
    inc     ax
    dec     cx
    jcxz    rdy11
    inc     ax
    inc     ax
    dec     cx
    jcxz    rdy11
    inc     ax
    dec     cx
    jcxz    rdy11
    inc     ax
    dec     cx
    jcxz    rdy11
    inc     ax
    inc     ax
    dec     cx
    jcxz    rdy11
    inc     ax
    dec     cx
    jcxz    rdy11
    inc     ax
    dec     cx
    cmp     cx,0
    jne     smore11
rdy11:
    .ELSEIF t_loc > 512
smore10:
    inc     ax
    inc     ax
    dec     cx
    jcxz    rdy10
    inc     ax
    dec     cx
    jcxz    rdy10
    inc     ax
    dec     cx
    jcxz    rdy10
    inc     ax
    dec     cx
    cmp     cx,0
    jne     smore10
rdy10:
    .ELSE
smore9:
    inc     ax
    inc     ax
    dec     cx
    jcxz    rdy9
    inc     ax
    dec     cx
    jcxz    rdy9
    inc     ax
    dec     cx
    jcxz    rdy9
    inc     ax
    dec     cx
    jcxz    rdy9
    inc     ax
    dec     cx
    jcxz    rdy9
    inc     ax
    dec     cx
    jcxz    rdy9
    inc     ax
    dec     cx
    jcxz    rdy9
    inc     ax
    dec     cx
    jne     smore9
rdy9:
    .ENDIF
shfl_d13:

    add     total_l,ax
    adc     total_h,0
    mov     ax,max_outl
    mov     dx,max_outh
    .IF     dx < total_h
    jmp     set_sz
    .ELSEIF dx == total_h
    .IF     ax < total_l
set_sz:
    mov     total_l,ax
    mov     total_h,dx
    xor     ax,ax
    jmp     fin_sh
    .ENDIF
    .ENDIF

    mov     o_buff_ptr,o_buff_loc   ;set o/p buffer ptr
    cmp     i_buff_count,0      ;see if file is exhausted
    jne     nxt_byte
    xor     ax,ax
fin_sh:

    push    ss
    pop     ds
    mov     bx,ecd
    mov     [bx],ax         ;return ecd

    .IF     ax != -1
    mov     ax,work_seg
    mov     ds,ax
    mov     es,ax
    mov     cx,tmp_var1
    mov     di,spec_copy
    add     di,cx
    mov     al,'\'
    std
    repne   scasb
    jnz     no_fix
    add     cx,2
no_fix:
    cld
    mov     ax,tmp_var1
    sub     ax,cx
    add     ax,14
    add     total_l,ax
    adc     total_h,0

    mov     ax,total_l
    mov     dx,total_h
    push    ax                      ;save these for a moment
    push    dx
    .IF     s_hand != 0
    mov     bx,s_hand
    close_f                         ;if source open close it
    .ENDIF
    .ENDIF

    unhook_crit  ecd
    pop     dx
    pop     ax
    ret
CWPackedSize ENDP
END
