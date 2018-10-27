;CWRDTEST.ASM -- Tests if a disk drive is ready for reading.
;
;Copyright (c) 1992 Phil Weber

;to create the far strings version of this program assemble with /DPDS

.Model Medium, Basic

    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far
    
IFDEF PDS
    Extrn StringInfo:Proc
ENDIF

.Code

CWReadTest Proc, Drive:Word

    Sub  SP,512           ;create space for local buffer

    Mov  DX,CS            ;install CEH
    Lea  BX,CS:CEH_Ret
    Call Setup_CEH

IFNDEF PDS                ;near strings code
    Mov  BX,Drive         ;put Drive$ descriptor into BX
    Mov  AL,[BX]          ;put LEN(Drive$) into DL
    Or   AL,AL            ;null string?
    Jz   GetDrive         ;yes, get the current drive and use that

    Mov  BX,[BX+02]       ;get address of Drive$
    Mov  AL,[BX]          ;now DL has ASC(Drive$)
    And  AL,223           ;convert to upper case
    Sub  AL,65            ;convert "A" to 0, "B" to 1, etc.
    Jmp  Short Do_It
ELSE                      ;far strings code
    Push SI               ;save SI for a moment
    Mov  SI,Drive
    Call StringInfo       ;returns AX = address, CX = length, DX = segment
    Pop  SI               ;retrieve SI
    Or   CX,CX            ;null string?
    Jz   GetDrive         ;yes, get the current drive and use that

    Push DS               ;save DS for a moment
    Mov  DS,DX            ;point DS:BX to the start of the string
    Mov  BX,AX
    Mov  AL,[BX]          ;now DL has ASC(Drive$)
    And  AL,223           ;convert to upper case
    Sub  AL,65            ;convert "A" to 0, "B" to 1, etc.
    Pop  DS
    Jmp  Short Do_It
ENDIF

GetDrive:
    Mov  AH,19h           ;get current drive from DOS
    Int  21h

Do_It:
    Mov  CX,1             ;read one sector:
    Mov  DX,0             ; sector 0
    Mov  BX,SP            ;point to local buffer
    Int  25h              ;call absolute read function
    Pop  DX               ;clean up stack
    Jc   ErrExit          ;if carry, something's wrong
    Mov  AX,-1            ;else read operations are OK
    Jmp  Short Exit

ErrExit:
    Call Load_DOSErr      ;put up the error code

CEH_Ret:
    Cmp  AH,2             ;if error code 2...
    Jne  FormatOK
    Mov  AX,1             ;return "Not formatted" error code
    Jmp  Short Exit

FormatOK:
    Xor  AX,AX            ;DOS says we can't read the disk

Exit:
    Call Restore_CEH      ;restore BASIC's critical error handler
    Add  SP,512
    Ret

CWReadTest Endp
End
