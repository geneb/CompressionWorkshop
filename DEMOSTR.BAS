'********** DEMOSTR.BAS - demonstrates compressing strings in memory
'
'Copyright (c) 1992 Fred Sexton Jr.

DEFINT A-Z
'$INCLUDE: 'ERRCODES.BI'                'defines the ErrCode strings

CLS
FOR X = 1 TO 100
 Test$ = Test$ + "abcdefghijklmn"       'create a long string
NEXT

PRINT Test$
PRINT
PRINT "This string uses"; LEN(Test$); "bytes"   'display its length

Save$ = Test$                                   'for testing only, not needed
CALL CWPackStringM(Test$, ErrCode)              'compress the string
IF ErrCode THEN
  PRINT CWMsg$(ErrCode)                         'display any error
  END                                           'and don't try to unpack it!
END IF

PRINT "It compressed to"; LEN(Test$); "bytes"   'display the new length
PRINT "The string can be decompressed whenever it is needed again"

CALL CWUnpackStringM(Test$, ErrCode)
IF ErrCode THEN PRINT CWMsg$(ErrCode)           'display any error
IF Test$ <> Save$ THEN PRINT "Error: no match"  'prove it worked

CALL CWReleaseMem(1)                            'release the memory

