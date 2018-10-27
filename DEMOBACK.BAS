'********** DEMOBACK.BAS - demonstrates the CW Shop backup subprogram

'Written by Phil Weber
'Copyright (c) 1992 Crescent Software, Inc.

'Compile and link as follows:
'
'  bc demoback /o;
'  bc backup /o /ah;
'  link demoback backup , , nul, cwshop ;

    
DEFINT A-Z
DECLARE SUB CWBackup (FileSpec$, Dest$, Recurse, ErrCode)
DECLARE SUB CWReleaseMem (Mode)
DECLARE FUNCTION MidChar% (A$, Ptr)

'$INCLUDE: 'ERRCODES.BI'                    'Create error msg arrays

Cmd$ = COMMAND$                             'Get command line
CmdLen = LEN(Cmd$)                          'Save its length

IF CmdLen = 0 THEN                          'If no params...
   PRINT "Enter the source file specification: ";
   LINE INPUT FileSpec$                     'Prompt for FileSpec$
ELSE
   Delim = INSTR(Cmd$, " ")                 'Find first space
   IF Delim = 0 THEN Delim = CmdLen + 1     'If none, use entire string
   FileSpec$ = LEFT$(Cmd$, Delim - 1)
END IF

IF CmdLen <= Delim THEN
   PRINT "Enter the destination drive letter: ";
   LINE INPUT Dest$                         'Prompt for Dest$
ELSE
   Start = Delim
   DO: Start = Start + 1
   LOOP UNTIL MidChar%(Cmd$, Start) <> 32   'Find next word
   Delim = INSTR(Start, Cmd$, " ")          'Find next space
   IF Delim = 0 THEN Delim = CmdLen + 1
   Dest$ = MID$(Cmd$, Start, Delim - Start)
END IF

IF CmdLen = 0 THEN                          'Prompt for Recurse
   PRINT "Do you wish to include subdirectories? (y/n) ";
   LINE INPUT Temp$: Temp$ = UCASE$(Temp$)
   IF MidChar%(Temp$, 1) = 89 THEN Recurse = -1
ELSEIF INSTR(MID$(Cmd$, Delim), "/S") THEN
   Recurse = -1
END IF

ErrCode = 20                 'Allow user 20 seconds to change disk
CALL CWBackup(FileSpec$, Dest$, Recurse, ErrCode)
CALL CWReleaseMem(1)

SELECT CASE ErrCode
  CASE 0
    PRINT "Backup successful!"
  CASE 255
    PRINT "Backup aborted by user."
  CASE ELSE
    PRINT CWMsg$(ErrCode)
END SELECT
END

