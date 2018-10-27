;********** DELTFILE.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.
;far strings mods by Ethan Winer

;NOTE: assemble this file as follows:
;
;  ML /c /W2 /WX /Fo DELTFILE.OBJ DELTFILE.ASM
;
;to create the far strings version of this program assemble with /DPDS:
;
;  ML /c /W2 /WX /DPDS /Fo\cwshop\object7\DELTFILE.OBJ DELTFILE.ASM

OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE  DELFILEV.INC
    INCLUDE  MISCMACS.INC

IFDEF PDS
    Extrn StringInfo: Proc
ENDIF

.CODE
CWDelFile  PROC uses ds si di, sfln:PTR WORD, dfln:PTR WORD, ecd:PTR WORD

Local dfln_local[80]:Byte           ;we'll copy dfln to here

    hook_crit
    mov     ax,work_seg
    .IF     ax == 0                 ;if not already allocated
    get_mem  -1,fin_sh              ;allocate memory
    .ENDIF
    mov     es,ax

    mov     di,vari_loc
    xor     ax,ax                   ;zero out variable work area
    mov     cx,20
    rep     stosw

IFNDEF PDS
    mov     bx,sfln
    mov     cx,[bx]
    mov     si,[bx+2]               ;make ASCIIZ copy of
    mov     di,CWfn_copy            ;CW file name
    rep     movsb
    xor     al,al
    stosb
ELSE
    Push    DS
    Mov     SI,sfln
    Call    StringInfo
    Mov     SI,AX
    Mov     DS,DX
    Mov     DI,CWfn_copy
    Rep     Movsb
    Mov     ES:[DI],CL
    Pop     DS
ENDIF

IFNDEF PDS
    mov     bx,dfln         ;this is the near strings code
    mov     cx,[bx]         ;and it leaves with CX = length
    mov     si,[bx+2]       ;  and SI = address
ELSE
    Push    DS              ;save DS and ES
    Push    ES
    Mov     SI,dfln
    Call    StringInfo      ;returns AX=address, CX=length, DX=segment
    Mov     SI,AX           ;copy from DS:SI
    Mov     DS,DX
    Push    SS              ;to SS:dfln_local
    Pop     ES
    Lea     DI,dfln_local
    Push    CX              ;save the string length and local buffer address
    Push    DI
    Rep     Movsb
    Mov     [DI],CL         ;an ES: override isn't needed because SS=DS
    Pop     SI              ;retrieve local buffer address (DI when pushed)
    Pop     CX              ;and retrieve the string length
    Pop     ES              ;restore ES and DS
    Pop     DS
ENDIF

    mov     di,cmpr_loc     ;Fred's code resumes
    .IF     BYTE PTR [si] == 42     ; 1st char of name * ?
    add     si,2
    mov     cx,3
cdlp:
    lodsb
    .IF     al > 96
    sub     al,32
    .ENDIF
    stosb                           ; get EXT for comparision
    loop    cdlp
    mov     dx,1
    jmp     cmpr_set
    .ENDIF
    xor     ah,ah
long_r:
    lodsb
    .IF     al > 96
    sub     al,32
    .ENDIF
    stosb                           ; get NAME for comparision
    inc     ah
    .IF     BYTE PTR [si] == 42     ; NAME.*
    mov     dx,2
    jmp     cmpr_set
    .ENDIF
    loop   long_r
    mov     dx,3
    xor     ch,ch
    mov     cl,ah
cmpr_set:
    mov     ax,es
    mov     ds,ax                   ;change ds to work_seg
    mov     cmpr_len,cx
    mov     fs_mode,dx

    open_rw  CWfn_copy,-2,fin_sh    ;open file (R\W)
    mov     CW_hand,bx              ;save handle
    read_f  6,0,-4,fin_sh           ;read file ID & cmt length

    .IF  WORD PTR ds:[0] != 5346H  ||  WORD PTR ds:[2] != 724AH
    mov     ax,-5                   ;check ID
    jmp     fin_sh
    .ENDIF

    s_fptr  WORD PTR ds:[4],0,1,-4,fin_sh
    mov     this_r_hdrl,ax          ;save file pointer
    mov     this_w_hdrl,ax
    mov     this_r_hdrh,dx
    mov     this_w_hdrh,dx

nxt_file:

    read_f  26,0,-4,fin_sh
    mov     ax,ds:[0]
    mov     nxt_r_hdrl,ax
    mov     ax,ds:[2]               ;save next fptr
    mov     nxt_r_hdrh,ax

    mov     si,12
    mov     di,cmpr_loc
    .IF     fs_mode == 1            ;*.EXT
n_char:
    inc     si
    cmp     BYTE PTR [si-1],46
    jne     n_char
    mov     cx,3
    repe    cmpsb
    jnz     keep_file
    .ELSE                           ;NAME.* or NAME.EXT
    mov     cx,cmpr_len
    repe    cmpsb
    jnz     keep_file
    .ENDIF

    .IF     nxt_r_hdrl == 0 && nxt_r_hdrh == 0
    s_fptr  this_w_hdrl,this_w_hdrh,0,-4,fin_sh
    xor     cx,cx
    mov     ah,40h                  ;truncate the file
    int     21h
    s_fptr  prev_w_hdrl,prev_w_hdrh,0,-4,fin_sh ;set fptr to hdr of previously
                                    ;  processed file
    mov     tmp_var1,0
    mov     tmp_var2,0
    write_f 4,tmpv_loc,-4,fin_sh
    jmp     del_done
    .ENDIF

    s_fptr  nxt_r_hdrl,nxt_r_hdrh,0,-4,fin_sh
    mov     this_r_hdrl,ax
    mov     this_r_hdrh,dx
    jmp     nxt_file

keep_file:
    mov     ax,this_r_hdrl
    mov     dx,this_r_hdrh
    mov     prev_r_hdrl,ax
    mov     prev_r_hdrh,dx

    .IF     dx == this_w_hdrh && ax == this_w_hdrl
    .IF     nxt_r_hdrl == 0 && nxt_r_hdrh == 0
    mov     ax,-13
    jmp     fin_sh
    .ENDIF
    mov     ax,this_w_hdrl
    mov     prev_w_hdrl,ax          ;save fptr to hdr of file
    mov     ax,this_w_hdrh          ;just processed
    mov     prev_w_hdrh,ax

    s_fptr  nxt_r_hdrl,nxt_r_hdrh,0,-4,fin_sh
    mov     this_r_hdrl,ax
    mov     this_w_hdrl,ax
    mov     this_r_hdrh,dx
    mov     this_w_hdrh,dx
    jmp     nxt_file

    .ENDIF

    s_fptr  this_w_hdrl,this_w_hdrh,0,-4,fin_sh
    mov     tmp_var1,0              ;write four zeroes this is where the
    mov     tmp_var2,0              ;fptr to next header will be written
    write_f 4,tmpv_loc,-4,fin_sh    ;if another file is added

    s_fptr  0,0,1,-4,fin_sh
    mov     tmp_var2,ax
    mov     tmp_var3,dx

    add     this_r_hdrl,4
    adc     this_r_hdrh,0
    mov     ax,nxt_r_hdrl
    mov     dx,nxt_r_hdrh
    .IF     ax == 0 && dx == 0
    s_fptr  0,0,2,-4,fin_sh
    .ENDIF

    sub     ax,this_r_hdrl
    sbb     dx,this_r_hdrh
    mov     fsize_decl,ax
    mov     fsize_dech,dx
    mov     tmp_var1,0

cpy_cont:
    .IF     fsize_dech == 0
    .IF     fsize_decl <= 55800     ;read 55800 at a time
    mov     ax,fsize_decl
    mov     tmp_var1,1              ;done indicator
    .ELSE
    sub     fsize_decl,55800
    mov     ax,55800
    .ENDIF
    .ELSE
    sub     fsize_decl,55800
    sbb     fsize_dech,0
    mov     ax,55800
    .ENDIF
    mov     tmp_var4,ax

    s_fptr  this_r_hdrl,this_r_hdrh,0,-4,fin_sh
    read_f  tmp_var4,0,-4,fin_sh    ;read some in
    s_fptr  0,0,1,-4,fin_sh
    mov     this_r_hdrl,ax
    mov     this_r_hdrh,dx
    s_fptr  tmp_var2,tmp_var3,0,-4,fin_sh
    write_f tmp_var4,0,-4,fin_sh    ;write some out
    s_fptr  0,0,1,-4,fin_sh
    mov     tmp_var2,ax
    mov     tmp_var3,dx
    cmp     tmp_var1,1          ;done?
    jne     cpy_cont

    .IF     prev_w_hdrh == 0
    cmp     prev_w_hdrl,0
    je      was_1st
    .ENDIF
    s_fptr  prev_w_hdrl,prev_w_hdrh,0,-4,fin_sh ;set fptr to hdr of previously
                                    ;  processed file
    write_f 4,thdr_loc,-4,fin_sh    ;write location of hdr of
                                    ;  file that was added
was_1st:
    mov     ax,this_w_hdrl
    mov     prev_w_hdrl,ax          ;save fptr to hdr of file
    mov     ax,this_w_hdrh          ;just processed
    mov     prev_w_hdrh,ax

    mov     ax,tmp_var2
    mov     this_w_hdrl,ax
    mov     ax,tmp_var3
    mov     this_w_hdrh,ax

    .IF     nxt_r_hdrl != 0 || nxt_r_hdrh != 0
    s_fptr  nxt_r_hdrl,nxt_r_hdrh,0,-4,fin_sh
    mov     this_r_hdrl,ax
    mov     this_r_hdrh,dx
    jmp     nxt_file
    .ENDIF

    s_fptr  this_w_hdrl,this_w_hdrh,0,-4,fin_sh
    xor     cx,cx
    mov     ah,40h                  ;truncate the file
    int     21h

del_done:
    xor     ax,ax                   ;ecd=0
fin_sh:
    push    ss
    pop     ds
    mov     bx,ecd
    mov     [bx],ax                 ;return ecd

    .IF     ax != -1
    mov     ax,work_seg
    mov     ds,ax
    .IF     CW_hand != 0
    mov     bx,CW_hand
    close_f                     ;if CWfile open close it
    .ENDIF
    .ENDIF
    unhook_crit  ecd
    ret
CWDelFile  ENDP
END
