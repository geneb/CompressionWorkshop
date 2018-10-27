'******** DOC2HELP.BAS

'Copyright (c) 1993 Ethan Winer

'Doc2Help converts each paragraph (delimited by one or more blank lines) in
'an ASCII text file to individual string "elements" in a compressed file.
'Each paragraph is then retrieved by number using the ReadHelp$() function.
'This function is in a separate file (READHELP.BAS) that can be added to your
'own programs.


DEFINT A-Z
DECLARE FUNCTION ReadHelp$ (HelpFile$, StringNumber)

'$INCLUDE: 'CWDECL.BI'
'$INCLUDE: 'ERRCODES.BI'

INPUT "Enter the name of the ASCII text file to compress: ", InFile$
INPUT "Enter the name of the result compressed file: ", OutFile$

IF INSTR(OutFile$, ".") = 0 THEN        'add .CWF extension if necessary
  OutFile$ = OutFile$ + ".CWF"
END IF

OPEN InFile$ FOR INPUT AS #1            'open the files
OPEN OutFile$ FOR OUTPUT AS #2          'initialize the output file in case
CLOSE #2                                '  it already exists and is too long
OPEN OutFile$ FOR BINARY AS #2          'then reopen it for binary mode
PUT #2, , NumStrings                    'placeholder, filled in later

DO WHILE NOT EOF(1)                     'while there's still input to be read

  LINE INPUT #1, Text$                  'get a line of text
  IF LEN(Text$) THEN                    'not a blank line
    IF LEN(Para$) THEN                  'there's already a sentence present
      Para$ = Para$ + " "               'so add a blank space to separate
    END IF
    Para$ = Para$ + Text$               'build the current paragraph

  ELSEIF LEN(Para$) THEN                'if the previous line was not blank
    DoPack = -1                         'assume string is long enough to pack
    CALL CWPackStringM(Para$, ErrCode)  'try to pack the string
    IF ErrCode THEN                     'an error happened, see which error
      IF ErrCode = -14 THEN             '  -14 is okay, and it simply means
        DoPack = 0                      '  the string is too short to pack
      ELSE                              'another error, clean up and end
        PRINT "Error "; ErrCode; CWMsg$(ErrCode)
        CLOSE
        KILL OutFile$
        END
      END IF
    END IF

    Length = LEN(Para$)                 'get the length of the text
    IF DoPack = 0 THEN Length = -Length 'negative length means its not packed
    PUT #2, , Length                    'write the length into the file
    PUT #2, , Para$                     'then write the paragraph text
    Para$ = ""                          'all done, clear Para$ for next time
    NumStrings = NumStrings + 1         'show we added another help string
  END IF

LOOP

SEEK #2, 1                              'seek to the start of the file
PUT #2, , NumStrings                    'and write the number of strings
CLOSE                                   'close the files

FOR X = 1 TO NumStrings                 'read the file as proof it all worked
  Para$ = ReadHelp$(OutFile$, 0)        '0 means get next successive string
  IF LEN(Para$) THEN                    'if a string was returned
    PRINT Para$                         'print it
  ELSE                                  'else StrNumber holds an error code
    PRINT "Error ";
    IF StrNumber < 0 THEN               'a CWShop error occurred
      PRINT StrNumber; CWMsg$(StrNumber)
    ELSE                                'a positive error code means ReadHelp
      PRINT "Input past end"            '  was asked to get an illegal string
    END IF
  END IF
NEXT

PRINT ReadHelp$("", 0)                  'null file name means close the file
CALL CWReleaseMem(1)                    'release the working memory

