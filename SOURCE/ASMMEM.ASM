;********** ASMMEM.ASM
;
;Copyright (c) 1992 Fred Sexton Jr.

OPTION EXPR16
.MODEL MEDIUM ,BASIC
    PUBLIC  work_seg
    PUBLIC  ary_wseg
    PUBLIC  cg_try_cont
    PUBLIC  cgfs_max
    
.DATA
    work_seg     WORD 0
    ary_wseg     WORD 0
    cg_try_cont  WORD 0
    cgfs_max     WORD 2  dup (0)
    
END
