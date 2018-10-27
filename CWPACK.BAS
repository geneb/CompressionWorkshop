'********* CWPACK.BAS - Compression Workshop packing utility program
'
'Copyright (c) 1992 Ethan Winer and Fred Sexton, Jr.

'If you have P.D.Q. compile and link as follows:
'
'  bc cwpack /o /s ;
'  bc getparam /o /s ;
'  link /ex /nod /noe /far /packc _
'    cwpack getparam _noval _noread _noerror , , nul , cwshop pdq ;
'  exe2com cwpack
'  del cwpack.exe
'  ren cwpack.com cwpack.exe

DEFINT A-Z
DECLARE FUNCTION FormatNum$ (IntVar)    'for formatting when /v is used
DECLARE FUNCTION GetParam$ (Switch$)    'returns command line parameters
DECLARE FUNCTION PathName$ (FullName$)  'extracts drive/path from a file name

'$INCLUDE: 'CWDECL.BI'                  'declares the various CWShop routines
'$INCLUDE: 'ERRCODES.BI'                'has the ErrCode strings

TYPE CWType                             'this TYPE variable is used
  FileName AS STRING * 12               '  when reading the names of files
  FileDate AS STRING * 3                '  contained in a compressed file
  FileTime AS STRING * 3
  FileSize AS LONG
END TYPE

PRINT "CWPACK - Copyright (c) 1992 Crescent Software, Inc."
PRINT

Cmd$ = UCASE$(COMMAND$)                     'UCASE$ is needed for P.D.Q.
IF LEN(Cmd$) = 0 OR INSTR(Cmd$, "?") THEN   'if no command line, display help
   PRINT "  Usage: CWPACK filename [options]"
   PRINT "Default: *.* to filename.CWF"
   PRINT
   PRINT "/A  [filespec] Append specified files to existing compressed file"
   PRINT "/C  [comment] Add comment (new files only)"
   PRINT "/D  [date [, time]] Compress newer files"
   PRINT "/L  [filename] Use response file with list of file names"
   PRINT "/M  [kbd command] Convert compressed file to self-extracting"
   PRINT "/R  [filespec] Remove specified files from compressed file"
   PRINT "/S  [filespec] Add specified files to a new compressed file"
   PRINT "/U  Update compressed file from files in current directory"
   PRINT "/V  View compressed file contents"
   END
END IF

Switch = INSTR(Cmd$, "/")               'check for switches
IF Switch THEN                          'there's at least one
  CWFName$ = RTRIM$(LEFT$(Cmd$, Switch - 1))    'the file name is before
  Cmd$ = MID$(Cmd$, Switch)                     '  the first switch
ELSE
  CWFName$ = Cmd$                       'the entire command line is the name
END IF

IF INSTR(CWFName$, ".") = 0 THEN        'add ".CWF" if no extension was given
  CWFName$ = CWFName$ + ".CWF"
END IF

TempSize$ = SPACE$(8)                   'for displaying the file sizes below
Path$ = PathName$(CWFName$)             'isolate path for possible use later


'---- View the names of the files within the compressed file.
'
IF LEN(GetParam$("/V")) THEN
  CALL CWGetComment(CWFName$, Cmt$, ErrCode)    'see if there's a comment
  GOSUB CheckError                              'see if an error occurred
  IF LEN(Cmt$) THEN PRINT Cmt$                  'print the file comment

  REDIM Array(0) AS CWType                      'establish an array
  CALL CWReadNames(CWFName$, Array(), ErrCode)  'read the file names
  GOSUB CheckError                              'see if an error occurred
  NumCWFiles = UBOUND(Array)                    'how many files are there?

  FOR X = 0 TO NumCWFiles                       'display the file names and
    PRINT Array(X).FileName; TAB(13);           '  other info
    RSET TempSize$ = STR$(Array(X).FileSize)
    PRINT TempSize$; TAB(23);

    PRINT FormatNum$(ASC(MID$(Array(X).FileDate, 2, 1))); "-";
    PRINT FormatNum$(ASC(MID$(Array(X).FileDate, 3, 1))); "-19";
    PRINT FormatNum$(ASC(MID$(Array(X).FileDate, 1, 1))); TAB(35);

    PRINT FormatNum$(ASC(MID$(Array(X).FileTime, 1, 1))); ":";
    PRINT FormatNum$(ASC(MID$(Array(X).FileTime, 2, 1))); ":";
    PRINT FormatNum$(ASC(MID$(Array(X).FileTime, 3, 1)))
   
    IF (X + 1) MOD 22 = 0 THEN          'if the screen has filled
      PRINT "--more-- ";                'prompt and pause for a keypress
      DO: LOOP UNTIL LEN(INKEY$)
      PRINT
    END IF
  NEXT

  PRINT NumCWFiles + 1; "files found in "; CWFName$
  END
END IF


'---- Update selected files already present within the compressed file.
'
IF LEN(GetParam$("/U")) THEN
  Tmp$ = ENVIRON$("TEMP")                       'is TEMP in the environment?
  IF LEN(Tmp$) = 0 THEN Tmp$ = ENVIRON$("TMP")  'no, but how about TMP?
  IF LEN(Tmp$) AND RIGHT$(Tmp$, 1) <> "\" AND RIGHT$(Tmp$, 1) <> ":" THEN
    Tmp$ = Tmp$ + "\"                           'add trailing "\" if needed
  END IF
  TempFile$ = Tmp$ + "$$CWPACK.TMP"             'this is the temp file name

  CALL CWUpdate(CWFName$, TempFile$, ErrCode)   'update the compressed file
  GOSUB CheckError                              'see if an error occurred
  PRINT CWFName$; " has been updated."          'report success
  GOTO EndIt                                    'this saves a bunch of code
END IF


'---- See if a list (response) file was specified, and if so open it.
'
ListFile$ = GetParam$("/L")
IF LEN(ListFile$) THEN                  'the list file switch was given
  ListFlag = -1                         'a flag uses smaller code tests later
  IF ListFile$ = "/L" THEN              'but not a list file name
    INPUT "List file name: "; ListFile$ 'prompt for the file name
  END IF
  OPEN ListFile$ FOR INPUT AS #1        'either way, open the list file
  IF ERR THEN                           'this is for P.D.Q. only
    PRINT "File not found."             'regular BASIC will simply crash
    END
  END IF
ELSE
'---- If no list file was given, see if they gave a file specification.
'
  Spec$ = GetParam$("/S")
  IF LEN(Spec$) THEN
    IF Spec$ = "/S" THEN                'they used /S but give no file spec
      INPUT "Compress file spec: "; Spec$   'so prompt for it
    END IF
  ELSE
    Spec$ = "*.*"                       '/S was not used, assume the default
  END IF
END IF


'---- See if they want to remove files from the compressed file.
'
RemoveSpec$ = GetParam$("/R")
IF LEN(RemoveSpec$) THEN
  IF ListFlag THEN                      'if they gave a list file, use it
    DO WHILE NOT EOF(1)                 'for each file name in the list file
      LINE INPUT #1, DelFile$                       'read the current name
      DelFile$ = RTRIM$(LTRIM$(DelFile$))           'trim blanks just in case
      CALL CWDelFile(CWFName$, DelFile$, ErrCode)   'and delete it
      GOSUB CheckError                  'see if an error occurred
    LOOP
    CLOSE #1                            'close the list file
  ELSE                                  'we're not using a list file
    IF RemoveSpec$ = "/R" THEN          'no file specification was given
      INPUT "Remove file spec: "; RemoveSpec$   'so prompt the user for it
    END IF
    CALL CWDelFile(CWFName$, RemoveSpec$, ErrCode)
    GOSUB CheckError                    'see if an error occurred
  END IF
  GOTO EndIt                            'this GOTO saves a bunch of code
END IF


'---- See if they want to add to an existing file.  If so, retrieve or ask
'     for the file spec.  Otherwise, see if they want to add a comment to
'     the new file being created.
'
AddSpec$ = GetParam$("/A")              'see if they used /A
IF LEN(AddSpec$) THEN                   'yes
  IF NOT ListFlag THEN                  'and they didn't specify a list file
    IF AddSpec$ = "/A" THEN             'but they didn't give a file spec
      INPUT "Append file spec: "; Spec$ 'so prompt for it
    ELSE
      Spec$ = AddSpec$
    END IF
  END IF
  ErrCode = 1                           'tell CWPackFiles[D] below to append
ELSE
  Cmt$ = GetParam$("/C")                'see if they used /C
  IF LEN(Cmt$) THEN                     'they did
    IF Cmt$ = "/C" THEN                 'but they didn't give the text
      INPUT "Comment string: "; Cmt$    'so prompt for it
    END IF
  END IF
END IF


'---- See if they want to select file based on their dates and times.
'
DateTime$ = GetParam$("/D")
IF LEN(DateTime$) THEN
  TDAct = -1                            'set time/date active flag
  IF DateTime$ = "/D" THEN              'they did not give the date and time
    INPUT "              Enter the date (MM-DD-YYYY): "; Dat$   'so prompt
    INPUT "24-hour time (HH:MM:SS) or Enter for none: "; Tim$   '  for those
  ELSE
    Found = INSTR(DateTime$, ",")       'see if they gave the optional time
    IF Found THEN                       'they did, extract the date and time
      Dat$ = RTRIM$(LEFT$(DateTime$, Found - 1))
      Tim$ = LTRIM$(MID$(DateTime$, Found + 1))
    ELSE
      Dat$ = DateTime$                  'they gave the date only
      Tim$ = "00:00:00"                 'so use 0 for the time
    END IF
  END IF
END IF


'---- Report that the file is either being created or appended to.
'
IF ErrCode THEN
  PRINT "Appending ";
ELSE
  IF Exist%(CWFName$) THEN
    DO: LOOP WHILE LEN(INKEY$)
    PRINT "Okay to overwrite "; CWFName$; "? (Y/N) ";
    DO
      X$ = UCASE$(INKEY$)
    LOOP UNTIL INSTR(" YN", X$) > 1
    PRINT X$
    IF X$ = "N" THEN END
  END IF
  PRINT "Creating ";
END IF
PRINT CWFName$


'---- If we're using a list file, read it and use the names it contains.
'
IF ListFlag THEN
  DO WHILE NOT EOF(1)
    LINE INPUT #1, Spec$                'for each file name/spec in the list
    Spec$ = RTRIM$(LTRIM$(Spec$))       'trim surrounding blanks just in case
DiskFull:
    IF TDAct THEN                       'if we're using a date and time
      CALL CWPackFilesD(Spec$, CWFName$, Cmt$, Tim$, Dat$, ErrCode)
    ELSE
      CALL CWPackFiles(Spec$, CWFName$, Cmt$, ErrCode)
    END IF

    IF ErrCode THEN                     'see what happened
      IF ErrCode = -9 THEN              'disk full error, handle it
        INPUT "Disk Full - insert new disk and enter new filename: "; CWFName$
        IF INSTR(CWFName$, ".") = 0 THEN CWFName$ = CWFName$ + ".CWF"
        CWFName$ = Path$ + CWFName$
        NumCWF = NumCWF + 1
        GOTO DiskFull                   'please don't complain, it works
      ELSEIF ErrCode = -13 THEN         'no matching file(s) error
        PRINT Spec$; " "; CWMsg$(ErrCode)   'this is not fatal, continue
      ELSE
        GOSUB CheckError                'else report the error and end
      END IF
    END IF
    ErrCode = 1                         'after the first file use append
  LOOP
  CLOSE #1

ELSE                                    'a list file was not given
DiskFull2:
  IF TDAct THEN                         'as above
    CALL CWPackFilesD(Spec$, CWFName$, Cmt$, Tim$, Dat$, ErrCode)
  ELSE
    CALL CWPackFiles(Spec$, CWFName$, Cmt$, ErrCode)
  END IF
  IF ErrCode THEN
    IF ErrCode = -9 THEN
      INPUT "Disk Full - insert new disk then enter new filename: "; CWFName$
      IF INSTR(CWFName$, ".") = 0 THEN CWFName$ = CWFName$ + ".CWF"
      CWFName$ = Path$ + CWFName$
      NumCWF = NumCWF + 1
      GOTO DiskFull2
    ELSE
      GOSUB CheckError
    END IF
  END IF
END IF


'---- See if they want to make a self-extracting file, but allow that only
'     if the disk didn't fill requiring multiple compressed files.
'
SelfExt$ = GetParam$("/M")              'see if they used /M
IF LEN(SelfExt$) THEN                   'they did
  IF NumCWF = 0 THEN                    'if only one compressed file was made
    IF SelfExt$ = "/M" THEN             'but there's no command, ask for it
    INPUT "Enter type-ahead command, or Enter for none"; Kbd$
    ELSE
      Kbd$ = SelfExt$                   'else, use the text that follows /M
    END IF
 
    IF LEN(Kbd$) THEN                   'if there is a keyboard command
      Kbd$ = Kbd$ + CHR$(13)            'add Enter so command will execute
    END IF

    CALL CWMakeExt(CWFName$, Kbd$, ErrCode)
    GOSUB CheckError                    'see if an error occurred
    KILL CWFName$                       'unREM to retain the .CWF file
  ELSE
    PRINT "More than one file was required -- unable to create a self-extracting file."
  END IF
END IF


'---- All done -- release the memory allocated by these routines and end.
'
GOTO EndIt


'---- GOSUB here to check for errors.
'
CheckError:
  IF ErrCode THEN                           'if an error occurred
     PRINT CWFName$; ": "; CWMsg$(ErrCode)  'display the error
     IF ErrCode = -10 THEN PRINT CWCritMsg$(CWCritErr%)
EndIt:
     CALL CWReleaseMem(Zero)                'release the memory
     END                                    'and end
  END IF
  RETURN                                    'else return

FUNCTION FormatNum$ (IntVar) STATIC

  Temp$ = STR$(IntVar)
  MID$(Temp$, 1, 1) = "0"
  FormatNum$ = RIGHT$(Temp$, 2)

END FUNCTION

FUNCTION PathName$ (FullName$) STATIC   'strips file name from drive/path

  PathName$ = ""                        'assume there's no drive or path

  FOR X = LEN(FullName$) TO 1 STEP -1   'walk backwards through the file name
    ThisChar = ASC(MID$(FullName$, X))        'grab this character
    IF ThisChar = 58 OR ThisChar = 92 THEN    'colon or backslash
      PathName$ = LEFT$(FullName$, X)         'keep just the drive/path
      EXIT FOR                                'and bail out of the loop
    END IF
  NEXT

END FUNCTION

