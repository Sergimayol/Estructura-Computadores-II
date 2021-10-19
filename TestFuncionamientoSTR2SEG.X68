*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program
            LEA     .STR,A0
            MOVE.L  #$E00000,A1
            JSR     STR2SEG
            SIMHALT
.STR        DC.B    'HOLAhola'
            DS.W    0
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
            MOVE.B  #.strmax,D7             ;Preparar D7 para .LOOP
            SUBQ    #1,D7                   
            
.LOOP       MOVE.B  (A0)+,D5                ;Copiar contenido A0(Str) en D5   
            CMP     #96,D5                  
            BLE     .DECO                   ;<=96 salta pq ya es mayus
            SUB.W   #32,D5                  ;Convierte a mayus(a=97, A=65)
.DECO
            JSR     DECOSTR                 ;Salto a subrutina decostr
            MOVE.B  D4,(A1)                 ;Guardar deco str en A1
            ADDQ    #2,A1                   ;Incremento @ A1
            DBRA    D7,.LOOP                
            
.strmax     EQU     8                       ;Max length of array
;--------SUBRUTINA DE DECODIFICAION STRING
DECOSTR:           
            CLR.L   D4                      ;Vaciar registro D4 / deco caracter
A           CMP     #'A',D5
            BNE     B
            MOVE.B  #%01110111,D4
            
B           CMP     #'B',D5
            BNE     C
            MOVE.B  #%01111100,D4
            
C           CMP     #'C',D5
            BNE     D
            MOVE.B  #%00111001,D4
            
D           CMP     #'D',D5
            BNE     E
            MOVE.B  #%01011110,D4
            
E           CMP     #'E',D5
            BNE     F
            MOVE.B  #%01111001,D4
            
F           CMP     #'F',D5
            BNE     G
            MOVE.B  #%01110001,D4
            
G           CMP     #'G',D5
            BNE     H
            MOVE.B  #%01111101,D4
            
H           CMP     #'H',D5
            BNE     I
            MOVE.b  #%01110110,D4
            
I           CMP     #'I',D5
            BNE     J
            MOVE.B  #%00000110,D4
            
J           CMP     #'J',D5
            BNE     K
            MOVE.B  #%00011110,D4
            
K           CMP     #'K',D5
            BNE     L
            MOVE.B  #%01110110,D4
            
L           CMP     #'L',D5
            BNE     M
            move.b	#%00111000,D4
                  
M           cmp	#'M',D5
	bne	N                       
	move.b	#%00110111,D4
	
N	cmp	#'N',D5
	bne	O
	move.b	#%01010100,D4
	
O	cmp	#'O',D5
	bne	P
	move.b	#%00111111,D4
	
P	cmp	#'P',D5
	bne	Q
	move.b	#%01110011,D4
	
Q	cmp	#'Q',D5
	bne	R
	move.b	#%00111111,D4
	
R	cmp	#'R',D5
	bne	S
	move.b	#%01010000,D4
	
S	cmp	#'S',D5
	bne	T
	move.b	#%01101101,D4
	
T	cmp	#'T',D5
	bne	U
	move.b	#%01111000,D4
	
U	cmp	#'U',D5
	bne	v
	move.b	#%00111110,D4
	
V	cmp	#'V',D5
	bne	W
	move.b	#%00111110,D4
		
W	cmp	#'W',D5
	bne	X
	move.b	#%00111110,D4

X	cmp	#'X',D5
	bne	Y
	move.b	#%01110110,D4

Y	cmp	#'Y',D5
	bne	Z
	move.b	#%01100110,D4
	
Z	cmp	#'Z',D5
	bne	space
	move.b	#%01011011,D4
	
space	cmp	#' ',D5
	bne	return
	move.b	#%00000000,D4

return 	RTS

    END    START        ; last line of source


*~Font name~Courier New~
*~Font size~14~
*~Tab type~0~
*~Tab size~4~
