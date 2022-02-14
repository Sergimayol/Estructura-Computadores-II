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
            MOVE.W  MOUY,D0                ; COPY MOUSE Y POSITION
            SUB.W   #GRDYOFF,D0
            MOVE.W  MOUX,D1                ; COPY MOUSE X POSITION
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
            CMP.B   #1,(A1,A0)              ; CELL ALREADY CREATED?                   
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

            MOVEM.L D0-D7/A0-A6,-(A7)       ; SAVE CONTENT REGISTER

            ; INIT. COUNTERS
            ADD.W   #1,GRDNGEN              ; INIT. GEN COUNTER TO 1
            CLR.W   GRDNPLR1                ; INIT. PLR 1 CONT. TO 0
            CLR.W   GRDNPLR2                ; INIT. PLR 2 CONT. TO 0
            MOVE.L  GRDDST,D0               ; COPY @ TO SWAP THEM
            MOVE.L  GRDSRC,D1
            MOVE.L  D0,GRDSRC               ; SWAP POINTERS
            MOVE.L  D1,GRDDST               
            MOVE.L  GRDSRC,A0               
            MOVE.L  GRDDST,A1              
            CLR.L   D0
            CLR.L   D1
            MOVE.W  #GRDWIDTH,D6
            MULU.W  #GRDHEIGH,D6
            SUB.W   #1,D6                   ; D6 = TOTAL NUM. CELLS
            MOVE.W  #0,D7                   ; CELL COUNTER
.LOOP       CLR.W   D2
            CLR.W   D3
            MOVE.W  #GRDWIDTH,D0 
            MULU.W  #GRDHEIGH,D0            ; D0 = TOTAL NUM. CELLS
            CLR.L   D5 
            MOVE.W  D7,D5                   
            DIVU.W  #GRDWIDTH,D5            ; POS. OF ACTUAL CELL (ROW & COL)
            SWAP.W  D5                      ; MOVE COL. TO LOW PART
            CMP.W   #0,D7                   ; FIRST CELL(TOP LEFT CORNER)?
            BEQ     .TPLFTCRN               ; IF IT'S, GO TO TPLFTCRN
            MOVE.W  D0,D4                   
            SUB.W   #GRDWIDTH,D4            ; GET LAST CELL OF FIRST COL.
            CMP.W   D4,D7                   ; ACT CELL IS ON THE LOW LEFT CORNER? 
            BEQ     .LWLFTCRN               ; IF IT'S, GO TO LWLFTCRN
            CMP.W   #0,D5                   ; ACT CELL ON FIRST COL(LEFT SIDE)?
            BEQ     .FTLFTCOL               ; IF IT'S, GO TO FTLFTCOL
            CMP.W   #GRDWIDTH,D7            ; ACT CELL ON FIRST ROW(TOP SIDE)?
            BLT     .TPFSTROW               ; ?, GO TO TPFSTROW
            CMP.W   #GRDWIDTH,D7            ; ACT CELL ON TOP RIGHT CORNER?
            BEQ     .TPRGTCRN               ; IF IT'S, GO TO TPRGTCRN
            SUB.W   #1,D0
            CMP.W   D0,D7                   ; ACT CELL ON LOW RIGHT CORNER?
            BEQ     .LWRGTCRN               ; IF IT'S, GO TO LWRGTCRN
            CMP.W   #GRDWIDTH-1,D5          ; ACT CELL ON LAST COL(RIGHT SIDE)?
            BEQ     .LTRGTCOL               ; IF IT'S, GO TO LTRGTCOL
            CMP.W   D4,D7                   ; ACT CELL ON LAST ROW(LOW SIDE)?
            BGT     .LWLSTROW               ; ?, GO TO LWLSTROW
            BRA     .MDLPRTGD               ; ACT CELL IT'S ON MIDDLE
            
 ; GET THE NEIGHTBOURS FROM TOP LEFT CORNER CELL           
.TPLFTCRN   MOVE.B  (GRDWIDTH-1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH*2-1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH+1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH*GRDHEIGH-GRDWIDTH,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH*GRDHEIGH-GRDWIDTH+1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH*GRDHEIGH-1,A0),D1
            BSR     .SURVLRLS
            BRA     .UPDGRDCL
            
 ; GET THE NEIGHTBOURS FROM LEFT EDGE CELL CELLS            
.FTLFTCOL   MOVE.B  (GRDWIDTH-1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH*2-1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH+1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-GRDWIDTH+1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-GRDWIDTH,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-1,A0),D1
            BSR     .SURVLRLS
            BRA     .UPDGRDCL 

 ; GET THE NEIGHTBOURS FROM LOWER LEFT CONER CELL        
.LWLFTCRN   MOVE.B  (GRDWIDTH-1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-GRDWIDTH,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-GRDWIDTH+1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-(GRDWIDTH*GRDHEIGH-GRDWIDTH),A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-(GRDWIDTH*GRDHEIGH-GRDWIDTH+1),A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-GRDWIDTH*GRDHEIGH+GRDWIDTH-1,A0),D1
            BSR     .SURVLRLS
            BRA     .UPDGRDCL 

 ; GET THE NEIGHTBOURS FROM TOP EDGE CELLS 
.TPFSTROW   MOVE.B  (-1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH-1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH+1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH*GRDHEIGH-GRDWIDTH-1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH*GRDHEIGH-GRDWIDTH+1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH*GRDHEIGH-GRDWIDTH,A0),D1
            BSR     .SURVLRLS
            BRA     .UPDGRDCL 

 ; GET THE NEIGHTBOURS FROM TOP RIGHT CONER CELL  
.TPRGTCRN   MOVE.B  (-1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-GRDWIDTH+1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH-1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH*GRDHEIGH-GRDWIDTH,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH*GRDHEIGH-GRDWIDTH-1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH*GRDHEIGH-GRDWIDTH+1,A0),D1
            BSR     .SURVLRLS
            BRA     .UPDGRDCL    
 
 ; GET THE NEIGHTBOURS FROM RIGHT EDGE CELLS            
.LTRGTCOL   MOVE.B  (-1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-GRDWIDTH+1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH-1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-GRDWIDTH-1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-GRDWIDTH,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-GRDWIDTH*2+1,A0),D1
            BSR     .SURVLRLS
            BRA     .UPDGRDCL 

 ; GET THE NEIGHTBOURS FROM LOWER RIGHT CONER CELL             
.LWRGTCRN   MOVE.B  (-1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-GRDWIDTH+1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-GRDWIDTH-1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-GRDWIDTH,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-GRDWIDTH*2+1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-(GRDWIDTH*GRDHEIGH-GRDWIDTH-1),A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-(GRDWIDTH*GRDHEIGH-GRDWIDTH),A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-GRDWIDTH*GRDHEIGH+1,A0),D1
            BSR     .SURVLRLS
            BRA     .UPDGRDCL   

 ; GET THE NEIGHTBOURS FROM LOW EDGE CELLS
.LWLSTROW   MOVE.B  (-1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-GRDWIDTH-1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-GRDWIDTH,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-GRDWIDTH+1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-(GRDWIDTH*GRDHEIGH-GRDWIDTH-1),A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-(GRDWIDTH*GRDHEIGH-GRDWIDTH+1),A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-(GRDWIDTH*GRDHEIGH-GRDWIDTH),A0),D1
            BSR     .SURVLRLS
            BRA     .UPDGRDCL  
            
 ; GET THE NEIGHTBOURS FROM MID GRID CELLS              
.MDLPRTGD   MOVE.B  (-1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH-1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (GRDWIDTH+1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-GRDWIDTH-1,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-GRDWIDTH,A0),D1
            BSR     .SURVLRLS
            MOVE.B  (-GRDWIDTH+1,A0),D1
            BSR     .SURVLRLS
            BRA     .UPDGRDCL
            ; UPDATE NEIGHTBOUR PLAYERS CELL COUNTER    
.SURVLRLS   CMP.B   #1,D1                   ; NEIGHTBOUR IS P1 CELL?                  
            BEQ     .NPL1ADD1               ; IF IT'S, ADD 1 TO P1 COUNTER
            CMP.B   #2,D1                   ; NEIGHTBOUR IS P2 CELL? 
            BEQ     .NPL2ADD1               ; IF IT'S, ADD 1 TO P2 COUNTER
            RTS                             ; RETURN TO NEXT NEIGHTBOUR
.NPL1ADD1   ADD.W   #1,D2                   ; ADD 1 TO NP1 COUNTER 
            RTS              
.NPL2ADD1   ADD.W   #1,D3                   ; ADD 1 TO NP2 COUNTER   
            RTS              
            ; UPDATE CELLS ON GRID(SURVIVAL RULES)
.UPDGRDCL   CMP.B   #0,(A0)                 ; IS ACT CELL IS A DEAD CELL?
            BEQ     .BIRTHRLS               ; IF IT'S, GO TO BIRTH RULES
            CMP.B   #1,(A0)                 ; ACT CELL IS P1 CELL?
            BNE     .P2RULES                    ; IF IT'S, GO TO P2 RULES                    
            MOVE.W  D2,D4                   ; MOVE P1 NEIGHTBOURS TO D4
            SUB.W   D3,D4                   ; SUB P2 NEIGHTBOURS TO P1 NEIGHTBOURS
            CMP.W   #3,D4                   ; NP1-?
            BEQ     .SETCLTP1
            CMP.W   #2,D4 
            BEQ     .SETCLTP1
            CMP.W   #1,D4
            BNE     .STCLDEAD
            CMP.W   #2,D2
            BGE     .SETCLTP1
            BRA     .STCLDEAD
.SETCLTP1   MOVE.B  #1,(A1)
            BRA     .ENDLOOP
.P2RULES    MOVE.W  D3,D4
            SUB.W   D2,D4
            CMP.W   #3,D4 
            BEQ     .SETCLTP2
            CMP.W   #2,D4 
            BEQ     .SETCLTP2
            CMP.W   #1,D4
            BNE     .STCLDEAD
            CMP.W   #2,D2
            BGE     .SETCLTP2
            BRA     .STCLDEAD
.SETCLTP2   MOVE.B  #2,(A1)
            BRA     .ENDLOOP
.STCLDEAD   MOVE.B  #0,(A1)
            ; CHECKS IF A NEW CELL IS POSSIBLE TO CREATE
            ; (BIRTH RULES)
.BIRTHRLS   CMP.W   #3,D2
            BNE     .NWPLR2CL
            CMP.W   #3,D3
            BNE     .NWPLR1CL
            BRA     .RANDMNUM
.NWPLR1CL   MOVE.B  #1,(A1)
            BRA     .ENDLOOP
.NWPLR2CL   CMP.W   #3,D3
            BNE     .ENDLOOP
            MOVE.B  #2,(A1)
            BRA     .ENDLOOP
.RANDMNUM   JSR     UTLRAND                 ; SUBR. TO GET RAN NUM.(1-2)
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
            BNE     .UPDP2CNT
            ADD.W   #1,GRDNPLR1             ; ADD 1 TO P1 CELL COUNTER
.UPDP2CNT   CMP.W   #2,D1
            BNE     .CLRCELL
            ADD.W   #1,GRDNPLR2             ; ADD 1 TO P2 CELL COUNTER
.CLRCELL    CLR.B   (A0)+            
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
            ; MACROS
SETCURSOR   MACRO 
            MOVE.W  #\1,D1
            LSL.W   #8,D1          
            MOVE.B  #\2,D1
            MOVE.L  #11,D0
            TRAP    #15 
            ENDM
SETFLLCLR   MACRO
            MOVEM.L D0-D1,-(A7)
            MOVE.L  #\1,D1
            MOVE.B  #81,D0                  
            TRAP    #15                     
            MOVEM.L (A7)+,D0-D1
            ENDM
DSPLYCONT   MACRO
            CLR.L   D1
            MOVE.W  (\1),D1
            MOVE.L  #3,D0
            TRAP    #15 
            ENDM
PRNTCHR     MACRO
            CLR.L   (A1)
            MOVE.W  .CHARPRNT,(A1)
            MOVE.W  #\1*8,D1
            MOVE.W  #\2*13,D2
            MOVE.L  #95,D0
            TRAP    #15 
            ENDM
            ; END OF MACROS
            
            MOVEM.L D0-D7/A0,-(A7)          ; SAVE CONTENT REGISTER
            
            ; SET PEN WIDTH
            MOVE.L  #1,D1
            MOVE.B  #93,D0
            TRAP    #15 
            
            MOVE.W  GRDNPLR1,D1
            CMP.W   GRDNPLR2,D1             ; WHO IS WINNING?
            BEQ     .EQUALS                 ; TIE
            BLT     .P2MRSCR                ; P1<P2, P2 WINS
            SETFLLCLR CLRLTBLU              ; SET FILL COLOR                       
            PRNTCHR GRDSCP1X,GRDSCP1Y       ; PRINT '*'
            BRA     .EXIT     
.P2MRSCR    SETFLLCLR CLRLTRED              ; SET FILL COLOR
            PRNTCHR GRDSCP2X,GRDSCP2Y       ; PRINT '*'
            BRA     .EXIT
.EQUALS     SETFLLCLR CLRLTBLU              ; SET FILL COLOR
            PRNTCHR GRDSCP1X,GRDSCP1Y       ; PRINT '*'
            SETFLLCLR CLRLTRED              ; SET FILL COLOR
            PRNTCHR GRDSCP2X,GRDSCP2Y       ; PRINT '*'
            ;PLOT SCORES
.EXIT       ; PLAYER 1
            SETCURSOR GRDSCP1X,GRDSCP1Y     ; SET CURSOR                  
            SETFLLCLR CLRLTBLU              ; SET FILL COLOR 
            DSPLYCONT GRDNPLR1              ; PLOT CONT NUMBER
            ; GENERATIONS
            SETCURSOR GRDSCNGX,GRDSCNGY     ; SET CURSOR                  
            SETFLLCLR CLRMDGRN              ; SET FILL COLOR 
            DSPLYCONT GRDNGEN               ; PLOT CONT NUMBER
            ; PLAYER 2
            SETCURSOR GRDSCP2X,GRDSCP2Y     ; SET CURSOR        
            SETFLLCLR CLRLTRED              ; SET FILL COLOR 
            DSPLYCONT GRDNPLR2              ; PLOT CONT NUMBER
            ; DRAW CELLS
            MOVE.L  (GRDDST), A0            ; COPY @ OF GRDDST
            CLR.L   D3                      ; COLMN COUNTER
            CLR.L   D4                      ; ROW COUNTER
            CLR.L   D5                      ; CELL COUNTER
            MOVE.W  #GRDYOFF,D2             ; TOP Y 
            MOVE.W  #GRDXOFF,D1             ; LEFT X 
            MOVE.W  #GRDWIDTH,D6            ; NUM. COLS
            MOVE.W  #GRDWIDTH,D7
            MULU.W  #GRDHEIGH,D7            ; TOTAL CELLS
.STRT       CMP.W   D7,D5                   ; ALL CELL PAINTED?
            BEQ     .DRWGRID                ; IF IT'S, DRAW GRID
            CMP     #0,D5                   ; IF NOT,PAINT CELLS 
            BEQ     .CLMN                   
            ADDQ.W  #1,D3
.CLMN       ADDQ.W  #1,D5
            CMP.W   D6,D3    
            BGE     .ROW
            CMP.B   #0,(A0)+                ; EMPTY CELL?
            BEQ     .STRT                   ; IF IT'S, NEXT CELL
            BRA     .DWCL                   ; IF NOT, DRAW CELL
.ROW        ADDQ.W  #1,D4                   ; NEW ROW
            CLR.W   D3                      ; NEW COLUMN
            CMP.B   #0,(A0)+                ; EMPTY CELL?
            BEQ     .STRT                   ; IF IT'S, NEXT CELL
            BRA     .DWCL                   ; IF NOT, DRAW CELL
.DWCL       MOVEM.L  D0-D4/A0,-(A7)
            CMP.B   #1,-(A0)                ; WHOSE PLAYER CELL?
            BEQ     .P1CEL                  ; IF IT'S 1 = PLYR 1
            SETFLLCLR  CLRLTRED             ; SET FILL COLOR
            BRA     .DRAW                   ; JMP TO PLOT CELL
.P1CEL      SETFLLCLR  CLRLTBLU             ; SET FILL COLOR
.DRAW       ; CALC CELL POS. & DRAW IT 
            MULU.W  #GRDSZCEL,D3
            MULU.W  #GRDSZCEL,D4
            ADD.W   D1,D3
            MOVE.W  D3,D1                   ; X1
            ADD.W   #GRDSZCEL,D3            ; X2
            ADD.L   D2,D4
            MOVE.W  D4,D2                   ; Y1
            ADD.W   #GRDSZCEL,D4            ; Y2
            MOVE.W  #87,D0
            TRAP    #15
            MOVEM.L (A7)+,D0-D4/A0
            BRA     .STRT
.DRWGRID    ;DRAW GRID
            ; SET PEN COLOR              
            MOVE.B  #80,D0
            MOVE.L  #CLRDKGRN,D1
            TRAP    #15
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
            
            MOVEM.L (A7)+,D0-D7/A0
            RTS
 
.CHARPRNT   DC.B    '*',0
            





*~Font name~Courier New~
*~Font size~14~
*~Tab type~0~
*~Tab size~4~
