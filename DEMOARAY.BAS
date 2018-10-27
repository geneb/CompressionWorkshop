'********* DEMOARAY.BAS
'
'Copyright (c) 1992 Fred Sexton Jr.
'
'For this demo the data in the arrays will hold 320 x 200 x 256 graphic
'images, and also the associated QuickBASIC palettes.


DEFINT A-Z
'$INCLUDE: 'ERRCODES.BI'

SCREEN 13
REDIM Image(32001)              'this will GET the images (64004) bytes
REDIM Pal&(255)                 'this will hold the palettes (1024 bytes)

FileName$ = "ARAYTEST.CWF"      'name of file to save arrays to
Mode = 1                        'for CWReleaseMem with the array routines

PRINT "Press <1> to create test file"
PRINT "Press <2> to view test file"
DO
  K$ = INKEY$
LOOP UNTIL K$ = "1" OR K$ = "2"
 
IF K$ = "1" THEN                'create a test file

  '---- the next 56 lines simply setup the palette and draw an image
  Z = 23
  FOR T = 1 TO 20
    Pal&(T) = Z: Pal&(T + 20) = Z * 256: Pal&(T + 40) = CLNG(Z * 65536)
    Pal&(T + 60) = (Z * 256) + Z: Pal&(T + 80) = CLNG(Z * 65536) + Z
    Z = Z + 2
  NEXT
  PALETTE USING Pal&(0)

  Clr = 1
  P2 = 39
  FOR P1 = 0 TO 19
    LINE (P1, P1)-(P2, P2), Clr, B
    LINE (P1 + 40, P1 + 40)-(P2 + 40, P2 + 40), Clr, B
    LINE (P1 + 80, P1 + 80)-(P2 + 80, P2 + 80), Clr, B
    LINE (P1 + 120, P1 + 120)-(P2 + 120, P2 + 120), Clr, B
    LINE (P1 + 160, P1 + 160)-(P2 + 160, P2 + 160), Clr, B
    LINE (P1 + 200, P1)-(P2 + 200, P2), Clr, B
    LINE (P1 + 240, P1 + 40)-(P2 + 240, P2 + 40), Clr, B
    LINE (P1 + 280, P1 + 80)-(P2 + 280, P2 + 80), Clr, B
    LINE (P1, P1 + 40)-(P2, P2 + 40), Clr + 20, B
    LINE (P1 + 40, P1 + 80)-(P2 + 40, P2 + 80), Clr + 20, B
    LINE (P1 + 80, P1 + 120)-(P2 + 80, P2 + 120), Clr + 20, B
    LINE (P1 + 120, P1 + 160)-(P2 + 120, P2 + 160), Clr + 20, B
    LINE (P1 + 160, P1)-(P2 + 160, P2), Clr + 20, B
    LINE (P1 + 200, P1 + 40)-(P2 + 200, P2 + 40), Clr + 20, B
    LINE (P1 + 240, P1 + 80)-(P2 + 240, P2 + 80), Clr + 20, B
    LINE (P1 + 280, P1 + 120)-(P2 + 280, P2 + 120), Clr + 20, B
    LINE (P1, P1 + 80)-(P2, P2 + 80), Clr + 40, B
    LINE (P1 + 40, P1 + 120)-(P2 + 40, P2 + 120), Clr + 40, B
    LINE (P1 + 80, P1 + 160)-(P2 + 80, P2 + 160), Clr + 40, B
    LINE (P1 + 120, P1)-(P2 + 120, P2), Clr + 40, B
    LINE (P1 + 160, P1 + 40)-(P2 + 160, P2 + 40), Clr + 40, B
    LINE (P1 + 200, P1 + 80)-(P2 + 200, P2 + 80), Clr + 40, B
    LINE (P1 + 240, P1 + 120)-(P2 + 240, P2 + 120), Clr + 40, B
    LINE (P1 + 280, P1 + 160)-(P2 + 280, P2 + 160), Clr + 40, B
    LINE (P1, P1 + 120)-(P2, P2 + 120), Clr + 60, B
    LINE (P1 + 40, P1 + 160)-(P2 + 40, P2 + 160), Clr + 60, B
    LINE (P1 + 80, P1)-(P2 + 80, P2), Clr + 60, B
    LINE (P1 + 120, P1 + 40)-(P2 + 120, P2 + 40), Clr + 60, B
    LINE (P1 + 160, P1 + 80)-(P2 + 160, P2 + 80), Clr + 60, B
    LINE (P1 + 200, P1 + 120)-(P2 + 200, P2 + 120), Clr + 60, B
    LINE (P1 + 240, P1 + 160)-(P2 + 240, P2 + 160), Clr + 60, B
    LINE (P1 + 280, P1)-(P2 + 280, P2), Clr + 60, B
    LINE (P1, P1 + 160)-(P2, P2 + 160), Clr + 80, B
    LINE (P1 + 40, P1)-(P2 + 40, P2), Clr + 80, B
    LINE (P1 + 80, P1 + 40)-(P2 + 80, P2 + 40), Clr + 80, B
    LINE (P1 + 120, P1 + 80)-(P2 + 120, P2 + 80), Clr + 80, B
    LINE (P1 + 160, P1 + 120)-(P2 + 160, P2 + 120), Clr + 80, B
    LINE (P1 + 200, P1 + 160)-(P2 + 200, P2 + 160), Clr + 80, B
    LINE (P1 + 240, P1)-(P2 + 240, P2), Clr + 80, B
    LINE (P1 + 280, P1 + 40)-(P2 + 280, P2 + 40), Clr + 80, B
    Clr = Clr + 1
    P2 = P2 - 1
  NEXT

  GET (0, 0)-(319, 199), Image  'GET the image to array

  ArrayID = 1
  ErrCode = 0                   'create file
  CALL CWPackArray(Image(), ArrayID, FileName$, ErrCode) 'pack array to file
  GOSUB CheckErr

  ArrayID = 2
  ErrCode = 1                   'append a previously created file
  CALL CWPackArray(Pal&(), ArrayID, FileName$, ErrCode)'pack palette to file
  GOSUB CheckErr

  LOCATE 25, 12
  PRINT "Press any key";
  DO: LOOP UNTIL LEN(INKEY$)

  '---- The next 39 lines simply setup the palette and draw an image
  CLS
  Z = 27
  FOR T = 1 TO 13
    Pal&(T) = Z * 256: Pal&(T + 13) = Z
    Pal&(T + 26) = CLNG(Z * 65536): Pal&(T + 39) = Z * 256 + Z
    Z = Z + 3
   NEXT
  PALETTE USING Pal&(0)

  X1 = 294: X2 = 0: X3 = 269: X4 = 319: X5 = 50: X6 = 25
  Y1 = 0: Y2 = 149: Y3 = 25: Y4 = 124: Y5 = 174: Y6 = 75: Y7 = 199: Y8 = 50
  Clr = 1

  FOR T = 1 TO 25
    LINE (0, Y1)-(X1, Y1), Clr: LINE -(X1, Y2), Clr: LINE -(75, Y2), Clr
    LINE (X2, 199)-(X2, Y3), Clr + 13: LINE -(X3, Y3), Clr + 13
    LINE -(X3, Y4), Clr + 13: LINE -(75, Y4), Clr + 13
    LINE (X4, 0)-(X4, Y5), Clr + 26: LINE -(X5, Y5), Clr + 26
    LINE -(X5, Y6), Clr + 26: LINE -(244, Y6), Clr + 26
    LINE (319, Y7)-(X6, Y7), Clr + 39: LINE -(X6, Y8), Clr + 39
    LINE -(244, Y8), Clr + 39
    X1 = X1 - 1: X2 = X2 + 1: X3 = X3 - 1
    X4 = X4 - 1: X5 = X5 + 1: X6 = X6 + 1
    Y1 = Y1 + 1: Y2 = Y2 - 1: Y3 = Y3 + 1: Y4 = Y4 - 1
    Y5 = Y5 - 1: Y6 = Y6 + 1: Y7 = Y7 - 1: Y8 = Y8 + 1
    IF T < 13 THEN Clr = Clr + 1 ELSE Clr = Clr - 1
  NEXT

  X = 0: X2 = 295: X3 = 319
  Y = 0: Y2 = 199

  FOR T = 1 TO 12
    LINE (X, Y)-(X, 24 - Y), T
    LINE (X + 75, Y + 125)-(X + 75, 149 - Y), T
    LINE (X, Y2)-(24 - X, Y2), T + 13
    LINE (X + 75, 299 - Y2)-(X + 75, Y2 - 75), T + 13
    LINE (X2, Y)-(614 - X2, Y), T + 26
    LINE (539 - X2, Y + 75)-(539 - X2, 99 - Y), T + 26
    LINE (X3, Y2)-(X3, 374 - Y2), T + 39
    LINE (X3 - 75, Y2 - 125)-(X3 - 75, 249 - Y2), T + 39
    X = X + 1: X2 = X2 + 1: X3 = X3 - 1: Y = Y + 1: Y2 = Y2 - 1
  NEXT
  GET (0, 0)-(319, 199), Image          'get the second image

  ArrayID = 3
  ErrCode = 1                           'append previously created file
  CALL CWPackArray(Image(), ArrayID, FileName$, ErrCode) 'pack array to file
  GOSUB CheckErr

  ArrayID = 4
  ErrCode = 1                           'append previously created file
  CALL CWPackArray(Pal&(), ArrayID, FileName$, ErrCode) 'pack palette to file
  GOSUB CheckErr

  LOCATE 25, 12
  COLOR 7
  PRINT "Press any key";
  DO: LOOP UNTIL LEN(INKEY$)

  CLS
  PRINT "image 1 =      64004"
  PRINT
  PRINT "palette 1 =     1024"
  PRINT
  PRINT "image 2 =      64004"
  PRINT
  PRINT "palette 2 =     1024"
  PRINT "             ÄÄÄÄÄÄÄÄ"
  PRINT "total =       130056  bytes"
  PRINT
  PRINT
  PRINT FileName$; " =  17224  bytes"
  PRINT "(17259 modified)"
  PRINT
  PRINT "bytes saved = 112848"
  PRINT
  PRINT "compression  ÷  87%"
  PRINT
  PRINT "NOTE: compression will vary depending on the data"

  LOCATE 25, 12
  PRINT "PRESS ANY KEY";
  DO: LOOP UNTIL LEN(INKEY$)

  ERASE Image
  ERASE Pal&
  CALL CWReleaseMem(Mode)                       'release allocated memory

ELSE                            'display an existing test file

  REDIM Image(0)
  REDIM Pal&(0)

  CLS
  COLOR 7

  ArrayID = 1
  ErrCode = 0                                     'load the array
  CALL CWUnpackArray(Image(), ArrayID, FileName$, ErrCode)
  IF ErrCode = -2 THEN
    PRINT "test file not found - press any key ";
    DO: LOOP UNTIL LEN(INKEY$)
    RUN
  ELSE
    GOSUB CheckErr
  END IF

  ArrayID = 2
  ErrCode = 0                                   'load the palette
  CALL CWUnpackArray(Pal&(), ArrayID, FileName$, ErrCode)
  GOSUB CheckErr

  PALETTE USING Pal&(0)                         'set palette
  PUT (0, 0), Image                             'display image

  LOCATE 25, 12
  COLOR 15
  PRINT "Press any key";
  DO: LOOP UNTIL LEN(INKEY$)

  ArrayID = 3
  ErrCode = 0                                   'load an array
  CALL CWUnpackArray(Image(), ArrayID, FileName$, ErrCode)
  GOSUB CheckErr

  ArrayID = 4
  ErrCode = 0                                   'load the palette
  CALL CWUnpackArray(Pal&(), ArrayID, FileName$, ErrCode)
  GOSUB CheckErr

  CLS
  PALETTE USING Pal&(0)                         'set palette
  PUT (0, 0), Image                             'display image

  LOCATE 25, 12
  COLOR 7
  PRINT "Press any key";
  DO: LOOP UNTIL LEN(INKEY$)

  LOCATE 1, 1
  PRINT "Press <1> to modify test file"
  PRINT "Press <2> to end"
  DO
    K$ = INKEY$
    IF K$ = "1" THEN EXIT DO
    IF K$ = "2" THEN
      CALL CWReleaseMem(1)
      END
    END IF
  LOOP
 
  Z = 27                                        'modify the palette array
  FOR T = 1 TO 13
    Pal&(T) = CLNG(Z * 65536) + Z
    Pal&(T + 13) = CLNG(Z * 65536) + Z * 256
    Pal&(T + 26) = CLNG(Z * 65536) + Z \ 2 * 256 + Z \ 2
    Pal&(T + 39) = CLNG(Z \ 2 * 65536) + Z * 256 + Z \ 2
    Z = Z + 3
  NEXT
  PALETTE USING Pal&(0)                         'set palette


  'Updating a modified array in the compressed file is a two step process
  '1) delete original array from the file
  '2) add modified array to file
 
  ArrayID = 4
  ErrCode = 0
  CALL CWDelArray(FileName$, ArrayID, ErrCode)  'delete existing version
  GOSUB CheckErr

  ArrayID = 4
  ErrCode = 1                                   'append to an existing file
  CALL CWPackArray(Pal&(), ArrayID, FileName$, ErrCode) 'pack palette to file
  GOSUB CheckErr
  CALL CWReleaseMem(Mode)                       'release allocated memory

END IF
END

CheckErr:
  IF ErrCode THEN
    PRINT "Error"; ErrCode; CWMsg$(ErrCode)
    CALL CWReleaseMem(Mode)
    END
  END IF
  RETURN

