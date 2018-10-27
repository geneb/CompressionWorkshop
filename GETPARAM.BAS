'********* GETPARAM.BAS - retrieves command line parameters for CWPACK/UNPACK

'Copyright (c) 1992 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION GetParam$ (Switch$)

'The GetParam$ function accepts a command line switch such as "/C" and looks
'at COMMAND$ to see if it is present on the command line.  If so, it returns
'either the text that follows the switch (trimmed) or the switch itself if no
'text was entered (the switch was used alone).  In the case of CWPACK.BAS and
'CWUNPACK.BAS, this lets these programs either use the text that was entered,
'or prompt for it if the switch was used alone.  If the specified switch is
'not present at all GetParam$ returns a null string.
'
'When using GetParam$ all switches must be preceded by a forward slash (/);
'you may not use a dash (-) or other delimiter.  This is needed so GetParam$
'can tell if another switch follows, to determine where the text for the
'current switch ends.

FUNCTION GetParam$ (Switch$) STATIC

  IF NOT BeenHere THEN                  'do this only once
    BeenHere = -1
    Cmd$ = COMMAND$
  END IF

  SwitchLen = LEN(Switch$)              'we'll need this later
  USwitch$ = UCASE$(Switch$)            'ensure consistency
  Found = INSTR(UCASE$(Cmd$), USwitch$) 'is this switch present?
  Offset = Found + SwitchLen            'we'll need this later too

  IF Found THEN                         'this switch is present
    TextEnd = INSTR(Offset, Cmd$, "/")  'does another switch follow?
    IF TextEnd THEN                     'another switch follows, it's simple
      Temp$ = MID$(Cmd$, Offset, TextEnd - Offset)
    ELSE
      Temp$ = MID$(Cmd$, Offset)        'no other switch, return through end
    END IF
    Temp$ = LTRIM$(RTRIM$(Temp$))       'either way, trim the text
    IF Temp$ = "" THEN Temp$ = USwitch$ 'no text, return the switch as a flag
    GetParam$ = Temp$
  ELSE
    GetParam$ = ""                      'no such switch, return a null string
  END IF

END FUNCTION

