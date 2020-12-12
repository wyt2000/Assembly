.MODEL SMALL
.386
DATA SEGMENT
    ZERO        REAL4   0.0
    TEN         REAL4   10.0
    THOUSAND    REAL4   1000.0
    FLOAT_TEMP  REAL4   ?
    POWER       REAL4   ?
    SIGN        DB      ?
    TRANS_TEMP  DD      ?
    EAX_7_0		DB      ?
	EAX_15_8	DB      ?
	EAX_23_16	DB      ?
	EAX_31_24	DB      ?
    INPUTX      DB      'Please input x: $'
    INPUTA1     DB      'Please input a1: $'
    INPUTA2     DB      'Please input a2: $'
    INPUTA3     DB      'Please input a3: $'
    ERRORX      DB      'Error: x<0!$'
    RESULT      DB      'The result is: $'
DATA ENDS

CODE SEGMENT
    ASSUME CS: CODE, DS: DATA

GETCHAR PROC 
    MOV     AH, 01H
    INT     21H
    MOV     AH, 0
    RET
GETCHAR ENDP

PUTCHAR PROC USES EAX EDX
    MOV     DL, AL
    MOV     AH, 02H
    INT     21H
    RET
PUTCHAR ENDP

PRINT_STRING PROC USES EAX
    MOV     AH, 09H
    INT     21H
    RET
PRINT_STRING ENDP

DIV32_10 PROC					    ;EAX = EAX / 10, EBX = EAX % 10
	MOV     EBX, 10

    MOV     EAX_7_0    ,   AL
    MOV     EAX_15_8   ,   AH
    SHR     EAX, 16
    MOV     EAX_23_16  ,   AL
    MOV     EAX_31_24  ,   AH

    MOV     AX, 0					;EAX[31:24] = EAX[31:24] / 10
    MOV     AL, EAX_31_24  
    DIV     BL
    MOV     EAX_31_24, AL
    
    MOV     AL, EAX_23_16			;EAX[23:16] = {EAX[31:24] % 10, EAX[23:16]} / 10    
    DIV     BL
    MOV     EAX_23_16, AL
    
    MOV     AL, EAX_15_8    
    DIV     BL
    MOV     EAX_15_8, AL
    
    MOV     AL, EAX_7_0
    DIV     BL
    MOV     EAX_7_0, AL
    
    MOV     EBX, 0
    MOV     BL, AH

    MOV     AH,     EAX_31_24
    MOV     AL,     EAX_23_16
    SHL     EAX,    16
    MOV     AH,     EAX_15_8 
    MOV     AL,     EAX_7_0  

    RET
DIV32_10 ENDP

READFLOAT PROC USES EAX EBX
    MOV     SIGN, 0
    FLDZ
    CALL    GETCHAR
    CMP     AL, '-'
    JNE     RD_INTEGER
    CALL    GETCHAR
    MOV     SIGN, 1
RD_INTEGER:                         ;ST(0) = 10 * ST(0) + EAX
    CMP     AL, '.'
    JE      RD_FRACTION
    CMP     AL, '0'
    JL      RD_FINISH
    CMP     AL, '9'
    JG      RD_FINISH
    SUB     AL, '0'
    AND     EAX, 0FH
    MOV     TRANS_TEMP, EAX
    FMUL    TEN
    FILD    TRANS_TEMP
    FADD
    CALL    GETCHAR
    JMP     RD_INTEGER
RD_FRACTION:                        ;ST(0) = ST(0) + EAX / POWER, POWER /= 10
    CALL    GETCHAR
    FLDZ
    FLD     TEN
    FSTP    POWER
RD_FRACTION_LOOP:
    CMP     AL, '0'
    JL      RD_FRAC_FINISH
    CMP     AL, '9'
    JG      RD_FRAC_FINISH
    SUB     AL, '0'
    AND     EAX, 0FH
    MOV     TRANS_TEMP, EAX
    FILD    TRANS_TEMP
    FDIV    POWER
    FADD
    FLD     POWER
    FMUL    TEN
    FSTP    POWER
    CALL    GETCHAR
    JMP     RD_FRACTION_LOOP
RD_FRAC_FINISH:
    FADD
RD_FINISH:
    CMP     SIGN, 0
    JE      RD_POSITIVE
    FCHS
RD_POSITIVE:
    RET
READFLOAT ENDP

WRITEFLOAT PROC USES EAX EBX ECX EDX
    MOV     SIGN, 0
    FMUL    THOUSAND
    FISTP   TRANS_TEMP
    MOV     EAX, TRANS_TEMP
    CMP     EAX, 0
    JGE     WRITE_POSITIVE
    MOV     SIGN, 1
    NOT     EAX
    ADD     EAX, 1
WRITE_POSITIVE:
    MOV     ECX, 0

WRITE_LOOP:
    CMP     EAX, 0
    JE      WRITE_OUTPUT
    CMP     ECX, 3
    JNE     WRITE_PASS
    MOV     BX, '.'
    PUSH    BX
    ADD     ECX, 1
WRITE_PASS:
    CALL    DIV32_10
    ADD     BX, '0'
    PUSH    BX
    ADD     ECX, 1
    JMP     WRITE_LOOP

WRITE_OUTPUT:
    CMP     ECX, 3
    JE      DIGIT_3
    CMP     ECX, 2
    JE      DIGIT_2
    CMP     ECX, 1
    JE      DIGIT_1
    CMP     ECX, 0
    JE      DIGIT_0
    JMP     WRITE_SIGN
DIGIT_3:
    MOV     BX, '.'
    PUSH    BX
    MOV     BX, '0'
    PUSH    BX
    ADD     ECX, 2
    JMP     WRITE_SIGN
DIGIT_2:
    MOV     BX, '0'
    PUSH    BX
    MOV     BX, '.'
    PUSH    BX
    MOV     BX, '0'
    PUSH    BX
    ADD     ECX, 3
    JMP     WRITE_SIGN
DIGIT_1:
    MOV     BX, '0'
    PUSH    BX
    MOV     BX, '0'
    PUSH    BX
    MOV     BX, '.'
    PUSH    BX
    MOV     BX, '0'
    PUSH    BX
    ADD     ECX, 4
    JMP     WRITE_SIGN
DIGIT_0:
    MOV     BX, '0'
    PUSH    BX
    MOV     BX, '0'
    PUSH    BX
    MOV     BX, '0'
    PUSH    BX
    MOV     BX, '.'
    PUSH    BX
    MOV     BX, '0'
    PUSH    BX
    ADD     ECX, 5
    JMP     WRITE_SIGN

WRITE_SIGN:
    CMP     SIGN, 0
    JE      OUTPUT_POSITIVE
    MOV     BX, '-'
    PUSH    BX
    ADD     ECX, 1
OUTPUT_POSITIVE:
    POP     AX
    CALL    PUTCHAR
    LOOP    OUTPUT_POSITIVE
    RET
WRITEFLOAT ENDP

MAIN:
    MOV     AX, DATA                ;set DS
    MOV     DS, AX

    MOV     DX, OFFSET INPUTX       ;input x & test x >= 0
    CALL    PRINT_STRING
    CALL    READFLOAT
    FCOM    ZERO
    FNSTSW  AX
    SAHF
    JAE     X_POSITIVE
    MOV     DX, OFFSET ERRORX
    CALL    PRINT_STRING
    JMP     MAIN_RETURN

X_POSITIVE:
    MOV     DX, OFFSET INPUTA1
    CALL    PRINT_STRING
    CALL    READFLOAT
    MOV     DX, OFFSET INPUTA2
    CALL    PRINT_STRING
    CALL    READFLOAT
    MOV     DX, OFFSET INPUTA3
    CALL    PRINT_STRING
    CALL    READFLOAT

    FXCH    ST(3)                   ;ST(0) - ST(3): x, a2, a1, a3
    FST     FLOAT_TEMP              ;m32fp = x
    FSQRT                           ;ST(0) = sqrt(x)
    FMULP   ST(2), ST(0)            ;ST(2) = a1 * sqrt(x), pop(x)
    FLD     FLOAT_TEMP              ;push(x)
    FYL2X                           ;ST(1) = a2 * log(x), pop(x)
    FLD     FLOAT_TEMP              ;push(x)
    FSIN                            ;ST(0) = sin(x)
    FMULP   ST(3), ST(0)            ;ST(3) = a3 * sin(x), pop(x)
    FADDP   ST(1), ST(0)            ;ST(1) = ST(0) + ST(1), pop()
    FADDP   ST(1), ST(0)            ;ST(1) = ST(0) + ST(1), pop()

    MOV     DX, OFFSET RESULT
    CALL    PRINT_STRING
    CALL    WRITEFLOAT

MAIN_RETURN:
    MOV     AH, 4CH             ;return 0
    INT     21H

CODE ENDS
END MAIN