*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
            ORG     $1000
    
            INCLUDE "CONST1.X68"      
     
START:                  
            LEA     .STR,A0
            MOVE.L  #$E00000,A1
            JSR     STR2SEG
.LOOP
            MOVE.B  #32,D0
            MOVE.B  #3,D1
            TRAP    #15
            MOVE.L  D1,A0
            JSR     MAPPRBIT
            MOVE.B  D4,(A1)
            BRA     .LOOP
            SIMHALT
.STR        DC.B    'CAll on me'
            DS.W    0
            
MAPPRBIT
            MOVE.B  (A0),D5
            
            CMP     #0,D5
            BNE     SW_1
            MOVE.B  UNO,D4
            MOVE.B  COD_C,D4
            
SW_1        CMP     #1,D5
            BNE     SW_2
            MOVE.B  UNO,D4
            
SW_2        CMP     #2,D5
            BNE     SW_3
            MOVE.B  UNO,D4
            
SW_3        CMP     #3,D5
            BNE     SW_4
            MOVE.B  UNO,D4
            
SW_4        CMP     #4,D5
            BNE     SW_5
            MOVE.B  UNO,D4
            
SW_5        CMP     #5,D5
            BNE     SW_6
            MOVE.B  UNO,D4
            
SW_6        CMP     #6,D5
            BNE     SW_7
            MOVE.B  UNO,D4
            
SW_7        CMP     #7,D5
            BNE     SW_RETURN
            MOVE.B  UNO,D4
            
SW_RETURN   RTS            
            
            
            
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
            MOVE.B  #STRLNGTH,D7             ;Preparar D7 para .LOOP
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
            
;--------SUBRUTINA DE DECODIFICAION STRING
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
            move.b  COD_L,D4
                  
M           cmp	#'M',D5
	bne	N                       
	move.b	COD_M,D4
	
N	cmp	#'N',D5
	bne	O
	move.b	COD_N,D4
	
O	cmp	#'O',D5
	bne	P
	move.b	COD_O,D4
	
P	cmp	#'P',D5
	bne	Q
	move.b	COD_P,D4
	
Q	cmp	#'Q',D5
	bne	R
	move.b	COD_Q,D4
	
R	cmp	#'R',D5
	bne	S
	move.b	COD_R,D4
	
S	cmp	#'S',D5
	bne	T
	move.b	COD_S,D4
	
T	cmp	#'T',D5
	bne	U
	move.b	COD_T,D4
	
U	cmp	#'U',D5
	bne	v
	move.b	COD_U,D4
	
V	cmp	#'V',D5
	bne	W
	move.b	COD_V,D4
		
W	cmp	#'W',D5
	bne	X
	move.b	COD_W,D4

X	cmp	#'X',D5
	bne	Y
	move.b	COD_X,D4

Y	cmp	#'Y',D5
	bne	Z
	move.b	COD_Y,D4
	
Z	cmp	#'Z',D5
	bne	space
	move.b	COD_Z,D4
	
space	cmp	#' ',D5
	bne	return
	move.b	COD_SPACE,D4

return 	RTS

    END    START        ; last line of source





*~Font name~Courier New~
*~Font size~14~
*~Tab type~0~
*~Tab size~4~
