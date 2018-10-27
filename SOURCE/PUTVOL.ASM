;----- PutVol.Asm - adds a volume label to a specified drive

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad

;Syntax - Drive$ = "A"
;         Volume$ = "LabelName"
;         CALL PutVol(Drive$, Volume$)
; Where Volume$ is the new label name,
;       Drive$ = "" for the default drive, or "A" or "a" or "B", etc.
;       Errors are returned in DOS/WhichError.

.Model Medium, Basic
.Data
    Extrn FCB:Byte
    Extrn Attr:Byte
    Extrn Drive:Byte
    Extrn Old_Name:Byte
    Extrn New_Name:Byte
    Extrn File_Name:Byte

.Code
    Include Mixed.Inc
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far
    Extrn Create_Err:Far, Reset_FCB:Far, DOS:Far

HProc PutVol, Driv:Ptr, Volume:Ptr

    Mov  DX,CS              ;install CEH
    Lea  BX,CS:Exit
    Call Setup_CEH

    Push DS
    Pop  ES                 ;insure that ES holds DS for string moves below

    Mov  CL,8               ;put the attribute for a volume name in CL
    Call Reset_FCB

    Lea  DX,FCB             ;put address of FCB into DS:DX for set DTA service
    Mov  AH,1Ah             ;set DTA service
    Call DOS                ;call DOS

    Mov  DI,Driv            ;put address of Drive$ descriptor into SI
    Cmp  Word Ptr [DI],0    ;is Drive$ a null indicating the default drive?
    Mov  DL,0               ;assure Drive is zero
    Jz   Do_It              ;yes, and default is already specified

    Mov  DI,[DI+02]         ;put address of Drive$ data into DI
    Mov  AL,[DI]            ;put first character of Drive$ into AL
    Cmp  AL,'a'             ;is it less than "a"?
    Jb   Continue           ;yes, skip
    Sub  AL,32              ;no, convert to upper case

Continue:
    Sub  AL,64              ;adjust so "A" = 1, "B" = 2, etc.

    Mov  DL,AL              ;get the drive spec into DL
    Lea  SI,File_Name       ;get address of File_Name into SI
    Mov  AH,47h             ;ask DOS to get the current directory
    Call DOS
    Jc   ErrExit            ;if carry, then drive spec is invalid

Do_It:
    Mov  SI,Volume          ;put address of Volume$ descriptor into SI
    Mov  CX,[SI]            ;and LEN(Volume$) into CX
    Cmp  CX,11              ;is Volume$ too long to put into the FCB?
    Jbe  Continue2          ;no, continue
    Mov  CX,11              ;yes, just use the first eleven characters

Continue2:
    Mov  SI,[SI+02]         ;point SI to first character in Volume$

    Mov  Drive,DL           ;place the drive indentifier into the FCB
    Cld                     ;we'll be moving characters forward
    Lea  DX,FCB             ;show DOS where the FCB is
    Mov  AH,11h             ;find file service (a volume label is file name)
    Call DOS                ;call DOS
    Or   AL,AL              ;was there a label?
    Js   Add_Label          ;if sign flag set, then search failed,
                            ;  AL would hold FFh as an error code)

    Mov  BX,CX              ;BX and CX hold label length
    Lea  DI,New_Name        ;set up to move Volume$ into the FCB
    Rep  Movsb              ;copy the new label there now
    Mov  AL,32              ;prepare to pad the rest of the FCB if needed

Pad_Loop:
    Cmp  BX,11              ;did we already have 11 characters?
    Jz   Ren_Label          ;yes, go rename it
    Inc  BX                 ;no, keep track of how many blanks we insert
    Stosb                   ;put the next blank in place
    Jmp  Pad_Loop

Ren_Label:
    Mov  AH,17h             ;prepare to rename the existing label
    Call DOS                ;ask DOS to do it
    Cmp  AL,0FFH            ;did we get an error?
    Jne  Exit               ;if not, then we're done
    Mov  AX,5               ;else, report "Access denied"
    Jmp  Short ErrExit

Add_Label:
    Mov  BX,CX              ;BX now holds the length of the label
    Lea  DI,Old_Name        ;prepare to move Volume$ into the FCB
    Rep  Movsb              ;move the new label into the FCB
    Mov  AL,32              ;prepare to pad the rest of the FCB label name
                            ;  with blanks (if < 11)

Add_Loop:
    Cmp  BX,11              ;did we already have 11 characters?
    Jz   Add_Label2         ;yes, skip this nonsense and add the bloody thing
    Inc  BX                 ;no, pad with blanks until done
    Stosb
    Jmp  Add_Loop

Add_Label2:
    Mov  AH,16h             ;tell DOS to create a new label
    Call DOS
    Cmp  AL,0FFH            ;did we get an error?
    Jne  NoError            ;if not, then we're almost done
    Mov  AX,5               ;else, simulate an "Access Denied" error
    Call Create_Err         ;and call Create_Err for some help

ErrExit:
    Call Load_DOSErr        ;translate the error code
    Jmp  Short Exit         ;and get out

NoError:
    Mov  AH,10h             ;close FCB service
    Call DOS

Exit:
    Call Restore_CEH        ;restore the QuickBASIC critical error handler
    HRet                    ;return to BASIC

HEndp
End
