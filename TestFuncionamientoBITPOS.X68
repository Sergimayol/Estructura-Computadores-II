*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program
            MOVE.B  #240,D0
            JSR     BITs
            SIMHALT
; -----------------------------------------------------------------------------
BITPOS
; GIVEN A BYTE, IT RETURNS THE POSITION (VALUE BETWEEN 0 AND 7) OF THE RIGHT-
; MOST BIT VALUED ONE. IF ALL BITS ARE ZERO, OUTPUTS 8
; INPUT    - D0.B THE BYTE
; OUTPUT   - D0.B THE BIT POSITION
; MODIFIES - NO REGISTER, ASIDE OF D0.B
; -----------------------------------------------------------------------------

BITs:
            BTST    #0,D0
            BNE     BIT0
            BTST    #1,D0                   ;XXXXXXX0
            BNE     BIT1
            BTST    #2,D0                   ;XXXXXX00
            BNE     BIT2
            BTST    #3,D0                   ;XXXXX000
            BNE     BIT3
            BTST    #4,D0                   ;XXXX0000
            BNE     BIT4
            BTST    #5,D0                   ;XXX00000
            BNE     BIT5
            BTST    #6,D0                   ;XX000000
            BNE     BIT6
            BTST    #7,D0                   ;X0000000
            BNE     BIT7 
            MOVE.W  #8,D0                   ;00000000 
            RTS                    

BIT7:
            MOVE.B #7,D0                    ;10000000
            RTS
BIT6:       
            MOVE.B #6,D0                    ;X1000000
            RTS
BIT5:
            MOVE.B #5,D0                    ;XX100000
            RTS
BIT4:
            MOVE.B #4,D0                    ;XXX10000
            RTS
BIT3:
            MOVE.B #3,D0                    ;XXXX1000
            RTS
BIT2:
            MOVE.B #2,D0                    ;XXXXX100
            RTS
BIT1:
            MOVE.B #1,D0                    ;XXXXXX10
            RTS
BIT0:
            MOVE.B #0,D0                    ;XXXXXXX1
            RTS

   END    START        ; last line of source
            

*~Font name~Courier New~
*~Font size~12~
*~Tab type~0~
*~Tab size~4~
