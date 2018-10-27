;======================================================================
; R$FORMAT.ASM
;   Copyright (c) 1992 Crescent Software
;   Copyright (c) 1992 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1/6/92        .000    Original version.
; 9/25/92       .001    Fix exit code to return correct info (EW).
;----------------------------------------------------------------------
PUBLIC  FormatDiskette

EXTRN   GetDisketteType:FAR

;======================================================================
; Equates
;----------------------------------------------------------------------
; These errors are defined by the BIOS.
;----------------------------------------------------------------------
ERR$INV_DISK_PARM       EQU     1
ERR$ADR_MARK_NOT_FND    EQU     2
ERR$WR_PROT_ERR         EQU     3
ERR$REQ_SEC_NOT_FND     EQU     4
ERR$DISK_CHG_LN_ACTV    EQU     6
ERR$DMA_OVRRUN          EQU     8
ERR$DMA_BNDRY           EQU     9
ERR$MED_TYP_NOT_FND     EQU     0CH
ERR$CRC_RD_ERR          EQU     10H
ERR$CTRLR_FAIL          EQU     20H
ERR$SEEK_FAIL           EQU     40H
ERR$DRV_NOT_RDY         EQU     80H     ;You'll get this if door open
;----------------------------------------------------------------------
; I define these additional errors.
;----------------------------------------------------------------------
ERR$INV_DRV             EQU     5       ;Can't find the drive
ERR$INV_CAP             EQU     7       ;Wrong capacity for drive
ERR$TRK_0_BAD           EQU     0AH     ;Bad disk/cap=1.4 with 720k disk
ERR$BAD_SECT            EQU     0BH     ;Bad sectors found and marked
;----------------------------------------------------------------------
; Drive types as returned by GetDisketteType.
;----------------------------------------------------------------------
DRIVE_360               EQU     1
DRIVE_1200              EQU     2
DRIVE_720               EQU     3
DRIVE_1440              EQU     4
;----------------------------------------------------------------------
; Program equates.
;----------------------------------------------------------------------
RETRY0                  EQU     5               ;Retries for track 0
RETRY                   EQU     3               ;Retries for other tracks

;======================================================================
;
;----------------------------------------------------------------------
LOMEM           SEGMENT AT      0000H

                ORG     (1EH * 4H)      ;Int 1Eh points to disk base
DISK_BASE       DD      ?

LOMEM           ENDS

;======================================================================
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
        DGROUP  GROUP   DSEG,USEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'

;----------------------------------------------------------------------
; Each entry defines all the information for a particular disk format.
;----------------------------------------------------------------------
; Media info/boot record for 360K 5.25" floppy.
;----------------------------------------------------------------------
MEDIA_360       DB      50H                     ; 0, Format gap length
                DB      40                      ; 1, Number of tracks
                DB      7                       ; 2, Root dir sectors
                DB      0EBH,2DH,90H            ; 3, JMP 30H, NOP
                DB      "SCHAEFER"              ; 6, System ID
                DW      512     ;200H           ;14, Bytes per sector
                DB      2                       ;16, Sectors per cluster
                DW      1                       ;17, # reserved sectors
                DB      2                       ;19, # copies of FAT
                DW      112     ;70H            ;20, # root directory entries
                DW      2*9*40  ;2D0H           ;22, Total # of sectors
                DB      0FDH                    ;24, Format ID
                DW      2                       ;25, Sectors per FAT
                DW      9                       ;27, Sectors per track
                DW      2                       ;29, Number of heads
                DD      0                       ;31, Special reserved sectors
;----------------------------------------------------------------------
; Media info/Boot record for 1.2M 5.25" floppy.
;----------------------------------------------------------------------
MEDIA_1200      DB      54H                     ;Format gap length
                DB      80                      ;Number of tracks
                DB      14                      ; 2, Root dir sectors
                DB      0EBH,30H,90H            ;JMP 29H, NOP
                DB      "SCHAEFER"              ;System ID
                DW      512     ;200H           ;Bytes per sector
                DB      1                       ;Sectors per cluster
                DW      1                       ;# reserved sectors
                DB      2                       ;# copies of FAT
                DW      224     ;E0H            ;# root directory entries
                DW      2*15*80 ;960H           ;Total # of sectors
                DB      0F9H                    ;Format ID
                DW      7                       ;Sectors per FAT
                DW      15                      ;Sectors per track
                DW      2                       ;Number of heads
                DD      0                       ;Special reserved sectors
;----------------------------------------------------------------------
; Media info/Boot record for 720K 3.5" floppy.
;----------------------------------------------------------------------
 MEDIA_720      DB      50H                     ;Format gap length
                DB      80                      ;Number of tracks
                DB      7                       ; 2, Root dir sectors
                DB      0EBH,30H,90H            ;JMP 29H, NOP
                DB      "SCHAEFER"              ;System ID
                DW      512     ;200H           ;Bytes per sector
                DB      2                       ;Sectors per cluster
                DW      1                       ;# reserved sectors
                DB      2                       ;# copies of FAT
                DW      112     ;E0H            ;# root directory entries
                DW      2*9*80  ;               ;Total # of sectors
                DB      0F9H                    ;Format ID
                DW      3                       ;Sectors per FAT
                DW      9                       ;Sectors per track
                DW      2                       ;Number of heads
                DD      0                       ;Special reserved sectors
;----------------------------------------------------------------------
; Media info/Boot record for 1.44M 3.5" floppy.
;----------------------------------------------------------------------
 MEDIA_1440     DB      6CH                     ;Format gap length
                DB      80                      ;Number of tracks
                DB      14                      ; 2, Root dir sectors
                DB      0EBH,30H,90H            ;JMP 29H, NOP
                DB      "SCHAEFER"              ;System ID
                DW      512     ;200H           ;Bytes per sector
                DB      1                       ;Sectors per cluster
                DW      1                       ;# reserved sectors
                DB      2                       ;# copies of FAT
                DW      224     ;E0H            ;# root directory entries
                DW      2*18*80 ;               ;Total # of sectors
                DB      0F0H                    ;Format ID
                DW      9                       ;Sectors per FAT
                DW      18                      ;Sectors per track
                DW      2                       ;Number of heads
                DD      0                       ;Special reserved sectors
;----------------------------------------------------------------------
; Common suffix for each boot record.
;----------------------------------------------------------------------
BOOTCODE        LABEL   BYTE                    ;offset 30h

                CLI                             ;No interrupts

                SUB     AX,AX                   ;AX = 0
                MOV     SS,AX                   ;Create stack
                MOV     SP,7C00H

                MOV     DS,AX                   ;DS=0000
                MOV     SI,OFFSET BOOTMSG - OFFSET BOOTCODE + 7C30h
                MOV     CX,BOOTMSGLEN           ;Message length
                CLD                             ;String moves forward

                LODSB                           ;AL=DS:[SI++]
                MOV     AH,0EH                  ;Write TTY
                MOV     BX,7
                INT     10H                     ; thru BIOS

                LOOP    $-8

                SUB     AX,AX                   ;Wait for key
                INT     16H                     ; thru BIOS

                MOV     WORD PTR DS:[472H],1234H
                DB      0EAH
                DW      0,0FFFFH

BOOTMSG         DB      13,10,"You cannot boot from this disk; it does"
                DB      13,10,"not contain the DOS system files."
                DB      13,10,"Replace or remove the diskette and "
                DB      13,10,"press Enter ",17,217," to reboot.",13,10

BOOTMSGLEN      EQU     $-OFFSET BOOTMSG

                DB      "Copyright (c) 1992, Robert L. Hummel"

BOOTCODELEN     EQU     $-OFFSET BOOTCODE

DSEG            ENDS

;----------------------------------------------------------------------
; Do not change order of data items. (Ethan, this means you.)
;----------------------------------------------------------------------
USEG            SEGMENT WORD    PUBLIC  'BSS'

SAVE_BASE       DW      1 DUP (?)
MEDIAPTR        DW      1 DUP (?)       ;Points to correct media info
TBUFPTR         DW      1 DUP (?)       ;Points to start of track buffer

DRIVENUM        DB      1 DUP (?)       ;Physical drive number
DRIVETYPE       DB      1 DUP (?)       ;Type of drive
FUNCTION        DB      1 DUP (?)       ;Used by format/verify proc
ERROR           DB      1 DUP (?)       ;Set if bad tracks detected

HEAD            DB      1 DUP (?)       ;Used by BIOS_WRITE
TRACK           DB      1 DUP (?)       ;Used by BIOS_WRITE
SECT            DB      1 DUP (?)       ;Used by BIOS_WRITE
NSECT           DB      1 DUP (?)       ;Used by BIOS_WRITE

USEG            ENDS

;======================================================================
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT BYTE    PUBLIC  'CODE'
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

;======================================================================
; FormatDiskette (FAR, QuickPak)
;   Copyright (c) 1992 Crescent Software
;   Copyright (c) 1992 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; This procedure formats a floppy diskette to the specified capacity.
;
; 1. Only the standard DOS capacities are supported.
; 2. Bad sectors are marked off.
;----------------------------------------------------------------------
; Usage:
;       Result% = FormatDiskette%(DrvNum%, Capacity%, SEG BufArray%)
;
; where:
;       DriveNumber% = physical drive number.
;               0 = 1st physical diskette
;               1 = 2nd physical diskette
;               2 = 3rd physical diskette
;                   etc.
;
;       Capacity% =  360, for  360K 5.25"
;                   1200, for  1.2M 5.25"
;                    720, for  720K 3.5"
;                   1440, for 1.44M 3.5"
;
;       BufArray% = Integer array work area (size in bytes)
;                 ( 9*4)+(2*512)=1060, for  360K 5.25"
;                 (15*4)+(7*512)=3644, for  1.2M 5.25"
;                 ( 9*4)+(3*512)=1572, for  720K 3.5"
;                 (18*4)+(9*512)=4680, for 1.44M 3.5"
;
;       Result% = 0, diskette formatted successfully
;               > 0, see error table
;----------------------------------------------------------------------
; Changes: AX BX CX DX ES
;----------------------------------------------------------------------
pDRVNUM%        EQU     BP+0CH                  ;Passed parameters
pCAP%           EQU     BP+0AH
dBUF%           EQU     BP+6

FormatDiskette  PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BP                      ;Create stack frame
                MOV     BP,SP

                PUSH    SI                      ;Preserve for caller
                PUSH    DI
;----------------------------------------------------------------------
; Initialize variables.
;----------------------------------------------------------------------
                CLD                             ;String moves forward
                SUB     AL,AL
                MOV     [ERROR],AL
;----------------------------------------------------------------------
; First determine the type of the drive by calling another function.
; On return, AX contains result:
; 0, Drive not present or cannot identify
; 1, 360K 5.25" 40 track
; 2, 1.2M 5.25" 80 track
; 3, 720K 3.5"  80 track
; 4, 1.4M 3.5"  80 track
;----------------------------------------------------------------------
                MOV     BX,[pDRVNUM%]           ;Pointer to drive #
                MOV     AX,[BX]
                MOV     [DRIVENUM],AL           ;Save it

                PUSH    BX                      ;Push argument
                CALL    GetDisketteType         ;Return in AX

            ASSUME ES: NOTHING
                OR      AX,AX                   ;AX <> 0 = error
                JNZ     FD_1

                MOV     AL,ERR$INV_DRV
                JMP     FD_EXIT
FD_1:
                MOV     [DRIVETYPE],AL          ;Save drive type
;----------------------------------------------------------------------
; The requested capacity must be supported by this drive.
; AL contains DRIVETYPE from preceeding call.
;----------------------------------------------------------------------
                MOV     BX,[pCAP%]              ;Get pointer
                MOV     BX,[BX]                 ;Capacity% code

                CMP     AL,DRIVE_1200           ;type >2 if 3.5" drive
                JA      FD_2C
                JB      FD_2A                   ;type <2 if 360K

                MOV     SI,OFFSET DGROUP:MEDIA_1200     ;Media = 1.2M
                CMP     BX,1200                 ;1.2M in 1.2M?
                JE      FD_2E
FD_2A:
                MOV     SI,OFFSET DGROUP:MEDIA_360      ;Media = 360K
                CMP     BX,360                  ;360K in either
                JE      FD_2E
;----------------------------------------------------------------------
; Error: Drive and capacity do not match.
;----------------------------------------------------------------------
FD_2B:
                MOV     AL,ERR$INV_CAP
                JMP     FD_EXIT
;----------------------------------------------------------------------
; Test for 3.5" drives.
;----------------------------------------------------------------------
FD_2C:
                CMP     AL,DRIVE_720
                JE      FD_2D

                MOV     SI,OFFSET DGROUP:MEDIA_1440     ;Media = 1.44M
                CMP     BX,1440                 ;1.44M in 1.44M?
                JE      FD_2E
FD_2D:
                MOV     SI,OFFSET DGROUP:MEDIA_720      ;Media = 720K
                CMP     BX,720                  ;720k in either
                JNE     FD_2B
;----------------------------------------------------------------------
; Drive type and requested capacity match. Save the pointer to the
; correct media info.
;----------------------------------------------------------------------
FD_2E:
                MOV     [MEDIAPTR],SI           ;Save pointer
;----------------------------------------------------------------------
; Save the current disk base, then alter the parameters required for
; this format.
;----------------------------------------------------------------------
                SUB     DX,DX                   ;Create 0
                MOV     ES,DX                   ;Address low memory
        ASSUME  ES:LOMEM

                LES     DI,ES:[DISK_BASE]       ;Point ES:DI to base
        ASSUME  ES:NOTHING

                MOV     BH,[SI]                 ;Format gap length
                MOV     BL,[SI+27]              ;Sectors per track

                XCHG    BH,ES:[DI+7]            ;Change req'd values
                XCHG    BL,ES:[DI+4]

                MOV     [SAVE_BASE],BX          ;Save old values
;----------------------------------------------------------------------
; Reset the diskette system.
; Note that AH=0, AL=DRIVENUM, and DX=0.
;----------------------------------------------------------------------
                XCHG    AX,DX                   ;Reset the diskette
                INT     13H                     ; thru BIOS
;----------------------------------------------------------------------
; Attempt to set the correct media/drive combination. A failure here
; aborts the entire format.
;----------------------------------------------------------------------
                CALL    SET_MEDIA
                JC      FD_2G
;----------------------------------------------------------------------
; Initialize the work buffer. Calculate the start of the track buffer.
;----------------------------------------------------------------------
                LES     DI,DWORD PTR [dBUF%]    ;Far ptr to buffer
        ASSUME  ES:NOTHING

                MOV     AX,[SI+14]              ;Bytes/sector
                MUL     WORD PTR [SI+25]        ;Sectors/FAT
                MOV     CX,AX                   ;Bytes to init
                SUB     AL,AL                   ;Store zeros
                REP     STOSB

                MOV     [TBUFPTR],DI            ;Save track buffer adr
;----------------------------------------------------------------------
; A floppy is layed out such that track 0 contains all the critical
; structures for the diskette. If it cannot be formatted successfully,
; the entire format is aborted.
;----------------------------------------------------------------------
                MOV     DL,[DRIVENUM]           ;Drive
                SUB     CH,CH                   ;Track
                SUB     DH,DH                   ;Head 0
                MOV     AL,[SI+27]              ;Sec/track
                MOV     AH,RETRY0               ;Retries

                MOV     BX,[TBUFPTR]            ;Relative to ES

                CALL    FORMAT_TRACK            ;Track 0, Head 0
                JC      FD_2F

                CALL    VERIFY_TRACK
                JC      FD_2F

                INC     DH                      ;Track 0, Head 1
                CALL    FORMAT_TRACK
                JC      FD_2F

                CALL    VERIFY_TRACK
                JNC     FD_2H
FD_2F:
		CMP     AL,3                    ;Write-protect error?
		JE      FD_2G                   ;Yes, error code is correct
		CMP     AL,80H                  ;Or maybe the door's open?
		JE      FD_2G                   ;Leave that code intact too
		MOV     AL,ERR$TRK_0_BAD        ;No, must be a bad track 0
FD_2G:
                JMP     FD_EXIT
FD_2H:
;----------------------------------------------------------------------
; Format a full track of this disk. Partial formats of tracks aren't
; supported (the same as DOS's format). Use fewer retries since the
; disk should already be spinning and warmed up.
;----------------------------------------------------------------------
                DEC     DH                      ;Head 0
                INC     CH                      ;Track 1

                MOV     BX,[TBUFPTR]            ;Track buffer
FD_7A:
                MOV     AH,RETRY                ;Retries
                MOV     AL,[SI+27]              ;Sector per track

                CALL    FORMAT_TRACK            ;May change AX
                JC      FD_7B

                CALL    VERIFY_TRACK            ;May change AX
                JNC     FD_7C
;----------------------------------------------------------------------
; If the verify operation fails, mark the entire track bad. Although
; the track could be checked sector by sector, DOS doesn't do it and
; most people just throw away a diskette with any bad sectors.
;----------------------------------------------------------------------
FD_7B:
                CALL    MARK_TRACK_BAD          ;Can't fail
;----------------------------------------------------------------------
; Advance to the next head. If HEAD=1, repeat the loop with the same
; value for the track. Otherwise, bump the track counter as well.
;----------------------------------------------------------------------
FD_7C:
                XOR     DH,1                    ;Toggle head 0/1
                JNZ     FD_7A                   ;If head 1, rpt track

                INC     CH                      ;Next track
                CMP     CH,[SI+1]               ;Compare # tracks
                JB      FD_7A                   ;Below since 0-based
;----------------------------------------------------------------------
; Physical format is complete. Perform the logical format to make this
; a DOS disk. The FATs are written first since the buffer area is
; required to build the other information areas.
;----------------------------------------------------------------------
                MOV     BX,WORD PTR [dBUF%]     ;Ptr to buffer
                MOV     AL,[SI+24]              ;Format ID
                MOV     ES:[BX],AL
                MOV     WORD PTR ES:[BX+1],0FFFFH ; in first entries

                MOV     AL,[SI+25]              ;Sectors per FAT
                MOV     CX,0002H                ;Track 0, Sector 2
                SUB     DH,DH                   ;Head 0
                MOV     DL,[DRIVENUM]           ;Drive number
                CALL    BIOS_WRITE              ;1st copy
                JC      FD_EXIT

                MOV     AL,[SI+25]              ;Sectors per FAT
                CALL    BIOS_WRITE              ;2nd copy
                JC      FD_EXIT
;----------------------------------------------------------------------
; Zero out one sector of the buffer.  Write the root directory one
; sector at a time right after the FATs.
;----------------------------------------------------------------------
                PUSH    CX                      ;preserve track/sect
                MOV     CX,[SI+14]              ;bytes per sector
                SHR     CX,1                    ; to words
                MOV     DI,BX                   ;start of buffer
                SUB     AX,AX                   ;write zeros
                REP     STOSW                   ;clear buffer

                POP     DI                      ;hold track/sect

                SUB     CH,CH
                MOV     CL,[SI+2]               ;CX = # root sectors
FD_8:
                XCHG    CX,DI                   ;CX = track/sect for write
                MOV     AL,1                    ;write one sector
                CALL    BIOS_WRITE              ;write to disk
                JC      FD_EXIT

                XCHG    CX,DI                    ;CX = count for loop

                LOOP    FD_8

;----------------------------------------------------------------------
; Construct the boot record and write it to the first sector.
;----------------------------------------------------------------------
                PUSH    SI
                MOV     DI,BX                           ;ES:DI = dest
                MOV     WORD PTR ES:[DI+1FEh],0AA55H    ;Boot signature

                ADD     SI,3                    ;Point to prefix
                MOV     CX,32/2                 ;Number of words
                REP     MOVSW

                LEA     DI,[BX+30H]             ;Destination
                MOV     SI,OFFSET DGROUP:BOOTCODE
                MOV     CX,BOOTCODELEN
                REP     MOVSB

                MOV     AL,1                    ;Write 1 sector
                MOV     CX,0001H                ;Track 0, Sector 1
                SUB     DH,DH                   ;Head 0
                MOV     DL,[DRIVENUM]           ;Drive number
                POP     SI
                CALL    BIOS_WRITE
                JC      FD_EXIT
;----------------------------------------------------------------------
; Format is done. Other operations, such as labeling the disk, can be
; done at the DOS level.
;----------------------------------------------------------------------
                MOV     AL,[ERROR]              ;Retrieve any error
FD_EXIT:
                SUB     AH,AH                   ;AH = 0
;----------------------------------------------------------------------
; Restore the disk base.
;----------------------------------------------------------------------
                SUB     DX,DX                   ;Create 0
                MOV     ES,DX                   ;Address low memory
        ASSUME  ES:LOMEM

                LES     DI,ES:[DISK_BASE]       ;ES:DI -> base
        ASSUME  ES:NOTHING

                MOV     BX,[SAVE_BASE]          ;Retrieve old values
                MOV     ES:[DI+7],BH            ;Restore old base
                MOV     ES:[DI+4],BL
;----------------------------------------------------------------------
; Exit to caller.
;----------------------------------------------------------------------
                POP     DI                      ;Restore registers
                POP     SI

                POP     BP                      ;Destroy stack frame
                RET     4*2                     ;Discard arguments

FormatDiskette  ENDP

;======================================================================
; BIOS_WRITE (Near, Internal)
;
; This proc automatically increments sectors, heads, and tracks and
; performs as many writes as required to output the total number of
; sectors specified.
;----------------------------------------------------------------------
; Entry:
;       AL = total sectors to write
;       CL = starting sector
;       CH = track
;       DL = physical driver number
;       DH = head
;       DS:SI -> media table
;       ES:BX -> workspace for track buffer
; Exit:
;       CY = FAIL
;       AL = error code
;       CX = ?
;       DX = ?
;
;       NC = SUCCESS
;       * = coordinates of first sector after write
;       CL = starting sector *
;       CH = track *
;       DL = physical drive number *
;       DH = head *
;----------------------------------------------------------------------
; Changes: AX CX DX
;----------------------------------------------------------------------
BIOS_WRITE      PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BX
                PUSH    DI
;----------------------------------------------------------------------
; Save the current T:H:S coordinates.
;----------------------------------------------------------------------
                MOV     [NSECT],AL              ;Save total sectors
                MOV     [SECT],CL               ;Current sector
                MOV     [HEAD],DH               ;Head
                MOV     [TRACK],CH              ;Track
;----------------------------------------------------------------------
; Determine how many sectors can be written without having to change
; heads or tracks. Write the smaller of requested sectors or that
; number.
;----------------------------------------------------------------------
BW_1A:
                MOV     AH,[SI+27]              ;Sectors per track
                XCHG    AH,AL
                SUB     AL,CL
                INC     AL                      ;Sectors left this track
                CMP     AH,AL                   ;CMP want to have
                JA      BW_1B

                MOV     AL,AH                   ;Write AL sectors
BW_1B:
;----------------------------------------------------------------------
; This section calculates what the coordinates of the next free sector
; will be AFTER the write is completed.
;
; TEMP = SECT+NSEC+1
; WHILE ( TEMP > MAXSECTOR) DO
;   SECT = SECT - MAXSECTOR
;   HEAD = HEAD + 1
;   IF HEAD > 1 THEN
;     HEAD = 0
;     TRACK = TRACK + 1
;   ENDIF
; ENDWHILE
;----------------------------------------------------------------------
                SUB     [NSECT],AL              ;Subtract # written
                ADD     CL,AL                   ; last used sector
BW_2A:
                CMP     CL,[SI+27]              ;CMP sect to max
                JBE     BW_2B

                SUB     CL,[SI+27]              ;Subtract sec per track
                XOR     DH,1                    ;Move to next head
                JNZ     BW_2A

                INC     CH                      ;Next track
                JMP     BW_2A
BW_2B:
                XCHG    [SECT],CL               ;Current sector
                XCHG    [HEAD],DH               ;Head
                XCHG    [TRACK],CH              ;Track
;----------------------------------------------------------------------
; Write the indicated number of sectors.
; Advance the buffer pointer.
;----------------------------------------------------------------------
                MOV     DI,AX                   ;Save sectors to write

                MOV     AH,3                    ;Write sectors
                INT     13H
           
                MOV     AL,AH                   ;Pos. error in AL
                JC      BW_EXIT

                PUSH    DX                      ;Save over mult

                MOV     AX,DI
                SUB     AH,AH                   ;AH=0
                MUL     WORD PTR [SI+14]        ;Bytes per sector
                ADD     BX,AX                   ;Advance buffer pointer

                POP     DX
;----------------------------------------------------------------------
; Update the registers from the pointers.
;----------------------------------------------------------------------
                MOV     CL,[SECT]               ;Current sector
                MOV     DH,[HEAD]               ;Head
                MOV     CH,[TRACK]              ;Track
;----------------------------------------------------------------------
; Continue if more sectors need to be written.
;----------------------------------------------------------------------
                MOV     AL,[NSECT]
                OR      AL,AL                   ;0 = no more to write
                JNZ     BW_1A

                CLC                             ;Signal success
;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
BW_EXIT:
                POP     DI                      ;Restore registers
                POP     BX
                RET

BIOS_WRITE      ENDP

;======================================================================
; FORMAT_TRACK (Near, Internal)
;----------------------------------------------------------------------
; Entry:
;       AH = times to retry if error
;       AL = sectors per track
;       CH = track
;       DL = physical driver number
;       DH = head
;       DS:SI -> media table
;       ES:BX -> workspace for track buffer
; Exit:
;       CF = NC, success
;
;       CF = CY, failure
;       AL = error code
;----------------------------------------------------------------------
; Changes: AX CX
;----------------------------------------------------------------------
FORMAT_TRACK    PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                MOV     BYTE PTR [FUNCTION],5
                JMP     SHORT FT_0

;======================================================================
; VERIFY_TRACK
;----------------------------------------------------------------------
; Except for the function number, this procedure is identical to the
; FORMAT_TRACK procedure.
;----------------------------------------------------------------------
; Changes: AX CX
;----------------------------------------------------------------------
VERIFY_TRACK    PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                MOV     BYTE PTR [FUNCTION],4   ;Verify function
FT_0:
;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
                PUSH    BP                      ;Save registers
                PUSH    DI
                PUSH    AX

                MOV     CL,1                    ;Starting sector
;----------------------------------------------------------------------
; Build the track buffer for this track. (CHRN)
; Leave ES:BX pointing to the beginning of the buffer.
;----------------------------------------------------------------------
                PUSH    AX                      ;Save passed info
                PUSH    CX
                PUSH    DX
                                                ;DH = head
                MOV     DL,CH                   ;Put track in DL

                SUB     CH,CH                   ;CH = 0
                MOV     CL,AL                   ;Number of sectors

                MOV     DI,CX                   ;Point DI 2 bytes
                SHL     DI,1                    ; less than length
                DEC     DI                      ; of finished buffer
                SHL     DI,1
                ADD     DI,BX                   ;Point to end of buf

                STD                             ;String moves reversed

                MOV     AL,CL                   ;Sector number
                MOV     AH,2                    ;Bytes/sector code=512
FT_1:
                STOSW                           ;Write sector/code

                DEC     AL                      ;Dec sector number
                XCHG    AX,DX

                STOSW                           ;Write track/head

                XCHG    AX,DX
                LOOP    FT_1                    ;Build entire track

                CLD                             ;String moves forward

                POP     DX                      ;Restore values
                POP     CX
                POP     AX
;----------------------------------------------------------------------
; Format the track.
;----------------------------------------------------------------------
FT_2A:
                MOV     DI,AX                   ;Save retries

                MOV     AH,[FUNCTION]           ;Format or verify
                INT     13H                     ; thru BIOS
                JC      FT_2B                   ;NC = success
;----------------------------------------------------------------------
; Exit the routine succesfully.
;----------------------------------------------------------------------
                POP     AX                      ;Restore AX
FT_EXIT:
                POP     DI                      ;Restore registers
                POP     BP
                RET
;----------------------------------------------------------------------
; FUNCTION was unsuccessful. Retry, then fail.
;----------------------------------------------------------------------
FT_2B:
                MOV     BP,AX                   ;Save error code (AH)

                SUB     AH,AH                   ;Reset diskette system
                INT     13H                     ; thru BIOS

                CALL    SET_MEDIA               ;Set media type again
                JC      FT_ERR

                MOV     AX,DI                   ;Get back retries
                DEC     AH                      ;Dec them
                JNZ     FT_2A                   ;NZ = try again
;----------------------------------------------------------------------
; Exit as a failure.
;----------------------------------------------------------------------
                MOV     AX,BP                   ;Retrieve error code
FT_ERR:
                MOV     AL,AH                   ;Error code in AL
                STC
                POP     DI                      ;Discard old AX
                JMP     FT_EXIT

VERIFY_TRACK    ENDP
FORMAT_TRACK    ENDP

;======================================================================
; MARK_TRACK_BAD (Near, Internal)
;
; Given the C (CH), H (DH), and R (always 1) coordinates of the first
; sector to mark bad, mark AL contiguous sectors bad in the FAT.
;
; Note the following:
; BIOS sector numbers are 1-based
; LSNs (logical sector numbers) are 0-based
; CNs (cluster numbers) are 0-based
;----------------------------------------------------------------------
; Entry:
;       CH = track
;       DL = physical driver number
;       DH = head
;       DS:SI -> media table
;       ES:BX -> workspace for track buffer
;       SS:BP -> stack frame
;
; Exit: None
;----------------------------------------------------------------------
; Changes: None
;----------------------------------------------------------------------
MARK_TRACK_BAD  PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    AX                      ;Save used registers
                PUSH    BX
                PUSH    CX
                PUSH    DX
                PUSH    DI
                PUSH    ES
;----------------------------------------------------------------------
; Set the return code for bad sectors.
;----------------------------------------------------------------------
                MOV     BYTE PTR [ERROR],ERR$BAD_SECT
;----------------------------------------------------------------------
; Translate CHR coordinates to a 0-based logical sector number.
; LSN = SPC*(NH*C+H)+S-1
; where
;       LSN = logical sector number (0-based)
;       SPC = sectors per cluster
;       NH = number of heads (always =2)
;       C = track (0-based)
;       H = head (0-based)
;       S = BIOS sector number (1-based) (always =1)
;----------------------------------------------------------------------
                SUB     CL,CL                   ;CL = 0
                XCHG    CH,CL                   ;CX = Track #
                SHL     CX,1                    ;*2 sides
                ADD     CL,DH                   ;Acct for odd head
                SUB     AH,AH                   ;AX = sect per track
                MOV     AL,[SI+27]              ;Sect per track
                MUL     CX                      ;LSN in DX:AX
                MOV     CX,AX                   ;Save LSN of 1st bad
;----------------------------------------------------------------------
; Determine the LSN of the first data sector.
; FDS = NF*SPF + RDS + RS
;----------------------------------------------------------------------
                MOV     AX,[SI+25]              ;Sectors per FAT
                MUL     BYTE PTR [SI+19]        ;* copies of FAT

                ADD     AX,[SI+17]              ;+ reserved sectors
                ADD     AL,[SI+2]               ;+ root dir sectors
;----------------------------------------------------------------------
; Subtract the LSN of the first data sector from our target LSN.
; This gives the sector number offset from the first data sector.
;----------------------------------------------------------------------
                NEG     AX                      ;Make negative
                ADD     AX,CX                   ;Subtract from LSN
;----------------------------------------------------------------------
; Convert DSN to a 0-based cluster number (CN).
;----------------------------------------------------------------------
                SUB     BH,BH
                MOV     BL,[SI+16]              ;sect per cluster
                DIV     BX
;----------------------------------------------------------------------
; The first data sector corresponds to cluster number 2.
; Bias the resulting CN by 2. This is the starting cluster number.
;----------------------------------------------------------------------
                ADD     AX,2                    ;Bias cluster #
                MOV     DX,AX                   ;Starting cluster #
;----------------------------------------------------------------------
; Determine how many clusters (NC) we need to mark as bad.
;----------------------------------------------------------------------
                SUB     AH,AH                   ;AH = 0
                MOV     AL,[SI+27]              ;Sect per track
                INC     AX                      ;Round up
                DIV     BYTE PTR [SI+16]        ;AL=AX/sect per cluster
                SUB     CH,CH
                MOV     CL,AL                   ;CX = # bad clusters
;----------------------------------------------------------------------
; Point ES:DI to FAT.
;----------------------------------------------------------------------
                LES     DI,DWORD PTR [dBUF%]    ;Far ptr to buffer
        ASSUME  ES:NOTHING
;----------------------------------------------------------------------
; Beginning with the first CN (in DX), mark NC (in CL) clusters bad.
;----------------------------------------------------------------------
MTB_1A:
                MOV     BX,DX                   ;Cluster number
                SHL     BX,1                    ;* 2...
                ADD     BX,DX                   ;-> *3
                SHR     BX,1                    ;\ 2 -> offset

                TEST    DL,1                    ;Even or odd?
                JNZ     MTB_1B

                OR      WORD PTR ES:[DI][BX],0FF7H ;Even entry
                JMP     SHORT MTB_1C
MTB_1B:
                OR      WORD PTR ES:[DI][BX],0FF70H ;Odd entry
MTB_1C:
                INC     DX                      ;Next cluster number
                LOOP    MTB_1A
;----------------------------------------------------------------------
; Return to caller.
;----------------------------------------------------------------------
                POP     ES                      ;Restore registers
        ASSUME  ES:NOTHING

                POP     DI
                POP     DX
                POP     CX
                POP     BX
                POP     AX

                RET

MARK_TRACK_BAD  ENDP

;======================================================================
; SET_MEDIA (Near, Internal)
;----------------------------------------------------------------------
; Entry:
;       DS:SI -> media table
; Exit :
;       CF = NC, success
;
;       CF = CY, failure
;       AL = error code
;----------------------------------------------------------------------
; Changes: AX
;----------------------------------------------------------------------
SET_MEDIA       PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BX                      ;Save used registers
                PUSH    CX
                PUSH    DX
                PUSH    DI
                PUSH    ES
                PUSH    AX                      ;May get discarded
;----------------------------------------------------------------------
; Attempt to set the correct media/drive combination using function 18h.
; This function is supported on late model XTs, ATs, and all PS/2.
; The function returns ES:DI pointing to a disk_base for the specified
; media, but we ignore it.
;----------------------------------------------------------------------
                MOV     AH,18H
                MOV     DL,[DRIVENUM]
                MOV     CH,[SI+1]               ;Number of tracks
                DEC     CH                      ;0-based
                MOV     CL,[SI+27]              ;Sectors per track
                INT     13H
        ASSUME  ES:NOTHING
                JNC     SM_EXIT
;----------------------------------------------------------------------
; If supported, but still failed, bomb out with error code.
;----------------------------------------------------------------------
                MOV     AL,AH                   ;Error code in AL
                CMP     AL,1                    ;1 = invalid command
                JNE     SM_ERR
;----------------------------------------------------------------------
; If Set Media failed because it wasn't supported, we can't format a
; 1.44M diskette.
;----------------------------------------------------------------------
                MOV     AL,ERR$INV_CAP
                CMP     SI,OFFSET DGROUP:MEDIA_1440
                JE      SM_ERR
;----------------------------------------------------------------------
; Use function 17h, Set DASD (Direct Access Storage Device) type.
; AL = 1, 360K in 360K
;      2, 360K in 1.2M
;      3, 1.2M in 1.2M
;      4, 720K in 720K (if supported)
;----------------------------------------------------------------------
                MOV     AH,17H                  ;Set DASD type
                MOV     DL,[DRIVENUM]
                MOV     AL,[DRIVETYPE]

                CMP     AL,3                    ;Change type 3 to 4
                JE      SM_4A

                CMP     AL,2                    ;Change 2 to 3 if...
                JNE     SM_4B

                CMP     SI,OFFSET DGROUP:MEDIA_1200     ;...Cap = 1.2M
                JNE     SM_4B
SM_4A:
                INC     AL                      ;Adjust argument
SM_4B:
                INT     13H                     ; thru BIOS
                JNC     SM_EXIT
;----------------------------------------------------------------------
; If supported, but still failed, bomb out with error code.
;----------------------------------------------------------------------
                MOV     AL,AH                   ;Error code in AL
                CMP     AL,1                    ;1 = invalid command
                JNE     SM_ERR
;----------------------------------------------------------------------
; If Set DASD failed because it wasn't supported, we can't format a
; 720k or 1.2M diskette (if that's what was requested).
;----------------------------------------------------------------------
                MOV     AL,ERR$INV_CAP          ;Assume error
                CMP     SI,OFFSET DGROUP:MEDIA_360
                JE      SM_EXIT
SM_ERR:
                STC                             ;CF = 1
                POP     BX                      ;Discard AX
                JMP     SHORT SM_5
SM_EXIT:
                CLC
                POP     AX                      ;Keep AX
SM_5:
                POP     ES                      ;Restore registers
        ASSUME  ES:NOTHING
                POP     DI
                POP     DX
                POP     CX
                POP     BX

                RET

SET_MEDIA       ENDP

CSEG            ENDS
                END

;======================================================================
; Media information.
; 1. Despite what you read in some books, BIOS sectors are 1-based;
;    head, track, logical sector, and FAT coordinates are 0-based.
; 2. ALL boot, FAT, and root directory sectors are located on track 0.
;----------------------------------------------------------------------
; BIOS INFORMATION              360K    1.2M    720K    1.44M
;----------------------------------------------------------------------
; Max head # (0-based)          1       1       1       1
;
; Max track # (0-based)         39      79      79      79
;                               (27h)   (4Fh)   (4Fh)   (4Fh)
;
; Sectors per track             9       15      9       18
;                               (9h)    (Fh)    (9h)    (12h)
;
; Total # sectors               720     2400    1440    2880
;----------------------------------------------------------------------
; DOS INFORMATION               360K    1.2M    720K    1.44M
;----------------------------------------------------------------------
; Media (format) ID             FDh     F9h     F9h     F0h
;
; # Boot sectors                1       1       1       1
;
; # Sectors per FAT             2       7       3       9
; # copies of FAT               2       2       2       2
; FAT type (bits)               12      12      12      12
;
; # Sectors in root directory   7       14      7       14
; # Root directory entries      112     224     112     224
;
; # Sectors per cluster         2       1       2       1
;
; # Number of clusters          354     2371    713     2847
;                               (162h)  (943h)  (2C9h)  (81Fh)
;----------------------------------------------------------------------

