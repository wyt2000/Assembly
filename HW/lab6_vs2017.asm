INCLUDE Irvine32.inc
INCLUDE macros.inc
.data
	m32fp REAL4 ?
	ZERO  REAL4 0.0
.code

my_GetChar  PROC 
    call ReadChar   	; get a character from keyboard
    .IF (al == 0dh)		; Enter key?
       call Crlf
    .ELSE
       call WriteChar  	; and echo it back
    .ENDIF
    ret
my_GetChar  ENDP

my_ReadFloat PROC USES eax ebx ecx
.data
sign	BYTE	?
itmp    SDWORD  ?
power   REAL8   ?
ten		REAL8  10.0
.code
    mov  sign,0

    ; look for an optional + or - first
    call my_GetChar
    cmp  al,'+'
    jne  R1
    ; is a '+' -- ignore it; sign= 0
    call my_GetChar
    jmp  R2
R1:
    cmp  al,'-'
    jne  R2
    ; is a '-' -- sign= 1
    call my_GetChar
    inc  sign

    ; here we are done with the optional sign flag
R2:
    ; look for a digit in the mantissa part
    .IF (al >= '0' && al <= '9') || (al == '.')	
      fldz     ; push a 0.  ONE thing in FPU stack
      .WHILE (al >= '0' && al <= '9')
        sub    al,'0'
        and    eax,0Fh
        mov    itmp,eax
        fmul   ten
        fild   itmp
        fadd
        call   my_GetChar
      .ENDW

      ; decimal point in the mantissa?
      .IF (al == '.')
        call my_GetChar
        fldz     ; start the fractional part
        fld   ten  ; get the power part started
        fstp  power  ; will be 10, 100, 1000, etc.
        .WHILE (al >= '0' && al <= '9')
          sub  al,'0'
          and  eax,0Fh
          mov  itmp,eax
          fild itmp
          fdiv power
          fadd
          fld  power
          fmul ten
          fstp power
          call my_GetChar
        .ENDW
        fadd       ; add the front end to the back end
      .ENDIF
    .ELSE
    .ENDIF
      
    ; OK -- now we have the ddd.ddd part in ST(0)
    ; Now look for an exponent
	; We still have the mantissa in the stack:  ONE thing

    .IF (sign == 1)
      fchs
    .ENDIF	  
    ret    	; result should be in FPU top
my_ReadFloat  ENDP

DIV32_10 PROC					;EAX = EAX / 10, EBX = EAX % 10
    .data
	EAX_7_0		BYTE ?
	EAX_15_8	BYTE ?
	EAX_23_16	BYTE ?
	EAX_31_24	BYTE ?
	.code

	MOV EBX, 10

    MOV [EAX_7_0    ],   AL
    MOV [EAX_15_8   ],   AH
    SHR EAX, 16
    MOV [EAX_23_16  ],   AL
    MOV [EAX_31_24  ],   AH

    MOV AX, 0					;EAX[31:24] = EAX[31:24] / 10
    MOV AL, [EAX_31_24]    
    DIV BL
    MOV [EAX_31_24], AL
    
    MOV AL, [EAX_23_16]			;EAX[23:16] = {EAX[31:24] % 10, EAX[23:16]} / 10    
    DIV BL
    MOV [EAX_23_16], AL
    
    MOV AL, [EAX_15_8]      
    DIV BL
    MOV [EAX_15_8], AL
    
    MOV AL, [EAX_7_0]
    DIV BL
    MOV [EAX_7_0], AL
    

    MOV EBX, 0
    MOV BL, AH

    MOV AH,     [EAX_31_24]
    MOV AL,     [EAX_23_16]
    SHL EAX,    16
    MOV AH,     [EAX_15_8 ]
    MOV AL,     [EAX_7_0  ]

    RET
DIV32_10 ENDP



my_WriteFloat PROC USES EAX EBX ECX
.data
thousand	REAL8  1000.0
.code
	mov		sign, 0
	fmul	thousand
	fistp   itmp
	mov		eax, itmp
	cmp		eax, 0
	jge		write_positive
	mov		sign, 1
	not		eax
	add		eax,  1
write_positive:
	mov		ecx, 0
	
write_loop:
	cmp		eax, 0
	je		write_output
	cmp		ecx, 3
	jne		write_pass
	mov		bx, '.'
	push	bx
	add		ecx, 1
write_pass:
	call	DIV32_10
	add		bx, '0'
	push	bx
	add		ecx, 1
	jmp		write_loop

write_output:
	cmp		ecx, 3
	je		digit_3
	cmp		ecx, 2
	je		digit_2
	cmp		ecx, 1
	je		digit_1
	cmp		ecx, 0
	je		digit_0
	jmp		write_sign

digit_3:
	mov		bx, '.'
	push	bx
	mov		bx, '0'
	push	bx
	add		ecx, 2
	jmp		write_sign

digit_2:
	mov		bx, '0'
	push	bx
	mov		bx, '.'
	push	bx
	mov		bx, '0'
	push	bx
	add		ecx, 3
	jmp		write_sign

digit_1:
	mov		bx, '0'
	push	bx
	mov		bx, '0'
	push	bx
	mov		bx, '.'
	push	bx
	mov		bx, '0'
	push	bx
	add		ecx, 4
	jmp		write_sign

digit_0:
	mov		bx, '0'
	push	bx
	mov		bx, '0'
	push	bx
	mov		bx, '0'
	push	bx
	mov		bx, '.'
	push	bx
	mov		bx, '0'
	push	bx
	add		ecx, 5
	jmp		write_sign

write_sign:
	cmp		sign, 0
	je		output_positive
	mov		bx, '-'
	push	bx
	add		ecx, 1
output_positive:
	pop		ax
	call	WriteChar
	loop	output_positive
	ret
my_WriteFloat ENDP

main PROC
	mWrite "Please enter x: "	
    call    my_ReadFloat
	fcom    ZERO
	fnstsw  ax
	sahf
	jae		x_greater_0
    mWrite  "Error: x<0!"
	exit

x_greater_0:
    mWrite "Please enter a1: "		
    call    my_ReadFloat

	mWrite "Please enter a2: "		
    call    my_ReadFloat

	mWrite "Please enter a3: "
    call    my_ReadFloat				
       
	fxch   ST(3)					;ST(0) - ST(3): x, a2, a1, a3
	fst    m32fp					;m32fp = x
	fsqrt							;ST(0) = sqrt(x)
	fmulp  ST(2), ST(0)				;ST(2) = a1 * sqrt(x), pop(x)
	fld	   m32fp					;push(x)
	fyl2x							;ST(1) = a2 * log(x), pop(x)
	fld	   m32fp					;push(x)
	fsin							;ST(0) = sin(x)
	fmulp  ST(3), ST(0)				;ST(3) = a3 * sin(x), pop(x)
	fadd							;ST(0) = ST(0) + ST(1)
	fadd							;ST(0) = ST(0) + ST(1)

    mWrite "The result is: "
	call    my_WriteFloat
    call    Crlf
    exit

main ENDP
END main