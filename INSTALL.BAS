'********** INSTALL.BAS - compression workshop install utility

'Copyright (c) 1992 Ethan Winer

'Note: If you run this program in the QB editor the QuickPak ExeName function
'will return the directory that QB.EXE was run from, which is not necessarily
'the current directory.  So you may have to enter a directory name where your
'various .CWF files reside for INSTALL to find them.
'
'To recompile this program you will need QuickPak Professional (version 4.0
'or later) and optionally P.D.Q.  If you are using P.D.Q. you can compile and
'link this program for the smallest size possible as follows:
'
'   bc install /o/s;
'   link /nod/noe/packc/far _
'     install _noread _noval _noerror , , nul , cwshop pro [basic7] pdq;
'   exe2com install
'   del install.exe
'   ren install.com install.exe
'
'The INSTALL.EXE program supplied with the Compression Workshop was created
'using the five steps shown above.


DEFINT A-Z

'---- Compression Workshop assembly language functions and subroutines
DECLARE FUNCTION CWCritErr% ()

DECLARE SUB CWGetComment (FileName$, Comment$, ErrCode)
DECLARE SUB CWReleaseMem (Mode)
DECLARE SUB CWUnpackFiles (FileName$, DSpec$, ErrCode)


'---- QuickPak assembly language functions and subroutines
DECLARE FUNCTION DOSVer% ()
DECLARE FUNCTION ExeName$ ()
DECLARE FUNCTION FCount% (FileSpec$)
DECLARE FUNCTION GetDir$ (Drive$)
DECLARE FUNCTION GetDrive% ()
DECLARE FUNCTION MidChar% (Work$, Position)
DECLARE FUNCTION QPValI% (Work$)
DECLARE FUNCTION WhichError% ()

DECLARE SUB Box0 (ULRow, ULCol, LRRow, LRCol, Style, Colr)
DECLARE SUB CDir (NewDir$)
DECLARE SUB Editor (Work$, ActLength, ScanCode, NumOnly, CapsOn, NormColor, HiColor, Row, Column)
DECLARE SUB MakeDir (NewDir$)
DECLARE SUB MidCharS (Work$, BYVAL Position, BYVAL NewChar)
DECLARE SUB QPrint0 (Work$, Colr)
DECLARE SUB ReadFile (BYVAL Address)
DECLARE SUB SetDrive (Drive$)
DECLARE SUB StuffBuf (Work$)


'---- BASIC procedures in this program file
DECLARE FUNCTION SourceDir$ ()

DECLARE SUB DrawScreen ()
DECLARE SUB EndIt ()
DECLARE SUB SelectFiles (FileNames$(), Choice, ExitCode)


'---- Define some constants and variables, and colors based on display type.
'
'$INCLUDE: 'ERRCODES.BI'                'defines the text of error messages

CONST MaxCWFiles% = 19                  'max. number of .CWF files per disk
One = 1                                 'saves four bytes per use in a CALL
Zero$ = CHR$(0)                         'call CHR$() just once here

Bar$ = "ฬ" + STRING$(78, 205) + "น"     'for the main screen separating bars
Blank$ = SPACE$(12)                     'to pad arrays when calling ReadFile
PadComment$ = SPACE$(36)                'for displaying the comment strings
PadDir$ = SPACE$(25)                    'for displaying the dest. directories
Msg$ = SPACE$(79)                       'for messages on the bottom line
IF INSTR(UCASE$(COMMAND$), "/B") THEN MonoFlag = -1   '/b forces mono colors

FG = 10: BG = 1                         'assume colors for a color display
NormColor = 123: HiColor = 75           'AMenu and default directory colors
MainColor = 26                          'main screen and box color
DEF SEG = 0                             'see if it's really a color display
IF (PEEK(&H463) = &HB4) OR MonoFlag THEN  'no, it's monochrome or /b was used
  FG = 0: BG = 7: NormColor = 7: HiColor = 112: MainColor = 112
END IF


'---- Get the directory INSTALL was run from or prompt for it if needed, to
'     ensure that there's at least one .CWF file present to install.
'
InstPath$ = SourceDir$
DO
  IF RIGHT$(InstPath$, 1) <> "\" THEN InstPath$ = InstPath$ + "\"
  InstSpec$ = InstPath$ + "*.CWF"
  NumCWFiles = FCount%(InstSpec$)
  IF NumCWFiles THEN EXIT DO
  PRINT "No .CWF files were found."
  INPUT "Enter the source directory or press Enter to end: ", InstPath$
  IF LEN(InstPath$) = 0 THEN END
LOOP
     
IF MidChar%(InstPath$, 2) <> 58 THEN    'if there's no drive letter (:)
  InstPath$ = CHR$(GetDrive%) + ":" + InstPath$ 'append the current drive
END IF


'---- See if they're installing more than one disk, and if so how many.
'
NumDisks = 1                                'assume only one disk for now
NumDisksFile$ = InstPath$ + "NUMDISKS.*"    'concatenate these just once

IF FCount%(NumDisksFile$) THEN
  DIM NumDisks$(0 TO 1)
  NumDisks$(0) = NumDisksFile$
  NumDisks$(1) = Blank$
  CALL ReadFile(BYVAL VARPTR(NumDisks$(0)))
  Dot = INSTR(NumDisks$(1), ".")
  NumDisks = QPValI%(MID$(NumDisks$(1), Dot + 1))
END IF


'---- See if there's a DEFAULT.DIR file in the root directory of the first
'     distribution disk, and if so read its contents.  Since we're already
'     using FCount it can serve as an Exist function without needing Exist.
'     If there's no DEFAULT.DIR file, default to current drive and directory.
'     And if the current drive is A: or B:, replace that with C:.
'
SaveDir$ = CHR$(GetDrive%) + ":" + GetDir$("")  'save this while we have it
DefaultDir$ = SaveDir$                          'then assign it as default

Temp$ = LEFT$(DefaultDir$, 2)                   'avoid using LEFT$() twice
IF Temp$ = "A:" OR Temp$ = "B:" THEN            'don't default to A: or B:
  CALL MidCharS(DefaultDir$, 1, 67)             'if A: or B:, substitute C:
END IF

DefaultDirFile$ = InstPath$ + "DEFAULT.DIR"     'concatenate these just once

IF FCount%(DefaultDirFile$) THEN                'open the file if it exists
  OPEN DefaultDirFile$ FOR INPUT AS #1
  INPUT #1, DefaultDir$
  CLOSE #1
  DefaultDir$ = UCASE$(DefaultDir$)
END IF


'---- See if there's a PROGRAM.RUN file in the root directory of the first
'     distribution disk, and if so read its contents.
'
RunFileName$ = InstPath$ + "PROGRAM.RUN"        'concatenate these just once
IF FCount%(RunFileName$) THEN                   'open the file if it exists
  OPEN RunFileName$ FOR INPUT AS #1
  INPUT #1, RunName$
  CLOSE #1
  RunName$ = RunName$ + CHR$(13)                'simulate pressing Enter
  IF LEN(RunName$) > 15 THEN RunName$ = ""      'don't use name if too long
END IF


'---- This is the main installation loop that cycles through each diskette.
'
FOR ThisDisk = 1 TO NumDisks

  '---- See how many .CWF files there are on the current disk, and limit the
  '     number we'll handle to MaxCWFiles% if there are more than that.  Then
  '     draw/redraw the main screen.
  '
  NumCWFiles = FCount%(InstSpec$)
  IF NumCWFiles > MaxCWFiles% THEN NumCWFiles = MaxCWFiles%
 
  CALL DrawScreen
 
  '---- Read the .CWF file names and display them in a vertical menu.  Then
  '     read any default directories (if present) within each .CWF file's
  '     comment, and display them in the destination directory fields.  For
  '     each .CWF file that doesn't have a corresponding default directory
  '     in the comment, use the contents of the main DEFAULT.DIR file found
  '     in the root directory of the disk.
  '
  REDIM CWFName$(0 TO NumCWFiles)
  REDIM DestDir$(1 TO NumCWFiles), Comment$(1 TO NumCWFiles)

  CWFName$(0) = InstSpec$
  FOR X = 1 TO NumCWFiles
    CWFName$(X) = Blank$
    DestDir$(X) = PadDir$
  NEXT
  CALL ReadFile(BYVAL VARPTR(CWFName$(0)))

  FOR X = 1 TO NumCWFiles               'look at each .CWF file comment
    LSET DestDir$(X) = DefaultDir$      'assume none, use the global default
    CALL CWGetComment(InstPath$ + RTRIM$(CWFName$(X)), Comment$(X), ErrCode)
    GOSUB CheckError                    'check for an error
    Bar = INSTR(Comment$(X), "þ")       'see if a directory was given
    IF Bar THEN                         'there is a directory for this file
      LSET DestDir$(X) = UCASE$(MID$(Comment$(X), Bar + 1)) 'dir is on right
      Comment$(X) = LEFT$(Comment$(X), Bar - 1)         'and comment on left
    END IF
  NEXT

  FOR X = 1 TO NumCWFiles               'add leading blanks to make room
    CWFName$(X) = "   " + CWFName$(X)   '  for the CHR$(251) check marks
    IF RIGHT$(Comment$(X), 1) = "๛" THEN    'they want this file checked
      CALL MidCharS(CWFName$(X), 2, 251)    'so check it in the file list box
      Comment$(X) = LEFT$(Comment$(X), LEN(Comment$(X)) - 1)
    END IF
    LSET PadComment$ = Comment$(X)      'display the directories and comments
    LOCATE X + 4, 2: CALL QPrint0(DestDir$(X), NormColor)  'while we're here
    LOCATE X + 4, 44: CALL QPrint0(PadComment$, NormColor)
  NEXT

  DO                                    'let the user select the files
    CALL SelectFiles(CWFName$(), Choice, ExitCode)
    IF ExitCode = 9 THEN                'they pressed Tab
      DO
        CALL Editor(DestDir$(Choice), ALen, EdScan, Zero, One, NormColor, HiColor, Choice + 4, 2)
        SELECT CASE EdScan              'how did the terminate editing?
          CASE -80                      'Down Arrow
            Choice = Choice + 1         'wrap around if they go past the end
            IF Choice > NumCWFiles THEN Choice = 1
          CASE -72                      'Up Arrow
            Choice = Choice - 1         'wrap to the end if they go before 1
            IF Choice < 1 THEN Choice = NumCWFiles
          CASE 27                       'Escape
            CALL CWReleaseMem(Zero)
            CALL EndIt
          CASE -60                      'F2
            ExitCode = -60              'tell SelectFiles to come right back
            EXIT DO                     '  so we can exit both levels of DO
          CASE ELSE
            EXIT DO                     'anything else returns to SelectFiles
        END SELECT
      LOOP
    ELSEIF ExitCode = -60 THEN          'F2
      ExitCode = 0                      'prevent unwanted recursion across
      EXIT DO                           '  multiple disks
    END IF
  LOOP


  '---- Install the selected files to the specified destination directories.
  '     For each file that is tagged, either change to the appropriate drive
  '     and directory, or ensure that we're back to the original path.
  '
  LOCATE 25, 2                                'for the status message below
  FOR X = 1 TO NumCWFiles                     'for each .CWF file present
    IF MidChar%(CWFName$(X), 2) = 251 THEN    'if it's tagged to install
                                              
      LSET Msg$ = "Installing" + RTRIM$(MID$(CWFName$(X), 3)) + "..."
      CALL QPrint0(Msg$, MainColor)           'advise the user as to progress

      DestPath$ = RTRIM$(DestDir$(X))         'work with a copy of the path
      IF X = 1 THEN FirstPath$ = DestPath$    'save this for PROGRAM.RUN

      IF MidChar%(DestPath$, 2) = 58 THEN     'if a drive was used (58 = ":")
        CALL SetDrive(DestPath$)              'change to that drive
        IF GetDrive% <> ASC(DestPath$) THEN   'no such drive
          ErrCode = 1                         'we'll look for this error in
          GOTO CheckError                     '  the code at CheckError
        END IF
        DestPath$ = MID$(DestPath$, 3)        'strip the drive letter & colon
      ELSE
        CALL SetDrive(SaveDir$)               'else return to original drive
      END IF

      'strip off a trailing "\" unless it refers to the root directory
      IF RIGHT$(DestPath$, 1) = "\" AND LEN(DestPath$) > 1 THEN
        DestPath$ = LEFT$(DestPath$, LEN(DestPath$) - 1)
      END IF
     
      IF LEN(DestPath$) THEN                  'if a directory is present
        CALL CDir(DestPath$)                  'change to it
      END IF
     
      IF WhichError% = 76 THEN                'no such directory exists
        CALL MakeDir(DestPath$)               'so first create it
        CALL CDir(DestPath$)                  'and then try to change to it
      END IF

      IF WhichError% = 76 THEN                'we still couldn't change there
        ErrCode = 1                           'we'll look for this error in
        GOTO CheckError                       '  the code at CheckError
      END IF

      'install all of the files inside this .CWF file and check for errors
      CALL CWUnpackFiles(InstPath$ + RTRIM$(MID$(CWFName$(X), 4)), "*.*", ErrCode)
      GOSUB CheckError

      IF INKEY$ = CHR$(27) THEN
        CALL CWReleaseMem(Zero)
        CALL EndIt
      END IF

    END IF
  NEXT

  IF ThisDisk < NumDisks THEN           'if there are more disks to install
    LOCATE 25, 2                        'prompt to insert the next disk
    LSET Msg$ = "Insert the next disk and press any key when ready"
    CALL QPrint0(Msg$, MainColor + 128)
    DO: LOOP WHILE LEN(INKEY$)          'first clear any pending keys
    DO: LOOP UNTIL LEN(INKEY$)          'then wait for a keypress
    CALL SetDrive(SaveDir$)             'return to the current drive and its
    CALL CDir(SaveDir$)                 'current directory before going on
  END IF

NEXT


'---- Report success and run the specified program (StuffBuf ignores a null
'     string argument.  Change to the first drive and directory installed to
'     before running the program.
'
COLOR 7, 0: CLS
LOCATE 10, 30: PRINT "Installation complete!"
LOCATE 22, 1
IF MidChar%(FirstPath$, 2) = 58 THEN CALL SetDrive(FirstPath$)
CALL CDir(FirstPath$)
CALL StuffBuf(RunName$)                 'stuff the buffer if appropriate
CALL CWReleaseMem(Zero)                 'release any memory we may have used
END                                     'and end


CheckError:                             'report any errors here and end
  IF ErrCode = 0 THEN RETURN            'no errors, return
 
  COLOR 7, 0: CLS : LOCATE 24, 2

  IF ErrCode < 0 THEN                   'it's a regular CW Shop error we know
    PRINT "Error"; ErrCode; "occurred: "; CWMsg$(ErrCode);
    IF ErrCode = -10 THEN PRINT " -- "; CWCritMsg$(CWCritErr%)
  ELSE
    PRINT "Unable to create directory: "; DestPath$ 'it must be the special
  END IF                                            '  case we set earlier

  CALL SetDrive(SaveDir$)               'return to the current drive and its
  CALL CDir(SaveDir$)                   'current directory before ending
  CALL CWReleaseMem(Zero)               'release any memory we may have used
                                        'and end here

SUB DrawScreen STATIC

  SHARED FG, BG, One, MainColor, Bar$
 
  '---- Draw the title screen and surrounding boxes.
  '
  COLOR FG, BG: CLS
  CALL Box0(One, One, 24, 80, 2, MainColor)
  LOCATE 2, 21: CALL QPrint0("Crescent Software's INSTALL Version 3.00", MainColor)
  LOCATE 3, 1: CALL QPrint0(Bar$, MainColor)

  LOCATE 4, 3
  CALL QPrint0("Destination Directories   Program Files                Comments", MainColor)

  CALL Box0(3, 27, 24, 43, One, MainColor)
  LOCATE 3, 27:  CALL QPrint0("ัอออออออออออออออั", MainColor)
  LOCATE 24, 27: CALL QPrint0("ฯอออออออออออออออฯ", MainColor)

  LOCATE 25, 2
  CALL QPrint0("Space: Select files to install   Tab: Edit destination   F2: Begin   Esc: Quit", MainColor)
 
END SUB

SUB EndIt STATIC
  COLOR 7, 0
  CLS
  END
END SUB

SUB SelectFiles (FileNames$(), Choice, ExitCode) STATIC

  SHARED NumCWFiles, NormColor, HiColor, Zero$

  IF ExitCode = -60 THEN EXIT SUB       'we got here via F2 pressed in Editor

  FOR X = 1 TO NumCWFiles               'first display all of the choices
    LOCATE 4 + X, 28
    CALL QPrint0(FileNames$(X), NormColor)
  NEXT

  IF Choice = 0 THEN Choice = 1         'start at element 1 if first time
  IF Choice > UBOUND(FileNames$) THEN Choice = 1 'or if Choice is too high

  DO
    LOCATE 4 + Choice                   'redraw current choice highlighted
    CALL QPrint0(FileNames$(Choice), HiColor)
    KeyHit$ = INKEY$                    'see what they want to do
    ExitCode = 0                        'assume there's no key pending
   
    IF LEN(KeyHit$) = 1 THEN
      ExitCode = ASC(KeyHit$)
    ELSEIF LEN(KeyHit$) = 2 THEN
      ExitCode = -ASC(MID$(KeyHit$, 2))
    END IF
   
    IF ExitCode = 32 THEN               'spacebar
      IF MidChar%(FileNames$(Choice), 2) = 251 THEN 'if it's now checked
        NewChar = 32                    'remove the check mark
      ELSE
        NewChar = 251                   'else add a check mark
      END IF
      CALL MidCharS(FileNames$(Choice), 2, NewChar)
      ExitCode = -80                    'select the next file automatically
    END IF

    SELECT CASE ExitCode
      CASE -80                          'Down Arrow
        GOSUB Deselect
        Choice = Choice + 1
        IF Choice > NumCWFiles THEN Choice = 1
      CASE -79                          'End key
        GOSUB Deselect
        Choice = NumCWFiles
      CASE -72                          'Up Arrow
        GOSUB Deselect
        Choice = Choice - 1
        IF Choice = 0 THEN Choice = NumCWFiles
      CASE -71                          'Home
        GOSUB Deselect
        Choice = 1
      CASE -60                          'F2
        EXIT SUB
      CASE 27                           'Escape
        CALL CWReleaseMem(Zero)
        CALL EndIt
      CASE 9                            'Tab
        LOCATE Choice + 4, 33
        GOSUB Deselect
        EXIT SUB
      CASE ELSE                         'this is needed for QB 4.0 only
    END SELECT
  LOOP

Deselect:                               're-paint the current choice, so it
  LOCATE Choice + 4, 28                 '  won't appear active
  CALL QPrint0(FileNames$(Choice), NormColor)
  RETURN

END SUB

FUNCTION SourceDir$ STATIC

' If we're running DOS 3.0 or later we can determine the directory INSTALL
' was run from, and read the .CWF file names from there.  Otherwise, the
' files need to be in the current directory on the current drive to be found.

  'SourceDir$ = ""                      'not really needed because this is
                                        '  called only once
  IF DOSVer% >= 300 THEN                'get the directory INSTALL was
    InstPath$ = ExeName$                '  run from
    FOR X = LEN(InstPath$) TO 1 STEP -1 'isolate the drive letter and path
      Char = MidChar%(InstPath$, X)     '  (strip off the name INSTALL.EXE)
      IF Char = 58 OR Char = 92 THEN    'look for a colon or a backslash
        SourceDir$ = LEFT$(InstPath$, X)
        EXIT FOR
      END IF
    NEXT
  END IF

END FUNCTION

