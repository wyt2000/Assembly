.MODEL SMALL
.386
DATA SEGMENT
    EAX_7_0     DB ?
    EAX_15_8    DB ?
    EAX_23_16   DB ?
    EAX_31_24   DB ?
    EDX_7_0     DB ?
    EDX_15_8    DB ?
    EDX_23_16   DB ?
    EDX_31_24   DB ?
DATA ENDS

CODE SEGMENT
    ASSUME CS: CODE, DS: DATA
    
PUTCHAR MACRO CHAR           ;putchar CHAR
    PUSH AX
    PUSH DX
    MOV DL, CHAR
    MOV AH, 02H
    INT 21H
    POP DX
    POP AX
ENDM            

DIV64_10 PROC NEAR         ;{EDX, EAX} = {EDX, EAX} / 10, BL = {EDX, EAX} % 10
    MOV BX, 10

    MOV [EAX_7_0    ],   AL
    MOV [EAX_15_8   ],   AH
    SHR EAX, 16
    MOV [EAX_23_16  ],   AL
    MOV [EAX_31_24  ],   AH
    MOV [EDX_7_0    ],   DL
    MOV [EDX_15_8   ],   DH
    SHR EDX, 16
    MOV [EDX_23_16  ],   DL
    MOV [EDX_31_24  ],   DH

    MOV AX, 0              ;EDX[31:24] = EDX[31:24] / 10
    MOV AL, [EDX_31_24]
    DIV BL
    MOV [EDX_31_24], AL

    MOV AL, [EDX_23_16]    ;EDX[23:16] = {EDX[31:24] % 10, EDX[23:16]} / 10
    DIV BL
    MOV [EDX_23_16], AL

    MOV AL, [EDX_15_8]     
    DIV BL
    MOV [EDX_15_8], AL

    MOV AL, [EDX_7_0]      
    DIV BL
    MOV [EDX_7_0], AL

    MOV AL, [EAX_31_24]      
    DIV BL
    MOV [EAX_31_24], AL
    
    MOV AL, [EAX_23_16]      
    DIV BL
    MOV [EAX_23_16], AL
    
    MOV AL, [EAX_15_8]      
    DIV BL
    MOV [EAX_15_8], AL
    
    MOV AL, [EAX_7_0]
    DIV BL
    MOV [EAX_7_0], AL
    

    MOV BX, 0
    MOV BL, AH

    MOV DH,     [EDX_31_24]
    MOV DL,     [EDX_23_16]    
    SHL EDX,    16
    MOV DH,     [EDX_15_8 ]
    MOV DL,     [EDX_7_0  ]
    MOV AH,     [EAX_31_24]
    MOV AL,     [EAX_23_16]
    SHL EAX,    16
    MOV AH,     [EAX_15_8 ]
    MOV AL,     [EAX_7_0  ]

    RET
DIV64_10 ENDP

PRINT64 PROC NEAR            ;print {EBX, EAX} in decimal
    PUSH EAX
    PUSH EBX
    PUSH ECX
    PUSH EDX
    MOV EDX, EBX
    MOV CX, 0
    MOV BX, 0
GET_DIGITS64:
    CALL DIV64_10
    ADD BL, '0'
    PUSH BX
    ADD CX, 1
    CMP EDX, 0
    JNE GET_DIGITS64
    CMP EAX, 0
    JNE GET_DIGITS64
FIND_ZERO64:
    POP BX
    PUTCHAR BL
    LOOP FIND_ZERO64

    POP EDX
    POP ECX
    POP EBX
    POP EAX
    RET
PRINT64 ENDP

MUL64 PROC NEAR          ;{EBX, EAX} = {EBX, EAX} * ECX
    PUSH EDX
    MUL ECX
    PUSH EAX
    PUSH EDX
    MOV EAX, EBX
    MUL ECX
    MOV EBX, EAX    
    POP EDX
    ADD EBX, EDX
    POP EAX
    POP EDX
    RET
MUL64 ENDP

FACT PROC NEAR           ;{EBX, EAX} = EAX!
    CMP EAX, 0
    JE  FACT_END
    CMP EAX, 1
    JE  FACT_END
    PUSH ECX
    MOV ECX, EAX
    SUB EAX, 1
    CALL FACT
    CALL MUL64
    POP ECX
    RET
FACT_END:
    MOV EBX, 0
    RET
FACT ENDP

READIN PROC NEAR             ;AX = input number
    PUSH BX
    PUSH CX
    MOV AH, 01H
    INT 21H
    MOV AH, 0
    SUB AX, '0'
    PUSH AX
    MOV AH, 01H
    INT 21H    
    CMP AL, '0'
    JL  SINGLE
    CMP AL, '9'
    JG  SINGLE
    PUTCHAR 10
    MOV AH, 0
    SUB AX, '0'
    MOV BX, AX    
    POP AX
    MOV CL, 10
    MUL CL
    ADD AX, BX
    JMP FINISH_RD
SINGLE:
    POP AX
FINISH_RD:
    POP CX
    POP BX
    RET
READIN ENDP

MAIN:
    MOV AX, DATA            ;set DS
    MOV DS, AX

    MOV EAX, 0
    CALL READIN
    CALL FACT
    CALL PRINT64

    MOV AH, 4CH             ;return 0
    INT 21H

CODE ENDS
END MAIN