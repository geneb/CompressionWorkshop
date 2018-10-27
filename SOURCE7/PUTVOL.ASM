;----- PutVol.Asm - adds a volume label to a specified drive
;
;Copyright (c) 1989 Ethan Winer
;Revised Jan 89 - J. R. Conrad
;BC7 version J. Munro

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
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far
    Extrn Create_Err:Far, Reset_FCB:Far, DOS:Far
    Extrn StringInfo:Proc

PutVol Proc Uses ES DI SI, Driv:Ptr, Volume:Ptr

    Mov  DX,CS              ;install CEH
    Lea  BX,CS:Exit
    Call Setup_CEH

    Mov  CL,8               ;put the attribute for a volume name in CL
    Call Reset_FCB

    Lea  DX,FCB             ;put address of FCB into DS:DX for set DTA service
    Mov  AH,1Ah             ;set DTA service
    Call DOS                ;call DOS

    Mov  CS:OldDS,DS
    Mov  CS:OldES,ES
    Mov  SI,Driv            ;put address of Drive$ descriptor into SI
    Call StringInfo
    Mov  ES,DX              ;put segment of Drive$ data into ES
    Mov  DI,AX              ;put address of Drive$ data into DI
    Mov  DL,0               ;assure Drive is zero
    Jcxz Do_It              ;is Drive$ a null indicating the default drive?
                            ;yes, and default is already specified
    Mov  AL,ES:[DI]         ;put first character of Drive$ into AL
    Cmp  AL,'a'             ;is it less than "a"?
    Jb   Continue           ;yes, skip
    Sub  AL,32              ;no, convert to upper case

Continue:
    Sub  AL,64              ;adjust so "A" = 1, "B" = 2, etc.
    Mov  Drive,AL           ;place the drive indentifier into the FCB
    Mov  DL,AL              ;get the drive spec into DL
    Lea  SI,File_Name       ;get address of File_Name into SI
    Mov  AH,47h             ;ask DOS to get the current directory
    Call DOS
    Jc   LeapFrog           ;if carry, then drive spec is invalid

Do_It:
    Mov  ES,CS:OldES
    Mov  SI,Volume          ;put address of Volume$ descriptor into SI
    Call StringInfo         ;and LEN(Volume$) into CX
    Mov  SI,AX              ;point SI to first character in Volume$
    Mov  ES,DX
    Cmp  CX,11              ;is Volume$ too long to put into the FCB?
    Jbe  Continue2          ;no, continue
    Mov  CX,11              ;yes, just use the first eleven characters

Continue2:

    Cld                     ;we'll be moving characters forward
    Lea  DX,FCB             ;show DOS where the FCB is
    Mov  AH,11h             ;find file service (a volume label is file name)
    Call DOS                ;call DOS
    Or   AL,AL              ;was there a label?
    Js   Add_Label          ;if sign flag set, then search failed,
                            ;  AL would hold FFh as an error code)

    Lea  DI,New_Name        ;set up to move Volume$ into the FCB
    Push ES                 ;swap ES & DS to send things in the right
    Push DS                 ;  direction with Movsb
    Pop  ES                 ;
    Pop  DS                 ;
    Mov  BX,CX              ;BX and CX hold label length
    Rep  Movsb              ;copy the new label there now
    Mov  AL,32              ;prepare to pad the rest of the FCB if needed

Pad_Loop:
    Cmp  BX,11              ;did we already have 11 characters?
    Jz   Ren_Label          ;yes, go rename it
    Inc  BX                 ;no, keep track of how many blanks we insert
    Stosb                   ;put the next blank in place
    Jmp  Pad_Loop

LeapFrog:
    Jmp  ErrExit

Ren_Label:
    Push ES                 ;set DS back to point at new label DS:DX
    Pop  DS                 ;
    Lea  DX,FCB             ;    set DX to point at FCB
    Mov  AH,17h             ;prepare to rename the existing label
    Call DOS                ;ask DOS to do it
    Cmp  AL,0FFH            ;did we get an error?
    Jne  Exit               ;if not, then we're done
    Mov  AX,5               ;else, report "Access denied"
    Jmp  Short ErrExit

Add_Label:
    Push ES
    Pop  DS
    Mov  ES,CS:OldDS        ;point ES at Old DS
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
    Push ES
    Pop  DS
    Lea  DX,FCB             ;retrieve address of FCB
    Mov  AH,16h             ;tell DOS to create a new label
    Call DOS
    Cmp  AL,0FFH            ;did we get an error?
    Jne  Exit               ;if not, then we're done
    Mov  AX,5               ;else, simulate an "Access Denied" error
    Call Create_Err         ;and call Create_Err for some help

ErrExit:
    Call Load_DOSErr        ;translate the error code

Exit:
    Call Restore_CEH        ;restore the QuickBASIC critical error handler
    Ret                     ;return to BASIC

PutVol Endp
    OldES  DW  ?
    OldDS  DW  ?

End
;bug fix 4/13/90 J.M.
