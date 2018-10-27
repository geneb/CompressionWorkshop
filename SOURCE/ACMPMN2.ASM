;********** ACMPMN2.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.


OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE  PCKARYMV.INC
    INCLUDE  MISCMACS.INC
    INCLUDE  CMPSMACS.INC
    
.CODE
acmps_main2  PROC

    mov     o_buff_ptr,o_buff_loc   ;initial o/p buffer loc ptr
    mov     si,i_buff_ptr
    xor     ah,ah
    mov     al,es:[si]              ;get a byte
    sub     asize_l,1
    sbb     asize_h,0
    inc     i_buff_ptr
    mov     hold_val,ax             ;initial hold value
    mov     t_loc,256               ;initial table location

    mov     ax,ds
    mov     dx,es
    mov     es,ax
    xor     di,di
    xor     ax,ax
    mov     cx,22572                ;clear hash table
    rep     stosw                   ;45145 bytes
    stosb
    mov     es,dx

nxt_byte:
    mov     si,i_buff_ptr

    mov     al,es:[si]              ;get a byte
    sub     asize_l,1
    sbb     asize_h,0
    inc     i_buff_ptr
    .IF     i_buff_ptr == 0
    mov     dx,es
    add     dx,1000H
    mov     es,dx
    .ENDIF
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
    .IF     si >= 45145
    sub     si,45145            ;hash table wrap
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

    .IF     asize_l == 0
    .IF     asize_h == 0        ;check if array is exhausted
    mov     di,o_buff_ptr
    add     o_buff_ptr,2
    mov     [di],ax             ;o/p hold value
    inc     t_loc		;***12/26/96*** need this before jump
    jmp     wrt_blk
    .ENDIF
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
    mov     di,o_buff_ptr
    add     o_buff_ptr,2
    mov     [di],ax             ;o/p hold value

    .IF     asize_l == 0
    .IF     asize_h == 0        ;check if array is exhausted
    mov     di,o_buff_ptr
    add     o_buff_ptr,2
    mov     ax,hold_val
    mov     [di],ax             ;o/p hold value
    inc     t_loc		;***12/26/96*** need this before jump
    jmp     wrt_blk
    .ENDIF
    .ENDIF

    inc     t_loc               ;next table location
    .IF     t_loc == 8192
    mov     t_loc,256           ;if table is full
    mov     ax,ds               ;clear it (45145 bytes)
    mov     dx,es
    mov     es,ax
    xor     di,di
    xor     ax,ax
    mov     cx,22572
    rep     stosw
    stosb
    mov     es,dx
    .ENDIF
    .IF     o_buff_ptr < 45657
    jmp     nxt_byte
    .ENDIF

wrt_blk:
    cmp     t_loc,256           ;table was just cleared
    je      do_13
    .IF     t_loc < 4097
    jmp     not_13
    .ENDIF
do_13:
    shfl13                      ;shuffle 16 to 13 bits
    jmp     shfl_d13
not_13:
    .IF t_loc > 2048
    shfl12                      ;shuffle 16 to 12 bits
    .ELSEIF t_loc > 1024
    shfl11                      ;shuffle 16 to 11 bits
    .ELSEIF t_loc > 512
    shfl10                      ;shuffle 16 to 10 bits
    .ELSE
    shfl9			;shuffle 16 to 9 bits
    .ENDIF
shfl_d13:

    mov     ax,o_buff_ptr       ;will have o/p byte count
    add     total_l,ax
    adc     total_h,0           ;total bytes this array
    mov     ax,total_l
    mov     dx,total_h          ;check compression
    .IF     dx > max_outh
    mov     ax,-14
    jmp     done_cmp
    .ELSEIF dx == max_outh
    .IF     ax > max_outl
    mov     ax,-14
    jmp     done_cmp
    .ENDIF
    .ENDIF

    mov     si,o_buff_loc
    mov     di,stor_loc
    mov     cx,o_buff_ptr
    add     stor_loc,cx
    mov     dx,es
    mov     ax,tmem_seg
    add     ax,tm_seg_fix
    mov     es,ax
    rep     movsb
    mov     es,dx
    .IF     stor_loc > 64000
    sub     stor_loc,64000
    add     tm_seg_fix,4000
    .ENDIF

    mov     o_buff_ptr,o_buff_loc   ;set o/p buffer ptr
    mov     di,o_buff_ptr

    mov     ax,ds
    mov     dx,es
    mov     es,ax
    mov     cx,256                  ;clear o/p buffer
    xor     ax,ax
    rep     stosw
    mov     es,dx
    .IF     asize_l != 0 || asize_h != 0    ;check if array is exhausted
    jmp     nxt_byte
    .ENDIF
    xor     ax,ax
done_cmp:
    ret
acmps_main2  ENDP
END
