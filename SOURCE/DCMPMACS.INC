;********** DCMPMACS.INC - bit shuffle macros for decompression routines
;
;Copyright (c) 1992 Fred Sexton Jr.

unshfl9 MACRO

    mov     si,224
    xor     di,di
    mov     dx,32

unsmore9:

    mov     ax,[si]
    and     ax,1FFH
    mov     [di],ax                 ;;1st code

    mov     ax,[si+1]
    shr     ax,1
    and     ax,1FFH
    mov     [di+2],ax               ;;2nd code

    mov     ax,[si+2]
    mov     cl,2
    shr     ax,cl
    and     ax,1FFH
    mov     [di+4],ax               ;;3rd code

    mov     ax,[si+3]
    mov     cl,3
    shr     ax,cl
    and     ax,1FFH
    mov     [di+6],ax               ;;4th code

    mov     ax,[si+4]
    mov     cl,4
    shr     ax,cl
    and     ax,1FFH
    mov     [di+8],ax               ;;5th code

    mov     ax,[si+5]
    mov     cl,5
    shr     ax,cl
    and     ax,1FFH
    mov     [di+10],ax              ;;6th code

    mov     ax,[si+5]
    mov     cl,5
    shr     ax,cl
    and     ax,1FFH
    mov     [di+10],ax              ;;6th code

    mov     ax,[si+6]
    mov     cl,6
    shr     ax,cl
    and     ax,1FFH
    mov     [di+12],ax              ;;7th code

    mov     ax,[si+7]
    mov     cl,7
    shr     ax,cl
    and     ax,1FFH
    mov     [di+14],ax              ;;8th code

    add     si,9
    add     di,16

    dec     dx
    cmp     dx,0
    je      dn9
    jmp     unsmore9

dn9:

ENDM

unshfl10  MACRO
    mov     si,192
    xor     di,di
    mov     dx,64

unsmore10:

    mov     ax,[si]
    and     ax,3FFH
    mov     [di],ax                 ;;1st code

    mov     ax,[si+1]
    mov     cl,2
    shr     ax,cl
    and     ax,3FFH
    mov     [di+2],ax               ;;2nd code

    mov     ax,[si+2]
    mov     cl,4
    shr     ax,cl
    and     ax,3FFH
    mov     [di+4],ax               ;;3rd code

    mov     ax,[si+3]
    mov     cl,6
    shr     ax,cl
    and     ax,3FFH
    mov     [di+6],ax               ;;4th code

    add     si,5
    add     di,8
    dec     dx
    cmp     dx,0
    jne     unsmore10

ENDM

unshfl11  MACRO
    mov     si,160
    xor     di,di
    mov     dx,32

unsmore11:

    mov     ax,[si]
    and     ax,7FFH
    mov     [di],ax                 ;;1st code

    mov     ax,[si+1]
    mov     cl,3
    shr     ax,cl
    and     ax,7FFH
    mov     [di+2],ax               ;;2nd code

    mov     ax,[si+2]
    mov     cl,6
    shr     ax,cl
    and     ax,7FFH
    mov     [di+4],ax
    mov     al,[si+4]
    and     al,1
    mov     cl,2
    shl     al,cl
    or      [di+5],al               ;;3rd code

    mov     ax,[si+4]
    shr     ax,1
    and     ax,7FFH
    mov     [di+6],ax               ;;4th code

    mov     ax,[si+5]
    mov     cl,4
    shr     ax,cl
    and     ax,7FFH
    mov     [di+8],ax               ;;5th code

    mov     ax,[si+6]
    mov     cl,7
    shr     ax,cl
    and     ax,7FFH
    mov     [di+10],ax
    mov     al,[si+8]
    and     al,3
    shl     al,1
    or      [di+11],al              ;;6th code

    mov     ax,[si+8]
    mov     cl,2
    shr     ax,cl
    and     ax,7FFH
    mov     [di+12],ax              ;;7th code

    mov     ax,[si+9]
    mov     cl,5
    shr     ax,cl
    and     ax,7FFH
    mov     [di+14],ax              ;;8th code


    add     si,11
    add     di,16

    dec     dx
    cmp     dx,0
    je      dn11
    jmp     unsmore11

dn11:

ENDM

unshfl12  MACRO
    mov     si,128
    xor     di,di
    mov     dx,128

unsmore12:

    mov     ax,[si]
    and     ax,0FFFH
    mov     [di],ax                 ;;1st code

    mov     ax,[si+1]
    mov     cl,4
    shr     ax,cl
    and     ax,0FFFH
    mov     [di+2],ax               ;;2nd code

    add     si,3
    add     di,4

    dec     dx
    cmp     dx,0
    jne     unsmore12

ENDM

unshfl13  MACRO
    mov     si,96
    xor     di,di
    mov     dx,32

unsmore13:

    mov     ax,[si]
    and     ax,1FFFH
    mov     [di],ax                 ;;1st code

    mov     ax,[si+1]
    mov     cl,5
    shr     ax,cl
    and     ax,1FFFH
    mov     [di+2],ax
    mov     al,[si+3]
    and     al,3
    mov     cl,3
    shl     al,cl
    or      [di+3],al               ;;2nd code

    mov     ax,[si+3]
    mov     cl,2
    shr     ax,cl
    and     ax,1FFFH
    mov     [di+4],ax               ;;3rd code

    mov     ax,[si+4]
    mov     cl,7
    shr     ax,cl
    and     ax,1FFFH
    mov     [di+6],ax
    mov     al,[si+6]
    and     al,0FH
    shl     al,1
    or      [di+7],al               ;;4th code

    mov     ax,[si+6]
    mov     cl,4
    shr     ax,cl
    and     ax,1FFFH
    mov     [di+8],ax
    mov     al,[si+8]
    and     al,1
    mov     cl,4
    shl     al,cl
    or      [di+9],al               ;;5th code

    mov     ax,[si+8]
    shr     ax,1
    and     ax,1FFFH
    mov     [di+10],ax              ;;6th code

    mov     ax,[si+9]
    mov     cl,6
    shr     ax,cl
    and     ax,1FFFH
    mov     [di+12],ax
    mov     al,[si+11]
    and     al,7
    mov     cl,2
    shl     al,cl
    or      [di+13],al              ;;7th code

    mov     ax,[si+11]
    mov     cl,3
    shr     ax,cl
    and     ax,1FFFH
    mov     [di+14],ax              ;;8th code

    add     si,13
    add     di,16

    dec     dx
    cmp     dx,0
    je      dn13
    jmp     unsmore13

dn13:

ENDM
