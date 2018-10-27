'*********** CWDECL.BI - Declarations for the Compression Workshop

'Copyright (c) 1992 Fred Sexton, Jr.


'----- Compression Workshop routines
'
DECLARE SUB CWArray2Scrn (Segment%, Address%, NumBytes%, Array() AS ANY)
DECLARE SUB CWDelArray (FileName$, ArrayID%, ErrCode%)
DECLARE SUB CWDelFile (FileName$, Spec$, ErrCode%)
DECLARE SUB CWMakeExt (FileName$, Buffer$, ErrCode%)
DECLARE SUB CWReadNames (FileName$, TypeArray() AS ANY, ErrCode%)
DECLARE SUB CWReleaseMem (Mode%)
DECLARE SUB CWSetMaxSize (MaxSize&)
DECLARE SUB CWPackArray (Array() AS ANY, ArrayID%, FileName$, ErrCode%)
DECLARE SUB CWPackArrayM (Array() AS ANY, ErrCode%)
DECLARE SUB CWPackFiles (Spec$, Dest$, Cmt$, ErrCode%)
DECLARE SUB CWPackFilesD (Spec$, Dest$, Cmt$, Tim$, Dat$, ErrCode%)
DECLARE SUB CWPackStrArray(Array$(), ArrayID%, FileName$, ErrCode%)
DECLARE SUB CWPackStrArrayM(SArray$(), IArray%(), ErrCode%)
DECLARE SUB CWPackStringM (Work$, ErrCode%)
DECLARE SUB CWScrn2Array (Segment%, Address%, NumBytes%, Array() AS ANY)
DECLARE SUB CWUnpackArray (Array() AS ANY, ArrayID%, FileName$, ErrCode%)
DECLARE SUB CWUnpackArrayM (Array() AS ANY, ErrCode%)
DECLARE SUB CWUnpackStrArray(Array$(), ArrayID%, FileName$, ErrCode%)
DECLARE SUB CWUnpackStrArrayM(Array$(), ArrayID%, FileName$, ErrCode%)
DECLARE SUB CWUnpackStringM (Work$, ErrCode%)
DECLARE SUB CWUnpackFiles (FileName$, DSpec$, ErrCode%)
DECLARE SUB CWUnpackFilesD (FileName$, Spec$, ErrCode%)
DECLARE SUB CWUpdate (FileName$, TempFile$, ErrCode%)

DECLARE FUNCTION CWCritErr% ()
DECLARE FUNCTION CWPackedSize& (FileName$, ErrCode%)


'----- QuickPak Professional routines included with the Compression Workshop
'
DECLARE SUB FClose (Handle%)
DECLARE SUB FCreate (FileName$)
DECLARE SUB FGetA (Handle%, SEG Buffer AS ANY, Bytes&)
DECLARE SUB FOpen (FileName$, Handle%)
DECLARE SUB FPutA (Handle%, SEG Buffer AS ANY, Bytes&)
DECLARE SUB InterruptX (IntNum%, Regs AS ANY)
DECLARE SUB MakeDir (DirName$)
DECLARE SUB PutVol (Drive$, Volume$)
DECLARE SUB ReadDir (BYVAL Address%)
DECLARE SUB ReadFile (BYVAL Address%)
DECLARE SUB SetAttr (FileName$, Attr%)

DECLARE FUNCTION DCount% (FileSpec$)
DECLARE FUNCTION ErrorMsg$ (ErrNo%)
DECLARE FUNCTION Exist% (FileSpec$)
DECLARE FUNCTION FCount% (FileSpec$)
DECLARE FUNCTION FLof& (Handle%)
DECLARE FUNCTION FormatDiskette% (Drive%, Capacity%, SEG Buffer AS ANY)
DECLARE FUNCTION GetAttr% (FileName$)
DECLARE FUNCTION GetDisketteType% (Drive%)
DECLARE FUNCTION GetVol$ (Drive$)
DECLARE FUNCTION MidChar% (Work$, Position%)
DECLARE FUNCTION PDQTimer& ()
DECLARE FUNCTION ReadTest% (Drive$)
DECLARE FUNCTION WhichError% ()
DECLARE FUNCTION WriteTest% (Drive$)
