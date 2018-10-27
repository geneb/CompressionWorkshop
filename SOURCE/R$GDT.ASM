;======================================================================
; R$GDT.ASM
;       Copyright (c) 1992 Crescent Software
;       Copyright (c) 1992 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1/6/92        .000    Original version.
; 10/15/92      .001    Detect 2.88MB Thanks Allen Hillman
;----------------------------------------------------------------------
PUBLIC GetDisketteType

;======================================================================
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
        DGROUP  GROUP   DSEG,USEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
DSEG            ENDS
USEG            SEGMENT WORD    PUBLIC  'BSS'
USEG            ENDS

;======================================================================
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT BYTE    PUBLIC  'CODE'
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

;======================================================================
; GetDisketteType (FAR, QuickPak)
;   Copyright (c) 1992 Crescent Software
;   Copyright (c) 1992 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; This procedure determines the type of diskette drive installed in the
; system and returns a unique code that identifies the type of drive.
;
; Note that this routine identifies only PHYSICAL diskette drives. On a
; single floppy system, for example, B: will be reported as not present.
;----------------------------------------------------------------------
; Usage:
;       Result% = GetDisketteType(DriveNumber%)
; where
;       DriveNumber% = physical drive number.
;               0 = 1st physical diskette
;               1 = 2nd physical diskette
;               2 = 3rd physical diskette
;                   etc.
;
;       Result = 0, Drive not present or cannot identify
;                1, 360K 5.25" 40 track
;                2, 1.2M 5.25" 80 track
;                3, 720K 3.5"  80 track
;                4, 1.4M 3.5"  80 track
;----------------------------------------------------------------------
; Changes: AX BX CX DX ES
;----------------------------------------------------------------------
GetDisketteType PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BP                      ;Create stack frame
                MOV     BP,SP

                PUSH    SI
                PUSH    DI                      ;Save used registers
;----------------------------------------------------------------------
; Get the passed diskette number.
;----------------------------------------------------------------------
                SUB     AX,AX                   ;Assume an error

                MOV     BX,WORD PTR [BP+6]      ;Get pointer
                MOV     DX,WORD PTR [BX]        ;Drive number
                MOV     SI,DX                   ;Save
;----------------------------------------------------------------------
; The Read Drive Parameters BIOS function is supported by all PCs
; except the PC, XT, PCjr, and early AT (BIOS 1/10/84). It returns the
; drive type in BL.
;----------------------------------------------------------------------
                MOV     AH,8                    ;Get disk type
                INT     13H                     ; thru BIOS
                JNC     GDT_3A
;----------------------------------------------------------------------
; The carry flag was set, indicating that this BIOS function is not
; supported on this machine. This means that the BIOS does not contain
; support for any 3.5" drives.
;
; All machines that support the 1.2M drive support the Read DASD
; (Direct Access Storage Device) Type function call.
;----------------------------------------------------------------------
                MOV     AH,15H                  ;Read DASD type
                MOV     DX,SI                   ;For drive in DL
                INT     13H                     ; thru BIOS
                JNC     GDT_2
;----------------------------------------------------------------------
; The carry flag was set. This can only be a 360k 5.25" drive.
;----------------------------------------------------------------------
                MOV     AX,1
                JMP     SHORT GDT_EXIT
;----------------------------------------------------------------------
; The Read DASD type call was successful. If the drive supports the
; change line it is a 1.2M. Otherwise, it is a 360k. AH contains the
; return code for the drive type.
;----------------------------------------------------------------------
GDT_2:
                SUB     AL,AL
                XCHG    AH,AL
                JMP     SHORT GDT_EXIT
;----------------------------------------------------------------------
; If CX=0, then the specified drive is not installed.
; By definition, AX already contains a 0, so simply return.
;----------------------------------------------------------------------
GDT_3A:
                JCXZ    GDT_EXIT
;----------------------------------------------------------------------
; If BL=0, then the CMOS was corrupt. Determine the drive type by
; matching the returned drive parameters.
;----------------------------------------------------------------------
                ADD     AL,BL
                JNZ     GDT_EXIT

                MOV     AX,CX
                MOV     CX,6

                CMP     AX,4F24h                ;Type 5 -- 2.88MB 3.5"
                LOOPE   GDT_3B

                CMP     AX,4F12H                ;Type 4
                LOOPE   GDT_3B

                CMP     AX,4F09H                ;Type 3
                LOOPE   GDT_3B

                CMP     AX,4F0FH                ;Type 2
                LOOPE   GDT_3B

                CMP     AX,2709H                ;Type 1
                LOOPE   GDT_3B
GDT_3B:
                MOV     AX,CX
GDT_EXIT:
                POP     DI
                POP     SI
                POP     BP
                RET     1*2

GetDisketteType ENDP

CSEG            ENDS
                END
