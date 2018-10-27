'********* DEMOMEM.BAS - demonstrated compressing memory in place
'
'Copyright (c) 1992 Fred Sexton Jr.

'NOTE: this demo requires a VGA graphics adapter

DEFINT A-Z
'$INCLUDE: 'ERRCODES.BI'                'has the ErrCode strings

SCREEN 13
REDIM Array(6401)                       'dimension array to hold image

'********* The next few lines draw the image *********************
REDIM Pal&(255)
PALETTE USING Pal&(0)                   'hide what we're doing
LINE (0, 0)-(319, 39), 8, B
LINE (1, 1)-(318, 38), 7, B
LINE (2, 2)-(317, 37), 8, B

COLOR 7
LOCATE 2, 8
PRINT "Crescent Software, Inc. Presents"
LOCATE 3, 12
PRINT "The Compression Workshop"
LOCATE 4, 11
PRINT "Written by Fred Sexton Jr."

CIRCLE (21, 20), 15, 1
Pi! = 3.14
CIRCLE (23, 20), 12, 1, (Pi! / 2), (3 * Pi! / 2), 1.25
PAINT (11, 20), 14, 1
PAINT (21, 20), 1

FOR X = 10 TO 41
 FOR Y = 8 TO 32 STEP 2
  IF POINT(X, Y) = 0 THEN PSET (X, Y), 1
 NEXT
NEXT
PALETTE


GET (0, 0)-(319, 39), Array             'get the image
PUT (0, 160), Array                     'display it again

Bytes = (UBOUND(Array) + 1) * 2         'total bytes in the array
LOCATE 10, 1
PRINT "This image normally uses"; Bytes; "bytes."

CALL CWPackArrayM(Array(), ErrCode)     'compress the array in place
IF ErrCode THEN PRINT CWMsg$(ErrCode)

Bytes = (UBOUND(Array) + 1) * 2         'total bytes in the array
                                        'after compression

PRINT "When compressed it uses  "; Bytes; "bytes."
SLEEP 5
LOCATE 13, 1
PRINT "The array can be decompressed whenever"
PRINT "the data is needed again."
SLEEP 5

CALL CWUnpackArrayM(Array(), ErrCode)   'decompress the array in place
IF ErrCode THEN PRINT CWMsg$(ErrCode)

FOR Y = 40 TO 120 STEP 40               'dislay restored image
 PUT (0, Y), Array, PSET                'multiple times
NEXT
CALL CWReleaseMem(1)                    'release memory used

SLEEP 10

