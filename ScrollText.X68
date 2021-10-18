*-----------------------------------------------------------
* Program Number: Final Project
* Written by    : Alan Swanson
* Date Created  : 1-29-05
* Description   : Enter a string of no more than 80 charaters 
*	lower or upper case and convert to upper case
*	and scroll the string on the hardware display
*-----------------------------------------------------------
START	ORG	$1000

*Title Message
		move.b	#14,d0		escape code to print a string
		lea	(TitleMsg,PC),a1	point to address of message
		trap	#15		print to screen

*Prompt Message
		move.b	#14,d0		escape code for printing a message
		lea	(PromptMsg,PC),a1	point to address of message
		trap	#15		print to screen

*user input
		move.b	#2,d0		escape code to enter a string
		lea	(buffer1,PC),a1	put the address of the buffer into a1
		trap	#15		print to screen
		move	d1,blen		length of string
		
		lea	(buffer2,PC),a5	points to the address of buffer2
		move.b 	#0,d2		set up loop counter

		lea	(buffer3,PC),a6	holds the letter to binary convertion

next		move.b	(a1)+,d1	move address to d1
		cmp	#96,d1		test for non lowercase letters
		ble	converted	test for <= 96

		cmp	#122,d1		test for >= 122
		bge	converted

		sub	#32,d1		convert to uppercase
		
converted	move.b	d1,(a5)+	moves d1 to address pointed to by a2
		add	#1,d2		increment loop
		
		move.b	d1,d5
		bsr	digit
		move.b	d4,(a6)+

		cmp	(blen,PC),d2		compare string length to loop counter
		ble	next		branch <= blen (string length)

		clr.l	d7
pad		move.b	#$00,(a6)+
		add.b	#1,d7
		cmp	#7,d7
		ble	pad

		add.w	#8,blen		

		*move.b	#14,d0		escape code to print a string
		*lea	(UpMsg,PC),a1	point to UpMsg address
		*trap 	#15		print to screen

		*move.b #14,d0		escape code to print a string
		*lea	(buffer2,PC),a1	point to new string
		*trap 	#15		print to screen

******************Hardware device***************************************

	move.b	#32,d0	trap task to get address of hardware
	move.b	#0,d1
	trap	#15	display hardware window
	move.b	#1,d1	
	trap	#15	get address of 7-segment display
	move.l	d1,a4	a4  = address of 7-segment display
	move.b	#2,d1
	trap	#15	get address of LEDs
	move.l	d1,a3	a3 = address of LEDs
	*move.b	#2,(a3)	light up a LED

	move.b	#3,d1
	trap	#15
	move.l	d1,a2
	adda.l	#14,a4

	lea	(buffer3,PC),a6
	move.w	blen,d5
		
	clr.l	d7
loop	move.b	(a2),d6		get number from switch
	move.b	d6,(a3)		light LED's
		
	cmp	d5,d7
	ble	pass
	lea	(buffer3,PC),a6
	move.l	#0,d7

pass	move.b	(a6)+,num1	display segment one
	move.b	num1,(a4)

	suba.l	#2,a4		display segment two
	move.b	num2,(a4)

	suba.l	#2,a4		display segment three
	move.b	num3,(a4)

	suba.l	#2,a4		display segment four
	move.b	num4,(a4)

	suba.l	#2,a4		display segment five
	move.b	num5,(a4)

	suba.l	#2,a4		display segment six
	move.b	num6,(a4)

	suba.l	#2,a4		display segment seven
	move.b	num7,(a4)

	suba.l	#2,a4		display segment eight
	move.b	num8,(a4)

	adda.l	#14,a4 
	
	add.b	#1,d7

	move.b	num7,num8
	move.b	num6,num7
	move.b	num5,num6
	move.b	num4,num5
	move.b	num3,num4
	move.b	num2,num3
	move.b	num1,num2


	move.b	#8,d0			delay switches determine delay time
	trap	#15
	move.l	d1,d3
	repeat
		trap	#15
		sub.l	d3,d1
	until.l d1 <hi> d6 do

	clr.l	d6
	bra	loop
	





		STOP	#$2000
digit 	clr.l	d4
A	cmp	#'A',d5
	bne	B
	*move.b	#%01110111,d4
	move.b	#%01111000,d4
	
B	cmp	#'B',d5
	bne	C
	move.b	#%01111100,d4
	
C	cmp	#'C',d5
	bne	D
	move.b	#%00111001,d4
	
D	cmp	#'D',d5
	bne	E
	move.b	#%01011110,d4
	
E	cmp	#'E',d5
	bne	F
	move.b	#%01111001,d4
	
F	cmp	#'F',d5
	bne	G
	move.b	#%01110001,d4
	
G	cmp	#'G',d5
	bne	H
	move.b	#%01111101,d4
	
H	cmp	#'H',d5
	bne	I
	move.b	#%01110110,d4
	
I	cmp	#'I',d5
	bne	J
	move.b	#%00000110,d4
	
J	cmp	#'J',d5
	bne	K
	move.b	#%00011110,d4
	
K	cmp	#'K',d5
	bne	L
	move.b	#%01110100,d4
	move.b	d4,(a6)+
	add.w	#1,blen
	move.b	#%00100000,d4
	
L	cmp	#'L',d5
	bne	M
	move.b	#%00111000,d4
	
M	cmp	#'M',d5
	bne	N
	move.b	#%00110011,d4
	move.b	d4,(a6)+
	add.w	#1,blen
	move.b	#%00100111,d4
	
N	cmp	#'N',d5
	bne	O
	move.b	#%01010100,d4
	
O	cmp	#'O',d5
	bne	P
	move.b	#%00111111,d4
	
P	cmp	#'P',d5
	bne	Q
	move.b	#%01110011,d4
	
Q	cmp	#'Q',d5
	bne	R
	move.b	#%00111101,d4
	move.b	d4,(a6)+
	add.w	#1,blen
	move.b	#%00011111,d4
	
R	cmp	#'R',d5
	bne	S
	move.b	#%01010000,d4
	
S	cmp	#'S',d5
	bne	T
	move.b	#%01101101,d4
	
T	cmp	#'T',d5
	bne	U
	move.b	#%00000111,d4
	move.b	d4,(a6)+
	add.w	#1,blen
	move.b	#%00000001,d4
	
U	cmp	#'U',d5
	bne	v
	move.b	#%00111110,d4
	
V	cmp	#'V',d5
	bne	W
	move.b	#%01100100,d4
	move.b	d4,(a6)+
	add.w	#1,blen
	move.b	#%01000010,d4
	
W	cmp	#'W',d5
	bne	X
	move.b	#%00111100,d4
	move.b	d4,(a6)+
	add.w	#1,blen
	move.b	#%00011110,d4
	
X	cmp	#'X',d5
	bne	Y
	move.b	#%01110000,d4
	move.b	d4,(a6)+
	add.w	#1,blen
	move.b	#%01000110,d4
	
Y	cmp	#'Y',d5
	bne	Z
	move.b	#%01100110,d4
	
Z	cmp	#'Z',d5
	bne	dash
	move.b	#%01011011,d4
dash	cmp	#'-',d5
	bne	per
	move.b	#%01000000,d4
per	cmp	#'.',d5
	bne	space
	move.b	#$80,d4
	
space	cmp	#' ',d5
	bne	return
	move.b	#%00000000,d4


return 	rts

*Constants
CR		equ	$0d		cariage return
LF		equ	$0a		line feed
buffer1		ds.b	80		first string
		ds.w	0
buffer2		ds.b 	80		second string
		ds.w	0
blen		ds.w	1		length of inputed string

buffer3		ds.b	80		converted letter to binary

num	ds.l	1
reset	ds.l	1
delay1	ds.w	1
delay2	ds.w	1
num1	ds.b	1
num2	ds.b	1
num3	ds.b	1
num4	ds.b	1
num5	ds.b	1
num6	ds.b	1
num7	ds.b	1
num8	ds.b	1


*Messages
UpMsg		dc.b	CR,LF,CR,LF,'The new uppercase string is ',CR,LF,0
TitleMsg	dc.b	'This program scrolls strings to the hardware device',CR,LF,CR,LF
		dc.b	'Press the toggle switches to control the speed',CR,LF,CR,LF,0
PromptMsg	dc.b	'Enter a string lower or upper case 80 charaters max',CR,LF,0
	
	END	START


*~Font name~Courier New~
*~Font size~14~
*~Tab type~0~
*~Tab size~4~
