;----- FLof.Asm - returns the length of a file opened for QuickPak binary

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad
;BC7 version J. Munro

;Syntax - Length = FLof&(Handle%)
;
;  Where Handle% is the number DOS originally assigned when the file was
;  opened, and Length receives its length.  Errors are returned in
;  DOS/WhichError.  Also, if an error occurs, FLof returns -1.  See the
;  comments in FLOC.ASM for more information about the DOS SEEK services.


.Model Medium, Basic
.Code
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far, DOS:Far

FLof Proc Uses SI DI, Handle:Ptr

    Mov  DX,CS            ;install CEH
    Lea  BX,CS:CEH_Ret
    Call Setup_CEH

    Mov  SI,Handle        ;get the address for Handle%
    Mov  BX,[SI]          ;and put it into BX
    Xor  CX,CX            ;set the file pointer 0 bytes from where it is now
    Mov  DX,CX            ;CX holds the high word, DX holds the low word
    Mov  AX,4201h         ;Move File Pointer service, relative to current LOC
    Call DOS              ;call DOS
    Jc   ErrExit          ;if the carry flag is set, there was an error

    Mov  DI,DX            ;save where we are now (DX:AX) in DI:SI
    Mov  SI,AX
    Mov  AX,4202h         ;ask DOS to seek to the end of the file
    Xor  CX,CX            ;this is done by requesting zero bytes with AL = 2
    Mov  DX,CX
    Call DOS
    Jc   ErrExit          ;it's unlikely there'd be an error now, but . . .

    Push DX               ;save DX and AX for a moment
    Push AX
    Mov  DX,SI            ;now get the original seek position back again
    Mov  CX,DI
    Mov  AX,4200h         ;and reset the file to where it had been
    Call DOS              ;call DOS
    Pop  AX               ;get AX and DX back again
    Pop  DX
    Jnc  Exit             ;just in case

ErrExit:
    Call Load_DOSErr      ;put up an error code

CEH_Ret:
    Mov  AX,-1            ;if error, return -1
    Mov  DX,AX

Exit:
    Call Restore_CEH      ;restore the QuickBASIC critical error handler
    Ret                   ;return to BASIC

Flof Endp
End
