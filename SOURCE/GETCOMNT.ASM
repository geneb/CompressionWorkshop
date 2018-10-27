;********** GETCOMNT.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.
;far strings mods by Ethan Winer

;to create the far strings version of this program assemble with /DPDS

OPTION EXPR16
.MODEL MEDIUM ,BASIC
    INCLUDE   MISCMACS.INC

IFDEF PDS
    Extrn StringInfo: Proc
    Extrn cw_opnit7:proc
ENDIF

.CODE
CWGetComment PROC uses si di, fln:PTR WORD, cmt:PTR WORD, ecd:PTR WORD

LOCAL  cmt_len:WORD,err_cd:word,fl_hand:word

    Mov     SI,ecd                  ;clear ErrCode (added 5-15-92 by EW)
    Mov     Word Ptr [SI],0

    hook_crit

IFNDEF PDS
    mov     bx,fln
    invoke  cw_opnit                    ;open file and check ID
ELSE
    Mov     SI,fln
    Call    cw_opnit7
ENDIF

    mov     err_cd,ax
    .IF     ax == 0
    .IF     cx != 0
    mov     cmt_len,cx
    mov     ax,cx
    mov     fl_hand,bx
    push    ax
    call    B$SPAC                  ;make a string of proper length
    push    ax
    mov     ax,cmt
    push    ax
    call    B$SASS
    mov     bx,fl_hand
    mov     si,cmt
IFNDEF PDS
    read_f  cmt_len,[si+2],-4,fin_sh    ;read comment string
ELSE
    Push    DS                  ;save DS
    Call    StringInfo          ;returns AX=address, CX=length, DX=segment
    Mov     DS,DX               ;show DOS where the far strings segment is
    Mov     DX,AX               ;and where to read the data into
    Mov     AH,3Fh              ;specify the DOS Read File service
    Int     21h                 ;read the comment from the file
    Pop     DS                  ;restore DS now
    Chek_crit                   ;Fred's macro
    Jnc     @F                  ;no carry, no error
    Mov     AX,-4               ;there was an error, show which one
    Jmp     fin_sh              ;and bail out now
@@:
    Cmp     AX,CX               ;see if we read as much as we asked for
    Je      @F                  ;we did, so that's okay too
    Mov     AX,-4               ;as above
    Jmp     fin_sh
@@:
ENDIF

    .ENDIF
    .ELSE
    mov     si,ecd
    mov     [si],ax
    .ENDIF
fin_sh:
    .IF     err_cd != -3
    close_f
    .ENDIF
    unhook_crit  ecd
    ret
CWGetComment    ENDP

END
