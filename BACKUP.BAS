'********** BACKUP.BAS - backup and restore subprograms and support routines

'Written by Phil Weber
'Copyright (c) 1992 Crescent Software, Inc.

'NOTE: This file must be compiled using /ah.  Otherwise you will be limited
'to no more than 512 files in the backup set.  However, it is not necessary
'to compile your main program or other support modules with /ah.
    
DEFINT A-Z
TYPE CWType
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

TYPE RegType
  AX    AS INTEGER
  BX    AS INTEGER
  CX    AS INTEGER
  DX    AS INTEGER
  BP    AS INTEGER
  SI    AS INTEGER
  DI    AS INTEGER
  Flags AS INTEGER
  DS    AS INTEGER
  ES    AS INTEGER
END TYPE

DECLARE SUB CreateDir (DirName$)
DECLARE SUB CWBackup (FileSpec$, Dest$, Recurse, ErrCode)
DECLARE SUB CWClipFile (Handle, Length&)
DECLARE SUB CWRestore (FileSpec$, Dest$, Recurse, ErrCode)
DECLARE SUB CWDiskRoom (Drive$, Free&, Total&)
DECLARE SUB FixPath (Path$)
DECLARE SUB GetFileDate (Handle, FDate$, FTime$)
DECLARE SUB PathName (FileSpec$, Path$)
DECLARE SUB PrepArray (Array$())
DECLARE SUB SetFileDate (Handle, FDate$, FTime$)
DECLARE SUB WipeDisk (Drive$)

DECLARE FUNCTION ChangeLine% (Drive$)
DECLARE FUNCTION CopyFile% (Src$, Dest$)
DECLARE FUNCTION CWCurDir$ ()
DECLARE FUNCTION CWFileSize& (FileName$)
DECLARE FUNCTION CWGetDrive$ ()
DECLARE FUNCTION DiskFormat% (Drive$)
DECLARE FUNCTION ErrorHandler% (ErrCode)
DECLARE FUNCTION Ext$ (FileNum)
DECLARE FUNCTION FileCount% (FileSpec$, Archive, Recurse)
DECLARE FUNCTION InsertDisk% (DiskNum, Dest$, TimeOut)
DECLARE FUNCTION Match% (Spec$, FileName$)
DECLARE FUNCTION Signed% (A&)
DECLARE FUNCTION Unsigned& (A)

DIM SHARED Regs AS RegType

'$INCLUDE: 'CWDECL.BI'

FUNCTION ChangeLine% (Drive$)

    'Calls BIOS to determine if Drive$ supports
    'automatic change line detection.

    ChangeLine% = 0                    'Assume it doesn't
    Regs.AX = &H1500
    Regs.DX = ASC(Drive$) - 65         'Convert A=0, B=1, etc.
    CALL InterruptX(&H13, Regs)
    IF (Regs.AX \ 256) = 2 THEN        'If AH = 2, then
       ChangeLine% = -1                '  answer is yes!
    END IF

END FUNCTION

FUNCTION CopyFile% (Src$, Dest$)

    'Copies single file, Src$, to Dest$, in 64K chunks.
    'Src$ and Dest$ may contain paths.

    CALL FCreate(Dest$)                     'Create Dest$
    IF WhichError% GOTO CFDone              'Bail if error
    IF FCount%(Src$) = 0 GOTO CFDone        'Same if Src$ not found

    CALL FOpen(Src$, Src)                   'Open Src$
    CALL FOpen(Dest$, Dest)                 '  and Dest$
    SrcLen& = FLof&(Src)                    'Save length of original file

    Remaining& = SrcLen&                    'Keep track of bytes to be copied
    DO WHILE Remaining& > 0
       Bytes& = 65534                       'Do 64K chunks
       IF Bytes& > Remaining& THEN          'Adjust Bytes& if less than
	  Bytes& = (Remaining& + 1) AND -2  '  64K needs to be copied
       END IF                               ' (Round Bytes& to next-higher
       REDIM Buffer(1 TO Bytes& \ 2)        '  even number)
       CALL FGetA(Src, Buffer(1), Bytes&)   'Get a chunk from Src...
       CALL FPutA(Dest, Buffer(1), Bytes&)  '  and put it to Dest
       IF WhichError% THEN EXIT DO          'Exit if error
       Remaining& = Remaining& - Bytes&     'Adjust Remaining& and
    LOOP                                    '  do it again

    IF WhichError% = 0 THEN
       DestLen& = FLof&(Dest)               'Make sure copy is same
       IF DestLen& <> SrcLen& THEN          '  length as original
	  CALL CWClipFile(Dest, SrcLen&)
       END IF
    END IF

    CALL FClose(Src)                        'Close 'em
    CALL FClose(Dest)

CFDone:
					    'Return error code to
    CopyFile% = WhichError%                 '  calling program

END FUNCTION

SUB CreateDir (DirName$)

    'Creates subdirectory DirName$, regardless
    'of how many levels deep it is.

    CALL FixPath(DirName$)                       'Make sure DirName$ ends
    Length = LEN(DirName$)                       '  with a backslash

    Ptr = INSTR(DirName$, "\") + 1               'Skip first '\'
    DO                                           'Find next one
       Backslash = INSTR(Ptr, DirName$, "\")     'Subdir name is from
       Temp$ = LEFT$(DirName$, Backslash - 1)    '  beginning to current '\'
       CALL MakeDir(Temp$)                       'Create subdir
       Ptr = Backslash + 1                       '  and look for next '\'
    LOOP UNTIL Backslash = Length                'Loop 'til end of DirName$

END SUB

SUB CWBackup (FileSpec$, Dest$, Recurse, ErrCode)

    STATIC Archive
    STATIC ArrayID
    STATIC BackupFile$
    STATIC TempFile$                            'These variables must
    STATIC TempSize&                            '  be preserved thru
    STATIC DirPtr                               '  recursive CALLs
    STATIC DiskNum
    STATIC FileNum
    STATIC Directory() AS CWType

    TimeOut = ErrCode                           'ErrCode contains
    ErrCode = 0                                 '  timeout value

    IF DiskNum = 0 THEN                         'If this is first time thru
       DiskNum = 1                              'First backup disk
       Dest$ = CHR$(ASC(Dest$) AND 223)         'Use only 1st letter of Dest$
       BackupFile$ = Dest$ + ":\CWBACKUP."      '  and convert to uppercase
       GOSUB BackupDisk                         'Prompt for first disk
						 
       Temp$ = ENVIRON$("TEMP")                 'Is there a TEMP variable
       IF LEN(Temp$) = 0 THEN                   '  in the environment?
	  Temp$ = ENVIRON$("TMP")               'No, then how about TMP?
       END IF
      
       Temp = LEN(Temp$)
       IF Temp THEN                             'If so, make sure the
	  CALL FixPath(Temp$)                   '  path ends with a backslash
       ELSE
	  Temp = 67
	  DO                                    'Otherwise, start with drive C
	     Temp$ = CHR$(Temp)
	     CALL CWDiskRoom(Temp$, Free&, Total&)    'Does it have enough
	     IF Free& > TempSize& THEN                '  free space to hold
		Temp$ = Temp$ + ":\"                  '  temp file?
		EXIT DO                               'Use it!
	     ELSE
		Temp = Temp + 1                 'Try the next drive
	     END IF
	  LOOP UNTIL Total& = -1
	  IF Total& = -1 THEN                   'If there's no suitable hard
	     ErrCode = -6                       '  drive for temp file, set
	     GOTO BackupExit                    '  ErrCode and exit
	  END IF
       END IF
       TempFile$ = Temp$ + "$$BACKUP.TMP"       'Temp file name
						'Set Archive = 0 to
       Archive = -1                             '  ignore archive bit
       Recurse = Recurse OR 256                 'Set bit 9 of Recurse
       Elements = FileCount%(FileSpec$, Archive, Recurse)  'Count files in set
       IF Elements = 0 THEN ErrCode = -13: GOTO BackupExit 'Exit if none
       REDIM Directory(1 TO Elements + 1) AS CWType        'Add an element for
    END IF                                                 '  backup directory

    Elements = FCount%(FileSpec$)               'Count files in current dir
    IF Elements THEN                            'If any...
       REDIM Array$(0 TO Elements)              'Create array of proper size
       CALL PrepArray(Array$())                 'Create space in array
       Array$(0) = FileSpec$
       CALL ReadFile(VARPTR(Array$(0)))         'Read file names into Array$()
    END IF

    Spec$ = FileSpec$                           'Use copy so FileSpec$ is not changed
    CALL PathName(Spec$, Path$)                 'Split FileSpec$ into components
    FOR I = 1 TO Elements                       'Loop thru file names
	Src$ = Path$ + RTRIM$(Array$(I))
	IF Archive THEN
	   Attr = GetAttr%(Src$)                'Save this file's attribute
	   IF (Attr AND 32) = 0 GOTO SkipThisFile
	END IF

	GOSUB BackupUI                              'Print screen message
	CALL FOpen(Src$, Handle)                    'Open file
	CALL GetFileDate(Handle, FDate$, FTime$)    'Get file date & time

	DirPtr = DirPtr + 1
	Directory(DirPtr).FilePath = Path$          'Create directory entry
	Directory(DirPtr).FileName = Array$(I)
	Directory(DirPtr).FileDate = FDate$
	Directory(DirPtr).FileTime = FTime$
	Directory(DirPtr).FileSize = FLof&(Handle)
	Directory(DirPtr).DiskNum = DiskNum
	Directory(DirPtr).FileNum = FileNum
	Directory(DirPtr).ArrayNum = ArrayID + 1

	Remaining& = Directory(DirPtr).FileSize     'Keep track of bytes
	DO WHILE Remaining& > 0                     '  to be read
	   Bytes& = 65534                           'Read 64K chunks
	   IF Bytes& > Remaining& THEN              'Read no more than needed
	      Bytes& = (Remaining& + 1) AND -2      'Round Bytes& to next
	   END IF                                   '  higher even number

	   Free& = TempSize& - CWFileSize&(TempFile$)
	   IF Bytes& > Free& THEN                   'If almost full read only
	      Bytes& = ((Free& + 1) AND -2) - 100   '  as many bytes as avail
	      TempFull = -1                         'Set flag so we know
	   END IF                                   '  to copy temp file

	   ArrayID = ArrayID + 1
	   REDIM Buffer(1 TO Bytes& \ 2)
	   CALL FGetA(Handle, Buffer(1), Bytes&)    'Get a chunk and
	   Remaining& = Remaining& - Bytes&         '  adjust Remaining&
	   DO                                       'ErrCode = 0 creates
	      ErrCode = FCount%(TempFile$)          '  new file
	      CALL CWPackArray(Buffer(), ArrayID, TempFile$, ErrCode)
	      Abort = ErrorHandler%(ErrCode)        'Handle errors
	      IF Abort GOTO BackupExit
	   LOOP WHILE ErrCode                       'Track how many arrays
	   Directory(DirPtr).Arrays = Directory(DirPtr).Arrays + 1
						      
	   IF TempFull THEN                         'If TempFull flag is set...
	      DestFile$ = BackupFile$ + Ext$(FileNum)  'Create dest file name
	      DO                                       'Copy temp file to disk
		 ErrCode = CopyFile%(TempFile$, DestFile$)
		 Abort = ErrorHandler%(ErrCode)
		 IF Abort GOTO BackupExit
	      LOOP WHILE ErrCode
	      FileNum = FileNum + 1                 'Increment file number
	      KILL TempFile$                        'Erase TempFile$
	      TempFull = 0                          'Clear TempFull flag

	      CALL CWDiskRoom(Dest$, Free&, Total&) 'Check free space on
	      IF Free& < TempSize& THEN             '  destination disk
		 IF Free& < 16384 THEN              'If < 16K free,
		    DiskNum = DiskNum + 1           '  prompt user for
		    GOSUB BackupDisk                '  next diskette
		    ArrayID = 0
		 ELSE
		    TempSize& = Free& - 100
		 END IF
	      END IF
	   END IF
	LOOP                                    'Loop thru source file
	CALL FClose(Handle)                     'Close it when finished
	IF Archive THEN
	   CALL SetAttr(Src$, Attr AND 223)     'Clear Archive bit
	END IF

SkipThisFile:
    NEXT I
						 
    IF Recurse THEN                             'If Recurse flag is set...
       DirSpec$ = Path$ + "*.*"
       Elements = DCount%(DirSpec$)             'Check for subdirs
       IF Elements THEN                         'If any...
	  REDIM Array$(0 TO Elements)
	  CALL PrepArray(Array$())              'Read subdir names into
	  Array$(0) = DirSpec$                  '  Array$()
	  CALL ReadDir(VARPTR(Array$(0)))       'Loop thru subdirs, calling
	  FOR I = 1 TO Elements                 '  CWBackup with new Spec$
	      ErrCode = TimeOut
	      Temp$ = Path$ + RTRIM$(Array$(I)) + "\" + Spec$
	      CALL CWBackup(Temp$, Dest$, Recurse, ErrCode)
	      IF ErrCode = 255 THEN EXIT FOR    'ErrCode = 255 gets us out
	  NEXT I                                '  of recursion without
       END IF                                   '  displaying redundant
    END IF                                      '  error messages

    IF Abort GOTO BackupExit
    Elements = UBOUND(Directory) - 1            'If DirPtr = number of files
    IF DirPtr = Elements THEN                   '  in backup set, we're done
       IF FCount%(TempFile$) THEN
	  DestFile$ = BackupFile$ + Ext$(FileNum)
	  DO
	     ErrCode = CopyFile%(TempFile$, DestFile$)     'Copy temp file to
	     Abort = ErrorHandler%(ErrCode)                '  diskette
	     IF Abort GOTO BackupExit
	  LOOP WHILE ErrCode
	  KILL TempFile$                        'Erase TempFile$
       END IF

       DestFile$ = BackupFile$ + "001"          'Save dir in first file
       CALL CWDiskRoom(Dest$, Free&, Total&)         'Get free space
       Bytes& = LEN(Directory(1)) * CLNG(Elements)   'How big is Directory()?
       IF Bytes& > Free& THEN                   'If not enough room on current
	  DiskNum = DiskNum + 1                 '  disk, prompt for a new one
	  GOSUB BackupDisk
	  ErrCode = 0                           'Create a new .CWF file
       ELSE
	  ErrCode = -1                          'Append to existing file
	  IF CWFileSize&(DestFile$) = 0 THEN
	     ErrCode = ErrCode + 1
	  END IF
       END IF                                       'Create a directory entry
						    '  for Directory() so
       DirPtr = DirPtr + 1                          '  CWRestore can know for
       Directory(DirPtr).FileName = "CWBACKUP.DIR"  '  sure what the last
       Directory(DirPtr).DiskNum = DiskNum          '  disk number is
						      
       DO
	  ArrayID = 0                           'Save Directory() as array zero
	  CALL CWPackArray(Directory(), ArrayID, DestFile$, ErrCode)
	  Abort = ErrorHandler%(ErrCode)
	  IF Abort THEN EXIT DO
       LOOP WHILE ErrCode
       DirPtr = 0
    END IF

BackupExit:
    IF Abort THEN
       ErrCode = 255
       IF FCount%(TempFile$) THEN
	  KILL TempFile$
       END IF
    END IF
    EXIT SUB

BackupUI:
    '==================== Your user interface here ====================
      PRINT Src$
    '==================================================================
    RETURN

BackupDisk:
    Abort = InsertDisk%(DiskNum, Dest$, TimeOut)      'Wait for new disk
    IF Abort GOTO BackupExit
    TempSize& = 362496
    FileNum = 1
    RETURN

END SUB

SUB CWClipFile (Handle, Length&) STATIC

     'Clips size of file belonging to
     'Handle to Length& bytes.

     Regs.AX = &H4200                            'Move file pointer
     Regs.BX = Handle                            '  to offset Length&
     Regs.CX = Signed%(Length& \ 65536)
     Regs.DX = Signed%(Length& AND 65535)
     CALL InterruptX(&H21, Regs)

     Regs.AX = &H4000                            'Write zero bytes
     Regs.BX = Handle                            '  (sets new size)
     Regs.CX = 0
     CALL InterruptX(&H21, Regs)

END SUB

FUNCTION CWCurDir$ STATIC

    'Returns current directory

    DIM Buffer AS STRING * 64                    'Create 64-byte Buffer$

    Regs.DX = 0                                  'Current drive
    Regs.AX = &H4700                             'Get current dir
    Regs.SI = VARPTR(Buffer$)                    'Point to Buffer$
    Regs.DS = VARSEG(Buffer$)
    CALL InterruptX(&H21, Regs)
    Temp = INSTR(Buffer$, CHR$(0)) - 1           'Look for terminating null
    CWCurDir$ = CWGetDrive$ + ":\" + LEFT$(Buffer$, Temp) + "\"
						 'Return complete path name
END FUNCTION

SUB CWDiskRoom (Drive$, Free&, Total&) STATIC

     'Return total space and available space
     'of disk in Drive$. (Assumes Drive$ is
     'uppercase, since CWBackup and CWRestore
     'capitalize it).

     Regs.AX = &H3600
     Regs.DX = ASC(Drive$) - 64                     'Convert A=1, B=2, etc.
     CALL InterruptX(&H21, Regs)
     IF Regs.AX = &HFFFF THEN                       'Error!
	Free& = -1
	Total& = -1
     ELSE                                           'AX = sectors-per-cluster
	Free& = CLNG(Regs.AX) * Regs.CX * Regs.BX   'BX = available clusters
	Total& = CLNG(Regs.AX) * Regs.CX * Regs.DX  'BX = bytes-per-sector
     END IF                                         'DX = total clusters

END SUB

FUNCTION CWFileSize& (FileName$) STATIC

     'Returns size of FileName$.

     CALL FOpen(FileName$, Handle)          'Open file
     IF WhichError% THEN
	CWFileSize& = 0                     'Return 0 if no file
     ELSE
	CWFileSize& = FLof&(Handle)         'Get length and
	CALL FClose(Handle)                 '  close file
     END IF

END FUNCTION

FUNCTION CWGetDrive$ STATIC

    'Gets current drive from DOS, and returns it
    'as uppercase drive letter.

    Regs.AX = &H1900
    CALL InterruptX(&H21, Regs)
    CWGetDrive$ = CHR$((Regs.AX AND 255) + 65)   'Convert 0=A, 1=B, etc.

END FUNCTION

SUB CWRestore (FileSpec$, Dest$, Recurse, ErrCode)

    TimeOut = ErrCode                           'ErrCode contains the timeout
    IF TimeOut = 0 THEN TimeOut = TimeOut + 1   ' value on entry
    ErrCode = 0                                 'Clear ErrCode assuming success
						'Convert FileSpec$ into
    Src$ = CHR$(ASC(FileSpec$) AND 223)         '  uppercase drive letter
    BackupFile$ = Src$ + ":\CWBACKUP."          'Name of source file
   
    DiskNum = 0                                 'Prompt user to insert
    GOSUB RestoreDisk                           '  last diskette
    REDIM Directory(1 TO 1) AS CWType
    SrcFile$ = BackupFile$ + Ext$(FileNum)

    DO                                          'Decompress directory
       CALL CWUnpackArray(Directory(), 0, SrcFile$, ErrCode)
       Abort = ErrorHandler%(ErrCode)           'Handle errors
       IF Abort GOTO RestoreExit
    LOOP WHILE ErrCode

    Elements = UBOUND(Directory)                'Size of Directory()
    DiskNum = Directory(Elements).DiskNum       'Current disk number
						 
    Spec$ = FileSpec$                           'Make copy of FileSpec$
    IF LEN(Spec$) = 1 THEN                      'If Spec$ is drive letter
       Spec$ = Spec$ + ":\"                     '  only, make it legal
    END IF
    CALL PathName(Spec$, BasePath$)             'Split Spec$ into components
    IF LEN(Spec$) = 0 THEN Spec$ = "*.*"        'If no file spec, use '*.*'
    IF LEN(BasePath$) < 4 THEN                        'If no path, use first
       BasePath$ = RTRIM$(Directory(1).FilePath)      '  path of backup set
    ELSE                                              'Change drive letter to
       MID$(BasePath$, 1) = CHR$(ASC(Directory(1).FilePath))  'backup drive
    END IF
    BaseLen = LEN(BasePath$) + 1                'Save length of starting path
						 
    Temp$ = Dest$
    IF INSTR(Temp$, "\") THEN                   'Ensure that path ends
       CALL FixPath(Temp$)                      '  with a backslash
    END IF                                      'Extract starting pathname
    CALL PathName(Temp$, Path$)                 '  from Temp$
    IF LEN(Path$) = 0 THEN                      'Use BasePath$ if no path
       Path$ = BasePath$                        '  specified by user
       MID$(Path$, 1) = CHR$(ASC(Dest$) AND 223)      'Change drive letter to
    END IF                                            '  destination drive
						 
    ErrCode = -13                               'Assume no matching files
    FOR I = 1 TO Elements - 1                   'Loop thru Directory()
	GOSUB TestPath                          'File path match BasePath$?
	IF PathsMatch THEN                      'If so...
	   IF Match%(Spec$, Directory(I).FileName) THEN   'Filename match Spec$?
	      IF Directory(I).DiskNum <> DiskNum THEN     'Change disk if
		 DiskNum = Directory(I).DiskNum           '  necessary
		 GOSUB RestoreDisk
	      END IF
						 'See if Dest$ is root directory
	      Dest$ = Path$ + RTRIM$(MID$(Directory(I).FilePath, BaseLen))
	      Temp = LEN(Dest$)                  'If not...
	      IF Temp > 3 THEN                   'Create subdirs as needed
		 Temp$ = LEFT$(Dest$, Temp - 1)
		 IF DCount%(Temp$) = 0 THEN CALL CreateDir(Dest$)
	      END IF
	      Dest$ = Dest$ + RTRIM$(Directory(I).FileName)

	      ErrCode = WhichError%             'Handle errors
	      IF ErrCode THEN
		 Abort = ErrorHandler%(ErrCode)
		 IF Abort GOTO RestoreExit
	      END IF

	      GOSUB RestoreUI                   'Print filename for user
	      CALL FCreate(Dest$)               'Create and open dest file
	      CALL FOpen(Dest$, Handle)
	      FileNum = Directory(I).FileNum
	      ArrayID = Directory(I).ArrayNum
	      Remaining = Directory(I).Arrays
					      
	      DO WHILE Remaining                'Decompress arrays and
		 REDIM Buffer(1 TO 1)           '  append to dest file
		 DO
		    SrcFile$ = BackupFile$ + Ext$(FileNum)
		    CALL CWUnpackArray(Buffer(), ArrayID, SrcFile$, ErrCode)
		    IF ErrCode = -16 THEN
		       FileNum = FileNum + 1    'Next file
		       IF FCount%(BackupFile$ + Ext$(FileNum)) = 0 THEN
			  ArrayID = 1
			  DiskNum = DiskNum + 1 'Next disk
			  GOSUB RestoreDisk
		       END IF
		    ELSEIF ErrCode THEN
		       Abort = ErrorHandler%(ErrCode)
		       IF Abort GOTO RestoreExit
		    ELSE
		       CALL FPutA(Handle, Buffer(1), UBOUND(Buffer) * 2&)
		       Remaining = Remaining - 1
		    END IF
		 LOOP WHILE ErrCode
		 ArrayID = ArrayID + 1
	      LOOP                              'Make sure new file is
						'  same size as original
	      IF FLof&(Handle) <> Directory(I).FileSize THEN
		 CALL CWClipFile(Handle, Directory(I).FileSize)
	      END IF
	      CALL SetFileDate(Handle, Directory(I).FileDate, Directory(I).FileTime)
	      CALL FClose(Handle)
	   END IF
	END IF
    NEXT

RestoreExit:
    IF Abort THEN ErrCode = 255
    EXIT SUB

RestoreDisk:
    Abort = InsertDisk%(DiskNum, Src$, -TimeOut)
    IF Abort GOTO RestoreExit
    FileNum = 1
    RETURN

RestoreUI:

    '==================== Your user interface here ====================
      PRINT Dest$
    '==================================================================
    RETURN

TestPath:
    PathsMatch = 0                              'Assume paths don't match
    IF Recurse THEN                             'If Recurse is true, file path
       IF INSTR(Directory(I).FilePath, BasePath$) THEN  'must simply contain
	  PathsMatch = -1                               '  BasePath$
       END IF                                   'Otherwise they must be equal
    ELSEIF RTRIM$(Directory(I).FilePath) = BasePath$ THEN
       PathsMatch = -1
    END IF
    RETURN

END SUB

FUNCTION DiskFormat% (Drive$)

    'Attempts to format diskette in Drive$ to highest
    'capacity allowed by the diskette drive.

    REDIM Buffer(1 TO 2340)                 'Buffer for FAT
    Drive = ASC(Drive$) - 65                'Convert A=0, B=1, etc.
    DriveType = GetDisketteType%(Drive)

    DO
       SELECT CASE DriveType
	  CASE 1                            '360K
	     Capacity = 360
	  CASE 2                            '1.2M
	     Capacity = 1200
	  CASE 3                            '720K
	     Capacity = 720
	  CASE 4                            '1.44M
	     Capacity = 1440
	  CASE ELSE                         'Unknown drive type
       END SELECT

       Temp = FormatDiskette%(Drive, Capacity, Buffer(1))
       IF Temp = 11 THEN                              'If bad sectors...
	  CALL CWDiskRoom(Drive$, Free&, Total&)      'Is disk at least
	  IF Free& < (Capacity * 3192&) \ 4 THEN      '  75% usable?
	     Temp = Temp - 1                          'If not, try again
	  END IF
       END IF
       IF Temp = 10 THEN                    'If disk is bad...
	  IF (DriveType AND 1) = 0 THEN     '  and DriveType is even...
	     DriveType = DriveType - 1      'Knock it down one notch
	  ELSE                              '  and try again
	     EXIT DO                        'Loop 'til DriveType is
	  END IF                            '  an odd number
       END IF
    LOOP UNTIL Temp = 0
    DiskFormat% = Temp

END FUNCTION

FUNCTION ErrorHandler% (ErrCode) STATIC

    'Prints message corresponding to ErrCode, and
    'waits for user to press a key. Returns -1 if
    'Esc is pressed, 0 for any other key.
    
    IF NOT BeenHere THEN
       BeenHere = -1
       '$INCLUDE: 'ERRCODES.BI'
       CWMsg$(-16) = "Wrong diskette"
    END IF

    ErrorHandler% = 0                       'Assume everything's OK
    SELECT CASE ErrCode
      'CASE 0
	  'No error, shown for clarity, add "success" statements if you want
       CASE 128
	  Msg$ = "Warning: Data on this disk will be erased!"
       CASE 255
	  ErrCode = 0
	  ErrorHandler% = -1
       CASE -10
	  Msg$ = CWCritMsg$(CWCritErr%)
       CASE -18 TO -1
	  Msg$ = CWMsg$(ErrCode)
       CASE ELSE
	  Msg$ = ErrorMsg$(ErrCode)
    END SELECT
    
    IF ErrCode THEN
       '==================== Your user interface here ====================
	 BEEP: PRINT Msg$
	 PRINT "Press Esc to quit, any other key to continue..."
	 PRINT

	 DO: LOOP WHILE LEN(INKEY$)              'Clear keyboard buffer
	 A$ = INPUT$(1)
	 IF ASC(A$) = 27 THEN
	    ErrorHandler% = -1
	 END IF
       '==================================================================
    END IF

END FUNCTION

FUNCTION Ext$ (FileNum) STATIC

    'Returns FileNum as three-byte zero-padded string
    'to be used as extension for backup file.

    Ext$ = RIGHT$("00" + LTRIM$(STR$(FileNum)), 3)

END FUNCTION

FUNCTION FileCount% (FileSpec$, Archive, Recurse)

    'Counts number of files matching FileSpec$,
    'recursing subdirectories if Recurse <> 0.
    'If Archive is non-zero, only files with
    'archive bit set are included.

    STATIC NumFiles

    IF Recurse AND 256 THEN                 'If bit 9 is set,
       NumFiles = 0                         'Initialize NumFiles
       Recurse = Recurse AND 255            '  and clear bit 9 for
    END IF                                  '  future iterations

    Spec$ = FileSpec$                       'Count files in current
    Temp = FCount%(Spec$)                   '  directory
    IF WhichError% GOTO FCExit
   
    CALL PathName(Spec$, Path$)             'Split FileSpec$ into components
    IF LEN(Path$) = 0 THEN                  'If no Path$ use current dir
       Path$ = CWCurDir$
       FileSpec$ = Path$ + Spec$
    END IF

    IF Archive THEN                         'Include only those with
       REDIM Array$(0 TO Temp)              '  archive bit set
       CALL PrepArray(Array$())
       Array$(0) = FileSpec$
       CALL ReadFile(VARPTR(Array$(0)))
       FOR I = 1 TO Temp
	   Attr = GetAttr%(Path$ + RTRIM$(Array$(I)))
	   IF (Attr AND 32) THEN NumFiles = NumFiles + 1
       NEXT
    ELSE
       NumFiles = NumFiles + Temp
    END IF
						 
    IF Recurse THEN
       DirSpec$ = Path$ + "*.*"
       NumDirs = DCount%(DirSpec$)               'Count subdirs
       IF NumDirs THEN
	  REDIM Array$(0 TO NumDirs)
	  CALL PrepArray(Array$())               'Make room in Array$()
	  Array$(0) = DirSpec$                   'Read subdir names
	  CALL ReadDir(VARPTR(Array$(0)))        '  into Array$()
	  FOR I = 1 TO NumDirs
	      Temp$ = Path$ + RTRIM$(Array$(I)) + "\" + Spec$
	      NumFiles = FileCount%(Temp$, Archive, Recurse)
	  NEXT I                                 'Call FileCount for each
       END IF                                    '  subdirectory
    END IF

FCExit:                                          'Return cumulative
    FileCount% = NumFiles                        '  file count

END FUNCTION

SUB FixPath (Path$)

    'This SUB does nothing more than append a trailing
    'backslash to Path$ if it doesn't have one.

    IF MidChar%(Path$, LEN(Path$)) <> 92 THEN
       Path$ = Path$ + "\"
    END IF

END SUB

SUB GetFileDate (Handle, FDate$, FTime$)

    'Gets a file's date and time from DOS, and
    'returns it as a packed 3-byte string.

    Regs.AX = &H5700
    Regs.BX = Handle
    CALL InterruptX(&H21, Regs)

    Temp& = Unsigned&(Regs.CX)
    Hr = Temp& \ 2048
    Min = (Temp& MOD 2048) \ 32
    Sec = ((Temp& MOD 2048) MOD 32) * 2
    FTime$ = CHR$(Hr) + CHR$(Min) + CHR$(Sec)

    Temp& = Unsigned&(Regs.DX)
    Yr = Temp& \ 512 + 80
    Mnth = (Temp& MOD 512) \ 32
    Dat = (Temp& MOD 512) MOD 32
    FDate$ = CHR$(Yr) + CHR$(Mnth) + CHR$(Dat)

END SUB

FUNCTION InsertDisk% (DiskNum, Drive$, Seconds)

    STATIC ChgLine                              'These variables must be
    STATIC BeenHere                             '  preserved between calls
						 
    IF NOT BeenHere THEN                        'First visit?
       BeenHere = -1                            'Not anymore!
       ChgLine = ChangeLine(Drive$)             'See if target drive
    END IF                                      '  supports change line

    IF Seconds < 0 THEN                         'If Seconds is negative,
       Restoring = -1                           '  we're restoring
       Seconds = ABS(Seconds)                   'Force Seconds positive
       GOSUB InsertMsg                          'Prompt user if restoring
    END IF

    DO: LOOP WHILE LEN(INKEY$)                  'Clear keyboard buffer
    Regs.DX = ASC(Drive$) - 65                  'Convert target drive to
						'  digit: A=0, B=1, etc.
    DO
       A$ = INKEY$                              'Test for keypress
       IF ChgLine THEN
	  Regs.AX = &H1600                      'See if disk has been changed
	  CALL InterruptX(&H13, Regs)
	  IF (Regs.Flags AND 1) THEN EXIT DO    'If so, call service 17h
						'  to reset diskette status
	  IF Restoring THEN                     'Ignore change line on
	     IF DiskNum = 0 THEN                '  first disk of set
		EXIT DO
	     END IF
	  ELSEIF DiskNum = 1 THEN
	     EXIT DO
	  END IF
       END IF
       IF NOT Prompt THEN GOSUB InsertMsg
    LOOP UNTIL LEN(A$)
						 
    Result = 0
    StopTime& = PDQTimer& + (Seconds * 18)      'Calculate stop time
    Volume$ = "CWB" + Ext$(DiskNum)             'Build volume label

    DO
       IF Restoring THEN                        'If restoring...
	  Temp$ = GetVol$(Drive$)               'Get volume label
	  Temp$ = RTRIM$(Temp$)                 'trim any trailing spaces
	  Result = WhichError%                  'Loop again if error
	  SELECT CASE Result
	     CASE 0                             'If no error then...
		IF DiskNum THEN                       'If DiskNum <> 0 then...
		   IF Temp$ <> Volume$ THEN           'Check volume label
		      Result = ErrorHandler%(-16)     'Wrong disk!
		      IF Result = 0 THEN Result = 1   'Loop again
		   END IF
		END IF
	     CASE 71
		'Ignore until timeout
	     CASE ELSE
		Result = ErrorHandler%(Result)  'Display error msg
		IF Result = 0 THEN Result = 1   'Loop again
	  END SELECT
       ELSE
	  Temp$ = Drive$ + ":\*.*"
	  Temp = FileCount%(Temp$, 0, -1)       'Does disk contain data?
	  Result = WhichError%                  'Loop again if error
	  SELECT CASE Result
	     CASE 0, 53                         'No error, or file not found
		IF Temp THEN                    'Warn user about existing data
		   Temp = ErrorHandler%(128)
		   Result = Temp
		END IF
		IF Temp = 0 THEN
		   CALL WipeDisk(Drive$)              'Erase disk
		   CALL PutVol(Drive$, Volume$)       'Put new volume label
		   Result = ErrorHandler%(WhichError%)
		END IF
	     CASE 57                            'Disk not formatted
		GOSUB FormatMsg
		Temp = DiskFormat%(Drive$)
	     CASE 71                            'Drive not ready
		'Ignore until timeout
	     CASE ELSE                          'Other error
		Result = ErrorHandler%(WhichError%)
		IF Result = 0 THEN Result = 1
	     END SELECT
       END IF
       IF Result = 71 THEN                      'Drive not ready
	  IF PDQTimer& >= StopTime& THEN        'If Seconds have passed,
	     Result = ErrorHandler%(Result)     'Error message
	     IF Result = 0 THEN Result = 1      'Loop again
	  ELSE
	     SLEEP 1                            'Wait a sec, then
	  END IF                                '  try again
       END IF
    LOOP UNTIL Result < 1                       'Loop 'til Result = 0 or -1
    InsertDisk% = Result
    EXIT FUNCTION

FormatMsg:
    '==================== Your user interface here ====================
      PRINT "Formatting diskette..."
    '==================================================================
    RETURN

InsertMsg:
    '==================== Your user interface here ====================
       PRINT : BEEP
       IF DiskNum THEN
	  PRINT "Insert disk number"; DiskNum; "in drive "; Drive$; "."
       ELSE
	  PRINT "Insert last diskette in drive "; Drive$; "."
       END IF
       'This PC doesn't support the changeline switch. Prompt for new disk.
       IF NOT ChgLine THEN PRINT "Press any key to continue..."
    '==================================================================
    Prompt = -1: RETURN

END FUNCTION

FUNCTION Match% (Spec$, FileName$)

    'Determines whether or not FileName$ matches
    'Spec$ (which may contain wildcards).

    Temp = -1                                    'Assume they match
    Spec$ = RTRIM$(UCASE$(Spec$))                'Trim and capitalize
    FileName$ = RTRIM$(UCASE$(FileName$))        '  both strings
    NameLen = LEN(FileName$)                     'Save lengths of
    SpecLen = LEN(Spec$)                         '  parameters
					       
    SpecPtr = 1: NamePtr = 1                     'Start at first char
    IF MidChar%(Spec$, SpecPtr) <> 42 THEN       'If first char of Spec$
       DO WHILE SpecPtr <= SpecLen               '  is not '*'...
	  Char = MidChar%(Spec$, SpecPtr)        'Compare one char at a time
	  IF Char = 46 THEN EXIT DO              'Exit when we hit a '.'
	  IF MidChar%(FileName$, NamePtr) <> Char THEN     'If they don't match,
	     IF Char <> 63 THEN                            '  and Spec$ doesn't
		Temp = 0                                   '  have a '?'...
		EXIT DO                          'No match!
	     END IF
	  ELSE
	     SpecPtr = SpecPtr + 1               'Check the next char
	     NamePtr = NamePtr + 1
	  END IF
       LOOP
    ELSE                                         'If Spec$ starts with '*'...
       SpecPtr = SpecPtr + 1                     'Look at extension
       Period = INSTR(FileName$, ".")            'If no period, then there's
       IF Period = 0 THEN Period = LEN(FileName$)     'no extension, so point
       NamePtr = Period + 1                           'at end of string
    END IF

    SpecPtr = SpecPtr + 1
    IF Temp THEN                                 'If strings still match...
       IF MidChar%(Spec$, SpecPtr) <> 42 THEN    'Check extension for '*'
	  DO WHILE SpecPtr <= SpecLen            'If not, do the one-at-a-
	     Char = MidChar%(Spec$, SpecPtr)     '  time thang
	     IF MidChar%(FileName$, NamePtr) <> Char THEN
		IF Char <> 63 THEN
		   Temp = 0
		   EXIT DO
		END IF
	     ELSE
		SpecPtr = SpecPtr + 1
		NamePtr = NamePtr + 1
	     END IF
	  LOOP
       ELSE
	  NamePtr = NameLen
       END IF
    END IF
    IF NamePtr < NameLen THEN                    'If we reach the end of Spec$
       Temp = 0                                  '  before the end of FileName$,
    END IF                                       '  then names don't match
    Match% = Temp

END FUNCTION

SUB PathName (FileSpec$, Path$)

    'Given full file spec in FileSpec$, returns path
    'portion in Path$, and remainder in FileSpec$.

    FileSpec$ = UCASE$(FileSpec$)                'Make uppercase
    FOR I = LEN(FileSpec$) TO 1 STEP -1          'Walk backwards looking
	IF MidChar%(FileSpec$, I) = 92 THEN      '  for a backslash
	   EXIT FOR
	END IF
    NEXT

    IF I THEN                                    'If found...
       Path$ = LEFT$(FileSpec$, I)               'Path$ is everything left
       IF INSTR(Path$, ":") = 0 THEN             '  of the special char
	  Path$ = CWGetDrive$ + ":" + Path$      'Append drive letter if
       END IF                                    '  needed
       FileSpec$ = MID$(FileSpec$, I + 1)        'FileSpec$ is everything
    ELSE                                         '  after the '\'
       Path$ = ""                                'If no path, return
    END IF                                       '  FileSpec$ unchanged

END SUB

SUB PrepArray (Array$())

    'Clears space in all elements of Array$()
    'for file or directory names.

    IF LEN(Temp$) = 0 THEN
       Temp$ = STRING$(12, 32)
    END IF
    FOR I = 1 TO UBOUND(Array$)
	Array$(I) = Temp$
    NEXT

END SUB

SUB SetFileDate (Handle, FDate$, FTime$)

    'Accepts desired date and time as packed 3-byte strings,
    'and calls DOS to adjust file associated with Handle.

    Hr = MidChar%(FTime$, 1)
    Min = MidChar%(FTime$, 2)
    Sec = MidChar%(FTime$, 3)

    Yr = MidChar%(FDate$, 1)
    Mnth = MidChar%(FDate$, 2)
    Dat = MidChar%(FDate$, 3)

    Regs.AX = &H5701
    Regs.BX = Handle
    Regs.CX = Signed%(Hr * 2048& + Min * 32 + Sec \ 2)
    Regs.DX = Signed%((Yr - 80) * 512& + Mnth * 32 + Dat)
    CALL InterruptX(&H21, Regs)

END SUB

FUNCTION Signed% (A&) STATIC

    'Converts unsigned integer to signed equivalent.

    IF A& > 32767 THEN
       Signed% = A& - 65536
    ELSE
       Signed% = A&
    END IF

END FUNCTION

FUNCTION Unsigned& (A) STATIC

    'Converts signed integer to unsigned equivalent.

    IF A < 0 THEN
       Unsigned& = A + 65536
    ELSE
       Unsigned& = A
    END IF

END FUNCTION

SUB WipeDisk (Drive$) STATIC

    'Erases all data on a diskette by clearing both FATs and root directory.
    'Note: This routine doesn't really overwrite the entire disk as its name
    'implies -- the data is still there, but DOS can't find it.

    DIM Zero AS STRING * 512
    DIM DirSect AS STRING * 512
    MID$(DirSect$, 1, 3) = "ýÿÿ"            'FD FF FF -- DO NOT TOUCH!

    CALL CWDiskRoom(Drive$, Free&, Total&)
    SELECT CASE Total&
       CASE 362496                          '360K
	  FAT = 4                           '  No. of FAT sectors
	  Root = 7                          '  Sectors in root dir
	  Sectors = 9                       '  Sectors per track
       CASE 730112                          '720K
	  FAT = 10
	  Root = 7
	  Sectors = 9
       CASE 1213952                         '1.2M
	  FAT = 14
	  Root = 14
	  Sectors = 15
       CASE 1457664                         '1.44M
	  FAT = 18
	  Root = 14
	  Sectors = 18
       CASE ELSE                            'Unknown format
    END SELECT

    IF FAT THEN                             'If disk is formatted...
       Regs.DS = -1                         'Overwrite sectors with Zero$
       Regs.ES = VARSEG(Zero$)
       Regs.BX = VARPTR(Zero$)
       Drive = ASC(Drive$) - 65                  'Assumes uppercase Drive$
       FOR I = 1 TO (FAT + Root)
	   GOSUB SetRegs
	   CALL InterruptX(&H13, Regs)
	   IF (Regs.Flags AND 1) THEN EXIT FOR   'Error!
       NEXT
       IF (Regs.Flags AND 1) = 0 THEN            'Write DirSect$ to first
	  I = 1                                  '  sector of each FAT
	  Regs.ES = VARSEG(DirSect$)
	  Regs.BX = VARPTR(DirSect$)
	  GOSUB SetRegs
	  CALL InterruptX(&H13, Regs)

	  I = FAT \ 2 + 1
	  GOSUB SetRegs
	  CALL InterruptX(&H13, Regs)
       END IF
    END IF
    EXIT SUB

SetRegs:
    Regs.AX = &H301                              'Translates DOS sector
    Track = I \ (Sectors * 2)                    '  number (I) into BIOS
    Sect = (I MOD Sectors) + 1                   '  side/track/sector
    Regs.CX = Track * 256& + Sect                '  coordinates, and
    Side = (I \ Sectors) MOD 2                   '  loads registers for
    Regs.DX = Side * 256 + Drive                 '  BIOS call
    RETURN

END SUB

