*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
            ORG     $1000
    
            INCLUDE "AUXILIAR.X68"
            
MAPBUTAD    DS.L    1 
MAPSEGAD    DS.L    1          
     
START:      
            
            MOVE.L  #$E00014,A0
            MOVE.L  #$E00000,A1
.LOOP
            
            JSR     MAPPRBIT
            BRA     .LOOP
            
            SIMHALT
            
            
MAPPRBIT    
            MOVE.L  A0,MAPBUTAD             ; Guardar @ A0
            MOVE.L  A1,MAPSEGAD             ; Guardar @ A1  
            MOVE.B  (A0),D0                 ; Preparamos D0, (A0) bits botones 
            BSR     BITPOS                  ; Obtenemos en D0 valor botones
            JSR     STR                     ; Obtenemos valor en A0 de info a mostrar
            BSR     STR2SEG                 ; Mostrar info en display
            MOVE.L  MAPBUTAD,A0             ; Restaurar @ A0
            MOVE.L  MAPSEGAD,A1             ; Restaurar @ A1
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
                      

    END    START        ; last line of source














*~Font name~Courier New~
*~Font size~14~
*~Tab type~0~
*~Tab size~4~
