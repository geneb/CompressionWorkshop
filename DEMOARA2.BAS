'************ DEMOARY2.BAS - shows how to use CWReadIDs and CWGetDetails

'Copyright (c) 1992 Crescent Software


DEFINT A-Z
'$INCLUDE: 'CWDECL.BI'
'$INCLUDE: 'ERRCODES.BI'

TYPE ArrayInfo
 ArrayID AS INTEGER
 BytesPerElement AS INTEGER     'returns the length of each element
 ArrayDimensions AS INTEGER     'returns 1 for A(X), 2 for A(X, Y), etc.
END TYPE

CLS
FileName$ = "ARAYTEST.CWF"      'created by first running DEMOARAY.BAS
IF NOT Exist%(FileName$) THEN   'oops!
  PRINT "Please run DEMOARAY.BAS first to create a file."
  END
END IF

REDIM AInfo(1 TO 1) AS ArrayInfo                'establish the array
CALL CWReadIDs(FileName$, AInfo(), ErrCode)     'return the array information
GOSUB CheckError                                'see if there was an error

FOR X = 1 TO UBOUND(AInfo)                      'for each array in the file
  REDIM Details(1 TO AInfo(X).ArrayDimensions)  'create a Details() array
  CALL CWGetDetails(FileName$, AInfo(X).ArrayID, Details(), ErrCode)
  GOSUB CheckError                              'see if there was an error
  
  PRINT "Array ID:"; AInfo(X).ArrayID
  PRINT "Bytes Per Element:"; AInfo(X).BytesPerElement
  PRINT "# of Dimensions:"; AInfo(X).ArrayDimensions

  FOR Y = 1 TO UBOUND(Details)
    PRINT TAB(5); "number of elements:"; Details(Y)
  NEXT

  PRINT
NEXT
END

CheckError:
  IF ErrCode THEN
    PRINT CWMsg$(ErrCode)
    IF ErrCode = -10 THEN PRINT CWCritMsg$(CWCritErr%)
    END
  END IF
  RETURN

