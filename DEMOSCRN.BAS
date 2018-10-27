'*********** SCRN2ARY.BAS
'
'Copyright (c) 1992 Fred Sexton Jr.

DEFINT A-Z
'$INCLUDE: 'ERRCODES.BI'                'has all the error codes

COLOR 14
CLS
PRINT "°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°";
PRINT "°±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±°";
PRINT "°±±²±±°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°±±²±±°";
PRINT "°±±²±±°                  ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»        °±±²±±°";
PRINT "°±±²±±°                //º                                    //º        °±±²±±°";
PRINT "°±±²±±°              //  º                                  //  º        °±±²±±°";
PRINT "°±±²±±°            //    º                                //    º        °±±²±±°";
PRINT "°±±²±±°          //      º                              //      º        °±±²±±°";
PRINT "°±±²±±°        ÉÍÍÍÍÍÍÍÍÍºÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»         º        °±±²±±°";
PRINT "°±±²±±°        º         º                            º         º        °±±²±±°";
PRINT "°±±²±±°        º         º                            º         º        °±±²±±°";
PRINT "°±±²±±°        º         º                            º         º        °±±²±±°";
PRINT "°±±²±±°        º         º                            º         º        °±±²±±°";
PRINT "°±±²±±°        º         º                            º         º        °±±²±±°";
PRINT "°±±²±±°        º         º                            º         º        °±±²±±°";
PRINT "°±±²±±°        º         ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍºÍÍÍÍÍÍÍÍÍ¼        °±±²±±°";
PRINT "°±±²±±°        º       //                             º       //         °±±²±±°";
PRINT "°±±²±±°        º     //                               º     //           °±±²±±°";
PRINT "°±±²±±°        º   //                                 º   //             °±±²±±°";
PRINT "°±±²±±°        º //                                   º //               °±±²±±°";
PRINT "°±±²±±°        ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼                  °±±²±±°";
PRINT "°±±²±±°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°±±²±±°";
PRINT "°±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± PRESS ANY KEY ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±°";
PRINT "°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°";

DO: LOOP WHILE INKEY$ = ""

REDIM Array(1999)                       'create a 4000 byte array
DEF SEG = 0                             'see if mono or color video segment
ScrnSeg = &HB800                        'assume color
IF PEEK(&H463) = &HB4 THEN
  ScrnSeg = &HB000                      'wrong, it's mono
END IF
Address = 0                             'offset for page 0
Bytes = 4000                            'page size

CALL CWScrn2Array(ScrnSeg, Address, Bytes, Array()) 'copy to the array
CALL CWPackArrayM(Array(), ErrCode)                 'then compress the array
IF ErrCode THEN PRINT CWMsg$(ErrCode)               'report errors if any

CLS
PRINT "This screen can be saved in"; (UBOUND(Array) + 1) * 2; "bytes."
PRINT "It can be decompressed and restored whenever needed."
PRINT "Press any key"
DO: LOOP WHILE INKEY$ = ""

CALL CWUnpackArrayM(Array(), ErrCode)               'decompress the array
IF ErrCode THEN PRINT CWMsg$(ErrCode)               'report errors if any

CALL CWArray2Scrn(ScrnSeg, Address, Bytes, Array()) 'copy back to screen
DO: LOOP WHILE INKEY$ = ""
CALL CWReleaseMem(1)                    'release memory

