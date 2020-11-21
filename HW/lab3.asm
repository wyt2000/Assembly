DATAS SEGMENT
    RAW_BUFFER      DW  600             ;raw input buffer size
                    DW  ?               ;number
                    DW  600  DUP(?)     ;buffer

    DATA_BUFFER     DW  105             ;true data buffer
                    DW  ?
                    DW  105  DUP(?)

    INPUT           DB  'INPUT3.TXT$'
DATAS ENDS

CODES SEGMENT
    ASSUME    CS:CODES, DS:DATAS

PUTCHAR MACRO CHAR                      ;putchar AH
     PUSH AX
     PUSH DX
     MOV DL, CHAR
     MOV AH, 02H
     INT 21H
     POP DX
     POP AX
ENDM

PRINT:                                  ;print DX in decimal
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    CMP DX, 0
    JGE NOT_NEGETIVE
    PUTCHAR '-'
    NOT DX
    ADD DX, 1
NOT_NEGETIVE:
    MOV AX, DX
    MOV CX, 0
GET_DIGITS:
    MOV BX, 10
    DIV BL
    ADD AH, '0'
    PUSH AX
    ADD CX, 1
    AND AH, 0
    CMP AL, 0
    JE FIND_ZERO
    JMP GET_DIGITS
FIND_ZERO:
    POP AX
    PUTCHAR AH
    LOOP FIND_ZERO
    POP DX
    POP CX
    POP BX
    POP AX
    RET

CONVERT:                                ;convert [BX...] to DX in decimal, change BX to ' '
    PUSH AX
    PUSH CX
    PUSH SI
    MOV SI, 0
    MOV AL, [BX]    
    CMP AL, '-'
    JNE  POSITIVE
    MOV SI, 1
    ADD BX, 1
POSITIVE:
    MOV CL, 10
    MOV AX, 0
    MOV DX, 0
SET_DIGITS:
    MOV DL, [BX]    
    CMP DL, ' '
    JE  FINISH
    MUL CL
    SUB DL, '0'
    ADD AX, DX
    ADD BX, 1
    JMP SET_DIGITS
FINISH:
    CMP SI, 0
    JE  MINUS
    MOV DX, 0
    SUB DX, AX
    JMP PLUS
MINUS:    
    MOV DX, AX
PLUS:
    POP SI
    POP CX
    POP AX
    RET

SWAP:                                   ;compare and swap [BX] and [BX+1]
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    MOV DX, OFFSET DATA_BUFFER + 2
    ADD BX, DX
    MOV SI, BX
    ADD SI, 2
    MOV AX, [BX]
    MOV CX, [SI]
    CMP CX, AX
    JGE NO_SWAP
    MOV [BX], CX
    MOV [SI], AX
NO_SWAP:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET

PRINT_RESULT:                           ;DX = the number of result * 2
    PUSH BX
    PUSH CX
    PUSH DX
    MOV CX, DX
    SHR CX, 1
    MOV BX, OFFSET DATA_BUFFER + 2
PRINT_LOOP:
    MOV DX, [BX]
    CALL PRINT
    PUTCHAR ' '
    ADD BX, 2
    LOOP PRINT_LOOP
    POP DX
    POP CX
    POP BX
    RET

MAIN:
    MOV AX, DATAS                       ;set DS
    MOV DS, AX

    LEA DX, INPUT                       ;open input file
    MOV AL, 00H
    MOV AH, 3DH
    INT 21H

    MOV BX, AX                          ;read file as ASCII
    MOV DX, OFFSET RAW_BUFFER + 2           
    MOV CX, 550
    MOV AH, 3FH
    INT 21H

    MOV CX, AX
    ADD CX, OFFSET RAW_BUFFER + 1       ;CX = the end of raw buffer
    MOV BX, OFFSET RAW_BUFFER + 2       ;BX = current position in raw buffer
    MOV SI, OFFSET DATA_BUFFER + 2      ;SI = current position in data buffer
STORE_DATA:
    CMP BX, CX
    JG  PASS
    CALL CONVERT
    MOV [SI], DX
    ADD BX, 1
    ADD SI, 2
    JMP STORE_DATA
PASS:
    MOV DX, SI                          ;SI = the end of the data buffer
    SUB DX, OFFSET DATA_BUFFER + 2      ;DX = the number of data * 2

    MOV AX, 0                           ;AX = i
ILOOP:
    CMP AX, DX
    JGE ILOOP_END

    MOV BX, DX                          ;BX = j
    SUB BX, 4
JLOOP:
    CMP BX, AX
    JL  JLOOP_END
    CALL SWAP
    SUB BX, 2
    JMP JLOOP
JLOOP_END:

    ADD AX, 2
    JMP ILOOP
ILOOP_END:

    CALL PRINT_RESULT

    MOV AH, 4CH                        ;return 0
    INT 21H

CODES ENDS
END MAIN