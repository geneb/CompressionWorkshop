;************ MSELFEXT.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.
;far strings mods by Ethan Winer
;
;Assemble this file using MASM 6.0 as follows:
;
;  ml /c /W2 /WX /FoMSELFEXT.OBJ MSELFEXT.ASM
;
;to create the far strings version of this program assemble with /DPDS:
;
;  ml /c /W2 /WX /DPDS /Fo\CWSHOP\OBJECT7\MSELFEXT.OBJ MSELFEXT.ASM

OPTION EXPR16
.MODEL MEDIUM ,BASIC
INCLUDE  MISCMACS.INC

IFDEF PDS
    Extrn StringInfo: Proc
ENDIF

typ_l    TEXTEQU  <WORD PTR ds:[55980]>
typ_in   TEXTEQU  <55982>
cg_hand  TEXTEQU  <WORD PTR ds:[55994]>
se_hand  TEXTEQU  <WORD PTR ds:[55996]>
d_hand   TEXTEQU  <WORD PTR ds:[55998]>

.CODE
CWMakeExt  PROC uses ds si di ,cfln:PTR WORD,typn:PTR WORD,ecd:PTR WORD
    hook_crit
    mov     ax,work_seg
    .IF     ax == 0             ;if not already allocated
    get_mem  -1,fin_sh          ;allocate memory
    .ENDIF
    mov     es,ax

    xor     ax,ax
    mov     cx,10
    mov     di,55980
    rep     stosw

IFNDEF PDS                      ;if near strings
    mov     bx,typn             
    mov     cx,[bx]
    mov     dx,cx
    mov     si,[bx+2]           ;type in string
    mov     di,typ_in
    rep     movsb
ELSE                            ;if far strings
    Push    DS                  
    Mov     SI,typn
    Call    StringInfo          ;returns AX=address, CX=length, DX=segment
    Mov     DX,CX
    Mov     SI,AX
    Mov     DS,DX
    Mov     DI,typ_in
    Rep     Movsb
    Pop     DS
ENDIF

IFNDEF PDS                      ;if near strings
    xor     di,di               
    mov     bx,cfln
    mov     cx,[bx]             ;asciiz file name
    mov     si,[bx+2]
    rep     movsb
    sub     ax,ax
    stosb
ELSE                            ;if far strings
    Push    DX                  ;save DX while we copy the file name
    Mov     SI,cfln
    Call    StringInfo          ;returns AX=address, CX=length, DX=segment
    Mov     SI,AX
    Mov     DS,DX
    Sub     DI,DI
    Rep     Movsb
    Sub     AX,AX               ;EW 12-28-93 these lines were mov es:[di],cl
    Stosb                       ;EW 12-28-93
    Pop     DX                  ;restore DX
ENDIF

    Push    ES
    Pop     DS
    mov     typ_l,dx            ;save length

    open_r  0,-3,fin_sh
    mov     cg_hand,bx
    read_f  4,100,-4,fin_sh
    .if     WORD PTR ds:[100] != 5346H || WORD PTR ds:[102] != 724AH
    mov     ax,-5
    jmp     fin_sh
    .endif
    s_fptr  0,0,0,-4,fin_sh

    sub     di,4
    mov     ax,5845H
    stosw                       ;change extension to EXE
    mov     ax,45H
    stosw

    mov     ax,6200H
    int     21H
    mov     es,bx               ;PSP seg
    mov     bx,2CH
    mov     ax,es:[bx]
    mov     es,ax               ;environ-seg
    xor     di,di
    xor     ax,ax
    mov     cx,32768
@@:
    repne   scasb
    cmp     byte ptr es:[di],0  ;look for double null
    jne     @B                  ;(even or odd length)
    add     di,3
    mov     si,di
    mov     cx,80
    repne   scasb               ;end of executing file name
    dec     di
    mov     cx,12
    mov     al,'\'
    std
    repne   scasb               ;find the last "\"
    cld
    mov     cx,di
    sub     cx,si
    inc     cx
    inc     cx                  ;length of stirng

    mov     ax,ds
    mov     dx,es
    mov     ds,dx               ;environ-seg
    mov     es,ax               ;work seg
    mov     di,100
    rep     movsb
    mov     ds,ax               ;work seg

    mov     ax,4553H            ;SELFEXT.EXE
    stosw
    mov     ax,464CH
    stosw
    mov     ax,5845H
    stosw
    mov     ax,2E54H
    stosw
    mov     ax,5845H
    stosw
    mov     ax,45H
    stosw

    open_r  100,-12,fin_sh      ;open SELFEXT.EXE
    mov     se_hand,bx

    create_f 0,-2,fin_sh
    mov     d_hand,bx

    mov     bx,se_hand
    read_f  3000,0,-4,fin_sh
    mov     bx,d_hand
    write_f ax,0,-4,fin_sh
    write_f 1,OFFSET typ_l,-4,fin_sh
    write_f 9,typ_in,-4,fin_sh
more_tg:                        ;copy se and cg to dest-
    mov     bx,cg_hand
    read_f  55980,0,-4,fin_sh
    mov     bx,d_hand
    write_f ax,0,-4,fin_sh
    cmp     ax,55980
    je      more_tg
    xor     ax,ax
fin_sh:
    mov     bx,ecd
    mov     ss:[bx],ax          ;return ecd
    .IF     ax != -1
    mov     bx,cg_hand
    .IF     bx != 0
    close_f
    .ENDIF
    mov     bx,se_hand
    .IF     bx != 0
    close_f
    .ENDIF
    mov     bx,d_hand
    .IF     bx != 0
    close_f
    .ENDIF
    .ENDIF
    unhook_crit  ecd
    ret
CWMakeExt  endp
end
