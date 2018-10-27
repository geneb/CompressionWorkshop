;********* CMPSMACS.INC - bit shuffle macros for compression routines
;
;Copyright (c) 1992 Fred Sexton Jr.

shfl9 MACRO
    mov     si,o_buff_loc
    mov     di,o_buff_loc
    mov     ax,o_buff_ptr
    sub     ax,si
    shr     ax,1
    mov     tmp_var1,ax         ;;code count
    mov     o_buff_ptr,0
smore9:
    mov     ax,[si]
    mov     [di],ax             ;;1st 9 bit code
    add     o_buff_ptr,2
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy9

    mov     ax,[si+2]
    shl     ax,1
    or      [di+1],al
    mov     al,ah
    xor     ah,ah
    mov     [di+2],ax           ;;2nd 9 bit code
    inc     o_buff_ptr
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy9

    mov     ax,[si+4]
    mov     cl,2
    shl     ax,cl
    or      [di+2],ax           ;;3rd 9 bit code
    inc     o_buff_ptr
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy9

    mov     ax,[si+6]
    mov     cl,3
    shl     ax,cl
    or      [di+3],al           ;;4th 9 bit code
    mov     al,ah
    xor     ah,ah
    mov     [di+4],ax
    inc     o_buff_ptr
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy9

    mov     ax,[si+8]
    mov     cl,4
    shl     ax,cl
    or      [di+4],ax           ;;5th 9 bit code
    inc     o_buff_ptr
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy9

    mov     ax,[si+10]
    mov     cl,5
    shl     ax,cl
    or      [di+5],al           ;;6th 9 bit code
    mov     al,ah
    xor     ah,ah
    mov     [di+6],ax
    inc     o_buff_ptr
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy9

    mov     ax,[si+12]
    mov     cl,6
    shl     ax,cl
    or      [di+6],ax           ;;7th 9 bit code
    inc     o_buff_ptr
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy9

    mov     ax,[si+14]
    mov     cl,7
    shl     ax,cl
    or      [di+7],al           ;;8th 9 bit code
    mov     [di+8],ah
    inc     o_buff_ptr
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy9

    add     si,16
    add     di,9
    jmp     smore9

rdy9:

ENDM


shfl10 MACRO

    mov     si,o_buff_loc
    mov     di,o_buff_loc

    mov     ax,o_buff_ptr
    sub     ax,si
    shr     ax,1
    mov     tmp_var1,ax         ;;code count

    mov     o_buff_ptr,0

smore10:

    mov     ax,[si]
    mov     [di],ax             ;;1st 10 bit code
    add     o_buff_ptr,2
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy10

    mov     ax,[si+2]
    mov     cl,2
    shl     ax,cl
    or      [di+1],al
    mov     al,ah
    xor     ah,ah
    mov     [di+2],ax           ;;2nd 10 bit code
    inc     o_buff_ptr
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy10

    mov     ax,[si+4]
    mov     cl,4
    shl     ax,cl
    or      [di+2],ax           ;;3rd 10 bit code
    inc     o_buff_ptr
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy10

    mov     ax,[si+6]
    mov     cl,6
    shl     ax,cl
    or      [di+3],al
    mov     [di+4],ah           ;;4th 10 bit code
    inc     o_buff_ptr
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy10

    add     si,8
    add     di,5
    jmp     smore10

rdy10:

ENDM

shfl11 MACRO

    mov     si,o_buff_loc
    mov     di,o_buff_loc

    mov     ax,o_buff_ptr
    sub     ax,si
    shr     ax,1
    mov     tmp_var1,ax         ;;code count

    mov     o_buff_ptr,0

smore11:

    mov     ax,[si]
    mov     [di],ax             ;;1st 11 bit code
    add     o_buff_ptr,2
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy11

    mov     ax,[si+2]
    mov     cl,3
    shl     ax,cl
    or      [di+1],al
    mov     al,ah
    xor     ah,ah
    mov     [di+2],ax           ;;2nd 11 bit code
    inc     o_buff_ptr
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy11

    mov     ax,[si+4]
    mov     cl,6
    shl     ax,cl
    or      [di+2],ax
    mov     ax,[si+4]
    mov     cl,2
    shr     ax,cl
    mov     al,ah
    xor     ah,ah
    mov     [di+4],ax           ;;3rd 11 bit code
    add     o_buff_ptr,2
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy11

    mov     ax,[si+6]
    shl     ax,1
    or      [di+4],ax           ;;4th 11 bit code
    inc     o_buff_ptr
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy11

    mov     ax,[si+8]
    mov     cl,4
    shl     ax,cl
    or      [di+5],al
    mov     al,ah
    xor     ah,ah
    mov     [di+6],ax           ;;5th 11 bit code
    inc     o_buff_ptr
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy11

    mov     ax,[si+10]
    mov     cl,7
    shl     ax,cl
    or      [di+6],ax
    mov     ax,[si+10]
    shr     ax,1
    mov     al,ah
    xor     ah,ah
    mov     [di+8],ax           ;;6th 11 bit code
    add     o_buff_ptr,2
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy11

    mov     ax,[si+12]
    mov     cl,2
    shl     ax,cl
    or      [di+8],ax           ;;7th 11 bit code
    inc     o_buff_ptr
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy11

    mov     ax,[si+14]
    mov     cl,5
    shl     ax,cl
    or      [di+9],al           ;;8th 11 bit code
    mov     [di+10],ah
    inc     o_buff_ptr
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy11

    add     si,16
    add     di,11

    jmp     smore11

rdy11:

ENDM

shfl12 MACRO
    mov     si,o_buff_loc
    mov     di,o_buff_loc

    mov     ax,o_buff_ptr
    sub     ax,si
    shr     ax,1
    mov     tmp_var1,ax         ;;code count

    mov     o_buff_ptr,0
smore12:

    mov     ax,[si]
    mov     [di],ax             ;;1st 12 bit code
    add     o_buff_ptr,2
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy12

    mov     ax,[si+2]
    mov     cl,4
    shl     ax,cl
    or      [di+1],al
    mov     [di+2],ah           ;;2nd 12 bit code
    inc     o_buff_ptr
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy12

    add     si,4
    add     di,3

    jmp     smore12

rdy12:

ENDM

shfl13 MACRO
    mov     si,o_buff_loc
    mov     di,o_buff_loc

    mov     ax,o_buff_ptr
    sub     ax,si
    shr     ax,1
    mov     tmp_var1,ax         ;;code count

    mov     o_buff_ptr,0
smore13:

    mov     ax,[si]
    mov     [di],ax             ;;1st 13 bit code
    add     o_buff_ptr,2
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy13

    mov     ax,[si+2]
    mov     cl,5
    shl     ax,cl
    or      [di+1],al
    mov     [di+2],ah
    mov     al,[si+3]
    mov     cl,3
    shr     al,cl
    mov     [di+3],al           ;;2nd 13 bit code
    add     o_buff_ptr,2
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy13


    mov     ax,[si+4]
    mov     cl,2
    shl     ax,cl
    or      [di+3],al
    mov     [di+4],ah           ;;3rd 13 bit code
    inc     o_buff_ptr
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy13

    mov     ax,[si+6]
    mov     cl,7
    shl     ax,cl
    or      [di+4],al
    mov     [di+5],ah
    mov     al,[si+7]
    shr     al,1
    mov     [di+6],al           ;;4th 13 bit code
    add     o_buff_ptr,2
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy13

    mov     ax,[si+8]
    mov     cl,4
    shl     ax,cl
    or      [di+6],al
    mov     [di+7],ah
    mov     al,[si+9]
    mov     cl,4
    shr     al,cl
    mov     [di+8],al           ;;5th 13 bit code
    add     o_buff_ptr,2
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy13

    mov     ax,[si+10]
    shl     ax,1
    or      [di+8],al
    mov     [di+9],ah           ;;6th 13 bit code
    inc     o_buff_ptr
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy13

    mov     ax,[si+12]
    mov     cl,6
    shl     ax,cl
    or      [di+9],al
    mov     [di+10],ah
    mov     al,[si+13]
    mov     cl,2
    shr     al,cl
    mov     [di+11],al          ;;7th 13 bit code
    add     o_buff_ptr,2
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy13

    mov     ax,[si+14]
    mov     cl,3
    shl     ax,cl
    or      [di+11],al
    mov     [di+12],ah          ;;8th 13 bit code
    inc     o_buff_ptr
    dec     tmp_var1
    cmp     tmp_var1,0
    je      rdy13

    add     si,16
    add     di,13

    jmp     smore13

rdy13:

ENDM
