'********** CWUNPACK.BAS - Compression Workshop unpacking utility program
'
'Copyright (c) 1992 Ethan Winer and Fred Sexton, Jr.

'If you have P.D.Q. compile and link as follows:
'
'  bc cwunpack /o /s ;
'  bc getparam /o /s ;
'  link /ex /nod /noe /far /packc _
'    cwunpack getparam _noval _noread _noerror , , nul , cwshop pdq ;
'  exe2com cwunpack
'  del cwunpack.exe
'  ren cwunpack.com cwunpack.exe


DEFINT A-Z
DECLARE FUNCTION BaseName$ (FullName$)  'strips drive/path from a file name
DECLARE FUNCTION FormatNum$ (IntVar)    'formats numbers for /V display
DECLARE FUNCTION GetParam$ (Switch$)    'returns command line parameters

'$INCLUDE: 'CWDECL.BI'                  'declares the various CWShop routines
'$INCLUDE: 'ERRCODES.BI'                'has the ErrCode strings

TYPE CWType                             'this TYPE variable is used
  FileName AS STRING * 12               '  when reading the names of files
  FileDate AS STRING * 3                '  contained in a compressed file
  FileTime AS STRING * 3
  FileSize AS LONG
END TYPE

PRINT "CWUNPACK - Copyright (c) 1992 Crescent Software, Inc."
PRINT

Cmd$ = UCASE$(COMMAND$)                     'UCASE is needed for P.D.Q.
IF LEN(Cmd$) = 0 OR INSTR(Cmd$, "?") THEN   'if there isn't a command line
   PRINT "  Usage: CWUNPACK filename [options]"     'display the usage info
   PRINT "Default: Decompress (overwrite) all files to current directory"
   PRINT
   PRINT "/D  Unpack non-existing and newer files only"
   PRINT "/D2 Unpack only files that are newer and already exist"
   PRINT "/L  [filename] Use response file with list of file names"
   PRINT "/O  [path] Override drive/path if present in response file"
   PRINT "/S  [filespec] Decompress file specification"
   PRINT "/T  [path] Target decompress drive/path"
   PRINT "/V  View compressed file contents"
   END
END IF

Switch = INSTR(Cmd$, "/")               'check for switches
IF Switch THEN                          'there's at least one
  CWFName$ = RTRIM$(LEFT$(Cmd$, Switch - 1))   'the file name is before
  Cmd$ = MID$(Cmd$, Switch)                    '  the first switch
ELSE
  CWFName$ = Cmd$                       'the entire command line is the name
END IF

IF INSTR(CWFName$, ".") = 0 THEN        'add ".CWF" if no extension was given
  CWFName$ = CWFName$ + ".CWF"
END IF

TempSize$ = SPACE$(8)                   'for displaying the file sizes below


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


'---- See if a list (response) file was specified, and if so open it.
'
ListFile$ = GetParam$("/L")
IF LEN(ListFile$) THEN                  'the list file switch was given
  IF ListFile$ = "/L" THEN              'but not a list file name
    INPUT "List file name: "; ListFile$ 'prompt for the file name
  END IF
  OPEN ListFile$ FOR INPUT AS #1        'either way, open the list file
  IF ERR THEN                           'this is for P.D.Q. only
    PRINT "File not found."             'regular BASIC will simply crash
    END
  END IF
  Over$ = GetParam$("/O")               'see if they used /O
  IF LEN(Over$) THEN                    'they did
    IF Over$ = "/O" THEN                'but they didn't give the path
      INPUT "Enter the destination path: ", Over$    'so prompt for it
    END IF
    IF LEN(Over$) AND RIGHT$(Over$, 1) <> "\" AND RIGHT$(Over$, 1) <> ":" THEN
      Over$ = Over$ + "\"               'Over$ must end with ":" or "\"
    END IF
  END IF
ELSE
'---- No list file was given, so see if they gave a file specification.
'
  Spec$ = GetParam$("/S")
  IF LEN(Spec$) THEN
    IF Spec$ = "/S" THEN                'they used /S but give no file spec
      INPUT "Decompress file spec: "; Spec$ 'so prompt for it
    END IF
  END IF
  IF LEN(Spec$) = 0 THEN Spec$ = "*.*"  'assign the default
END IF


'---- See if a target drive/path was specified.
'
Target$ = GetParam$("/T")               'see if they used /T
IF LEN(Target$) THEN                    'they did
  IF Target$ = "/T" THEN                'but they didn't give the path
    INPUT "Enter the target path: ", Target$    'so prompt for it
  END IF
  IF RIGHT$(Target$, 1) <> "\" AND RIGHT$(Target$, 1) <> ":" THEN
    Target$ = Target$ + "\"             'Target$ must end with ":" or "\"
  END IF
  Spec$ = Target$ + Spec$               'create full path spec
END IF


'---- See if they want to decompress newer files only, and if they want to
'     also require that the files already exist in the current directory.
'
DateComp$ = GetParam$("/D")             'see if they used /D
IF LEN(DateComp$) THEN                  'yes,
  TDAct = -1                            '  set the flag for later
  IF DateComp$ = "2" THEN ErrCode = 1   'now see if the used /D2
END IF

'---- And away we go......
'
PRINT "Decompressing "; CWFName$

IF LEN(ListFile$) THEN
  DO WHILE NOT EOF(1)                   'call for each file in list
    LINE INPUT #1, Spec$
    Spec$ = RTRIM$(LTRIM$(Spec$))       'trim surrounding blanks just in case
    IF LEN(Over$) THEN                  'use the drive/path override if given
      Spec$ = Over$ + BaseName$(Spec$)
    END IF
    IF TDAct THEN                       'call the appropriate version
      CALL CWUnpackFilesD(CWFName$, Spec$, ErrCode)
    ELSE
      CALL CWUnpackFiles(CWFName$, Spec$, ErrCode)
    END IF
    GOSUB CheckError                    'see if an error occurred
  LOOP
  CLOSE #1
ELSE                                    'we're not using a list file
  IF TDAct THEN                         'as above
    CALL CWUnpackFilesD(CWFName$, Spec$, ErrCode)
  ELSE
    CALL CWUnpackFiles(CWFName$, Spec$, ErrCode)
  END IF
  GOSUB CheckError
END IF


'---- All done -- release the memory allocated by these routines and end.
'
CALL CWReleaseMem(Zero)
END


'---- GOSUB here to check for errors.
'
CheckError:
  IF ErrCode THEN                       'if an error occurred
    IF ErrCode = -13 THEN               'no matching file(s) error
      PRINT Spec$; " "; CWMsg$(ErrCode) 'this is not fatal, continue
    ELSE
      PRINT CWFName$; ": "; CWMsg$(ErrCode)     'else display the error
      IF ErrCode = -10 THEN PRINT CWCritMsg$(CWCritErr%)
      CALL CWReleaseMem(Zero)                   'release the memory
      END                                       'and end
    END IF
  END IF
  RETURN                                'else return

FUNCTION BaseName$ (FullName$) STATIC   'strips drive/path from a file name

  BaseName$ = FullName$                 'assume there's no drive or path

  FOR X = LEN(FullName$) TO 1 STEP -1   'walk backwards through the file name
    ThisChar = ASC(MID$(FullName$, X))        'grab this character
    IF ThisChar = 58 OR ThisChar = 92 THEN    'colon or backslash
      BaseName$ = MID$(FullName$, X + 1)      'keep just the file name
      EXIT FOR                                'and bail out of the loop
    END IF
  NEXT
 
END FUNCTION

FUNCTION FormatNum$ (IntVar) STATIC

  Temp$ = STR$(IntVar)
  MID$(Temp$, 1, 1) = "0"
  FormatNum$ = RIGHT$(Temp$, 2)

END FUNCTION

