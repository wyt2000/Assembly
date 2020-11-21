DATA SEGMENT
     ARRAY DB 200 DUP(?)

DATA ENDS

CODE SEGMENT
     ASSUME CS: CODE, DS: DATA

PUTCHAR MACRO CHAR  ;putchar AH
     PUSH AX
     PUSH DX
     MOV DL, CHAR
     MOV AH, 02H
     INT 21H
     POP DX
     POP AX
ENDM            

PRINT:              ;print DX in decimal
     PUSH AX
     PUSH BX
     PUSH CX
     PUSH DX
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

MAIN:
     MOV AX, DATA   ;set DS
     MOV DS, AX

     MOV AH, 01H    ;input N
     INT 21H
     SUB AL, '0'
     PUTCHAR 10

     AND AH, 0      ;save N and get N^2
     PUSH AX        
     MUL AL         
     MOV CX, AX
     MOV BX, 1

SAVE_NUM:           ;save 1 ~ N^2
     MOV [ARRAY+BX], BL
     INC BX
     LOOP SAVE_NUM     

     MOV CX, AX     ;pop N
     POP AX         
     MOV BX, 1
     MOV DX, 0
     MOV SI, 0      ;EOL
     MOV DI, 1      ;line number

PRINT_NUM:
     CMP SI, DI
     JGE IDLE
     MOV DL, [ARRAY+BX]
     CALL PRINT
     PUTCHAR ' '
IDLE:     
     INC BX
     INC SI
     CMP SI, AX
     JNE PASS
     PUTCHAR 10
     MOV SI, 0
     INC DI
PASS:
     LOOP PRINT_NUM

     MOV AH, 4CH    ;return 0
     INT 21H

CODE ENDS
END MAIN