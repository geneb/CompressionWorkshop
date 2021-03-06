;----- SetAttr.Asm - sets a file's attributes

;Copyright (c) 1989 Ethan Winer
;Revised Jan 89 - J. R. Conrad
;BC7 version J.Munro

;Syntax - FileName$ = "\Path\Filename.Ext"
;         Attr = 2     'this example sets the attribute to hidden
;         CALL SetAttr(FileName$, Attr%)
;         Errors are returned in DOS/WhichError

.Model Medium, Basic
.Data

    Extrn File_Name:Byte  ;this is in External.Asm

.Code
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far
    Extrn Load_File:Far, DOS:Far

SetAttr Proc Uses ES DI SI, FName:Ptr, Attr:Ptr

    Mov  DX,CS            ;install CEH
    Lea  BX,CS:Exit
    Call Setup_CEH

    Mov  SI,FName         ;SI holds address of FileName$ descriptor
    Call Load_File        ;create an ASCIIZ string
    Jc   ErrExit          ;quit if an error was detected

    Mov  SI,Attr          ;get address of Attr%
    Mov  CX,[SI]          ;put it into CX

    Mov  AX,4301h         ;set attribute service
    Call DOS              ;call DOS to do the dirty work
    Jnc  Exit             ;if the carry flag isn't set, it went as planned

ErrExit:
    Call Load_DOSErr

Exit:
    Call Restore_CEH      ;restore the QuickBASIC critical error handler
    Ret                   ;return to BASIC

SetAttr Endp
End
