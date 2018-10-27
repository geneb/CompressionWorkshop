;********** FCMPMAIN.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.
;
OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE  PACKFLSV.INC
    INCLUDE  MISCMACS.INC
    INCLUDE  CMPSMACS.INC
    
.CODE
fcmp_main  PROC 
    mov     bx,d_hand
    mov     tmp_var1,13
    write_f 1,tmpv_loc,-4,done_cmp      ;write cmp ind.
    add     cg_totwl,1
    adc     cg_totwh,0                  ;total CG bytes

    mov     bx,s_hand
    mov     i_buff_ptr,i_buff_loc       ;i/p buffer ptr
    read_f  10000,i_buff_loc,-4,done_cmp
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

    mov     al,[si]                     ;get a byte
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
    .IF     fsize_decl == 0
    .IF     fsize_dech == 0     ;check if source is exhausted
    mov     di,o_buff_ptr
    add     o_buff_ptr,2
    mov     [di],ax             ;o/p hold value
    inc     t_loc		;***12/26/96*** need this before jump
    jmp     wrt_file
    .ENDIF
    .ENDIF
    mov     bx,s_hand           ;refill i/p buffer
    mov     i_buff_ptr,i_buff_loc
    read_f  10000,i_buff_loc,-4,done_cmp
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
    mov     di,o_buff_ptr
    add     o_buff_ptr,2
    mov     [di],ax             ;o/p hold value

    .IF     i_buff_count == 0
    .IF     fsize_decl == 0
    .IF     fsize_dech == 0     ;check if source is exhausted
    mov     di,o_buff_ptr
    add     o_buff_ptr,2
    mov     ax,hold_val
    mov     [di],ax             ;o/p hold value
    inc     t_loc		;***12/26/96*** need this before jump
    jmp     wrt_file
    .ENDIF
    .ENDIF
    mov     bx,s_hand           ;refill i/p buffer
    mov     i_buff_ptr,i_buff_loc
    read_f  10000,i_buff_loc,-4,done_cmp
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
    cmp     t_loc,256           ;table was just cleared
    je      do_13
    .IF     t_loc < 4097
    jmp     not_13
    .ENDIF
do_13:
    shfl13                  ;shuffle 16 to 13 bits
    jmp     shfl_d13
not_13:
    .IF t_loc > 2048
    shfl12                  ;shuffle 16 to 12 bits
    .ELSEIF t_loc > 1024
    shfl11                  ;shuffle 16 to 11 bits
    .ELSEIF t_loc > 512
    shfl10                  ;shuffle 16 to 10 bits
    .ELSE
    shfl9		    ;shuffle 16 to 9 bits
    .ENDIF
shfl_d13:

    mov     ax,o_buff_ptr       ;will have o/p byte count
    add     total_l,ax
    adc     total_h,0           ;total bytes this file
    add     cg_totwl,ax
    adc     cg_totwh,0          ;total CG bytes

    mov     ax,total_l
    mov     dx,total_h          ;check compression
    .IF     dx > max_outh       ;decide whether to store
    jmp     begn_store
    .ELSEIF dx == max_outh
    .IF     ax > max_outl
    jmp     begn_store
    .ENDIF
    .ENDIF

    mov     bx,d_hand
    write_f o_buff_ptr,o_buff_loc,-4,done_cmp,1
    mov     o_buff_ptr,o_buff_loc       ;set o/p buffer ptr
    xor     ax,ax
    mov     di,o_buff_ptr
    mov     cx,256                  ;clear o/p buffer
    rep     stosw
    cmp     i_buff_count,0          ;see if file is exhausted
    je      g_nxtfile
    jmp     nxt_byte

begn_store:
    mov     bx,s_hand
    s_fptr  0,0,0,-4,done_cmp       ;reset source file pointer
    mov     bx,d_hand
    mov     dx,this_hdrl
    mov     cx,this_hdrh
    add     dx,hdr_len
    adc     cx,0                    ;set dest- file pointer
    s_fptr  dx,cx,0,-4,done_cmp     ;to cmp ind. location
    mov     tmp_var1,0              ;write a zero to indicate
    write_f 1,tmpv_loc,-4,done_cmp  ;file is not compressed
    xor     cx,cx
    mov     ah,40H                  ;truncate file to eliminate
    int     21h                     ;any extra that was written
stor_file:
    mov     bx,s_hand
    read_f  45000,0,-4,done_cmp     ;read from source
    mov     bx,d_hand
    write_f ax,0,-4,done_cmp,1      ;write to dest-
    cmp     ax,45000
    je      stor_file

g_nxtfile:

    mov     bx,s_hand
    close_f                         ;close source
    mov     s_hand,0
    mov     bx,d_hand
    .IF     prev_hdrh == 0
    cmp     prev_hdrl,0
    je      was_1st
    .ENDIF
    s_fptr  prev_hdrl,prev_hdrh,0,-4,done_cmp ;set fptr to hdr of previously
                                              ;  processed file
    write_f  4,thdr_loc,-4,done_cmp ;write location of hdr of
                                    ;  file that was added
was_1st:
    mov     ax,this_hdrl
    mov     prev_hdrl,ax            ;save fptr to hdr of file
    mov     ax,this_hdrh            ;just processed
    mov     prev_hdrh,ax

    s_fptr  0,0,2,-4,done_cmp
    mov     this_hdrl,ax            ;save fptr to EOF
    mov     this_hdrh,dx
    mov     cg_totwl,ax
    mov     cg_totwh,dx             ;total CG bytes

    xor     ax,ax
done_cmp:
    ret
fcmp_main  ENDP
END
