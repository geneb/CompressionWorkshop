;*********** RDNAMES.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.
;far strings mods by Ethan Winer

;to create the far strings version of this program assemble with /DPDS

OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE  MISCMACS.INC

IFDEF PDS
    Extrn cw_opnit7:proc
ENDIF

.CODE
CWReadNames  PROC uses si di, fln:PTR WORD, fnary:PTR WORD, ecd:PTR WORD

LOCAL t_mem [13]:WORD,f_hand:WORD,f_ptr [2]:WORD,f_cnt:WORD,ary_di:WORD

    hook_crit

IFNDEF PDS
    mov     bx,fln
    invoke  cw_opnit                    ;open file and check ID
ELSE
    Mov     SI,fln
    Call    cw_opnit7
ENDIF

    cmp     ax,-3
    je      fin_sh
    cmp     ax,0
    jl      all_done

    mov     f_hand,bx
    s_fptr  cx,0,1,-4,all_done          ;move fptr ahead to first header
    mov     f_ptr,ax
    mov     f_ptr+2,dx
    mov     f_cnt,0
    
nxt_hdr:
    lea     dx,t_mem
    read_f  4,dx,-4,all_done            ;read ptr to next header
    .IF     t_mem == 0
    cmp     t_mem+2,0
    je      count_d
    .ENDIF
    
    inc     f_cnt                       ;count files
    s_fptr  t_mem,t_mem+2,0,-4,all_done ;set fptr to next header
    jmp     nxt_hdr
    
count_d:
    mov     si,fnary
    mov     ax,[si+16]
    push    ax
    add     ax,f_cnt            ;count
    push    ax
    mov     ax,22
    push    ax
    mov     ax,[si+8]
    push    ax
    push    si
    call    B$RDIM                      ;redimension the array
    
    mov     bx,f_hand
    s_fptr  f_ptr,f_ptr+2,0,-4,all_done ;set fptr to first header
    .IF    f_cnt > 2977
    mov     ary_di,20                   ;huge fudge
    .ELSE
    mov     ary_di,0
    .ENDIF
    
    inc     f_cnt
    mov     es,[si+2]                   ;set es to array seg
    
more_files:
    lea     dx,t_mem
    read_f  26,dx,-4,all_done
    mov     cx,6
    lea     si,t_mem+12
    mov     di,ary_di
    rep     movsw           ;copy name to array

    mov     ax,t_mem+7
    shr     al,1
    add     al,80
    stosb                   ;year
    mov     ax,t_mem+6
    mov     cl,5
    shr     ax,cl
    and     ax,0Fh          ;month
    stosb
    mov     ax,t_mem+6
    and     al,1Fh
    stosb                   ;day
    mov     ax,t_mem+5
    mov     cl,3
    shr     al,cl
    stosb                   ;hours
    mov     ax,t_mem+4
    mov     cl,5
    shr     ax,cl
    and     al,3Fh          ;minutes
    stosb
    mov     ax,t_mem+4
    and     al,1Fh
    shl     al,1
    stosb                   ;seconds

    lea     si,t_mem+8
    mov     cx,2
    rep     movsw                       ;copy time and date to array

    mov     cx,12
    mov     di,ary_di
    xor     al,al                       ;look for null
    repne   scasb
    jnz     f_len12                     ;the name is 12 characters long
    dec     di
    inc     cx                          ;pad with spaces
    mov     al,32
    rep     stosb
f_len12:
    dec     f_cnt
    .IF     f_cnt != 0
    s_fptr  t_mem,t_mem+2,0,-4,all_done ;set fptr to next header
    add     ary_di,22
    jmp     more_files
    .ENDIF
    xor     ax,ax
all_done:
    mov     dx,ax
    close_f
    mov     ax,dx
fin_sh:
    mov     bx,ecd
    mov     [bx],ax
    unhook_crit  ecd
    ret
CWReadNames  ENDP

END
