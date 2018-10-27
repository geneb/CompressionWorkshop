;*********** UPACKFLS.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.
;far strings mods by Ethan Winer

;to create the far strings version of this program assemble with /DPDS

OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE UPCKFLSV.INC
    INCLUDE MISCMACS.INC
    INCLUDE DCMPMACS.INC

IFDEF PDS
    Extrn StringInfo: Proc
ENDIF
    
.CODE
CWUnpackFiles PROC uses ds si di, sfln:PTR WORD, dest:PTR WORD, ecd:PTR WORD
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

IFNDEF PDS
    mov     bx,sfln
    mov     cx,[bx]
    mov     si,[bx+2]               ;make ASCIIZ copy of
    xor     di,di                   ;source file name
    rep     movsb
    xor     al,al
    stosb
ELSE
    Mov     SI,sfln
    Call    StringInfo          ;returns AX=address, CX=length, DX=segment
    Mov     SI,AX
    Mov     DS,DX
    Sub     DI,DI
    Rep     Movsb
    Mov     ES:[DI],CL
ENDIF

    mov     ax,es
    mov     ds,ax                   ;change ds to work_seg

    open_r  0,-3,fin_sh             ;open file (R)
    mov     s_hand,bx               ;save handle
    read_f  6,hdr_buff_loc,-4,fin_sh               ;read file ID & cmt length
    .IF     nxt_hdrl != 5346H || nxt_hdrh != 724AH ;check ID
    mov     ax,-5
    jmp     fin_sh
    .ENDIF
    s_fptr  f_time,0,1,-4,fin_sh    ;set fptr to first header

    push    ss
    pop     ds

IFNDEF PDS
    mov     bx,dest
    mov     cx,[bx]
    mov     si,[bx+2]
ELSE
    Mov     SI,dest
    Call    StringInfo          ;returns AX=address, CX=length, DX=segment
    Mov     SI,AX
    Mov     DS,DX
ENDIF

    mov     di,dest_loc         ;make copy of dest$
    Or      CX,CX               ;skip this if it's a null string
    Jz      @F                  ;else Loop below will copy 64K bytes!

cdlp:
    lodsb
    .IF     al > 96             ;capitalize as we go
    sub     al,32
    .ENDIF
    stosb
    loop    cdlp
@@:
    xor     al,al
    stosb
    dec     di
    
    mov     ax,es
    mov     ds,ax

    mov     cx,di
    sub     cx,dest_loc
    mov     al,92
    std
    repne   scasb                   ;check dest$ for a path
    .IF     ZERO?
    add     di,2
    .ELSE
    mov     di,dest_loc
    .ENDIF
    cld
    mov     dpath_end,di            ;save location of end of path

    .IF     BYTE PTR [di] == 42     ; 1st char of name * ?
    cmp     BYTE PTR [di+2],42      ; 3rd char of name * ?
    je      g_nxtfile
    mov     ax,[di+2]
    mov     ds:[cmpr_loc],ax
    mov     al,[di+4]
    mov     ds:[cmpr_loc+2],al      ; get EXT for comparision
    mov     fs_mode,1
    jmp     g_nxtfile
    .ENDIF

    mov     si,cmpr_loc
    xchg    si,di
long_r:                             ; get NAME for comparision
    movsb
    inc     cmpr_len
    .IF     BYTE PTR [si] == 42     ; NAME.*
    mov     fs_mode,2
    .ELSEIF BYTE PTR [si] == 0      ; NAME.EXT
    mov     fs_mode,3
    .ELSE
    jmp     long_r
    .ENDIF

g_nxtfile:

    mov     bx,s_hand
    read_f  26,hdr_buff_loc,-4,fin_sh   ;read header

    .IF     fs_mode == 0            ;do all the files
    jmp     do_this_file
    .ENDIF

    mov     si,fname_loc
    mov     di,cmpr_loc
    .IF     fs_mode == 1            ;*.EXT
n_char:
    inc     si
    cmp     BYTE PTR [si-1],46
    jne     n_char
    mov     cx,3
    repe    cmpsb
    jz      do_this_file
    .ELSE                           ;NAME.* or NAME.EXT
    mov     cx,cmpr_len
    repe    cmpsb
    jz      do_this_file
    .ENDIF
check_nxt:
    cmp     nxt_hdrl,0
    jne     not_last
    cmp     nxt_hdrh,0              ;last header?
    jne     not_last
    .IF     fnd_ind == 0
    mov     ax,-13
    .ELSE
    xor     ax,ax
    .ENDIF
    jmp     fin_sh
not_last:
    mov     bx,s_hand
    s_fptr  nxt_hdrl,nxt_hdrh,0,-4,fin_sh   ;set fptr to next header
    jmp     g_nxtfile

do_this_file:
    mov     fnd_ind,1
    mov     si,fname_loc
    mov     di,si                   ;determine length of name
    mov     cx,13
    xor     ax,ax
    repne   scasb
    mov     cx,di
    sub     cx,si
    mov     name_len,cx
    mov     al,[di]
    mov     cmp_ind,ax              ;cmp/stored indicator

    mov     di,dpath_end            ;append name to path
    rep     movsb

    mov     ax,-13
    add     ax,name_len
    cmp     ax,0
    je      fprt_ok
    s_fptr  ax,0FFFFH,1,-4,fin_sh   ;reset fptr according to
fprt_ok:                            ;length of name

    create_f  dest_loc,-2,fin_sh    ;create file
    mov     d_hand,bx               ;save handle

     invoke fdcmp_main              ;call the decompression routine

     cmp    ax,0
     jne    fin_sh
    .IF     fs_mode != 3            ;only 1 file to do
    jmp     check_nxt
    .ENDIF
    xor     ax,ax
fin_sh:
    push    ss
    pop     ds
    mov     bx,ecd
    mov     [bx],ax                 ;return ecd
    .IF     ax != -1
    mov     ax,work_seg
    mov     ds,ax
    .IF     s_hand != 0
    mov     bx,s_hand
    close_f                         ;if source open close it
    .ENDIF
    .IF     d_hand != 0
    mov     bx,d_hand
    close_f                         ;if dest open close it
    .ENDIF
    .ENDIF
    unhook_crit  ecd
    ret
CWUnpackFiles  ENDP
END
