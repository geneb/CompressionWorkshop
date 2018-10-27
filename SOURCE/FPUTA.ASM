;----- FPutA.Asm - writes a dynamic array to a binary file

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad
;BC7 Version J. Munro

;Syntax - CALL FPutA(Handle%, SEG Array(Start), NumBytes&)
;
;  Where Handle% is the number DOS originally assigned when the file was
;  opened, Array(Start) is the array that contains the data to write,
;  and NumBytes is the number of words to be written.  Note that NumBytes
;  can be either integer(%) or long integer(&).  Byte counts greater than
;  32K can be passed in a long integer parameter.  Errors are returned in
;  DOS/WhichError.

.Model Medium, Basic
.Code
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far, DOS:Far

FPutA Proc Uses SI, Handle:Ptr, Array:DWord, NumBytes:Ptr

    Mov  DX,CS            ;install CEH
    Lea  BX,CS:Exit
    Call Setup_CEH

    Push DS               ;save DS before we trash it below
    Mov  SI,Handle        ;get the address for Handle%
    Mov  BX,[SI]          ;and put it into BX
    Mov  SI,NumBytes      ;get the address for NumBytes
    Mov  CX,[SI]          ;put it into CX
    Lds  DX,Array         ;load DS:DX with segmented address of Array%(Start)

    Mov  AX,27            ;assume Source$ is null
    Jcxz ErrExit          ;it IS null, get out now!

    Mov  AH,40h           ;specify Write service
    Call DOS              ;call DOS
    Jc   ErrExit          ;get out if there was an error

    Cmp  AX,CX            ;check for the disk full case
    Je   Exit             ;if AX = CX, then buffer was written
    Mov  AX,21            ;else, disk is full

ErrExit:
    Call Load_DOSErr      ;put up the error code

Exit:
    Pop  DS               ;restore DS before we return to BASIC
    Call Restore_CEH      ;restore the QuickBASIC critical error handler
    Ret                   ;return to BASIC

FPutA Endp
End
