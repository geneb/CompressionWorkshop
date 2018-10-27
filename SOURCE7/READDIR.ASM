;----- ReadDir.Asm - gets a list of directories into a BASIC string array

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad
;BC7 version J.Munro

;Syntax -
;
;   DirName$(0) = "*.*"
;   CALL ReadDir(BYVAL VARPTR(DirName$(0)))
;
;   Where DirName$(0) holds the directory specification, and subsequent
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

ReadDir Proc Uses ES DS DI SI, FName:Ptr

    Mov  CS:OldES,ES

    Mov  DX,CS            ;install CEH
    Lea  BX,CS:Exit
    Call Setup_CEH

    Lea  DX,QPDTA         ;put address of QPDTA into DS:DX for set DTA service
    Mov  AH,1Ah           ;set DTA service - creates space for file names
    Call DOS

    Mov  SI,FName         ;SI holds address of DirName$(0) descriptor
    Mov  BX,SI            ;save address in BX so we can find successive
                          ;  elements later
    Call Load_File        ;create an ASCIIZ string
    Jc   ErrExit          ;quit if an error was detected

    Mov  CS:Found,BX      ;save BX in Found for the "file not found" test
    Mov  BP,00010011b     ;the attribute for a directory (+ read-only/hidden)

    Mov  AH,4Eh           ;find first matching file name service
    Mov  CX,BP            ;specify search to include only directories
    Call DOS              ;call DOS
    Jc   ErrExit          ;no more directories (or invalid directory name)

Got_File:
    Test Byte Ptr [QPDTA+21],10000b ;is it in fact a directory?
    Jz   More                       ;no, skip ahead
    Cmp  Byte Ptr [QPDTA+30],"."    ;is it a "." or ".." directory entry?
    Je   More                       ;yes, skip over those too

    Add  BX,4             ;now BX holds address of next DirName$() descriptor

    Mov  ES,CS:OldES

    Mov  SI,BX
    Call StringInfo
    Mov  ES,DX

    Cmp  CX,12            ;is the string at least 12 characters long?
    Jb   BadBuffer        ;no, so get out now
    Mov  DI,AX            ;DI holds address of first character in DirName$()
    Lea  SI,QPDTA         ;get the DTA address again
    Add  SI,30            ;Source Index now points to file name area in QPDTA
                          ;  from QPDTA to DirName$()
Move_Chars:
    Lodsb                 ;get character in file name from QPDTA
    Test AL,AL            ;is it a CHR$(0) indicating the end of this name?
    Jz   Pad_Spc          ;yes, fill remainder of DirName$() with spaces
                          ;  and continue on to the next file name
    Stosb                 ;no, put it into DirName$()
    Dec  CX               ;show that another character was placed
                          ;  into DirName$()
    Jmp  Move_Chars       ;continue

Pad_Spc:
    Mov  AL,32            ;prepare to fill remainder of DirName$ with blanks
                          ;  (to clear any previous names)
    Rep  Stosb            ;the count remaining in CX specifies how many
                          ;  blanks to move into DirName$
More:
    Mov  AH,4Fh           ;find next matching file name service
    Mov  CX,BP            ;specify search to include only directories
    Call DOS              ;call DOS
    Jnc  Got_File         ;if not carry, do it until done

    Mov  BP,SP            ;we have to recover BP to access Found
    Add  BP,2             ;BP was one word above SP (too cool)
    Cmp  CS:Found,BX      ;did we get a file?
    Jne  Exit             ;if yes, then exit without error
    Mov  AX,2             ;if not, quit with "file not found" error
    Jmp  Short ErrExit

BadBuffer:
    Mov  AX,27            ;string buffer must be dimensioned to 12

ErrExit:
    Call Load_DOSErr      ;translate the error code

Exit:
    Call Restore_CEH      ;restore the QuickBASIC critical error handler
    Ret                   ;return to BASIC

ReadDir Endp
    OldES  DW  ?
    Found  DW  ?
End
