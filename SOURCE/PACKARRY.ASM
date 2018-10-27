;********** PACKARRY.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.
;far strings mods by Ethan Winer

;to create the far strings version of this program assemble with /DPDS


OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE  PACKARYV.INC
    INCLUDE  MISCMACS.INC

IFDEF PDS
    Extrn StringInfo: Proc
ENDIF

.CODE
CWPackArray PROC uses ds si di, sary:PTR WORD, aryid:PTR WORD, dest:PTR WORD,
    ecd:PTR WORD
    
    hook_crit
    mov     ax,ary_wseg
    .IF     ax == 0                 ;if not alredy allocated
    mov     ax,4C40H                ;allocate memory
    mov     dx,0FFFFH
    push    dx
    push    ax
    call    B$SETM
    
    mov     ah,48H
    mov     bx,2875
    int     21h
    .IF     CARRY?
    mov     ax,-1
    jmp     fin_sh
    .ENDIF
    mov     ary_wseg,ax
    .ENDIF
    mov     es,ax

    mov     di,vari_loc
    xor     ax,ax                   ;zero out variable work area
    mov     cx,21
    rep     stosw

IFNDEF PDS
    mov     bx,dest
    mov     cx,[bx]
    mov     si,[bx+2]           ;make ASCIIZ copy of
    xor     di,di               ;dest file name
    rep     movsb
    xor     al,al
    stosb
ELSE
    Push    DS
    Mov     SI,dest
    Call    StringInfo          ;returns AX=address, CX=length, DX=segment
    Mov     SI,AX
    Mov     DS,DX
    Sub     DI,DI
    Rep     Movsb
    Mov     ES:[DI],CL
    Pop     DS
ENDIF

    mov     bx,ecd                  ;mode value is passed in ecd
    mov     cx,[bx]
    mov     ax,es
    mov     ds,ax                   ;set DS to work_seg

    .IF     cx == 0                 ;==0  =>create new cg file
    create_f  0,-2,fin_sh           ;create file
    mov     d_hand,bx               ;save handle
    mov     tmp_var1,5346H          ;set file ID (DWord)
    mov     tmp_var2,724AH
    write_f  4,tmpv_loc,-4,fin_sh   ;write ID
    .ELSE                           ;!=0  =>append existing cg file
    open_rw  0,-3,fin_sh
    mov      d_hand,bx              ;save handle
    read_f   4,tmpv_loc,-4,fin_sh
    .IF     tmp_var1 != 5346H || tmp_var2 != 724AH   ;check ID
    mov     ax,-5
    jmp     fin_sh
    .ENDIF
    
    mov     prev_hdrl,4             ;save header location
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

    mov     bx,sary
    mov     al,ss:[bx+9]
    .IF     al > 3
    mov     ax,-15              ;not dynamic
    jmp     fin_sh
    .ENDIF

    mov     si,aryid
    xor     di,di
    xor     ax,ax
    stosw
    stosw
    mov     ax,ss:[si]
    stosw

    xor     dx,dx
    mov     ax,ss:[bx+6]        ;# of paragraphs used
    mov     cx,4
@@:
    shl     ax,1
    .IF     CARRY?
    inc     dx
    .ENDIF
    loop    @B
    
    mov     asize_l,ax          ;# of bytes
    mov     asize_h,dx
    mov     max_outl,ax         ;set max_out value
    mov     max_outh,dx

    mov     ax,ss:[bx+12]       ;B-P-E
    stosw
    xor     ah,ah
    mov     al,ss:[bx+8]        ;number of dimensions
    stosw
    mov     cx,ax
    add     bx,14
@@:
    mov     ax,ss:[bx]
    stosw                       ;elements each dim-
    add     bx,4
    loop    @B
    mov     hdr_len,di
    
    mov     bx,sary
    mov     ax,ss:[bx+2]
    mov     es,ax               ;set es to array seg-
    mov     bx,d_hand
    write_f di,0,-4,fin_sh

    invoke   acmps_main

fin_sh:
    push    ss
    pop     ds
    mov     bx,ecd
    mov     dx,[bx]
    mov     [bx],ax             ;return ecd
    mov     cx,ax
    .IF     cx != -1
    mov     ax,ary_wseg
    mov     ds,ax
    mov     bx,d_hand
    
    .IF     cx == -9                ;floppy full
    s_fptr  this_hdrl,this_hdrh,0,-4,fin_sh
    xor     cx,cx                   ;truncate file
    mov     ah,40H
    int     21h
    .ELSEIF cx==-15 && dx==0
    close_f
    mov     bx,0
    xor     dx,dx               ;delete the file
    mov     ah,41H
    int     21h
    .ENDIF
    
    .IF     bx != 0
    close_f                     ;if dest open close it
    .ENDIF
    .ENDIF
    
    unhook_crit  ecd
    
    ret
    
CWPackArray  ENDP
END
