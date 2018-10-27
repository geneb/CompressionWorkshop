;----- GetVol.Asm - retrieves the volume label for a specified drive

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad

;Syntax - Volume$ = GetVol$(Drive$)
;         where Volume$ receives the returned path,
;         and Drive$ = "" for the default drive, or "A" or "a" or "B", etc.
;
;         Drive$ can be a string of any length, since GetVol looks only
;         at the first character.


;Errors are returned in DOS/WhichError.  If a volume name is not found,
;GetVol$ returns a null string and WhichError returns with "file not found".


.Model Medium, Basic
.Data
    Extrn FN_Len:Byte
    Extrn File_Name:Byte
    Extrn FCB:Byte
    Extrn Drive:Byte
    Extrn Old_Name:Byte

.Code
    Include Mixed.Inc
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far, DOS:Far
    Extrn Reset_FCB:Far

HProc GetVol, Driv:Ptr

    Mov  DX,CS            ;install CEH
    Lea  BX,CS:Exit
    Call Setup_CEH

    Push DS
    Pop  ES               ;insure that ES holds Data Segment
    Mov  CL,8             ;put the attribute for a volume name in CL
    Call Reset_FCB        ;start with a fresh FCB

    Lea  DI,FN_Len        ;get the address for the function's descriptor
    Xor  AX,AX            ;clear it to show a null in case of an error later
    Cld                   ;be sure the Stosw works forward
    Stosw
    Lea  AX,Old_Name      ;assign the address of the volume label DOS returns
    Stosw                 ;  into the descriptor's address area
    Sub  DI,4             ;point DI to the length part again for later

    Lea  DX,FCB           ;put address of FCB into DS:DX for set DTA service
    Mov  AH,1Ah           ;set DTA service
    Call DOS              ;call DOS

    Mov  SI,Driv          ;put address of Drive$ descriptor into SI
    Cmp  Word Ptr [SI],0  ;is Drive$ a null indicating the default drive?
    Mov  DL,0             ;assure Drive is zero
    Jz   Do_It            ;yes, and default is already specified

    Mov  SI,[SI+02]       ;put address of Drive$ data into SI
    Mov  AL,[SI]          ;put first character of Drive$ into AL
    Cmp  AL,'a'           ;is it less than "a"?
    Jb   Continue         ;yes, skip
    Sub  AL,32            ;no, convert to upper case

Continue:
    Sub  AL,64            ;adjust so "A" = 1, "B" = 2, etc.
    Mov  DL,AL            ;put the drive spec into DL
    Lea  SI,File_Name     ;point SI to File_Name
    Mov  AH,47h           ;ask DOS for the current directory
    Call DOS              ;  this step validates the drive spec
    Jc   ErrExit          ;if carry, then drive was invalid

Do_It:
    Mov  Drive,DL         ;place the drive indentifier into the FCB
    Lea  DX,FCB           ;show DOS where the FCB is
    Mov  AH,11h           ;find file service (volume label is actually a file)
    Call DOS              ;call DOS
    Or   AL,AL            ;was there a label?
    Mov  AX,2             ;assume file was not found
    Js   ErrExit          ;if sign flag set, then the search failed,
                          ;  DOS would put FFh into AL as an error code)
    Mov  Word Ptr [DI],11 ;assign eleven characters for the volume name
    Jmp  Short Exit       ;and quit without error

ErrExit:
    Call Load_DOSErr      ;translate the error code

Exit:
    Lea  AX,FN_Len        ;show BASIC where the function's descriptor is
    Call Restore_CEH      ;restore the QuickBASIC critical error handler
    HRet                  ;return to BASIC

HEndp
End
