*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                                      
*            MOVE.W  #&00,D0                 ;BIT0=0 BIT1=0
*            MOVE.W  #%01,D0                 ;BIT0=0 BIT1=1
*            MOVE.W  #%10,D0                 ;BIT0=1 BIT1=0
            MOVE.W  #%11,D0                  ;BIT0=1 BIT1=1
            JSR     MAPINIT
            SIMHALT
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
; -----------------------------------------------------------------------------
BITXX:
            BTST    #1,D0
            BNE     BIT1X
            BTST    #0,D0                   ;0
            BNE     BIT01 
            JMP     RETORNO                 ;00 No hacer nada.
BIT1X:
            BTST    #0,D0                   ;10
            BNE     BIT11
            JSR     GTHWADDR                ;10 Recoger direcciones de mapeo.
            JMP     RETORNO
BIT11:
            JSR     SHOWWIN
            JSR     GTHWADDR                ;11 Mostrar ventana y recoger direcciones de mapeo.
            JMP     RETORNO
BIT01:
            JSR     SHOWWIN                 ;01 Mostrar ventana.
            JMP     RETORNO

RETORNO:
            RTS
;--------------parte mostrar hardware------------------------
SHOWWIN
            MOVEM.L D0-D1,-(A7)
            MOVE.B  #32, D0
            CLR.B   D1
            TRAP    #15
            MOVEM.L (A7)+,D0-D1
            RTS
;--------------parte get parametros--------------------------
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

* Put variables and constants here

    END    START        ; last line of source


*~Font name~Courier New~
*~Font size~16~
*~Tab type~0~
*~Tab size~4~
