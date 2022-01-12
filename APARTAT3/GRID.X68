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


            MOVEM.L D0-D7/A0-A6,-(A7)       ; SAVE CONTENT REGISTERS

            MOVE.W  MOUY,D0                 ; COPY MOUSE Y POSITION
            MOVE.W  MOUX,D1                 ; COPY MOUSE X POSITION
            
            ;MOUSE INSIDE?
            ; GET GRID POSITION
            MOVE.W  #GRDYOFF,D2             ; TOP Y
            MOVE.W  #GRDXOFF,D3             ; LEFT X
                        
            ; IF D2<D0 MOUSE NOT INSIDE (IS UPPER THAN THE BUTTON)
            CMP.W   D2,D0
            BLT     .END
            ; IF D3<D1 MOUSE NOT INSIDE (IS ON THE LEFT SIDE)
            CMP.W   D3,D1
            BLT     .END
            ; IF D4>D0 MOUSE NOT INSIDE (IS LOWER THAN THE BUTTON)
            MOVE.W  D2,D4
            ADD.W   #GRDPXHEI,D4            ; BOTTOM Y
            SUB.W   #1,D4
            CMP.W   D4,D0
            BGT     .END
            ; IF D5>D0 MOUSE NOT INSIDE (IS ON THE RIGHT SIDE)
            MOVE.W  D3,D5
            ADD.W   #GRDPXWID,D5             ; RIGHT X
            SUB.W   #1,D5
            CMP.W   D5,D1
            BGT     .END
            
            CLR.L   D0
            CLR.L   D1
            ; CALCULATE CELL POSITION
            MOVE.W  MOUY,D0                 ; COPY MOUSE Y POSITION
            SUB.W   #GRDYOFF,D0
            MOVE.W  MOUX,D1                 ; COPY MOUSE X POSITION
            SUB.W   #GRDXOFF,D1
            DIVU.W  #GRDSZCEL,D0
            DIVU.W  #GRDSZCEL,D1
            
            MULU.W  #GRDWIDTH,D0
            ADD.W   D1,D0
            MOVE.W  D0,A0 
            
            MOVE.L  (GRDDST), A1
             
            ; CHECK CLICK(RIGHT OR LEFT)
            BTST    #0,MOUVAL
            BEQ     .RGHTCLK
            BRA     .PLYR1R2
            
.RGHTCLK    BTST    #1,MOUVAL 
            BEQ     .END
            BRA     .CLRCELL
            
.PLYR1R2    MOVE.W  #(GRDWIDTH/2)-1,D2      ; D2= HALF GRID
            CMP.W   D2,D1                   ; CHECK WHICH PLAYER IS
            BGT     .PLAYER2                
            
            ; PLAYER 1
.PLAYER1    CMP.B   #1,(A1,A0)              ; CELL ALREADY CREATED?                   
            BEQ     .END                    ; IF IT IS, RETURN
            ADD.W   #1,GRDNPLR1             ; IF NOT,ADD 1 TO COUNTER
            MOVE.B  #1,(A1,A0)              ; AND CREATE CELL
            BRA     .END
            
            ; PLAYER 2
.PLAYER2    CMP.B   #2,(A1,A0)              ; CELL ALREADY CREATED?              
            BEQ     .END                    ; IF IT IS, RETURN
            ADD.W   #1,GRDNPLR2             ; IF NOT,ADD 1 TO COUNTER
            MOVE.B  #2,(A1,A0)              ; AND CREATE CELL
            BRA     .END 
         
.CLRCELL    CMP.B   #0,(A1,A0)              ; CELL ALREADY CREATED?          
            BEQ     .END                    ; IF IT IS, RETURN
            CMP.B   #1,(A1,A0)              ; CHECK IF CELL IS P1
            BNE     .CLRPLR2                ; IF NOT, CLEAR P2 CELL
            SUB.W   #1,GRDNPLR1             ; SUB 1 FROM P1 COUNTER
.CLRPLR2    CMP.B   #2,(A1,A0)              ; CHECK IF CELL IS P2
            BNE     .SETZERO                ; IF NOT REMOVE CELL
            SUB.W  #1,GRDNPLR2              ; SUB 1 FROM P2 COUNTER
            
.SETZERO    MOVE.B  #0,(A1,A0)              ; SET CELL TO 0(DEAD)
                       
.END        MOVEM.L (A7)+,D0-D7/A0-A6       ; RESTORE CONTENT REGISTERS
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

            MOVEM.L D0-D7/A0-A6,-(A7)

            ADD.W   #1,GRDNGEN ;ADD 1 TO GEN COUNTER
            CLR.W   GRDNPLR1 ;SET P1 COUNTER TO 0
            CLR.W   GRDNPLR2 ;SET P2 COUNTER TO 0
            
            MOVE.L  GRDDST,D0
            MOVE.L  GRDSRC,D1
            MOVE.L  D0,GRDSRC
            MOVE.L  D1,GRDDST ;SWITCH MATRIX POINTERS
            MOVE.L  GRDSRC,A0 ;MOVE MATRIX SRC POINTER TO A0
            MOVE.L  GRDDST,A1 ;MOVE MATRIX DST POINTER TO A1
            CLR.L   D0
            CLR.L   D1


            MOVE.W  #GRDWIDTH,D6
            MULU.W  #GRDHEIGH,D6
            SUB.W   #1,D6 ;D6 CONTAINS TOTAL NUMBER OF CELLS OF GRID FOR LOOP
            MOVE.W  #0,D7 ;CELL COUNTER

            
.LOOP       CLR.W   D2
            CLR.W   D3
            MOVE.W  #GRDWIDTH,D0 
            MULU.W  #GRDHEIGH,D0 ;D0 CONTAINS TOTAL NUMBER OF CELLS STARTING FROM 0
            CLR.L   D5 
            MOVE.W  D7,D5
            DIVU.W  #GRDWIDTH,D5 ;GET ROW AND COL POS FROM ACTUAL CELL
            SWAP.W  D5 ;SWAP COL TO LOW WORD
            
            CMP.W   #0,D7 ;CHECK IF IT'S ON THE FIRST CELL (TOP LEFT CORNER)
            BEQ     .TLC                    
            MOVE.W  D0,D4
            SUB.W   #GRDWIDTH,D4 ;GET THE FIRST CELL OF THE LAST ROW
            CMP.W   D4,D7 ;CHECK IF ACT CELL IS ON THE LOW LEFT CORNER 
            BEQ     .LLC
            CMP.W   #0,D5 ;CHECH IF ACT CELL IS ON THE FIRST COL (LEFT SIDE GRID)
            BEQ     .MLC
            CMP.W   #GRDWIDTH,D7 ;CHECH IF ACT CELL IS ON THE FIRST ROW (TOP SIDE GRID)
            BLT     .TC     
            
            CMP.W   #GRDWIDTH,D7 ;CHECH IF ACT CELL IS ON THE LAST CELL OF FIRST ROW (TOP RIGHT CORNER)
            BEQ     .TRC
            SUB.W   #1,D0
            CMP.W   D0,D7 ;CHECH IF ACT CELL IS ON THE LAST CELL OF LAST ROW (LOW RIGHT CORNER)
            BEQ     .LRC
            CMP.W   #GRDWIDTH-1,D5 ;CHECH IF ACT CELL IS ON THE LAST COL (RIGHT SIDE GRID)
            BEQ     .MRC
            CMP.W   D4,D7 ;CHECH IF ACT CELL IS ON THE LAST ROW (LOW SIDE GRID)
            BGT     .LC
            BRA     .MC  ;OTHERWISE IT'S ON MIDDLE GRID
            
            
            
 ;GET THE NEIGHTBOURS FROM TOP LEFT CONER CELL           
.TLC        MOVE.B  (GRDWIDTH-1,A0),D1
            BSR     .CALCN
            MOVE.B  (1,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH*2-1,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH+1,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH*GRDHEIGH-GRDWIDTH,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH*GRDHEIGH-GRDWIDTH+1,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH*GRDHEIGH-1,A0),D1
            BSR     .CALCN
            BRA     .SRULES
            
 ;GET THE NEIGHTBOURS FROM LEFT EDGE CELL CELLS            
.MLC        MOVE.B  (GRDWIDTH-1,A0),D1
            BSR     .CALCN
            MOVE.B  (1,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH*2-1,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH+1,A0),D1
            BSR     .CALCN
            MOVE.B  (-GRDWIDTH+1,A0),D1
            BSR     .CALCN
            MOVE.B  (-GRDWIDTH,A0),D1
            BSR     .CALCN
            MOVE.B  (-1,A0),D1
            BSR     .CALCN
            BRA     .SRULES 

 ;GET THE NEIGHTBOURS FROM LOWER LEFT CONER CELL        
.LLC        MOVE.B  (GRDWIDTH-1,A0),D1
            BSR     .CALCN
            MOVE.B  (1,A0),D1
            BSR     .CALCN
            MOVE.B  (-GRDWIDTH,A0),D1
            BSR     .CALCN
            MOVE.B  (-GRDWIDTH+1,A0),D1
            BSR     .CALCN
            MOVE.B  (-1,A0),D1
            BSR     .CALCN
            MOVE.B  (-(GRDWIDTH*GRDHEIGH-GRDWIDTH),A0),D1
            BSR     .CALCN
            MOVE.B  (-(GRDWIDTH*GRDHEIGH-GRDWIDTH+1),A0),D1
            BSR     .CALCN
            MOVE.B  (-GRDWIDTH*GRDHEIGH+GRDWIDTH-1,A0),D1
            BSR     .CALCN
            BRA     .SRULES 


 ;GET THE NEIGHTBOURS FROM TOP EDGE CELLS 
.TC         MOVE.B  (-1,A0),D1
            BSR     .CALCN
            MOVE.B  (1,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH-1,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH+1,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH*GRDHEIGH-GRDWIDTH-1,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH*GRDHEIGH-GRDWIDTH+1,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH*GRDHEIGH-GRDWIDTH,A0),D1
            BSR     .CALCN
            BRA     .SRULES 

 ;GET THE NEIGHTBOURS FROM TOP RIGHT CONER CELL  
.TRC        MOVE.B  (-1,A0),D1
            BSR     .CALCN
            MOVE.B  (-GRDWIDTH+1,A0),D1
            BSR     .CALCN
            MOVE.B  (1,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH-1,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH*GRDHEIGH-GRDWIDTH,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH*GRDHEIGH-GRDWIDTH-1,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH*GRDHEIGH-GRDWIDTH+1,A0),D1
            BSR     .CALCN
            BRA     .SRULES    
 
 ;GET THE NEIGHTBOURS FROM RIGHT EDGE CELLS            
.MRC        MOVE.B  (-1,A0),D1
            BSR     .CALCN
            MOVE.B  (-GRDWIDTH+1,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH-1,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH,A0),D1
            BSR     .CALCN
            MOVE.B  (1,A0),D1
            BSR     .CALCN
            MOVE.B  (-GRDWIDTH-1,A0),D1
            BSR     .CALCN
            MOVE.B  (-GRDWIDTH,A0),D1
            BSR     .CALCN
            MOVE.B  (-GRDWIDTH*2+1,A0),D1
            BSR     .CALCN
            BRA     .SRULES 

 ;GET THE NEIGHTBOURS FROM LOWER RIGHT CONER CELL             
.LRC        MOVE.B  (-1,A0),D1
            BSR     .CALCN
            MOVE.B  (-GRDWIDTH+1,A0),D1
            BSR     .CALCN
            MOVE.B  (-GRDWIDTH-1,A0),D1
            BSR     .CALCN
            MOVE.B  (-GRDWIDTH,A0),D1
            BSR     .CALCN
            MOVE.B  (-GRDWIDTH*2+1,A0),D1
            BSR     .CALCN
            MOVE.B  (-(GRDWIDTH*GRDHEIGH-GRDWIDTH-1),A0),D1
            BSR     .CALCN
            MOVE.B  (-(GRDWIDTH*GRDHEIGH-GRDWIDTH),A0),D1
            BSR     .CALCN
            MOVE.B  (-GRDWIDTH*GRDHEIGH+1,A0),D1
            BSR     .CALCN
            BRA     .SRULES   

 ;GET THE NEIGHTBOURS FROM LOW EDGE CELLS
.LC         MOVE.B  (-1,A0),D1
            BSR     .CALCN
            MOVE.B  (1,A0),D1
            BSR     .CALCN
            MOVE.B  (-GRDWIDTH-1,A0),D1
            BSR     .CALCN
            MOVE.B  (-GRDWIDTH,A0),D1
            BSR     .CALCN
            MOVE.B  (-GRDWIDTH+1,A0),D1
            BSR     .CALCN
            MOVE.B  (-(GRDWIDTH*GRDHEIGH-GRDWIDTH-1),A0),D1
            BSR     .CALCN
            MOVE.B  (-(GRDWIDTH*GRDHEIGH-GRDWIDTH+1),A0),D1
            BSR     .CALCN
            MOVE.B  (-(GRDWIDTH*GRDHEIGH-GRDWIDTH),A0),D1
            BSR     .CALCN
            BRA     .SRULES  
            
 ;GET THE NEIGHTBOURS FROM MID GRID CELLS              
.MC         MOVE.B  (-1,A0),D1
            BSR     .CALCN
            MOVE.B  (1,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH-1,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH,A0),D1
            BSR     .CALCN
            MOVE.B  (GRDWIDTH+1,A0),D1
            BSR     .CALCN
            MOVE.B  (-GRDWIDTH-1,A0),D1
            BSR     .CALCN
            MOVE.B  (-GRDWIDTH,A0),D1
            BSR     .CALCN
            MOVE.B  (-GRDWIDTH+1,A0),D1
            BSR     .CALCN
            BRA     .SRULES
                
.CALCN      CMP.B   #1,D1 ;CHECK IF NEIGHTBOUR IS P1 CELL                  
            BEQ     .ADDNP1 ;ADD 1 TO P1 COUNTER IF SO
            CMP.B   #2,D1 ;CHECK IF NEIGHTBOUR IS P2 CELL 
            BEQ     .ADDNP2 ;ADD 1 TO P2 COINTER IF SO
            RTS ;RETURN TO GET NEXT NEIGHTBOUR
.ADDNP1     ADD.W   #1,D2 ;ADD 1 TO NP1 COUNTER 
            RTS
.ADDNP2     ADD.W   #1,D3 ;ADD 1 TO NP2 COUNTER   
            RTS
                        

.SRULES     CMP.B   #0,(A0) ;CHECK IF ACTUAL CELL IS A DEAD CELL
            BEQ     .BRULES ;GO TO BIRTH RULES IF SO
            CMP.B   #1,(A0) ;CHECK IF ACTUAL CELL IS P1 CELL
            BNE     .P2R ;GO TO P2 RULES                    
            MOVE.W  D2,D4 ;MOVE P1 NEIGHTBOURS TO D4
            SUB.W   D3,D4 ;SUB P2 NEIGHTBOURS TO P1 NEIGHTBOURS
            CMP.W   #3,D4 ;CHECK IF NP1-
            BEQ     .CTOP1
            CMP.W   #2,D4 
            BEQ     .CTOP1
            CMP.W   #1,D4
            BNE     .CTODEAD
            CMP.W   #2,D2
            BGE     .CTOP1
            BRA     .CTODEAD
            
.CTOP1      MOVE.B  #1,(A1)
            BRA     .ENDLOOP
            
.P2R        MOVE.W  D3,D4
            SUB.W   D2,D4
            CMP.W   #3,D4 
            BEQ     .CTOP2
            CMP.W   #2,D4 
            BEQ     .CTOP2
            CMP.W   #1,D4
            BNE     .CTODEAD
            CMP.W   #2,D2
            BGE     .CTOP2
            BRA     .CTODEAD
            
.CTOP2      MOVE.B  #2,(A1)
            BRA     .ENDLOOP

.CTODEAD    MOVE.B  #0,(A1)

.BRULES     CMP.W   #3,D2
            BNE     .BP2C
            CMP.W   #3,D3
            BNE     .BP1C
            BRA     .RANDC
            
.BP1C       MOVE.B  #1,(A1)
            BRA     .ENDLOOP
            
.BP2C       CMP.W   #3,D3
            BNE     .ENDLOOP
            MOVE.B  #2,(A1)
            BRA     .ENDLOOP
            
.RANDC      JSR     UTLRAND                 	; GET RANDOM NUMBER BETWEEN 1 AND 2
            
            MOVE.B  D1,(A1)  

  
.ENDLOOP    ADD.L   #1,A0
            ADD.L   #1,A1
            ADD.W   #1,D7
            DBRA    D6,.LOOP


            MOVE.W  #GRDWIDTH*GRDHEIGH-1,D0
            MOVE.L  GRDSRC,A0
            MOVE.L  GRDDST,A1
.END        MOVE.B  (A1)+,D1
            CMP.W   #1,D1
            BNE     .P2COUNTER
            ADD.W   #1,GRDNPLR1
.P2COUNTER  CMP.W   #2,D1
            BNE     .CLRC
            ADD.W   #1,GRDNPLR2
.CLRC       CLR.B   (A0)+            
            DBRA.W  D0,.END
            
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

            MOVEM.L D0-D3/A0-A6,-(A7)       ; SAVE CONTENT REGISTERS
            
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
            MOVE.L  #GRDWIDTH*2+1,D2          ; NUMBER OF BYTES TO READ
            TRAP    #15                     ; READ THE DATA
            MOVE.W  #GRDWIDTH/2-1,D2
.COPY       MOVE.B  (A1)+,D0                ; PICK ONE LOADED CHARACTER
            SUB.B   #'0',D0                 ; CONVERT FROM ASCII TO NUMBER
            CMP.W   #2,D0
            BNE     .STORE
            MOVE.W  #1,D0
.STORE      MOVE.B  D0,(A0)+                ; STORE DATA
            ADDQ.L  #1,A1                   ; SKIP THE COMMA
            DBRA.W  D2,.COPY
            ADD.W   #GRDWIDTH/2,A0
            DBRA.W  D3,.LOOP
            MOVE.B  #56,D0                  ; CLOSE FILE
            TRAP    #15
.END        ADD.L   #512,A7                 ; RESTORE STACK
            
            MOVEM.L (A7)+,D0-D3/A0-A6       ; RESTORES CONTENT REGISTERS
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
            MOVE.W  #GRDWIDTH/2-1,D2
            ADD.L   #GRDWIDTH,A1
            ADD.W   #GRDWIDTH/2,A0
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
            CLR.L   D0
            MOVE.B  #11,D0                  
            MOVE.B  #\1,D1
            LSL.W   #8,D1
            MOVE.B  #\2,D1 
            TRAP    #15
            CLR.L   D1
            CLR.L   D0
            ENDM
            
SETFLLCLR   MACRO
            CLR.L   D1
            CLR.L   D0
            MOVE.B  #81,D0                  
            MOVE.L  #\1,D1
            TRAP    #15
            CLR.L   D1
            CLR.L   D0
            ENDM
            
SETNUMBER   MACRO
            CLR.L   D1
            CLR.L   D0
            MOVE.B  #3,D0
            MOVE.W  \1,D1                  
            TRAP    #15
            CLR.L   D1
            CLR.L   D0
            ENDM
            
SETPENCLR   MACRO
            CLR.L   D1
            CLR.L   D0
            MOVE.B  #80,D0
            MOVE.L  #\1,D1
            TRAP    #15
            CLR.L   D1
            CLR.L   D0
            ENDM
            
PRINTCHAR   MACRO
            CLR.L   D1
            CLR.L   D0
            MOVE.B  #6,D0                   
            MOVE.B  #'*',D1                 
            TRAP    #15 
            CLR.L   D1
            CLR.L   D0                    
            ENDM
            
PLOTCEL     MACRO
            MOVEM.L  D0-D4/A1,-(A7)
            CMP.B   #1,-(A1)
            BNE     .P2CEL
            SETFLLCLR CLRLTBLU
            BRA     .DRAW
.P2CEL      SETFLLCLR CLRLTRED
            
.DRAW       
            MOVE.B  D7,\1
            MULU    #GRDSZCEL,\1
            ADD.W   #GRDXOFF,\1
            MOVE.W  \1,\3
            ADD.W   #GRDSZCEL,\3
            MOVE.W  D6,\2
            MULU    #GRDSZCEL,\2
            ADD.W   #GRDYOFF,\2
            MOVE.W  \2,\4
            ADD.W   #GRDSZCEL,\4
            
            MOVEM.L (A7)+,D0-D4/A1
            
            ENDM
            
            MOVEM.L D0-D7/A0-A6,-(A7)       ; SAVE CONTENT REGISTERS
            
            ; SET PEN WIDTH/THICKNESS
            MOVE.B  #93,D0
            MOVE.L  #2,D1
            TRAP    #15
            
            ;SCORES
            ; DRAW *
            MOVE.W  (GRDNPLR1),D2
            MOVE.W  (GRDNPLR2),D3
            CMP.W   D2,D3 
            BEQ     .EQUALS
            BGT     .P2MRSCR                ; PLAYER1<PLAYER2
            SETCURSOR GRDSCP1X,GRDSCP1Y-1   ; SET CURSOR
            SETFLLCLR CLRLTBLU              ; SET FILL COLOR
            PRINTCHAR
            BRA     .EXIT
.P2MRSCR    SETCURSOR GRDSCP2X,GRDSCP2Y-1   ; SET CURSOR
            SETFLLCLR CLRLTRED              ; SET FILL COLOR
            PRINTCHAR
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
            
            MOVE.L  (GRDDST),D1
            MOVE.L  D1,A1
            CLR.L   D1
            CLR.W   D5 ;CELL COUNTER
            CLR.W   D3 ;COL COUNTER
            CLR.W   D4 ;ROW COUNTER
            MOVE.W  #GRDYOFF,D2 ;TOP Y GRID POS
            MOVE.W  #GRDXOFF,D1 ;LEFT X GRID POS
            MOVE.W  #GRDWIDTH,D6 ;NUM OF COL
            MOVE.W  D6,D7
            MULU.W  #GRDHEIGH,D7 TOTAL N OF CELLS
            
            
.CHKCEL     CMP.W   D7,D5
            BEQ     .SKIP
            CMP     #0,D5
            BEQ     .NEXTCOL
            ADDQ.W  #1,D3
.NEXTCOL    ADDQ.W  #1,D5
            CMP.W   D6,D3    
            BGE     .NEXTROW
            CMP.B   #0,(A1)+
            BEQ     .CHKCEL
            BRA     .PAINTCEL
            
.NEXTROW    ADDQ.W  #1,D4
            CLR.W   D3 ;RESET COL COUNTER
            CMP.B   #0,(A1)+
            BEQ     .CHKCEL
            BRA     .PAINTCEL
            
.PAINTCEL   PLOTCEL D1,D2,D3,D4
            BRA     .CHKCEL
            
.SKIP               
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
