'********** DATETIME.BAS - FixDate and FixTime functions

'Copyright (c) 1992 Crescent Software, Inc.

DEFINT A-Z
DECLARE FUNCTION FixDate$ (AnyDate$)
DECLARE FUNCTION FixTime$ (AnyTime$)

DEF FnPad$ (Number$) = RIGHT$("0" + Number$, 2)

FUNCTION FixDate$ (InDate$) STATIC

  Last = 1
  Flag = 0
  Year$ = ""
  Length = LEN(InDate$)
 
  FOR X = 1 TO Length
    ThisChar = ASC(MID$(InDate$, X, 1))
    IF ThisChar = 45 OR ThisChar = 47 OR X = Length THEN  '"-" or "/" or end
      IF X = Length THEN
        Flag = 1
        Year$ = "19"
      END IF
      Output$ = Output$ + Year$ + FnPad$(MID$(InDate$, Last, X - Last + Flag))
      Last = X + 1
      IF Flag = 0 THEN Output$ = Output$ + "-"
    END IF
  NEXT

  FixDate$ = Output$

END FUNCTION

FUNCTION FixTime$ (InTime$) STATIC

  Last = 1
  Flag = 0
  Length = LEN(InTime$)

  FOR X = 1 TO Length
    ThisChar = ASC(MID$(InTime$, X, 1))
    '----------- dash ----------- slash ---------- colon - end of string
    IF ThisChar = 45 OR ThisChar = 47 OR ThisChar = 58 OR X = Length THEN
      IF X = Length THEN Flag = 1
      Output$ = Output$ + FnPad$(MID$(InTime$, Last, X - Last + Flag))
      Last = X + 1
      IF Flag = 0 THEN Output$ = Output$ + ":"
    END IF
  NEXT

  FixTime$ = Output$


END FUNCTION

