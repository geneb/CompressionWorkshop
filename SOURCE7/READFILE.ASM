;----- ReadFile.Asm - gets a list of file names into a BASIC string array

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad
;BC7 version J.Munro

;Syntax -
;
;   FileName$(0) = "*.*"
;   CALL ReadFile(BYVAL VARPTR(FileName$(0)))
;
;   Where FileName$(0) holds the directory specification, and subsequent
;   elements receive the directory entries.
;   Errors are returned in DOS/WhichError.

.Model Medium, Basic
.Data
    Extrn QPDTA:Byte      ;these are in External.Asm
    Extrn File_Name:Byte

.Code
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far
    Extrn Load_File:Far, DOS:Far
    Extrn StringInfo:Proc

ReadFile Proc Uses ES DI SI BP, FName:Ptr

    Mov  CS:OldES,ES
    Mov  DX,CS            ;install CEH
    Lea  BX,CS:Exit
    Call Setup_CEH

    Lea  DX,QPDTA         ;put address of QPDTA into DS:DX for set DTA service
    Mov  AH,1Ah           ;set DTA service - creates space for file names
    Call DOS

    Mov  SI,FName         ;SI holds address of FileName$(0) descriptor
    Mov  BX,SI            ;save address of FileName$(0) so we can find
                          ;  successive elements later
    Call Load_File        ;create an ASCIIZ string
    Jc   ErrExit          ;quit if an error was detected

    Mov  BP,00100111b     ;the attribute for any type of file

    Cld                   ;clear direction flag to keep things movin' f'ward
    Mov  AH,4Eh           ;find first matching file name service
    Mov  CX,BP            ;specify search to include any type of file
    Call DOS              ;call DOS
    Jc   ErrExit          ;none were found

Got_File:

    Add  BX,4             ;now BX holds address of next FileName$() descriptor
    Mov  SI,BX            ;point SI at next array descriptor
    Mov  ES,CS:OldES      ;retread ES for stringinfo to use

    Call StringInfo       ;get address and length of array element

    Cmp  CX,12            ;is the string at least 12 characters long?
    Jb   BadBuffer        ;no, so get out now
    Mov  DI,AX            ;DI holds address of first character in FileName$()
    Mov  ES,DX
    Lea  SI,QPDTA         ;get the QPDTA address again
    Add  SI,30            ;Source Index now points to file name area in QPDTA

Move_Chars:
    Lodsb                 ;get character in file name from QPDTA
    Test AL,AL            ;is it a CHR$(0) indicating the end of this name?
    Jz   Pad_Spc          ;yes, fill remainder of FileName$() with spaces
                          ;  and continue on to the next file name
    Stosb                 ;no, put it into FileName$()
    Loop Move_Chars       ;continue until done

Pad_Spc:
    Mov  AL,32            ;prepare to fill remainder of FileName$ with blanks
                          ;  (to clear any previous names)
    Rep  Stosb            ;the count remaining in CX specifies how many
                          ;  blanks to move into FileName$

    Mov  AH,4Fh           ;find next matching file name service
    Call DOS              ;let DOS find the next file
    Jnc  Got_File         ;if not carry, then process the next file
    Jmp  Short Exit       ;else, we're done!

BadBuffer:
    Mov  AX,27            ;string buffer must be dimensioned to at least 12

ErrExit:
    Call Load_DOSErr      ;put up an error code

Exit:
    Call Restore_CEH      ;restore the QuickBASIC critical error handler
    Ret

ReadFile Endp
    OldES  DW  ?

End
