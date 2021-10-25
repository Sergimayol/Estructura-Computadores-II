; =============================================================================
; TITLE    : AUXILIARY CODE
; AUTHOR   : Alejandro Rodriguez & Sergi Mayol
; COMMENTS :
; HISTORY  :
; =============================================================================
; -----------------------------------------------------------------------------
STR2SEG
; CONVERTS A STRING OF 8 CHARS INTO THE 7-SEGMENT DISPLAYS WORDS SEQUENCE,
; READY TO BE SENT TO THE DISPLAYS.
; ACCEPTS CHARACTERS FROM A TO Z AND FROM a TO z AND SPACE. CAPITAL AND NON
; CAPITAL ARE DISPLAYED WITH THE SAME GRAPHIC.
; INPUT    - A0 POINTER TO THE STRING (8 CHAR)
;            A1 POINTER TO THE ADDRESS WHERE TO PUT THE WORDS SEQUENCE
; OUTPUT   - MEMORY FROM (A1) TO (A0+15) MODIFIED.
; MODIFIES - NO REGISTERS MODIFIED
; NOTE     - BEHAVIOR IN FRONT OF CHARS OUTSIDE RANGES A-Z AND a-z AND SPACE
;            IS UNDEFINED
; -----------------------------------------------------------------------------
            MOVE.W  #STRLNGTH,D7             ;Preparar D7 para .LOOP
            SUBQ    #1,D7                   
            
.LOOP       MOVE.B  (A0)+,D5                ;Copiar contenido A0(Str) en D5   
            CMP     #96,D5                  
            BLE     .DECO                   ;<=96 salta pq ya es mayus
            SUB.W   #32,D5                  ;Convierte a mayus(a=97, A=65)
.DECO
            CMP     #0,D5
            BEQ     .FINAL
            JSR     DECOSTR                 ;Salto a subrutina decostr
            MOVE.B  D4,(A1)                 ;Guardar deco str en A1
            ADDQ    #2,A1                   ;Incremento @ A1
            DBRA    D7,.LOOP                
.FINAL
            MOVE.B  #0,D5                   ;Bucle para apagar seg restantes
            JSR     DECOSTR
            MOVE.B  D4,(A1)
            ADDQ    #2,A1
            DBRA    D7,.FINAL 
            RTS
;--------SUBRUTINA DECODIFICAION STRING
DECOSTR:           
	
            CLR.L   D4                      ;Vaciar registro D4 / deco caracter
            
A           CMP     #'A',D5
            BNE     B
            MOVE.B  COD_A,D4
            
B           CMP     #'B',D5
            BNE     C
            MOVE.B  COD_B,D4
            
C           CMP     #'C',D5
            BNE     D
            MOVE.B  COD_C,D4
            
D           CMP     #'D',D5
            BNE     E
            MOVE.B  COD_B,D4
            
E           CMP     #'E',D5
            BNE     F
            MOVE.B  COD_E,D4
            
F           CMP     #'F',D5
            BNE     G
            MOVE.B  COD_F,D4
            
G           CMP     #'G',D5
            BNE     H
            MOVE.B  COD_G,D4
            
H           CMP     #'H',D5
            BNE     I
            MOVE.b  COD_H,D4
            
I           CMP     #'I',D5
            BNE     J
            MOVE.B  COD_I,D4
            
J           CMP     #'J',D5
            BNE     K
            MOVE.B  COD_J,D4
            
K           CMP     #'K',D5
            BNE     L
            MOVE.B  COD_K,D4
            
L           CMP     #'L',D5
            BNE     M
            MOVE.B  COD_L,D4
                  
M           CMP     #'M',D5
            BNE     N                       
            MOVE.B  COD_M,D4
	
N           CMP     #'N',D5
            BNE     O
            MOVE.B  COD_N,D4

O           CMP     #'O',D5
            BNE     P
            MOVE.B  COD_O,D4
	
P           CMP     #'P',D5
            BNE     Q                       
            MOVE.B  COD_P,D4
	
Q           CMP     #'Q',D5
            BNE     R
            MOVE.B  COD_Q,D4
	
R           CMP     #'R',D5
            BNE     S
            MOVE.B  COD_R,D4
	
S           CMP     #'S',D5
            BNE     T
            MOVE.B  COD_S,D4
	
T           CMP     #'T',D5
            BNE     U
            MOVE.B  COD_T,D4
	
U           CMP     #'U',D5
            BNE     V
            MOVE.B  COD_U,D4
	
V           CMP     #'V',D5
            BNE     W
            MOVE.B  COD_V,D4
		
W           CMP     #'W',D5
            BNE     X
            MOVE.B  COD_W,D4

X           CMP     #'X',D5
            BNE     Y
            MOVE.B  COD_X,D4

Y           CMP     #'Y',D5
            BNE     Z
            MOVE.B  COD_Y,D4

Z           CMP     #'Z',D5
            BNE     space
            MOVE.B  COD_Z,D4
	
space       CMP     #' ',D5
            BNE     return
            MOVE.B  COD_SPACE,D4

return 	RTS

; -----------------------------------------------------------------------------
BITPOS
; GIVEN A BYTE, IT RETURNS THE POSITION (VALUE BETWEEN 0 AND 7) OF THE RIGHT-
; MOST BIT VALUED ONE. IF ALL BITS ARE ZERO, OUTPUTS 8
; INPUT    - D0.B THE BYTE
; OUTPUT   - D0.B THE BIT POSITION
; MODIFIES - NO REGISTER, ASIDE OF D0.B
; -----------------------------------------------------------------------------
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
            MOVE.B  #8,D0                   ;00000000                     
            RTS                            

BIT7:
            MOVE.B  #7,D0                   ;10000000
            RTS
BIT6:       
            MOVE.B  #6,D0                   ;X1000000
            RTS
BIT5:
            MOVE.B  #5,D0                   ;XX100000
            RTS
BIT4:
            MOVE.B  #4,D0                   ;XXX10000
            RTS
BIT3:
            MOVE.B  #3,D0                   ;XXXX1000
            RTS
BIT2:
            MOVE.B  #2,D0                   ;XXXXX100
            RTS
BIT1:
            MOVE.B  #1,D0                   ;XXXXXX10
            RTS
BIT0:
            MOVE.B  #0,D0                   ;XXXXXXX1
            
            RTS                                         












*~Font name~Courier New~
*~Font size~14~
*~Tab type~0~
*~Tab size~4~
