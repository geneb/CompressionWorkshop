'********* DEMOSARA.BAS - demonstrates string array routines (see README)

'Copyright (c) 1992 Crescent Software, Inc.

DEFINT A-Z
CLS

REDIM A$(99)
REDIM B$(99)
REDIM C$(99)

FOR T = 0 TO 95 STEP 5
   A$(T) = "this"
   A$(T + 1) = "is"
   A$(T + 2) = "a"
   A$(T + 3) = "test"
   A$(T + 4) = "string"
NEXT
FOR T = 0 TO 99
   B$(T) = A$(T)
   C$(T) = A$(T)
NEXT


REDIM Tmp(0)
CALL CWPackStrArrayM(A$(), Tmp(), Ecd)
PRINT "M-packed", Ecd

ID = 1
Fln$ = "test.cwf"
Ecd = 0
CALL CWPackStrArray(B$(), ID, Fln$, Ecd)
PRINT "packed", Ecd


REDIM A$(0)
CALL CWUnpackStrArrayM(A$(), Tmp(), Ecd)
PRINT "M-unpacked", Ecd

REDIM B$(0)
Ecd = 0
CALL CWUnpackStrArray(B$(), ID, Fln$, Ecd)
PRINT "unpacked", Ecd


NoErr = -1
FOR T = 0 TO 9
 IF A$(T) <> C$(T) THEN
   PRINT "error a"; T; A$(T)
   NoErr = 0
 END IF
 IF B$(T) <> C$(T) THEN
   PRINT "error b"; T
   NoErr = 0
 END IF
NEXT

IF NoErr THEN PRINT "No Errors"
PRINT "done"

CALL CWReleaseMem(1)

