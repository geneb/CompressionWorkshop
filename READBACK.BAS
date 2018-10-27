'********** READBACK.BAS - shows how to read the files on a backup disk

'Copyright (c) 1992 Ethan Winer

DEFINT A-Z
'$INCLUDE: 'CWDECL.BI'
'$INCLUDE: 'ERRCODES.BI'

'FnPad$ returns two-digit numbers padded with a leading zero if necessary.
DEF FnPad$ (IntVar) = RIGHT$("0" + LTRIM$(STR$(IntVar)), 2)


'FnExt$ returns three-digit numbers padded with leading zeros as necessary.
DEF FnExt$ (FileNum) = RIGHT$("00" + LTRIM$(STR$(FileNum)), 3)


'FnDateTime$ formats dates packed as CHR$(Year) + CHR$(Month) + CHR$(Day) and
'it also formats times packed as CHR$(Hour) + CHR$(Minute) + CHR$(Second).
DEF FnDateTime$ (DT$, Delimiter$)
  STATIC X, Temp$, Year$

  IF Delimiter$ = "-" THEN              'we're formatting a date
    Year$ = MID$(DT$, 1, 1)             'swap the Month and Year digits
    MID$(DT$, 1, 2) = MID$(DT$, 2, 2)
    MID$(DT$, 3, 1) = Year$
  END IF

  FOR X = 1 TO 3
    Temp$ = Temp$ + FnPad$(ASC(MID$(DT$, X, 1)))
    IF X < 3 THEN Temp$ = Temp$ + Delimiter$
  NEXT

  FnDateTime$ = Temp$
  Temp$ = ""
END DEF


TYPE CWType                             'this defines the backup hearder info
  FilePath AS STRING * 98
  FileName AS STRING * 12
  FileDate AS STRING * 3
  FileTime AS STRING * 3
  FileSize AS LONG
  DiskNum  AS INTEGER
  FileNum  AS INTEGER
  ArrayNum AS INTEGER
  Arrays   AS INTEGER
END TYPE
REDIM Directory(1 TO 1) AS CWType       'this array receives the names, etc.
 
PRINT "Enter the drive letter for the disk that holds the backup set: ";
DO
  Drive$ = UCASE$(INKEY$)
LOOP UNTIL LEN(Drive$)
PRINT Drive$

Backup$ = Drive$ + ":\CWBACKUP.001"     'name of backup file, or use .002
CALL CWUnpackArray(Directory(), Zero, Backup$, ErrCode)
IF ErrCode THEN
  PRINT CWMsg$(ErrCode)
  IF ErrCode = -10 THEN PRINT CWCritMsg$(CWCritErr%)
  END
END IF

PRINT "Source file name"; TAB(32); "Date"; SPC(7); "Time"; SPC(8); "Size"
PRINT "=========================="; TAB(30); "========"; SPC(3); "========";
PRINT SPC(3); "=========="
Size$ = SPACE$(10)                      'to format the file sizes
Elements = UBOUND(Directory)            'get the size of the Directory array
FOR X = 1 TO Elements - 1               'the last element is not used here
  PRINT RTRIM$(Directory(X).FilePath);
  PRINT RTRIM$(Directory(X).FileName); TAB(30);
  PRINT FnDateTime$(Directory(X).FileDate, "-"); SPC(3);
  PRINT FnDateTime$(Directory(X).FileTime, ":");
  RSET Size$ = STR$(Directory(X).FileSize)
  PRINT SPC(3); Size$
 
  IF X MOD 22 = 0 THEN                  'pause every 22 lines
    PRINT "-more- ";
    DO: LOOP UNTIL LEN(INKEY$)
    PRINT
  END IF
NEXT

CALL CWReleaseMem(1)

