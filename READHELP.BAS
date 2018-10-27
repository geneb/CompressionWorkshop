'********** READHELP.BAS

'Copyright (c) 1993 Ethan Winer


'The ReadHelp$ function in this file is used to read individual strings from
'a compressed help file.  See DOC2HELP.BAS for a demonstration.


DEFINT A-Z
DECLARE FUNCTION ReadHelp$ (HelpFile$, StringNumber)

'$INCLUDE: 'CWDECL.BI'
'$INCLUDE: 'ERRCODES.BI'

FUNCTION ReadHelp$ (HelpFile$, StrNumber) STATIC

  IF NOT Opened THEN                    'if this is the first call
    Opened = -1                         'show we're now in gear
    FileNum = FREEFILE                  'get the next available file number
    OPEN HelpFile$ FOR BINARY AS #FileNum   'open the help file
    GET #FileNum, , NumStrings              'read and save how many strings
  END IF                                    '  are in the file

  IF LEN(HelpFile$) = 0 THEN            'null file name means close the file
    CLOSE #FileNum
    EXIT FUNCTION
  END IF

  IF StrNumber THEN                     'find this string (else get next one)
    IF StrNumber > NumStrings THEN      'they asked for an impossible string
      ReadHelp$ = ""                    'return a null string to show that
      EXIT FUNCTION                     'exit leaving StrNumber positive to
    END IF                              '  show this error vs. a normal error

    SEEK #FileNum, 3                    'start at beginning, past NumStrings
    FOR X = 2 TO StrNumber              'walk through the file
      GET #FileNum, , Length            'get this string's length
      SEEK #FileNum, SEEK(FileNum) + ABS(Length)  'skip over this string but
    NEXT                                          'ignore negative lengths
  END IF
   
  GET #FileNum, , Length                'read the current string's length
  DoUnpack = -1                         'assume the string was in fact packed
  IF Length < 0 THEN                    'this string was too short to pack
    DoUnpack = 0                        'show we should not try to unpack it
    Length = -Length                    'fix the length
  END IF

  Text$ = SPACE$(Length)                'make a string to hold the text
  GET #FileNum, , Text$                 'read the text
  IF DoUnpack THEN                      'if the string was originally packed
    CALL CWUnpackStringM(Text$, ECode)  'unpack it
  END IF

  ReadHelp$ = Text$                     'either way, return the text

END FUNCTION

