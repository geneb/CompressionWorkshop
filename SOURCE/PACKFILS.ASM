;********** PACKFILS.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.
;far strings mods by Ethan Winer

;to create the far strings version of this program assemble with /DPDS


OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE  PACKFLSV.INC
    INCLUDE  MISCMACS.INC

IFDEF PDS
    Extrn StringInfo: Proc
ENDIF
    
.CODE
CWPackFiles PROC uses ds si di, spec:PTR WORD, dest:PTR WORD,
    cmt:PTR WORD, ecd:PTR WORD
    
    hook_crit
    mov     ax,work_seg
    .IF     ax == 0                 ;if not already allocated
    get_mem  -1,fin_sh              ;allocate memory
    .ENDIF
    mov     es,ax

   mov     ax,cg_try_cont
   .IF     ax == 1                  ;last call had zero write
   mov     bx,ecd
   mov     ax,[bx]
   .IF     ax == -9                 ;calling program requests
   mov     WORD PTR [bx],0          ;continue previous operation
   mov     WORD PTR es:[55984],1    ;set cg_cont_flag
   jmp     skp_vclr
   .ENDIF
   .ENDIF

    mov     di,vari_loc
    xor     ax,ax                   ;zero out variable work area
    mov     cx,40
    rep     stosw

skp_vclr:
    mov     cg_try_cont,0
    mov     ax,cgfs_max
    mov     es:[55990],ax
    mov     ax,cgfs_max+2
    mov     es:[55992],ax

IFNDEF PDS
    mov     bx,dest
    mov     cx,[bx]
    mov     si,[bx+2]               ;make ASCIIZ copy of
    mov     di,dest_copy            ;dest file name
    rep     movsb
    xor     al,al
    stosb
ELSE
    Push    DS
    Mov     SI,dest
    Call    StringInfo          ;returns AX=address, CX=length, DX=segment
    Mov     SI,AX
    Mov     DS,DX
    Mov     DI,dest_copy
    Rep     Movsb
    Mov     ES:[DI],CL
    Pop     DS
ENDIF

    mov     bx,ecd                  ;mode value is passed in ecd
    mov     cx,[bx]

IFNDEF PDS
    mov     bx,cmt
    mov     dx,[bx]                 ;get length of comment string
ELSE
    Push    DS
    Push    CX
    Mov     SI,cmt
    Call    StringInfo          ;returns AX=address, CX=length, DX=segment
    Mov     DX,CX
    Pop     CX
    Pop     DS
ENDIF
    
    mov     ax,es
    mov     ds,ax                   ;set DS to work_seg
    mov     tmp_var3,dx
    mov     dest_end,di             ;save ptr to end of string
    mov     cg_totwl,0
    mov     cg_totwh,0
    mov     prev_hdrl,0
    mov     prev_hdrh,0
    mov     d_hand,0
    mov     s_hand,0

    .IF     cx == 0                 ;==0  =>create new cg file
    create_f  dest_copy,-2,fin_sh   ;create file
    mov     d_hand,bx               ;save handle
    mov     tmp_var1,5346H          ;set file ID (DWord)
    mov     tmp_var2,724AH
    write_f  6,tmpv_loc,-4,fin_sh   ;write ID and comment length
    cmp     tmp_var3,0
    je      no_cmt
    mov     cx,tmp_var3

    push    ss
    pop     ds
    mov     si,cmt
    
IFNDEF PDS
    write_f cx,[si+2],-4,fin_sh     ;write comment string
ELSE
    Push    DS                  ;save DS
    Call    StringInfo          ;returns AX=address, CX=length, DX=segment
    Mov     DS,DX               ;show DOS where the far strings segment is
    Mov     DX,AX               ;and where to write the data from
    Mov     AH,40h              ;specify the DOS Write File service
    Int     21h                 ;write the comment to the file
    Pop     DS                  ;restore DS, before possible jump to fin_sh
    Chek_crit                   ;Fred's macro
    Jnc     @F                  ;no carry, no error
    Mov     AX,-4               ;there was an error, show which one
    Jmp     fin_sh              ;and bail out now
@@:
    Cmp     AX,CX               ;see if we read as much as we asked for
    Je      @F                  ;we did, so that's okay too
    Mov     AX,-9               ;as above, except return a "Disk full" error
    Jmp     fin_sh
@@:
ENDIF

    mov     ax,es
    mov     ds,ax
no_cmt:
    .ELSE                           ;!=0  =>append existing cg file
    open_rw  dest_copy,-3,fin_sh
    mov      d_hand,bx              ;save handle
    s_fptr   0,0,2,-4,fin_sh
    mov      cg_totwl,ax            ;get file size
    mov      cg_totwh,dx
    s_fptr   0,0,0,-4,fin_sh
    read_f   6,tmpv_loc,-4,fin_sh
    .IF     tmp_var1 != 5346H || tmp_var2 != 724AH   ;check ID
    mov     ax,-5
    jmp     fin_sh
    .ENDIF
    s_fptr  tmp_var3,0,1,-4,fin_sh  ;set fptr to first header
    mov     prev_hdrl,ax            ;save header location
    mov     prev_hdrh,dx
nxt_hdr:
    read_f  4,tmpv_loc,-4,fin_sh    ;read file pointer to next header
    cmp     tmp_var1,0              ;check if last header
    jne     set_nxt_hdr
    cmp     tmp_var2,0
    je      last_hdr
set_nxt_hdr:
    s_fptr  tmp_var1,tmp_var2,0,-4,fin_sh   ;set file pointer to next header
    mov     prev_hdrl,ax            ;save header location
    mov     prev_hdrh,dx
    jmp     nxt_hdr
last_hdr:
    .ENDIF

    s_fptr  0,0,2,-4,fin_sh         ;set pointer to EOF
    mov     this_hdrl,ax            ;save pointer to EOF
    mov     this_hdrh,dx
    g_dta
    mov     orig_dta_ofs,bx         ;save orginal dta
    mov     orig_dta_seg,es
    mov     ax,ds
    mov     es,ax
    s_dta   dta_loc                 ;set DTA to wseg:dta_loc

    .IF     cg_cont_flag == 1
    jmp     nxt_file
    .ENDIF

    push    ss
    pop     ds

IFNDEF PDS
    mov     bx,spec   ;*
    mov     cx,[bx]
    mov     si,[bx+2]
    mov     di,spec_copy
    rep     movsb                   ;make ASCIIZ copy of
    xor     al,al                   ;search string
    stosb
ELSE
    Push    DS
    Mov     SI,spec
    Call    StringInfo          ;returns AX=address, CX=length, DX=segment
    Mov     SI,AX
    Mov     DS,DX
    Mov     DI,spec_copy
    Rep     Movsb
    Mov     ES:[DI],CL
    Pop     DS
ENDIF
    
    mov     ax,es
    mov     ds,ax

    mov     dx,spec_copy
    mov     cx,7                    ;N-R-H-S
    mov     ah,4EH                  ;find first match
    int     21h
    Chek_crit
    .IF     CARRY?
    mov     ax,-13
    jmp     fin_sh
    .ENDIF

    mov     cx,di
    sub     cx,spec_copy
    mov     al,92
    std
    repne   scasb                   ;check spec$ for a path
    .IF     ZERO?
    add     di,2
    .ELSE
    mov     di,spec_copy
    .ENDIF
    cld
    mov     spec_end,di             ;save location of end of path

nxt_file:
    mov     total_l,0
    mov     total_h,0
    mov     si,dta_loc + 30
    mov     di,si
    xor     al,al
    mov     cx,13
    repne   scasb
    sub     di,si                   ;determine length of name
    mov     name_len,di
    mov     cx,di
    mov     di,spec_end
    rep     movsb                   ;append found$ to path
    mov     cx,name_len
    mov     si,dest_end
    sub     si,cx
    sub     di,cx
    repe    cmpsb                   ;compare found$ to dest$
    .IF     ZERO?
g_new_file:
    mov     ah,4FH                  ;find a different file
    int     21h
    Chek_crit
    .IF     CARRY?                  ;no more matching
    .IF     f_opened == 0           ;check if this was first file
    mov     ax,-13
    .ELSE
    xor     ax,ax                   ;ecd=0
    .ENDIF
    jmp     fin_sh
    .ENDIF
    jmp     nxt_file
    .ENDIF

    .IF     WORD PTR ds:[dta_loc+26] < 2 && WORD PTR ds:[dta_loc+28] == 0
    jmp     g_new_file              ;files must have 2 bytes min.
    .ENDIF

    mov     tmp_var1,0              ;write four zeroes
    mov     tmp_var2,0              ;this is where the fptr
    mov     bx,d_hand               ;to next header will be written
    write_f  4,tmpv_loc,-4,fin_sh   ;if another file is added

    mov     ax,8
    add     ax,name_len
    mov     hdr_len,ax
    write_f ax,dta_loc+22,4,fin_sh  ;write the file header
    add     hdr_len,4               ;save total length of header
    mov     ax,hdr_len
    add     cg_totwl,ax
    adc     cg_totwh,0              ;total CG bytes

    mov     ax,WORD PTR ds:[dta_loc+26]
    mov     fsize_decl,ax
    mov     max_outl,ax
    mov     ax,WORD PTR ds:[dta_loc+28]     ;save copy of file size
    mov     fsize_dech,ax
    mov     max_outh,ax

    open_r   spec_copy,-3,fin_sh    ;open source file
    mov      s_hand,bx              ;save handle
    mov      f_opened,1             ;sucessful opening indicator

    invoke   fcmp_main

    cmp     ax,0
    jne     fin_sh
    mov     cg_cont_flag,0
    mov     ah,4FH          ;find next file
    int     21h
    Chek_crit
    .IF     !CARRY?
    jmp     nxt_file
    .ENDIF
    xor     ax,ax                   ;ecd=0
fin_sh:
    push    ss
    pop     ds
    mov     bx,ecd
    mov     dx,[bx]
    mov     [bx],ax                 ;return ecd
    mov     cx,ax
    .IF     ax != -1
    mov     ax,work_seg
    mov     ds,ax
    mov     bx,d_hand
    .IF     cx == -9            ;floppy full or max size
    .IF     cg_cont_flag == 1
    mov     si,ecd
    mov     WORD PTR ss:[si],-8     ;single file too big to fit on disk
    jmp     del_it
    .ENDIF
    mov     si,OFFSET cg_try_cont
    mov     WORD PTR ss:[si],1
    s_fptr  this_hdrl,this_hdrh,0,-4,fin_sh
    xor     cx,cx                   ;truncate file
    mov     ah,40H
    int     21h
    .ELSEIF cx == -13 || cx == -3
    .IF     dx == 0
del_it:
    close_f
    mov     bx,0
    mov     dx,dest_copy            ;delete the file
    mov     ah,41H
    int     21h
    .ENDIF
    .ENDIF
    .IF     bx != 0
    close_f                         ;if dest open close it
    .ENDIF
    .IF     s_hand != 0
    mov     bx,s_hand
    close_f                         ;if source open close it
    .ENDIF
    .IF     orig_dta_ofs != 0
    mov     ax,orig_dta_ofs         ;if DTA was changed reset it
    mov     dx,orig_dta_seg
    mov     ds,ax
    mov     ah,1AH
    int     21h
    .ENDIF
    .ENDIF
    unhook_crit  ecd
    ret
CWPackFiles  ENDP
END
