; =============================================================================
; TITLE    : BUTTON MANAGEMENT
; AUTHOR   : ANTONI BURGUERA
; HISTORY  : 05-JULY-2021 - CREATION
; COMMENTS : * A BUTTON IS DEFINED BY A STATIC DATA BLOCK (SDB), WHICH DOES NOT
;              CHANGE OVER TIME, AND A VARIABLE DATA BLOCK (VDB), THAT CAN
;              CHANGE OVER TIME. CHANGES IN THE VDB ARE PRODUCED WHEN CALLING
;              SUBROUTINE BTNUPD.
;
;            * THE BUTTON SDB (CAN BE IN ROM) HAS THE FOLLOWING FIELDS. THE
;              NUMBER DENOTES THE OFFSET WITH RESPECT TO THE SDB START:
;
;                +0  - WORD - YTOP COORDINATE (PIXELS)
;                +2  - WORD - XLEFT COORDINATE (PIXELS)
;                +4  - WORD - HEIGHT (PIXELS)
;                +6  - WORD - WIDTH (PIXELS)
;                +8  - LONG - CALLBACK POINTER
;                +12 - BYTE STRING - ZERO TERMINATED STRING. TEXT TO SHOW.
;
;            * THE BUTTON VDB (MUST BE IN RAM) IS:
;
;                +0 - LONG - POINTER TO THE STATIC DATABLOCK
;                +4 - BYTE - STATUS WITH FORMAT XXXXXCPI WHERE:
;                            - I (BIT 0) - 1=MOUSE INSIDE, 0=MOUSE OUTSIDE
;                            - P (BIT 1) - 1=MOUSE PRESSED INSIDE
;                                          0=MOUSE NOT PRESSED INSIDE
;                            - C (BIT 2) - 1=MOUSE CLICKED INSIDE
;                                          0=MOUSE NOT CLICKED INSIDE
;                            NOTE THAT IF I=0 THEN P=C=0, IF I=1 AND P=0
;                            THEN C=0.
; =============================================================================

; -----------------------------------------------------------------------------
BTNINIT
; INITIALIZES THE BUTTON BY:
;  * COPYING THE SDB POINTER INTO THE VDB.
;  * CLEARING THE STATUS BYTE.
; INPUT    : A0 - POINTER TO THE VARIABLE DATABLOCK
;            A1 - POINTER TO THE STATIC DATABLOCK
; OUTPUT   : NONE
; MODIFIES : NONE
; -----------------------------------------------------------------------------

            MOVEM.L D0-D7/A0-A1,-(A7)       ; Save content registers
            
            MOVE.L  A1,(A0)                 ; Copy SDB pointer into VDB
            CLR.B   4(A0)                   ; CLEAR STATUS BYTE(VDB)                

            MOVEM.L (A7)+,D0-D7/A0-A1       ; Restore content resgiters
            
            RTS

; -----------------------------------------------------------------------------
BTNUPD
; UPDATES THE BUTTON VDB AND EXECUTES THE CALLBACK IF REQUIRED
; INPUT    : A0 - POINTER TO THE VARIABLE DATABLOCK
; OUTPUT   : NONE
; MODIFIES : NONE
; -----------------------------------------------------------------------------
            
            MOVEM.L D0-D5/A0-A2,-(A7)       ; Save content registers
            
            MOVE.B   #0,4(A0)               ; CLEAR STATUS BYTE
            MOVE.L  (A0),A1                 ; COPY @ SDB OF BUTTON
            
            ; COPY MOUSE POSITION
            MOVE.W  MOUY,D0                 ; COPY MOUSE Y POSITION
            MOVE.W  MOUX,D1                 ; COPY MOUSE X POSITION
            
            ; GET BUTTON POSITION
            MOVE.W  (A1)+,D2                ; TOP Y
            MOVE.W  (A1)+,D3                ; LEFT X
            MOVE.W  (A1)+,D4                ; HEIGHT
            MOVE.W  (A1)+,D5                ; WIDTH  
            
            ; IF D2<D0 MOUSE NOT INSIDE (IS UPPER THAN THE BUTTON)
            CMP.W   D2,D0
            BLT     .MOUSEOUT
            
            ; IF D3<D1 MOUSE NOT INSIDE (IS ON THE LEFT SIDE)
            CMP.W   D3,D1
            BLT     .MOUSEOUT
            
            ; IF D4>D0 MOUSE NOT INSIDE (IS LOWER THAN THE BUTTON)
            ADD.W   D2,D4
            CMP.W   D4,D0
            BGT     .MOUSEOUT
            
            ; IF D5>D0 MOUSE NOT INSIDE (IS ON THE RIGHT SIDE)
            ADD.W   D3,D5
            CMP.W   D5,D1
            BGT     .MOUSEOUT

            ; UPDATE VDB 
            MOVE.B  #1,4(A0)                ; I (BIT 0) = 1
            BTST    #0,MOUVAL               ; BUTTON NOT PRESSED?
            BEQ     .END                    ; BUTTON NOT PRESSED
            MOVE.B  #3,4(A0)                ; P (BIT 1) = 1
            BTST    #0,MOUEDGE              ; BUTTON NOT CLICKED?
            BEQ     .END                    ; BUTTON NOT CLICKED
            MOVE.B  #7,4(A0)                ; C (BIT 2) = 1
            
            ; EXECUTE CALLBACK
            MOVE.L  (A1),A2                 ; COPY @ CALLBACK
            JSR     (A2)                    ; JUMP TO CALLBACK SUBR
            BRA     .END                    
            
.MOUSEOUT   CLR.B   4(A0)                   ; I,P,C = 0

.END        MOVEM.L (A7)+,D0-D5/A0-A2       ; Restore content resgiters
           
            RTS

; -----------------------------------------------------------------------------
BTNPLOT
; PLOTS THE BUTTON. A RECTANGLE IS DRAWN WITH THICKNESS BTNPENWD. THE CONTOUR
; COLOR IS BTNPENCL. THE FILL COLOR IS BLACK IF THE MOUSE IS NOT INSIDE,
; BTNSELCL IF THE MOUSE IS INSIDE BUT THE MOUSE BUTTON IS NOT PRESSED AND
; BTNPRSCL IF THE MOUSE BUTTON IS PRESSED INSIDE.
; INPUT    : A0 - POINTER TO THE VARIABLE DATABLOCK
; OUTPUT   : NONE
; MODIFIES : NONE
; -----------------------------------------------------------------------------

            MOVEM.L D0-D7/A0-A2,-(A7)       ; Save content registers
            
            ; SET PEN COLOR
            MOVE.B  #80,D0
            MOVE.L  #BTNPENCL,D1
            TRAP    #15
            
            ; SET PEN WIDTH/THICKNESS
            MOVE.B  #93,D0
            MOVE.L  #BTNPENWD,D1
            TRAP    #15
            
            CMP.B   #0,4(A0)                
            BEQ     .MOUSEOUT
    
            CMP.B   #2,4(A0) 
            BEQ     .MOUPRESD 
    
            ; MOUSE INSIDE   
            MOVE.L  #BTNSELCL,D1
            BRA     .SALIR
              
.MOUPRESD   MOVE.L  #BTNPRSCL,D1            ; MOUSE PRESSED
            BRA     .SALIR
            
.MOUSEOUT   MOVE.L  #CLRBLACK,D1            ; MOUSE OUTSIDE
            
.SALIR      MOVE.B  #81,D0                  ; SET FILL COLOR
            TRAP    #15
            
            MOVE.L  (A0),A1                 ; COPY @ SDB OF BUTTON
            CLR.L   D1
            
            ; GET COORDINATES(UP)
            MOVE.W  (A1)+,D2                ; UPPER Y
            MOVE.W  (A1)+,D1                ; LEFT X
            
            ; GET HEIGHT
            MOVE.W  (A1)+,D4
            MOVE.W  D4,-(A7)
            
            ; GET WIDTH 
            MOVE.W  (A1)+,D3
            MOVE.W  D3,D7

            ; GET COORDINATES(LOW)
            ADD.W   D1,D3                   ; RIGHT X
            MOVE.W  D2,D5                   
            ADD.W   D4,D5                   ; LOWER Y
            MOVE.W  D5,D4 
            
            ; DRAW BUTTON
            MOVE.B  #87,D0
            TRAP    #15
            
            ; SET PEN COLOR
            MOVE.W  D1,D5                   ; SAVE D1 CONTENT
            MOVE.B  #80,D0
            MOVE.L  #CLRWHITE,D1
            TRAP    #15
            CLR.L   D1
            MOVE.W  D5,D1                   ; RESTORE D1
            
            ; GET & DRAW TEXT
            ADD.W   #4,A1
            ; TEXTWIDTH  = NUMCAR*CHRWIDTH ; CHARACTER WIDTH
            ; TEXTHEIGHT = CHRHEIGH        ; CHARACTER HEIGHT
            CLR.L   D5
            MOVE.L  (A0),A2
            ADD.W   #12,A2
            MOVE.B  (A2)+,D6
.LOOP       CMP     #0,D6                   ; GET TEXT LENGTH            
            BEQ     .DONE
            ADD.W   #1,D5
            MOVE.B  (A2)+,D6                
            BRA     .LOOP
.DONE       MULU.W  #CHRWIDTH,D5
            SUB.W   D5,D7                   ; WIDTH-TEXTWIDTH
            DIVU.W  #2,D7                   ; (WIDTH-TEXTWIDTH)/2
            ADD.W   D7,D1                   ; LEFTX +(WIDTH-TEXTWIDTH)/2

            MOVE.W  (A7)+,D4
            SUB.W   #CHRHEIGH,D4            ; HEIGHT-TEXTHEIGHT
            DIVU.W  #2,D4                   ; (HEIGHT-TEXTHEIGHT)/2
            ADD.W   D4,D2                   ; UPPERY+(HEIGHT-TEXTHEIGHT)/2
            
            MOVE.B  #95,D0
            TRAP    #15
            
            MOVEM.L (A7)+,D0-D7/A0-A2       ; Restore content resgiters
            
            RTS
                

*~Font name~Courier New~
*~Font size~14~
*~Tab type~0~
*~Tab size~4~
