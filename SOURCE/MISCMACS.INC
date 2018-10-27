;********** MISCMACS.INC - miscellaneous CW Shop macros
;
;Copyright (c) 1992 Fred Sexton Jr.
;far strings mods by Ethan Winer

B$SETM       PROTO
B$RDIM       PROTO
B$SPAC       PROTO
B$SASS       PROTO
B$LEFT       PROTO
cw_opnit     PROTO
acmps_main   PROTO
acmps_main2  PROTO
adcmp_main   PROTO
adcmp_main2  PROTO
fcmp_main    PROTO
fdcmp_main   PROTO
cw_crit_hdlr PROTO

EXTERNDEF    work_seg:WORD
EXTERNDEF    ary_wseg:WORD
EXTERNDEF    cg_try_cont:WORD
EXTERNDEF    cgfs_max:WORD
EXTERNDEF    old_crit:WORD
EXTERNDEF    crit_er:WORD

;installs critical error handler
hook_crit    MACRO
    mov     crit_er,0
    mov     ax,3524h
    int     21h
    mov     old_crit,bx
    mov     old_crit+2,es
    mov     dx,OFFSET CW_crit_hdlr
    mov     ax,SEG CW_crit_hdlr
    mov     ds,ax
    mov     ax,2524h
    int     21h
    mov     ax,@data
    mov     ds,ax
ENDM

;removes critical error handler
unhook_crit  MACRO  ecd_ptr:REQ
    mov     ax,@data
    mov     ds,ax
    mov     dx,old_crit
    mov     ax,old_crit+2
    mov     ds,ax
    mov     ax,2524h
    int     21h
    mov     ax,@data
    mov     ds,ax
    .IF     crit_er != 0
    mov     bx,ecd_ptr
    mov     WORD PTR [bx],-10
    .ENDIF
ENDM

Chek_crit  MACRO
    pushf
    push    bx
    mov     bx,OFFSET crit_er
    .IF     WORD PTR ss:[bx] == 0
    pop     bx
    popf
    .ELSE
    pop     bx
    popf
    stc
    .ENDIF
ENDM

;set DTA - sets DTA to DS:add_r
s_dta  MACRO add_r:REQ
IFDIFI   <add_r>,<0>
  IFDIFI   <add_r>,<dx>
    mov     dx,add_r
  ENDIF
ELSE
    xor     dx,dx
ENDIF
    mov     ah,1AH
    int     21h
ENDM

;get DTA - returns DTA in ES:BX
g_dta   MACRO
    mov     ah,2FH
    int     21h
ENDM

;create file - creates normal file using name at DS:add_r
;handle returned in bx
create_f  MACRO  add_r:REQ,e_val:REQ,e_loc:REQ
IFDIFI   <add_r>,<0>
  IFDIFI   <add_r>,<dx>
    mov     dx,add_r
  ENDIF
ELSE
    xor     dx,dx
ENDIF
    xor     cx,cx
    mov     ah,3CH
    int     21h
    Chek_crit
    .IF     CARRY?
    mov     ax,e_val
    jmp     e_loc
    .ENDIF

    mov     bx,ax
ENDM

;open file #1 - opens file using name at DS:add_r for read
;handle returned in bx
open_r  MACRO add_r:REQ,e_val:REQ,e_loc:REQ
IFDIFI   <add_r>,<0>
  IFDIFI   <add_r>,<dx>
    mov     dx,add_r
  ENDIF
ELSE
    xor     dx,dx
ENDIF
    mov     ax,3D00H
    int     21h
    Chek_crit
    .IF     CARRY?
    mov     ax,e_val
    jmp     e_loc
    .ENDIF
    mov     bx,ax
ENDM

;open file #2 - opens file using name at DS:add_r for read/write
;handle returned in bx
open_rw  MACRO  add_r:REQ,e_val:REQ,e_loc:REQ
IFDIFI   <add_r>,<0>
  IFDIFI   <add_r>,<dx>
    mov     dx,add_r
  ENDIF
ELSE
    xor     dx,dx
ENDIF
    mov     ax,3D02H
    int     21h
    Chek_crit
    .IF     CARRY?
    mov     ax,e_val
    jmp     e_loc
    .ENDIF
    mov     bx,ax
ENDM

;close file -closes file
;(handle must be in bx)
close_f MACRO
    mov     ah,3EH
    int     21h
ENDM

;read file - reads file to buffer at DS:add_r
;(handle must be in bx)
read_f  MACRO   byt_s:REQ,add_r:REQ,e_val:REQ,e_loc:REQ
IFDIFI   <byt_s>,<cx>
    mov     cx,byt_s
ENDIF
IFDIFI   <add_r>,<0>
  IFDIFI   <add_r>,<dx>
    mov     dx,add_r
  ENDIF
ELSE
    xor     dx,dx
ENDIF
    mov     ah,3FH
    int     21h
    Chek_crit
    .IF     CARRY?
    mov     ax,e_val
    jmp     e_loc
    .ENDIF
    .IF     ax == 0
    mov     ax,e_val
    jmp     e_loc
    .ENDIF
ENDM

;write file - writes data at DS:add_r to file
;(handle must be in bx)
write_f  MACRO  byt_s:REQ,add_r:REQ,e_val:REQ,e_loc:REQ,wrtg_cg
IFDIFI   <byt_s>,<cx>
    mov     cx,byt_s
ENDIF
IFDIFI   <add_r>,<0>
  IFDIFI   <add_r>,<dx>
    mov     dx,add_r
  ENDIF
ELSE
    xor     dx,dx
ENDIF
    mov     ah,40H
    int     21h
    Chek_crit
    .IF     CARRY?
    mov     ax,e_val
    jmp     e_loc
    .ENDIF
    .IF     ax != cx
    mov     ax,-9
    jmp     e_loc
    .ENDIF
IFNB  <wrtg_cg>
    mov     cx,cg_maxxl
    mov     dx,cg_maxxh
    .IF     cx !=0 || dx != 0
    .IF     cg_totwh > dx
    mov     ax,-9
    jmp     e_loc
    .ELSEIF cg_totwh == dx
    .IF     cg_totwl >= cx
    mov     ax,-9
    jmp     e_loc
    .ENDIF
    .ENDIF
    .ENDIF
ENDIF

ENDM

;delete file - deletes file name at DS:add_r
delete_f  MACRO  add_r:REQ,e_val:REQ,e_loc:REQ
IFDIFI   <add_r>,<0>
  IFDIFI   <add_r>,<dx>
    mov     dx,add_r
  ENDIF
ELSE
    xor     dx,dx
ENDIF
    mov     ah,41H
    int     21h
    Chek_crit
    .IF     CARRY?
    mov     ax,e_val
    jmp     e_loc
    .ENDIF
ENDM

;set file pointer - sets the file pointer
;(handle must be in bx)
s_fptr  MACRO  ls_w:REQ,ms_w:REQ,m_de:REQ,e_val:REQ,e_loc:REQ
IFDIFI   <ls_w>,<0>
  IFDIFI   <ls_w>,<dx>
    mov     dx,ls_w
  ENDIF
ELSE
    xor     dx,dx
ENDIF
IFDIFI   <ms_w>,<0>
  IFDIFI   <ms_w>,<cx>
    mov     cx,ms_w
  ENDIF
ELSE
    xor     cx,cx
ENDIF
IFDIFI   <m_de>,<0>
  IFDIFI   <m_de>,<al>
    mov     al,m_de
  ENDIF
ELSE
    xor     al,al
ENDIF
    mov     ah,42H
    int     21h
    Chek_crit
    .IF     CARRY?
    mov     ax,e_val
    jmp     e_loc
    .ENDIF

ENDM

;allocate memory for file cmp&dcmp routine work area
get_mem  MACRO  e_val:REQ,e_loc:REQ
    mov     ax,2530H
    mov     dx,0FFFFH
    push    dx
    push    ax
    call    B$SETM
    mov     ah,48H
    mov     bx,3500
    int     21h
    .IF     CARRY?
    mov     ax,e_val
    jmp     e_loc
    .ENDIF
    mov     work_seg,ax
    mov     cg_try_cont,0
ENDM


;converts time & date string to DOS integer format
cnvrt_td  MACRO  e_val:REQ,e_loc:REQ

IFNDEF PDS                      ;this is the near strings code
    mov     bx,tyme
    mov     ax,[bx]
    .IF     ax != 8
    mov     ax,e_val
    jmp     e_loc
    .ENDIF
    mov     si,[bx+2]
    mov     al,[si]
    sub     al,48
    mov     cl,10
    mul     cl
    mov     ah,[si+1]
    sub     ah,48
    add     al,ah
    mov     cl,3
    shl     al,cl
    mov     dh,al               ;convert hrs
    xor     dl,dl
    mov     al,[si+3]
    sub     al,48
    mov     cl,10
    mul     cl
    mov     ah,[si+4]
    sub     ah,48
    add     al,ah
    xor     ah,ah
    mov     cl,5
    shl     ax,cl
    or      dx,ax               ;convert mins
    mov     al,[si+6]
    sub     al,48
    mov     cl,10
    mul     cl
    mov     ah,[si+7]
    sub     ah,48
    add     al,ah
    shr     al,1
    or      dl,al               ;convert secs
    mov     es:[tyme_loc],dx    ;time int is in dx

ELSE                            ;this is the far strings code
    Mov     SI,tyme
    Call    StringInfo          ;returns AX=address, CX=length, DX=segment
    Cmp     CX,8
    Je      @F
    Mov     AX,e_val
    Jmp     e_loc
@@:
    Push    DS
    Mov     DS,DX
    Mov     SI,AX
    mov     al,[si]
    sub     al,48
    mov     cl,10
    mul     cl
    mov     ah,[si+1]
    sub     ah,48
    add     al,ah
    mov     cl,3
    shl     al,cl
    mov     dh,al               ;convert hrs
    xor     dl,dl
    mov     al,[si+3]
    sub     al,48
    mov     cl,10
    mul     cl
    mov     ah,[si+4]
    sub     ah,48
    add     al,ah
    xor     ah,ah
    mov     cl,5
    shl     ax,cl
    or      dx,ax               ;convert mins
    mov     al,[si+6]
    sub     al,48
    mov     cl,10
    mul     cl
    mov     ah,[si+7]
    sub     ah,48
    add     al,ah
    shr     al,1
    or      dl,al               ;convert secs
    mov     es:[tyme_loc],dx    ;time int is in dx
    Pop     DS
ENDIF


IFNDEF PDS                      ;this is the near strings code
    mov     bx,dyte
    mov     ax,[bx]
    .IF     ax != 10
    mov     ax,e_val
    jmp     e_loc
    .ENDIF
    mov     si,[bx+2]
    mov     al,[si+8]
    sub     al,48
    mov     cl,10
    mul     cl
    mov     ah,[si+9]
    sub     ah,48
    add     al,ah
    sub     al,80
    shl     al,1
    mov     dh,al               ;convert yrs
    xor     dl,dl
    mov     al,[si]
    sub     al,48
    mov     cl,10
    mul     cl
    mov     ah,[si+1]
    sub     ah,48
    add     al,ah
    xor     ah,ah
    mov     cl,5
    shl     ax,cl
    or      dx,ax               ;convert mths
    mov     al,[si+3]
    sub     al,48
    mov     cl,10
    mul     cl
    mov     ah,[si+4]
    sub     ah,48
    add     al,ah
    or      dl,al               ;convert days
    mov     es:[dyte_loc],dx    ;date int is in dx

ELSE                            ;this is the far strings code

    Mov     SI,dyte
    Call    StringInfo          ;returns AX=address, CX=length, DX=segment
    Cmp     CX,10
    Je      @F
    Mov     AX,e_val
    Jmp     e_loc
@@:
    Push    DS
    Mov     DS,DX
    Mov     SI,AX
    mov     al,[si+8]
    sub     al,48
    mov     cl,10
    mul     cl
    mov     ah,[si+9]
    sub     ah,48
    add     al,ah
    sub     al,80
    shl     al,1
    mov     dh,al               ;convert yrs
    xor     dl,dl
    mov     al,[si]
    sub     al,48
    mov     cl,10
    mul     cl
    mov     ah,[si+1]
    sub     ah,48
    add     al,ah
    xor     ah,ah
    mov     cl,5
    shl     ax,cl
    or      dx,ax               ;convert mths
    mov     al,[si+3]
    sub     al,48
    mov     cl,10
    mul     cl
    mov     ah,[si+4]
    sub     ah,48
    add     al,ah
    or      dl,al               ;convert days
    mov     es:[dyte_loc],dx    ;date int is in dx
    Pop     DS
ENDIF

ENDM
