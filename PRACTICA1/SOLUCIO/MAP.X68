; =============================================================================
; TITLE    : MEMORY MAPPED HARD CODE
; AUTHOR   : Alejandro Rodriguez & Sergi Mayol
; COMMENTS :
; HISTORY  :
; =============================================================================
; -----------------------------------------------------------------------------
MAPINIT
; SHOWS HARDWARE WINDOW AND GETS MAPPING ADDRESSESG.
; INPUT    - D0.B BIT 0: SHOW HARDWARE WINDOW (1: YES, 0: NO)
;                 BIT 1: GET MAPPING ADDRESSES (1: YES, 0: NO)
;                 BIT 2-7: NOT USED.
;            A0 POINTER TO RAM ADDRESS TO STORE THE MAPPING ADDRESSES IN THIS
;               ORDER: 7-SEGMENT, LEDS, SWITCHES, BUTTONS.
;               IF D0.B BIT 1 IS ZERO, A0 IS NOT USED.
; OUTPUT   - NO OUTPUT THROUGH REGISTERS
;            RAM POINTED BY A0 IS MODIFIED IF D0.B BIT 1 IS 1
; MODIFIES - NONE
; -----------------------------------------------------------------------------u            BTST    #1,D0
            
            MOVE.W  D0,-(SP)                ;Guardar contenido resgitros
            MOVE.W  D1,-(SP)
            MOVE.W  A0,-(SP)
            
            BNE     BIT1X
            BTST    #0,D0                   ;0
            BNE     BIT01 
            JMP     RETORNO                 ;00 No hacer nada.
BIT1X:
            BTST    #0,D0                   ;10
            BNE     BIT11
            JSR     GTHWADDR                ;10 Recoger @ de mapeo.
            JMP     RETORNO
BIT11:
            JSR     SHOWHWIN
            JSR     GTHWADDR                ;11 Mostrar ventana y recoger @ de mapeo.
            JMP     RETORNO
BIT01:
            JSR     SHOWHWIN                ;01 Mostrar ventana.
            JMP     RETORNO

RETORNO:
            MOVE.W  (SP)+,A0                ;Restaurar contenido registros
            MOVE.W  (SP)+,D1
            MOVE.W  (SP)+,D0
            
            RTS
;--------------mostrar hardware------------------------
SHOWHWIN
            MOVEM.L D0-D1,-(A7)
            MOVE.B  #32, D0
            CLR.B   D1
            TRAP    #15
            MOVEM.L (A7)+,D0-D1
            RTS
 ;--------------get parametros-------------------------
GTHWADDR
            MOVEM.L A0-A1/D0-D2,-(A7)
            LEA     .DATA,A1
            MOVE.W  #3,D2
            MOVE.B  #32,D0
.LOOP       MOVE.B  (A1)+,D1
            TRAP    #15
            MOVE.L  D1,(A0)+
            DBRA.W  D2,.LOOP
            MOVEM.L (A7)+,A0-A1/D0-D2
            RTS
            ; TRAP #15 FUNCTION 32 PARAMETERS
.DATA       DC.B    1,2,3,7
            DS.W    0
; -----------------------------------------------------------------------------
MAPPRBIT
; PRINTS 'ZERO','ONE','TWO',...,'SEVEN' INTO THE 7-SEGMENT DISPLAYS DEPENDING
; ON THE BUTTON THAT IS PRESSED (ZERO IS THE RIGHTMOST, SEVEN IS THE LEFTMOST).
; PRINTS 'NONE' IF NO BUTTON IS PRESSED.
; INPUT    - A0 BUTTONS MAPPING ADDRESS
;            A1 7-SEGMENT DISPLAY MAPPING ADDRESS
; OUTPUT   - NONE THROUGH REGISTERS
; MODIFIES - NO REGISTER MODIFIED
; -----------------------------------------------------------------------------            
            MOVE.W  D0,-(SP)                ;Guardar contenido resgitros
            MOVE.L  A0,-(SP)  
            
            MOVE.B  (A0),D0                 ; Preparamos D0, (A0) bits botones
            NOT.B   D0                      ; Cambiar valores bits D0 
            BSR     BITPOS                  ; Obtenemos en D0 valor botones
            JSR     STR                     ; Obtenemos valor en A0 de info a mostrar
            BSR     STR2SEG                 ; Mostrar info en display
            MOVE.L  MAPBUTAD,A0             ; Restaurar @ A0
            MOVE.L  MAPSEGAD,A1             ; Restaurar @ A1
            
            MOVE.L  (SP)+,A0                ;Restaurar contenido registros
            MOVE.W  (SP)+,D0
            
            RTS     

STR:       
            CMP     #8,D0                  
            BNE     STR0
            LEA     NADA,A0
            RTS
            
STR0:       CMP     #0,D0
            BNE     STR1
            LEA     CERO,A0
            RTS

STR1:       
            CMP     #1,D0
            BNE     STR2
            LEA     UNO,A0
            RTS
            
STR2:       CMP     #2,D0
            BNE     STR3
            LEA     DOS,A0
            RTS
            
STR3:       CMP     #3,D0
            BNE     STR4
            LEA     TRES,A0
            RTS

STR4:       CMP     #4,D0
            BNE     STR5
            LEA     CUATRO,A0
            RTS
            
STR5:       CMP     #5,D0
            BNE     STR6
            LEA     CINCO,A0
            RTS
            
STR6:       CMP     #6,D0
            BNE     STR7
            LEA     SEIS,A0
            RTS

STR7:       
            LEA     SIETE,A0
            
            RTS            
                      













*~Font name~Courier New~
*~Font size~16~
*~Tab type~0~
*~Tab size~4~
