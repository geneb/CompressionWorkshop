;----- MakeDir.Asm - MKDIR substitute that traps errors

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad

;Syntax - CALL MakeDir(NewDir$)
;
;Errors are returned in DOS/WhichError

.Model Medium, Basic
.Data

    Extrn File_Name:Byte  ;this is in External.Asm

.Code
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far
    Extrn Create_Err:Far, Load_File:Far, DOS:Far

MakeDir Proc Uses ES SI DI, NewDir:Ptr

    Mov  DX,CS            ;install CEH
    Lea  BX,CS:Exit
    Call Setup_CEH

    Mov  SI,NewDir        ;SI holds address of NewDir$ descriptor
    Call Load_File        ;create an ASCIIZ string
    Jc   ErrExit          ;quit if an error was detected

    Mov  AH,39h           ;DOS make directory service
    Call DOS              ;call DOS to do it
    Jnc  Exit             ;no error, leave DOSError% set to zero

ErrExit:
    Call Create_Err       ;else, cook the error code
    Call Load_DOSErr      ;translate the error code

Exit:
    Call Restore_CEH      ;restore the QuickBASIC critical error handler
    Ret                   ;return to BASIC

MakeDir Endp
End
