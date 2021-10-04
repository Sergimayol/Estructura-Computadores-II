*-----------------------------------------------------------
* Title      : Colors 68k
* Written by : Sergi
* Date       : 04/10/2021
* Description: Basic color values of 68k.
*-----------------------------------------------------------   
         
            ORG     $1000
            
*--------Constant values------------------------------------
BLACK       equ     $00000000
MAROON      equ     $00000080
GREEN       equ     $00008000
OLIVE       equ     $00008080
NAVY        equ     $00800000
PURPLE      equ     $00800080
TEAL        equ     $00808000
GRAY        equ     $00808080
RED         equ     $000000FF
LIME        equ     $0000FF00
YELLOW      equ     $0000FFFF
BLUE        equ     $00FF0000
FUCHSIA     equ     $00FF00FF
AQUA        equ     $00FFFF00
LTGRAY      equ     $00C0C0C0
WHITE       equ     $00FFFFFF*-----------------------------------------------------------
START:                  ; first instruction of program

* Put program code here

            SIMHALT             ; halt simulator

* Put variables and constants here

            END    START        ; last line of source

*~Font name~Courier New~
*~Font size~16~
*~Tab type~0~
*~Tab size~4~
