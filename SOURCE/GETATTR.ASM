;----- GetAttr.Asm - gets a file's attributes

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad

;Syntax - FileName$ = "\Path\Filename.Ext"
;         Attr = GetAttr%(FileName$)
;         IF Attr  = - 1 THEN . . . file not found or some other error
;         Errors are returned in DOS/WhichError.

.Model Medium, Basic
.Data
    Extrn File_Name:Byte  ;this is in External.Asm

.Code
    Include Mixed.Inc
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far
    Extrn Load_File:Far, DOS:Far

HProc GetAttr, FName:Ptr

    Mov  DX,CS            ;install CEH
    Lea  BX,CS:CEH_Ret
    Call Setup_CEH

    Mov  SI,FName         ;SI holds address of FileName$ descriptor
    Call Load_File        ;create an ASCIIZ string
    Jc   ErrExit          ;quit if an error was detected

    Mov  AX,4300h         ;get attribute service
    Call DOS              ;call DOS to do the dirty work
    Jc   ErrExit          ;if the carry flag is set, an error occured

    Xor  CH,CH            ;clear CH so we can use all of CX
    Mov  AX,CX            ;now put CX into AX for the function output
    Jmp  Short Exit       ;skip over the error handler

ErrExit:
    Call Load_DOSErr      ;put up the error code

CEH_Ret:
    Mov  AX,-1            ;set Attribute to -1 to show an error

Exit:
    Call Restore_CEH
    HRet                  ;return to BASIC

HEndp
End
