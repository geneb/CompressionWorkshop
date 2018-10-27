'********** DEMOSIZE.BAS - demonstrates the CWPackedSize function

DEFINT A-Z
DECLARE FUNCTION CWPackedSize& (FileName$, ErrCode)

'$INCLUDE: 'ERRCODES.BI'

NewSize& = CWPackedSize&("CWSHOP.LIB", ErrCode)
IF ErrCode THEN
  PRINT "Error "; ErrCode; "occurred: "; CWMsg$(ErrCode)
ELSE
  PRINT "The compressed file size will be"; NewSize&; "bytes"
END IF

CALL CWReleaseMem(Zero)

