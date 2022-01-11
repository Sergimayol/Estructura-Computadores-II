; =============================================================================
; TITLE    : GRID MANAGEMENT
; AUTHOR   : ANTONI BURGUERA
; HISTORY  : 05-JULY-2021 - CREATION
; COMMENTS : * THERE ARE TWO MATRICES (GRDMATR0 AND GRDMATR1) AND TWO POINTERS
;              TO THESE MATRICES (GRDSRC AND GRDDST).
;
;            * THE MATRIX TO BE PLOTTED IS ALWAYS THE ONE POINTED BY GRDDST.
;
;            * THE MATRIX TO BE UPDATED BY THE MOUSE (GRDMUPD) IS ALWAYS THE
;              ONE POINTED BY GRDDST.
;
;            * THE RULES-UPDATE (GRDRUPD) SWITCHES THE POINTERS AND THEN READS
;              THE NEW SOURCE MATRIX (GRDSRC) TO DETERMINE THE NUMBER OF
;              NEIGHBORS. THE RESULTING CELL VALUE IS WRITTEN TO THE DESTINA-
;              TION MATRIX, POINTED BY GRDDST.
; =============================================================================

; -----------------------------------------------------------------------------
GRDINIT
; INITIALIZE THE GRID AS FOLLOWS:
; * POINTS THE SOURCE GRID POINTER TO GRDMATR0.
; * POINTS THE DESTINATION GRID POINTER TO GRDMATR1.
; * RESETS THE COUNTERS (GRDNPLR1, GRDNPLR2, GRDNGEN).
; * FILLS THE TWO MATRICES (GRDMATR0 AND GRDMATR1) WITH ZEROS.
; INPUT    : NONE
; OUTPUT   : NONE
; MODIFIES : NONE
; -----------------------------------------------------------------------------
            MOVEM.L A0/D0,-(A7)
            MOVE.L  #GRDMATR0,(GRDSRC)
            MOVE.L  #GRDMATR1,(GRDDST)
            CLR.W   (GRDNPLR1)
            CLR.W   (GRDNPLR2)
            CLR.W   (GRDNGEN)
            LEA     GRDMATR0,A0
            MOVE.W  #GRDWIDTH*GRDHEIGH*2-1,D0
.LOOP       CLR.B   (A0)+
            DBRA.W  D0,.LOOP
            MOVEM.L (A7)+,A0/D0
            RTS

; -----------------------------------------------------------------------------
GRDMUPD
; GRID UPDATE USING MOUSE. THE INTERFACE IS AS FOLLOWS:
; * IF MOUSE IS NOT PRESSED OR IS OUTSIDE THE PLOTTED GRID, DOES NOTHING.
; * IF LEFT MOUSE BUTTON IS PRESSED INSIDE THE GRID:
;   - A PLAYER 1 (VALUE=1) CELL IS CREATED AT THE MOUSE POSITION IF THE MOUSE
;     IS ON THE LEFT HALF OF THE GRID.
;   - A PLAYER 2 (VALUE=2) CELL IS CREATED AT THE MOUSE POSITION IF THE MOUSE
;     IS ON THE RIGHT HALF OF THE GRID.
; * IF RIGHT MOUSE BUTTON IS PRESSED INSIDE THE GRID, THE CELL WHERE THE MOUSE
;   IS IS CLEARED (VALUE=0).
; INPUT    : NONE
; OUTPUT   : NONE
; MODIFIES : NONE
; -----------------------------------------------------------------------------

; TODO : PLACE YOUR CODE HERE


            MOVEM.L D0-D7/A0-A6,-(A7)

            MOVE.W  MOUY,D0                 ; COPY MOUSE Y POSITION
            MOVE.W  MOUX,D1                 ; COPY MOUSE X POSITION
            
            ; GET GRID POSITION
            MOVE.W  #GRDYOFF,D2             ; TOP Y
            MOVE.W  #GRDXOFF,D3             ; LEFT X
            MOVE.W  #GRDHEIGH,D4            ; HEIGHT
            MOVE.W  #GRDWIDTH,D5            ; WIDTH  
            
            ; IF D2<D0 MOUSE NOT INSIDE (IS UPPER THAN THE BUTTON)
            CMP.W   D2,D0
            BLT     .END
            
            ; IF D3<D1 MOUSE NOT INSIDE (IS ON THE LEFT SIDE)
            CMP.W   D3,D1
            BLT     .END
            
            ; IF D4>D0 MOUSE NOT INSIDE (IS LOWER THAN THE BUTTON)
            ADD.W   D2,D4
            CMP.W   D4,D0
            BGT     .END
            
            ; IF D5>D0 MOUSE NOT INSIDE (IS ON THE RIGHT SIDE)
            ADD.W   D3,D5
            CMP.W   D5,D1
            BGT     .END
            
            ;CALCULAR POS
            MOVE.W  MOUY,D0                 ; COPY MOUSE Y POSITION
            SUB.W   #GRDYOFF,D0
            MOVE.W  MOUX,D1                 ; COPY MOUSE X POSITION
            SUB.W   #GRDXOFF,D1
            DIVU.W  #GRDSZCEL,D0
            DIVU.W  #GRDSZCEL,D1
            
            MULU.W  #GRDWIDTH,D0
            ADD.W   D1,D0
            MOVE.W  D0,A0
            
            MOVE.L  GRDDST,A1
            
            ; COMPROBAR CLICK DER o IZQ
            BTST    #0,MOUVAL
            BEQ     .CLICKDER
            BRA     .CALP1P2
            
.CLICKDER   BTST    #1,MOUVAL
            BEQ     .END
            BRA     .CLRCELL
            
.CALP1P2    MOVE.W  #(GRDWITH/2)-1,D2
            CMP.W   D2,D1
            BGT     .PLAYER2
            
.PLAYER1    CMP.B   #1,(A1,A0)              
            BEQ     .END
            ADD.W   #1,GRDNPLR1
            MOVE.B  #1,(A1,A0)
            BRA     .END
            
.PLAYER2    CMP.B   #2,(A1,A0)              
            BEQ     .END
            ADD.W   #1,GRDNPLR2
            MOVE.B  #2,(A1,A0)
            BRA     .END 
         
.CLRCELL    CMP.B   #0,(A1,A0)              
            BEQ     .END
            CMP.B   #1,(A1,A0)
            BNE     .CLRP2
            SUB.W   #1,GRDNPLR1
.CLRP2      CMP.B   #2,(A1,A0)
            BNE     .SETZERO 
            SUB.W  #1,GRDNPLR2
            
.SETZERO    MOVE.B  #0,(A1,A0) 
                       
.END        MOVEM.L (A7)+,D0-D7/A0-A6       
            RTS

; -----------------------------------------------------------------------------
GRDRUPD
; UPDATES THE GRID ACCORDING TO 2-PLAYER GAME OF LIFE RULES AS FOLLOWS:
; * ADDS 1 TO THE NUMBER OF GENERATIONS (GRDNGEN)
; * SWITCHES THE MATRIX POINTERS (GRDDST AND GRDSRC).
; * CHECKS THE NEIGHBORS USING THE NEW SOURCE MATRIX (POINTER BY GRDDRC)
; * THE RESULTS OF APPLYING THE RULES ARE WRITTEN INTO THE NEW DESTINATION
;   MATRIX (POINTED BY GRDDST).
; * THE RULES ARE THE FOLLOWING, WHERE P1 AND P2 ARE 1 AND 2 RESPECTIVELY,
;   DEAD CELLS ARE REPRESENTED BY 0 AND NP1 AND NP2 DENOTE THE NUMBER OF
;   PLAYER 1 AND PLAYER 2 NEIGHBORS RESPECTIVELY:
;   + SURVIVAL RULES
;     - IF CELL IS P1 AND NP1-NP2 IS 2 OR 3 -> NEW VALUE IS P1
;     - IF CELL IS P1 AND NP1-NP2 IS 1 AND NP1>=2 -> NEW VALUE IS P1
;     - OTHERWISE -> NEW VALUE IS 0
;     - IF CELL IS P2 AND NP2-NP1 IS 2 OR 3 -> NEW VALUE IS P2
;     - IF CELL IS P2 AND NP2-NP1 IS 1 AND NP2>=2 -> NEW VALUE IS P2
;     - OTHERWISE -> NEW VALUE IS 0
;   + BIRTH RULES
;     - THE CELL HAS EXACTLY THREE P1 NEIGHBOURS AND THE NUMBER
;       OF P2 NEIGHBOURS IS DIFFERENT FROM THREE. IN THIS CASE A
;       P1 TOKEN IS BORN IN THE CELL.
;     - THE CELL HAS EXACTLY THREE P2 NEIGHBOURS AND THE NUMBER
;       OF P1 NEIGHBOURS IS DIFFERENT FROM THREE. IN THIS CASE A
;       P2 TOKEN IS BORN IN THE CELL.
;     - THE CELL HAS EXACTLY THREE WHITE AND THREE BLACK NEIGHBOURS.
;       IN THIS CASE AN UNBIASED COIN DETERMINES WHETHER A WHITE OR
;       BLACK TOKEN IS BORN IN THE CELL.
; INPUT    : NONE
; OUTPUT   : NONE
; MODIFIES : NONE
; -----------------------------------------------------------------------------

; TODO : PLACE YOUR CODE HERE

            MOVEM.L D0-D7/A0-A6,-(A7)


        

            MOVEM.L (A7)+,D0-D7/A0-A6       
            RTS

; -----------------------------------------------------------------------------
GRDSAVE
; SAVES THE GRID INTO A FILE IN CSV FORMAT
; INPUT    : NONE
; OUTPUT   : NONE
; MODIFIES : NONE
; NOTE     : THE LOCAL BUFFER SIZE MUST BE MAX(512,2*GRDWIDTH+1). PLEASE CHANGE
;            IT ACCORDINGLY IF GRDWIDTH*2+1 IS LARGER THAN 512.
; -----------------------------------------------------------------------------
            MOVEM.L D0-D7/A0-A6,-(A7)       ; TO BE OPTIMIZED
            MOVE.B  #50,D0                  ; CLOSE ALL FILES (RECOMMENDED)
            TRAP    #15
            SUB.L   #512,A7                 ; ROW BUFFER IN LOCAL MEMORY
            MOVE.B  #58,D0                  ; SHOW FILE DIALOG TASK
            MOVE.L  #1,D1                   ; DISPLAY SAVE DIALOG
            LEA     .MSG,A1                 ; STANDARD MESSAGE
            LEA     .FILTER,A2              ; NO FILTER
            MOVE.L  A7,A3                   ; FILE NAME BUFFER
            CLR.W   (A3)                    ; ENSURE THERE IS NO STRING
            TRAP    #15
            TST.B   D1
            BEQ     .END                    ; IF CANCELLED, DO NOTHING
            MOVE.L  A3,A1                   ; PLACE THE FILENAME INTO A1
            MOVE.B  #52,D0                  ; CREATE NEW FILE
            TRAP    #15
            TST.W   D0                      ; CHECK CREATION ERROR
            BNE     .END                    ; DO NOTHING MORE IF ERROR
            MOVE.L  A7,A6                   ; PUT A6 INTO START OF BUFFER
            MOVE.L  A7,A1                   ; PUT A1 INTO START OF BUFFER
            MOVE.L  (GRDDST), A0            ; A0: POINTER TO THE DATA TO WRITE
            MOVE.W  #GRDHEIGH-1,D3          ; D3: NUMBER OF ROWS - 1
.LOOPY      MOVE.W  #GRDWIDTH-1,D2          ; D2: NUMBER OF COLUMNS - 1
.LOOP       MOVE.B  #'0',D0                 ; ADD CHAR '0' AND THE CELL VALUE
            ADD.B   (A0)+,D0
            MOVE.B  D0, (A6)+               ; STORE IT IN THE BUFFER
            MOVE.B  #',',(A6)+              ; NOW PUT THE COMMA
            DBRA.W  D2,.LOOP
            MOVE.B  #$0D,-1(A6)             ; STORE CARRIAGE RETURN (REMOVE ',')
            MOVE.B  #$0A,(A6)               ; STORE LINE FEED
            MOVE.B  #54,D0                  ; WRITE TO FILE TASK NUMBER
            MOVE.L  #GRDWIDTH*2+1,D2        ; NUMBER OF BYTES TO WRITE
            TRAP    #15                     ; WRITE (A1 IS ALREADY THERE)
            MOVE.L  A1,A6                   ; GO BACK TO THE BUFFER START
            DBRA.W  D3,.LOOPY
            MOVE.B  #56,D0                  ; CLOSE FILE
            TRAP    #15
.END        ADD.L   #512,A7                 ; RESTORE STACK
            MOVEM.L (A7)+,D0-D7/A0-A6       ; TO BE OPTIMIZED
            RTS
.MSG        DC.B    'SELECT A CSV FILE TO SAVE',0
.FILTER     DC.B    '*.CSV',0
            DS.W    0

; -----------------------------------------------------------------------------
GRDLOAD
; LOADS THE GRID FROM A CSV FORMATTED FILE
; INPUT    : NONE
; OUTPUT   : NONE
; MODIFIES : NONE
; NOTE     : THE LOCAL BUFFER SIZE MUST BE MAX(512,2*GRDWIDTH+1). PLEASE CHANGE
;            IT ACCORDINGLY IF GRDWIDTH*2+1 IS LARGER THAN 512.
; -----------------------------------------------------------------------------
            MOVEM.L D0-D7/A0-A6,-(A7)       ; TO BE OPTIMIZED
            MOVE.B  #50,D0                  ; CLOSE ALL FILES (RECOMMENDED)
            TRAP    #15
            SUB.L   #512,A7                 ; ROW BUFFER IN LOCAL MEMORY
            MOVE.B  #58,D0                  ; SHOW FILE DIALOG TASK
            CLR.L   D1                      ; DISPLAY LOAD DIALOG
            LEA     .MSG,A1                 ; STANDARD MESSAGE
            LEA     .FILTER,A2              ; NO FILTER
            MOVE.L  A7,A3                   ; FILE NAME BUFFER
            CLR.W   (A3)                    ; ENSURE THERE IS NO STRING
            TRAP    #15
            TST.B   D1
            BEQ     .END                    ; IF CANCELLED, DO NOTHING
            MOVE.L  A3,A1                   ; PLACE THE FILENAME INTO A1
            MOVE.B  #51,D0                  ; OPEN EXISTING FILE
            TRAP    #15
            TST.W   D0                      ; CHECK ERRORS
            BNE     .END                    ; IF ERRORS, DO NOTHING MORE
            MOVE.L  A7,A6                   ; PUT A6 INTO START OF BUFFER
            MOVE.L  A7,A1                   ; PUT A1 INTO START OF BUFFER
            MOVE.L  (GRDDST), A0            ; POINTER TO STORE PROCESS. DATA
            MOVE.W  #GRDHEIGH-1,D3
.LOOP       MOVE.L  A6,A1
            MOVE.B  #53,D0                  ; READ DATA TASK NUMBER
            MOVE.L  #GRDWIDTH*2+1,D2        ; NUMBER OF BYTES TO READ
            TRAP    #15                     ; READ THE DATA
            MOVE.W  #GRDWIDTH-1,D2
.COPY       MOVE.B  (A1)+,D0                ; PICK ONE LOADED CHARACTER
            SUB.B   #'0',D0                 ; CONVERT FROM ASCII TO NUMBER
            MOVE.B  D0,(A0)+                ; STORE DATA
            ADDQ.L  #1,A1                   ; SKIP THE COMMA
            DBRA.W  D2,.COPY
            DBRA.W  D3,.LOOP
            MOVE.B  #56,D0                  ; CLOSE FILE
            TRAP    #15
.END        ADD.L   #512,A7                 ; RESTORE STACK
            MOVEM.L (A7)+,D0-D7/A0-A6       ; TO BE OPTIMIZED
            RTS
.MSG        DC.B    'SELECT A CSV FILE TO LOAD',0
.FILTER     DC.B    '*.CSV',0
            DS.W    0

; -----------------------------------------------------------------------------
GRDLLEFT
; LOADS THE LEFT PART OF THE GRID FROM A CSV FORMATTED FILE
; INPUT    : NONE
; OUTPUT   : NONE
; MODIFIES : NONE
; NOTE     : THE LOCAL BUFFER SIZE MUST BE MAX(512,2*GRDWIDTH+1). PLEASE CHANGE
;            IT ACCORDINGLY IF GRDWIDTH*2+1 IS LARGER THAN 512.
; NOTE     : ALL THE ACTIVE CELLS ARE STORED AS PLAYER 1 INDEPENDLY OF THEIR
;            ACTUAL VALUE.
; -----------------------------------------------------------------------------

; TODO : PLACE YOUR CODE HERE

            MOVEM.L D0-D7/A0-A6,-(A7)       ; SAVE CONTENT REGISTERS
            
            MOVE.B  #50,D0                  ; CLOSE ALL FILES (RECOMMENDED)
            TRAP    #15
            SUB.L   #512,A7                 ; ROW BUFFER IN LOCAL MEMORY
            MOVE.B  #58,D0                  ; SHOW FILE DIALOG TASK
            CLR.L   D1                      ; DISPLAY LOAD DIALOG
            LEA     .MSG,A1                 ; STANDARD MESSAGE
            LEA     .FILTER,A2              ; NO FILTER
            MOVE.L  A7,A3                   ; FILE NAME BUFFER
            CLR.W   (A3)                    ; ENSURE THERE IS NO STRING
            TRAP    #15
            TST.B   D1
            BEQ     .END                    ; IF CANCELLED, DO NOTHING
            MOVE.L  A3,A1                   ; PLACE THE FILENAME INTO A1
            MOVE.B  #51,D0                  ; OPEN EXISTING FILE
            TRAP    #15
            TST.W   D0                      ; CHECK ERRORS
            BNE     .END                    ; IF ERRORS, DO NOTHING MORE
            MOVE.L  A7,A6                   ; PUT A6 INTO START OF BUFFER
            MOVE.L  A7,A1                   ; PUT A1 INTO START OF BUFFER
            MOVE.L  (GRDDST), A0            ; POINTER TO STORE PROCESS. DATA
            MOVE.W  #GRDHEIGH-1,D3
.LOOP       MOVE.L  A6,A1
            MOVE.B  #53,D0                  ; READ DATA TASK NUMBER
            MOVE.L  #GRDWIDTH*2+1,D2        ; NUMBER OF BYTES TO READ
            TRAP    #15                     ; READ THE DATA
            ;En teoría llega hasta la mitad de las casillas y se renicia
            ;para la siguiente fila
            MOVE.W  #(GRDWIDTH/2)-1,D2      ; COPY HALF OF GRID
.COPY       MOVE.B  (A1)+,D0                ; PICK ONE LOADED CHARACTER
            SUB.B   #'0',D0                 ; CONVERT FROM ASCII TO NUMBER
            CMP.W   #2,D0
            BNE     .STORE
            MOVE.W  #1,D0
.STORE      MOVE.B  D0,(A0)+                ; STORE DATA
            ADDQ.L  #1,A1                   ; SKIP THE COMMA
            DBRA.W  D2,.COPY
            DBRA.W  D3,.LOOP
            MOVE.B  #56,D0                  ; CLOSE FILE
            TRAP    #15
.END        ADD.L   #512,A7                 ; RESTORE STACK
            
            MOVEM.L (A7)+,D0-D7/A0-A6       ; RESTORES CONTENT REGISTERS
            RTS

.MSG        DC.B    'SELECT A CSV FILE TO LOAD',0
.FILTER     DC.B    '*.CSV',0
            DS.W    0

; -----------------------------------------------------------------------------
GRDLRGT
; LOADS THE RIGHT PART OF THE GRID FROM A CSV FORMATTED FILE
; INPUT    : NONE
; OUTPUT   : NONE
; MODIFIES : NONE
; NOTE     : THE LOCAL BUFFER SIZE MUST BE MAX(512,2*GRDWIDTH+1). PLEASE CHANGE
;            IT ACCORDINGLY IF GRDWIDTH*2+1 IS LARGER THAN 512.
; NOTE     : ALL THE ACTIVE CELLS ARE STORED AS PLAYER 2 INDEPENDLY OF THEIR
;            ACTUAL VALUE.
; -----------------------------------------------------------------------------

; TODO : PLACE YOUR CODE HERE

            MOVEM.L D0-D7/A0-A6,-(A7)       ; SAVE CONTENT REGISTERS

            MOVE.B  #50,D0                  ; CLOSE ALL FILES (RECOMMENDED)
            TRAP    #15
            SUB.L   #512,A7                 ; ROW BUFFER IN LOCAL MEMORY
            MOVE.B  #58,D0                  ; SHOW FILE DIALOG TASK
            CLR.L   D1                      ; DISPLAY LOAD DIALOG
            LEA     .MSG,A1                 ; STANDARD MESSAGE
            LEA     .FILTER,A2              ; NO FILTER
            MOVE.L  A7,A3                   ; FILE NAME BUFFER
            CLR.W   (A3)                    ; ENSURE THERE IS NO STRING
            TRAP    #15
            TST.B   D1
            BEQ     .END                    ; IF CANCELLED, DO NOTHING
            MOVE.L  A3,A1                   ; PLACE THE FILENAME INTO A1
            MOVE.B  #51,D0                  ; OPEN EXISTING FILE
            TRAP    #15
            TST.W   D0                      ; CHECK ERRORS
            BNE     .END                    ; IF ERRORS, DO NOTHING MORE
            MOVE.L  A7,A6                   ; PUT A6 INTO START OF BUFFER
            MOVE.L  A7,A1                   ; PUT A1 INTO START OF BUFFER
            MOVE.L  (GRDDST), A0            ; POINTER TO STORE PROCESS. DATA
            MOVE.W  #GRDHEIGH-1,D3
.LOOP       MOVE.L  A6,A1
            MOVE.B  #53,D0                  ; READ DATA TASK NUMBER
            MOVE.L  #GRDWIDTH*2+1,D2        ; NUMBER OF BYTES TO READ
            TRAP    #15                     ; READ THE DATA
            ;En teoría llega hasta la mitad de las casillas y se renicia
            ;para la siguiente fila
            MOVE.W  #(GRDWIDTH/2)-1,D2      ; COPY HALF OF GRID
            ;En teoría si se empieza a guadar desde la mitad, se tendría que guardar
            ;la parte derecha del grid, es decir, por cada fila sse tiene que empezar
            ;por la mitad y para ello sumando la mitad del grid a donde se guarda 
            ;tendría que funcionar
            ADD.W   D2,A0
            ADD.W   #GRDWIDTH,A1            ; A1 contiene el doble por las comas
.COPY       MOVE.B  (A1)+,D0                ; PICK ONE LOADED CHARACTER
            SUB.B   #'0',D0                 ; CONVERT FROM ASCII TO NUMBER
            CMP.W   #1,D0
            BNE     .STORE
            MOVE.W  #2,D0
.STORE      MOVE.B  D0,(A0)+                ; STORE DATA
            ADDQ.L  #1,A1                   ; SKIP THE COMMA
            DBRA.W  D2,.COPY
            DBRA.W  D3,.LOOP
            MOVE.B  #56,D0                  ; CLOSE FILE
            TRAP    #15
.END        ADD.L   #512,A7                 ; RESTORE STACK
            
            
            MOVEM.L (A7)+,D0-D7/A0-A6       ; RESTORES CONTENT REGISTERS
            RTS

.MSG        DC.B    'SELECT A CSV FILE TO LOAD',0
.FILTER     DC.B    '*.CSV',0
            DS.W    0

; -----------------------------------------------------------------------------
GRDPLOT
; PLOTS THE GRID
; INPUT    : NONE
; OUTPUT   : NONE
; MODIFIES : NONE
; -----------------------------------------------------------------------------

; TODO : PLACE YOUR CODE HERE
SETCURSOR   MACRO
            CLR.L   D1
            MOVE.B  #11,D0                  
            MOVE.B  #\1,D1
            LSL     #8,D1
            MOVE.B  #\2,D1 
            TRAP    #15
            ENDM
            
SETFLLCLR   MACRO
            CLR.L   D1
            MOVE.B  #81,D0                  
            MOVE.L  #\1,D1
            TRAP    #15
            ENDM
            
SETNUMBER   MACRO
            CLR.L   D1
            MOVE.B  #3,D0
            MOVE.W  \1,D1                  
            TRAP    #15
            ENDM
            
SETPENCLR   MACRO
            CLR.L   D1
            MOVE.B  #80,D0
            MOVE.L  #\1,D1
            TRAP    #15
            ENDM
            
PRINTCHAR   MACRO
            MOVE.B  #6,D0                   ; TASK ID TO PRINT A CHARACTER
            MOVE.B  #'*',D1                 ; CHARACTER TO PRINT
            TRAP    #15                     ; PRINT
            ENDM

            MOVEM.L D0-D7/A0-A6,-(A7)       ; SAVE CONTENT REGISTERS
            
            
* GRDPXWID   ; GRID DISPLAY WIDTH (PIXELS)           
* GRDPXHEI   ; GRID DISPLAY HEIGHT(PIXELS)
* GRDSZCEL   ; GRID CELL SIZE (PIXELS)
* GRDWIDTH   ; NUMBER OF GRID COLUMNS
* GRDHEIGH   ; NUMBER OF GRID ROWS
* GRDHEIGH-1 ; NUMBER OF ROWS-1
* GRDWIDTH-1 ; NUMBER OF COLUMNS-1
* NUMCELTOTAL = NUMCOLUMNS*NUMROWS
* SCRWIDTH   ; SCREEN WIDTH (PIXELS)
* SCRHEIGH   ; SCREEN HEIGHT (PIXELS)
* GRDVEMRG   ; TOP MARGIN (2 BUTTON ROWS)
* GRDMSWID   ; MASK TO GET X FROM GRID OFFSET
* GRDMSHEI   ; MASK TO GET Y FROM GRID OFFSET
* GRDXOFF    ; X OFFSETS TO DISPLAY CENTERED GRID
* GRDYOFF    ; Y OFFSET CENT. GRD
* GRDSCP1X   ; PLAYER 1 SCORE X (CHAR RESOL.)
* GRDSCP1Y   ; PLAYER 1 SCORE Y (CHAR RESOL.)
* GRDSCP2X   ; PLAYER 2 SCORE X (CHAR RES.)
* GRDSCP2Y   ; PLAYER 2 SCORE Y (CHAR RESOL.)
* GRDSCNGX   ; NUM. GENER. X (CHAR RESOL.)
* GRDSCNGY   ; NUM. GENER. Y (CHAR RESOL.)

            ;RECORRER MATRIZ E IR PINTADO
            ; SET PEN WIDTH/THICKNESS
            MOVE.B  #93,D0
            MOVE.L  #2,D1
            TRAP    #15
            MOVE.W  #GRDHEIGH-1,D6
            MOVE.W  #GRDWIDTH-1,D7
            CLR.L   D6
            CLR.L   D7
            ; DRAW CELLS COLORS
            MOVE.L  (GRDDST), A0 
            MOVE.W  #0,D6
.ROWS       CMP.W   #GRDHEIGH-1,D6
            BEQ     .FINFOR1
            MOVE.W  #0,D7   
.CLMS       CMP.W   #GRDWIDTH-1,D7
            BEQ     .FINFOR2
            ;
            MOVE.W  D6,D2
            MOVE.W  D7,D1
            MOVE.B  (A0)+,D5
            CMP.B   #0,D5
            BEQ     .VACIA
            CMP.B   #1,D5
            BEQ     .P1
            ; CASILLA ROJA
            SETFLLCLR CLRLTRED
            BRA.W   .PAINT
.P1         ; CASILLA AZUL
            SETFLLCLR CLRLTBLU
.VACIA      ; FONDO NEGRO
            SETFLLCLR CLRBLACK
.PAINT      CLR.L   D1
            MOVE.B  D7,D1
            MULU    #GRDSZCEL,D1
            ADD.W   #GRDXOFF,D1
            MOVE.W  D1,D3
            ADD.W   #GRDSZCEL,D3
            MOVE.W  D6,D2
            MULU    #GRDSZCEL,D2
            ADD.W   #GRDYOFF,D2
            MOVE.W  D2,D4
            ADD.W   #GRDSZCEL,D4
            
            MOVE.B  #87,D0
            TRAP    #15
            ;
            ADDQ.W  #1,D7
            BRA.W   .CLMS
.FINFOR2    ADDQ.W  #1,D6
            BRA.W   .ROWS
.FINFOR1    ;YA ESTA :D        
            
            ;SCORES
            ; DRAW *
            MOVE.W  (GRDNPLR1),D2
            MOVE.W  (GRDNPLR2),D3
            CMP.W   D2,D3 
            BEQ     .EQUALS
            BGT     .P2MRSCR                ; PLAYER1<PLAYER2
            SETCURSOR GRDSCP1X,GRDSCP1Y-1   ; SET CURSOR
            SETFLLCLR CLRLTBLU              ; SET FILL COLOR
            BRA     .EXIT
.P2MRSCR    SETCURSOR GRDSCP2X,GRDSCP2Y-1   ; SET CURSOR
            SETFLLCLR CLRLTRED              ; SET FILL COLOR
            BRA     .EXIT
.EQUALS     SETCURSOR GRDSCP1X,GRDSCP1Y-1   ; SET CURSOR
            SETFLLCLR CLRLTBLU              ; SET FILL COLOR
            PRINTCHAR
            SETCURSOR GRDSCP2X,GRDSCP2Y-1   ; SET CURSOR
            SETFLLCLR CLRLTRED              ; SET FILL COLOR
            PRINTCHAR
.EXIT       ;PLAYER SCORES
            SETPENCLR CLRWHITE              ; SET PEN COLOR       
            ; PLAYER 1
            SETCURSOR GRDSCP1X,GRDSCP1Y     ; SET CURSOR
            SETFLLCLR CLRLTBLU              ; SET FILL COLOR
            SETNUMBER D2                    ; WRITE NUMBER
            
            ; GENERATIONS
            SETCURSOR GRDSCNGX,GRDSCNGY     ; SET CURSOR
            SETFLLCLR CLRLTGRN              ; SET FILL COLOR
            SETNUMBER (GRDNGEN)             ; WRITE NUMBER

            ; PLAYER 2
            SETCURSOR GRDSCP2X,GRDSCP2Y     ; SET CURSOR
            SETFLLCLR CLRLTRED              ; SET FILL COLOR
            SETNUMBER D3                    ; WRITE NUMBER
            
            ;GRID
            SETPENCLR CLRDKGRN              ; SET PEN COLOR
            
            ; DRAW LINES
            MOVE.B  #84,D0
            
            ; VERTICAL                       
            MOVE.W  #GRDWIDTH,D5
            MOVE.W  #GRDXOFF,D1             ; X1
            MOVE.W  #GRDYOFF,D2             ; Y1
            MOVE.W  #GRDXOFF,D3             ; X2
            MOVE.W  #GRDPXHEI,D4
            ADD.W   D2,D4                   ; Y2
            
.LNVRTCL    TRAP    #15
            ADD.W   #GRDSZCEL,D1
            MOVE.W  D1,D3               
            DBRA.W  D5,.LNVRTCL
            
            ; HORIZONTAL
            MOVE.W  #GRDHEIGH,D5
            MOVE.W  #GRDXOFF,D1             ; X1 (Y1 SAME AS VERTICAL)
            MOVE.W  #GRDPXWID,D3
            ADD.W   D1,D3                   ; X2
            MOVE.W  #GRDYOFF,D4             ; Y2
            
.LNHRZNTL   TRAP    #15           
            ADD.W   #GRDSZCEL,D2
            MOVE.W  D2,D4
            DBRA.W  D5,.LNHRZNTL
            
            MOVEM.L (A7)+,D0-D7/A0-A6       ; RESTORE CONTENT REGISTERS
     
            RTS










































*~Font name~Courier New~
*~Font size~14~
*~Tab type~0~
*~Tab size~4~
