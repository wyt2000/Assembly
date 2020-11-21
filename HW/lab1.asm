DATAS SEGMENT
    INPUT_BUFFER    DB  255             ;size
                    DB  ?               ;char number
                    DB  255  DUP(?)     ;string buffer
    
    INPUT           DB  'INPUT1.TXT$'

    OUTPUT_BUFFER   DB  255               
                    DB  ?                   
                    DB  255  DUP(?)
    
    OUTPUT          DB  'OUTPUT1.TXT$'
DATAS ENDS

CODES SEGMENT
    ASSUME    CS:CODES, DS:DATAS
START:
    MOV  AX, DATAS                      ;set DS
    MOV  DS, AX

    LEA  DX, INPUT_BUFFER               ;read from keyboard
    MOV  AH, 0AH
    INT  21H

    MOV  BL, [INPUT_BUFFER + 1]         ;set string end
    MOV  [BX + INPUT_BUFFER + 2], '$' 

    LEA  DX, INPUT                      ;create INPUT1.TXT
    MOV  CX, 0000H
    MOV  AH, 3CH    
    INT  21H

    MOV  AL, 03H                        ;open INPUT1.TXT
    MOV  AH, 3DH
    INT  21H

    MOV  DX, OFFSET INPUT_BUFFER + 2    ;write INPUT1.TXT
    MOV  BX, AX
    MOV  CL, [INPUT_BUFFER + 1]
    MOV  AH, 40H
    INT  21H

    MOV  AH, 3EH                        ;close INPUT1.TXT
    INT  21H

    LEA  DX, INPUT                      ;open INPUT1.TXT
    MOV  AL, 00H                        
    MOV  AH, 3DH
    INT  21H
    MOV  BX, AX

    MOV  DX, OFFSET OUTPUT_BUFFER + 2   ;read INPUT1.TXT    
    MOV  CL, 1
    MOV  AH, 3FH

READ_LOOP:
    CMP  AX, 0
    JE   READ_FINISH

    MOV  AH, 3FH                        ;recover AH
    INT  21H                            ;read next char

    MOV  SI, DX                         ;convert lowercase
    MOV  CL, [SI]
    CMP  CL, 'a'
    JL   IDLE
    CMP  CL, 'z'
    JG   IDLE
    SUB  CL, 32
    MOV  [SI], CL

IDLE:    
    MOV  CX, 1                          ;recover CX

    ADD  DX, 1
    JMP  READ_LOOP

READ_FINISH:
    MOV  CX, OFFSET OUTPUT_BUFFER + 2
    SUB  DX, CX
    MOV  [OUTPUT_BUFFER + 1], DL

    MOV  SI ,DX
    MOV  [SI + OUTPUT_BUFFER + 2], '$' 

    MOV  AH, 3EH                        ;close INPUT1.TXT
    INT  21H

    MOV  DL, 10                         ;newline
    MOV  AH, 02H
    INT  21H

    LEA  DX, OUTPUT_BUFFER + 2          ;print string
    MOV  AH, 09H
    INT  21H

    LEA  DX, OUTPUT                     ;create OUTPUT1.TXT
    MOV  CX, 0000H
    MOV  AH, 3CH    
    INT  21H

    MOV  AL, 03H                        ;open OUTPUT1.TXT
    MOV  AH, 3DH
    INT  21H

    MOV  DX, OFFSET OUTPUT_BUFFER + 2   ;write OUTPUT1.TXT
    MOV  BX, AX
    MOV  CL, [OUTPUT_BUFFER + 1]
    MOV  AH, 40H
    INT  21H

    MOV  AH, 4CH                        ;return 0
    INT  21H
CODES ENDS
END START