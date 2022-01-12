*-----------------------------------------------------------
* Program Number: 6_11 Conway's Life
* Written by    : Daniel W Strimpel
* Date Created  : 2-27-04
* Modified      : May-17-2004 by Chuck Kelly
*       I was so impressed by Dan's program that I thought it would make a
*       nice demonstration for the structured assembly syntax. It might be
*       fun to be able to save and load cell patterns. I'll leave that for
*       someone else to do :)
*
*                 May-22-2004 by Daniel Strimpel
*       I added the feature to read in the initial pattern from a file with
*       any extention. The file must be generated in the program because
*       I found that any files made outside of this program have each
*       character a word value, whereas this program only has each character
*       a byte value. I also added the feature to save files to any type of
*       extension. This makes it easy to create and save any patterns for
*       future opening. The clear feature was also added to clear the screen
*       of all data.
*
*                 August-23-2005 by Aaron Curley (Part of the fix was provided by Lee Davison)
*       Fixed the 'paintCell', 'drawGrid', and 'drawCursor' routines so they would  
*       draw correctly on the new simulator version. 
*
*		  October-18-2008 by Chuck Kelly
*	Added mouse support.
*	Detection of Sim68K version
*
* Description   : This program is Conway's Life
*           If a cell is occupied and 2 or 3 of its neighbors are occupied
*           then it stays occupied. If less than 2 or more than 4 neighbors
*           are occupied the cell dies. If a cell is unoccupied and 3 of its
*           neighbors are occupied then it becomes occupied.
*
* 
*-----------------------------------------------------------

	ORG	$1000
ESC	EQU	$1B
CAP_O	EQU	$4F
CAP_S	EQU	$53
SPACE	EQU	$20
COLSIZE	EQU	9
ROWSIZE	EQU	7
COLS	EQU	63
ROWS	EQU	63
GLEFT	EQU	32
GTOP	EQU	30
GBOTTOM EQU	GTOP+ROWS*ROWSIZE-1
GRIGHT	EQU	GLEFT+COLS*COLSIZE-1
NORMAL	EQU	0
HIGHLIGHT EQU	1

* buttons
QUIT_BTN	EQU	0		; button sequence
START_BTN	EQU	1
STOP_BTN	EQU	2
OPEN_BTN	EQU	3
SAVE_BTN	EQU	4
CLEAR_BTN	EQU	5
BUTTONS_LEFT	EQU	10		; left edge of button menu in pixels
BUTTON_WIDTH	EQU	61		; width of each button
BUTTON_HEIGHT	EQU	21		; height of each button
BUTTON_GAP	EQU	9		; gap between buttons
BUTTON_TOP	EQU	5
BUTTON_BOTTOM	EQU	BUTTON_TOP+BUTTON_HEIGHT
QUIT_LEFT	EQU	QUIT_BTN*(BUTTON_WIDTH+BUTTON_GAP)+BUTTONS_LEFT
START_LEFT	EQU	START_BTN*(BUTTON_WIDTH+BUTTON_GAP)+BUTTONS_LEFT
STOP_LEFT	EQU	STOP_BTN*(BUTTON_WIDTH+BUTTON_GAP)+BUTTONS_LEFT
OPEN_LEFT	EQU	OPEN_BTN*(BUTTON_WIDTH+BUTTON_GAP)+BUTTONS_LEFT
SAVE_LEFT	EQU	SAVE_BTN*(BUTTON_WIDTH+BUTTON_GAP)+BUTTONS_LEFT
CLEAR_LEFT	EQU	CLEAR_BTN*(BUTTON_WIDTH+BUTTON_GAP)+BUTTONS_LEFT

GREEN	equ	$00008000
LTGRAY	equ	$00C0C0C0
DKGRAY	equ	$00404040
BLACK	equ	$00000000
WHITE	equ	$00FFFFFF
MAROON	equ	$00000080
LIME	EQU	$0000FF00


* cell offsets
UL	equ	-COLS-1			Upper Left
UM	equ	-COLS			Upper Middle
UR	equ	-COLS+1			Upper Right
L	equ	-1			Left
R	equ	1			Right
LL	equ	COLS-1			Lower Left
LM	equ	COLS			Lower Middle
LR	equ	COLS+1			Lower Right
ULWRAP	equ	-1			Upper Left Wrapped around to right edge
URWRAP	equ	-COLS-COLS+1		Upper Right Wrapped around to left edge
LWRAP	equ	COLS-1			Left Wrapped around to right edge
RWRAP	equ	-COLS+1			Right Wrapped around to left edge
LLWRAP	equ	COLS+COLS-1		Lower Left Wrapped around to right edge
LRWRAP	equ	1			Lower Right Wrapped around to left edge

* Checks for keypress, if key pending returns it in D1.B, else returns 0
READ_KEY MACRO
  move.b #7,d0
  trap       #15			check for pending key
  if.b d1 <ne> #0 then			if key pending
    move.b  #5,d0
    trap    #15				read key into d1
  endi
  ENDM

* Set the pen color
SET_PEN MACRO
  movem.l d0-d1,-(sp)
  move.l  #\1,d1
  move.b  #80,d0
  trap    #15
  movem.l (sp)+,d0-d1
  ENDM

* Set the fill color
SET_FILL MACRO
  movem.l d0-d1,-(sp)
  move.l  #\1,d1
  move.b  #81,d0
  trap    #15
  movem.l (sp)+,d0-d1
  ENDM

* Display text on top of screen
DISPLAY_TEXT MACRO
  movem.l d0-d1/a1,-(sp)
  move.w  #0,d1
  move.b  #11,d0			set text position to top
  trap    #15
  move.b  #14,d0    			display text
  lea	  \1,a1
  trap    #15
  movem.l (sp)+,d0-d1/a1
  ENDM

* Set echo to on or off
SET_ECHO MACRO
  IFC '\1','ON'
    move.b #1,d1
  ENDC
  IFC '\1','OFF'
    move.b #0,d1
  ENDC
  move.b  #12,d0
  trap    #15
  ENDM
  
* Delay for hundredths of a second in param 1
DELAY MACRO
  move.b  #23,d0			trap task 23
  move.l  #\1,d1			delay amount
  trap    #15
  ENDM

*-----------------------------------------------------------
button	macro
  movem.l d1-d4/a1,-(sp)
  move.l #(\1*(BUTTON_WIDTH+BUTTON_GAP)+BUTTONS_LEFT),d1	; left
  move.l #BUTTON_TOP,d2			; top
  move.l #\1,d3				; button number
  lea	 \2,a1				; caption
  move.l #\3,d4				; normal or highlighted
  bsr	 drawButton
  movem.l (sp)+,d1-d4/a1
  endm
  
********************** PROGRAM START ******************************
START:
  * Initialize Trap #15 vector
  move.l  #versionTrap,$BC		; Trap #15
  move.b  #4,d1				; request Sim68K version number
  move.b  #32,d0			; task 32 Simulator Environment
  trap    #15
  * If Sim68K is new enough to have task 32 then the trap will return to here.
  * D1.L will contain the version number or be unchanged on versions that do not
  * understand the #4 version number request.
  * If the simulator is too old to have task 32 then the versionTrap
  * handler below will end the program.
  if.l d1 <lo> #$040000 then.s		; if version prior to 4.0.0
    bra   oldVersion			; display message and end
  endi

  * Initialize IRQ vectors 
  move.l  #mouseUpIRQ,$64		; IRQ1
  move.b  #60,d0			; set mouse IRQ
  move.w  #$0102,d1			; IRQ1 for mouse up
  trap	  #15

  move.l  #mouseDownIRQ,$68		; IRQ2
  move.b  #60,d0			; set mouse IRQ
  move.w  #$0201,d1			; IRQ2 for mouse down
  trap	  #15

  move.l  #mouseMoveIRQ,$6C		; IRQ3
  move.b  #60,d0			; set mouse IRQ
  move.w  #$0304,d1			; IRQ3 for mouse move
  trap	  #15

  
  move.b  #32,d0			; Simulator Environment
  move.b  #05,d1			; Enable Exceptions
  trap    #15 

  bsr     drawGrid  			; draw starting grid
  lea     grid1,a3
  lea     grid2,a4
  SET_ECHO OFF  

  clr.l  d6				; d6 is row
  clr.l  d7				; d7 is col

*------------------------- MAIN LOOP ------------------------------
  bsr dispMenu1
  repeat
    repeat
      DELAY 1 				; 1/100 delay to reduce CPU workload
    until.b life <hi> #0 or.b quit <hi> #0 do
    if.b life <hi> #0 then.s
      bsr lifeCycle 			; life begins
    endi
  until.b quit <hi> #0 do

  move.w  #$FF00,d1
  move.b  #11,d0
  trap    #15				; clear the screen

exit
  MOVE.B	#9,D0
  TRAP	#15				; Halt Simulator

oldVersion
  DISPLAY_TEXT  oldVerMsg
  bra  exit

*------------------------------------------------------------------
* IRQ handlers

* mouse handler 
*   Trap #15 Task 61 reads mouse 
*      D1.B = 00 to read current state of mouse
*           = 01 to read mouse up state
*           = 02 to read mouse down state
*      The mouse data is contained in the following registers
*      D0 as bits = Ctrl, Alt, Shift, Double, Middle, Right, Left
*           Left is Bit0, Right is Bit 1 etc.
*           1 = true, 0 = false
*           Shift, Alt, Ctrl represent the state of the corresponding keys.
*      D1.L = 16 bits Y, 16 bits X in pixel coordinates. (0,0 is top left)
mouseDownIRQ
	movem.l	d0-d2,-(sp)
	move.b	#61,d0		; read mouse
	move.b	#2,d1		; mouse down state
	trap	#15
	clr.l	d2
	move.w	d1,d2		; d2 is mouse X
	swap	d1		; d1 is mouse Y
	and.l	#$0FFFF,d1

	; if mouse inside grid
	if.w d2 <hs> #GLEFT and.w d2 <ls> #GRIGHT then.s
	  if.w d1 <hs> #GTOP and.w d1 <ls> #GBOTTOM then.s
	    if.b life <eq> #0 then.s	; if in edit mode
              sub.w #GLEFT,d2
              divu #COLSIZE,d2
              move.w d2,d7	; d7 is X
              sub.w #GTOP,d1
              divu #ROWSIZE,d1
              move.w d1,d6	; d6 is Y
              lsr.b #1,d0
              if <cs> then.s	; if left button click
                bsr  cellOn
              else
                lsr.b #1,d0
                if <cs> then.s	; if right button click
                  bsr  cellOff
                endi
              endi
              bra  exitMD
            endi
	  endi
	endi
	
	; if mouse inside button
	if.w d1 <hi> #BUTTON_TOP and.w d1 <lo> #BUTTON_BOTTOM then	if inside button height range
          if.w d2 <hs> #QUIT_LEFT and.w d2 <ls> #QUIT_LEFT+BUTTON_WIDTH then
            button QUIT_BTN,QuitBtn,HIGHLIGHT
            move.b #1,quit
            bra    exitMD
          endi
          if.w d2 <hs> #START_LEFT and.w d2 <ls> #START_LEFT+BUTTON_WIDTH then
            button START_BTN,StartBtn,HIGHLIGHT
            move.b #1,life
            bra    exitMD
          endi
          if.w d2 <hs> #STOP_LEFT and.w d2 <ls> #STOP_LEFT+BUTTON_WIDTH then
            button STOP_BTN,StopBtn,HIGHLIGHT
            move.b #0,life
            bra    exitMD
          endi
          if.w d2 <hs> #OPEN_LEFT and.w d2 <ls> #OPEN_LEFT+BUTTON_WIDTH then
            button OPEN_BTN,OpenBtn,HIGHLIGHT
            bra exitMD
          endi
          if.w d2 <hs> #SAVE_LEFT and.w d2 <ls> #SAVE_LEFT+BUTTON_WIDTH then
            button SAVE_BTN,SaveBtn,HIGHLIGHT
            bra exitMD
          endi
          if.w d2 <hs> #CLEAR_LEFT and.w d2 <ls> #CLEAR_LEFT+BUTTON_WIDTH then
            button CLEAR_BTN,ClearBtn,HIGHLIGHT
            move.b #0,life
            bsr clearData
            bsr drawGrid1
          endi
	endi	  
exitMD	movem.l	(sp)+,d0-d2
	rte

mouseUpIRQ
	bsr dispMenu1
	movem.l	d0-d2,-(sp)
	move.b	#61,d0		; read mouse
	move.b	#1,d1		; mouse up state
	trap	#15
	clr.l	d2
	move.w	d1,d2		; d2 is mouse X
	swap	d1		; d1 is mouse Y
	and.l	#$0FFFF,d1

	; if mouse inside button
	if.w d1 <hi> #BUTTON_TOP and.w d1 <lo> #BUTTON_BOTTOM then	if inside button height range
          if.w d2 <hs> #OPEN_LEFT and.w d2 <ls> #OPEN_LEFT+BUTTON_WIDTH then
            move.b #0,life
            bsr openFile
            bsr drawGrid1			draw data on grid
            bra exitMU
          endi
          if.w d2 <hs> #SAVE_LEFT and.w d2 <ls> #SAVE_LEFT+BUTTON_WIDTH then
            move.b #0,life
            bsr saveData
            bra exitMU
          endi
	endi	  
exitMU	movem.l	(sp)+,d0-d2
	rte

mouseMoveIRQ
	movem.l	d0-d2,-(sp)
	move.b	#61,d0		; read mouse
	move.b	#0,d1		; mouse state
	trap	#15
	clr.l	d2
	move.w	d1,d2		; d2 is mouse X
	swap	d1		; d1 is mouse Y
	and.l	#$0FFFF,d1

	; if mouse inside grid
	if.w d2 <hs> #GLEFT and.w d2 <ls> #GRIGHT then.s
	  if.w d1 <hs> #GTOP and.w d1 <ls> #GBOTTOM then.s
	    if.b life <eq> #0 then.s	; if in edit mode
              sub.w #GLEFT,d2
              divu #COLSIZE,d2
              move.w d2,d7	; d7 is X
              sub.w #GTOP,d1
              divu #ROWSIZE,d1
              move.w d1,d6	; d6 is Y
              lsr.b #1,d0
              if <cs> then.s	; if left button click
                bsr  cellOn
              else
                lsr.b #1,d0
                if <cs> then.s	; if right button click
                  bsr  cellOff
                endi
              endi
            endi
	  endi
	endi
	
	movem.l	(sp)+,d0-d2
	rte

*---------------------------------------------------------------
* If the trap call to get the version number of Sim68K fails
* it will come here which means it is an older verion.
versionTrap
  bra oldVersion
	

*------------------- LIFE CYCLES -------------------------------
* each loop is one generation of life
* the cells are processed from top to bottom and left to right
* loop until user quits
  
lifeCycle
  
  movem.l d0-d7/a0-a6,-(a7)
  
  repeat

    move.l  a3,a5			save a3
    move.l  a4,a6			save a4
    clr d6
    clr d7

    move.l a3,a2
    adda.l #(ROWS-1)*COLS,a2		address of bottom row in a2

    * process the top left corner and wrap the edges
    clr    d0
    add.b  (COLS-1,a2),d0		add upper left cell (wrap around from lower right corner)
    add.b  (a2),d0			add upper middle cell (wrap around from bottom row)
    add.b  (R,a2),d0			add upper right cell (wrap around from bottom row)
    add.b  (LWRAP,a3),d0		add left cell (wrap around to right edge)
    add.b  (R,a3),d0			add right cell
    add.b  (LLWRAP,a3),d0		add lower left cell (wrap around to right edge)
    add.b  (LM,a3),d0			add lower middle cell
    add.b  (LR,a3),d0			add lower right cell
    bsr    drawCell

    * process the top row (except for the corners) and wrap the edge around to the bottom row
    for d7 = #1 to #COLS-2 do		for each col except ends
      clr    d0
      add.b  (L,a2,d7),d0		add upper left cell (wrap around from bottom row)
      add.b  (a2,d7),d0			add upper middle cell (wrap around from bottom row)
      add.b  (R,a2,d7),d0		add upper right cell (wrap around from bottom row)
      add.b  (L,a3,d7),d0		add left cell
      add.b  (R,a3,d7),d0		add right cell
      add.b  (LL,a3,d7),d0		add lower left cell
      add.b  (LM,a3,d7),d0		add lower middle cell
      add.b  (LR,a3,d7),d0		add lower right cell
      bsr    drawCell
    endf
    
    * process the top right corner and wrap the edges
    clr    d0
    add.b  (L,a2,d7),d0			add upper left cell (wrap around from bottom row)
    add.b  (a2,d7),d0			add upper middle cell (wrap around from bottom row)
    add.b  (a2),d0			add upper right cell (wrap around from lower left corner)
    add.b  (L,a3,d7),d0			add left cell
    add.b  (RWRAP,a3,d7),d0		add right cell (wrap around to left edge)
    add.b  (LL,a3,d7),d0		add lower left cell
    add.b  (LM,a3,d7),d0		add lower middle cell
    add.b  (LRWRAP,a3,d7),d0		add lower right cell (wrap around to left edge)
    bsr    drawCell

    adda.l  #COLS,a3			address of next row
    adda.l  #COLS,a4

    * process the rest of the rows (except the bottom)
    for d6 = #1 to #ROWS-2 do		for rest of rows (except bottom)

      clr    d7
      * process the left edge and wrap around
      clr    d0
      add.b  (ULWRAP,a3),d0		add upper left cell (wrap around to right edge)
      add.b  (UM,a3),d0			add upper middle cell
      add.b  (UR,a3),d0			add upper right cell
      add.b  (LWRAP,a3),d0		add left cell (wrap around to right edge)
      add.b  (R,a3),d0			add right cell
      add.b  (LLWRAP,a3),d0		add lower left cell (wrap around to right edge)
      add.b  (LM,a3),d0			add lower middle cell
      add.b  (LR,a3),d0			add lower right cell
      bsr    drawCell

      * process the rest of the cells in this row (except the right edge)
      for d7 = #1 to #COLS-2 do		for each col
        clr	d0
	add.b	(UL,a3,d7),d0		add upper left cell
	add.b	(UM,a3,d7),d0		add upper middle cell
	add.b	(UR,a3,d7),d0		add upper right cell
	add.b	(L,a3,d7),d0		add left cell
	add.b	(R,a3,d7),d0		add right cell
	add.b	(LL,a3,d7),d0		add lower left cell
	add.b	(LM,a3,d7),d0		add lower middle cell
	add.b	(LR,a3,d7),d0		add lower right cell
        bsr     drawcell		draw cell at d6,d7
      endf

      * process the right edge and wrap around
      clr    d0
      add.b  (UL,a3,d7),d0		add upper left cell
      add.b  (UM,a3,d7),d0		add upper middle cell
      add.b  (URWRAP,a3,d7),d0		add upper right cell
      add.b  (L,a3,d7),d0		add left cell
      add.b  (RWRAP,a3,d7),d0		add right cell (wrap around to left edge)
      add.b  (LL,a3,d7),d0		add lower left cell
      add.b  (LM,a3,d7),d0		add lower middle cell
      add.b  (LRWRAP,a3,d7),d0		add lower right cell (wrap around to left edge)
      bsr    drawCell

      adda.l  #COLS,a3			address of next row
      adda.l  #COLS,a4

    endf


    * process the bottom row (address of top row is in a5)

    * process the bottom left corner and wrap the edges
    clr    d0
    clr    d7
    add.b  (ULWRAP,a3),d0		add upper left cell (wrap around to right edge)
    add.b  (UM,a3),d0			add upper middle cell
    add.b  (UR,a3),d0			add upper right cell
    add.b  (LWRAP,a3),d0		add left cell (wrap around to right edge)
    add.b  (R,a3),d0			add right cell
    add.b  (COLS-1,a5),d0		add lower left cell (wrap around from upper right corner)
    add.b  (a5),d0			add lower middle cell (wrap around from top row)
    add.b  (R,a5),d0			add lower right cell (wrap around from top row)
    bsr    drawCell

    * process the bottom row (except for the corners) and wrap the edge around to the top row
    for d7 = #1 to #COLS-2 do		for each col except ends
      clr    d0
      add.b  (UL,a3,d7),d0		add upper left cell
      add.b  (UM,a3,d7),d0		add upper middle cell
      add.b  (UR,a3,d7),d0		add upper right cell
      add.b  (L,a3,d7),d0		add left cell
      add.b  (R,a3,d7),d0		add right cell
      add.b  (L,a5,d7),d0		add lower left cell (wrap around from top row)
      add.b  (a5,d7),d0			add lower middle cell (wrap around from top row)
      add.b  (R,a5,d7),d0		add lower right cell (wrap around from top row)
      bsr    drawCell
    endf
    
    * process the bottom right corner and wrap the edges
    clr    d0
    add.b  (UL,a3,d7),d0		add upper left cell
    add.b  (UM,a3,d7),d0		add upper middle cell
    add.b  (URWRAP,a3,d7),d0		add upper right cell (wrap around from left edge)
    add.b  (L,a3,d7),d0			add left cell
    add.b  (RWRAP,a3,d7),d0		add right cell (wrap around to left edge)
    add.b  (L,a5,d7),d0			add lower left cell (wrap around from top row)
    add.b  (a5,d7),d0			add lower middle cell (wrap around from top row)
    add.b  (a5),d0			add lower right cell (wrap around from upper left corner)
    bsr    drawCell

    move.l a6,a3			swap grid1 with grid2
    move.l a5,a4

  until.b life <eq> #0 or.b quit <hi> #0 do	loop until stop
  movem.l (a7)+,d0-d7/a0-a6
  rts

*-----------------------------------------------------------*
drawCell: 
  if.b (a3,d7) <ne> #0 then.s			if cell alive
    if.b d0 <eq> #2 OR.b d0 <eq> #3 then.s	if 2 or 3 neighbors
      move.b #1,(a4,d7)				keep alive
    else.s
      move.b #0,(a4,d7)				kill
      SET_FILL      BLACK			set fill color to black
      bsr   paintCell				clear cell at d6,d7
    endi
  else      else, cell dead
    if.b d0 <eq> #3 then.s			if 3 neighbors
      move.b #1,(a4,d7)				cell is born
      SET_FILL      LTGRAY			set fill color to ltGray
      bsr   paintCell				set cell at d6,d7
    else
      move.b #0,(a4,d7)				clear cell in grid
    endi
  endi
  rts

*-----------------------------------------------------------
*
* Name      : drawGrid
* Purpose   : Draws the gameGrid
* Registers : d0->trap code
*             d1->color/x1
*             d2->y1
*             d3->x2
*             d4->y2
*             d5->counter
drawGrid
* Save working registers
  movem.l d0-d5,-(a7)

* Display Grid
  SET_PEN GREEN				; set pen color to green

* Draw vertical grid lines
  move.b #84,d0
  move.w #GLEFT,d1
  move.w #GTOP,d2
  move.w #GLEFT,d3
  move.w #GBOTTOM,d4

  dbloop d5 = #COLS
    trap #15				; draw line from d1,d2 to d3,d4
    add.w #COLSIZE,d1
    move.w d1,d3
  unless

* Draw horizontal grid lines
  move.w #GLEFT,d1
  move.w #GRIGHT,d3			; This line was changed by Aaron Curley
  move.w #GTOP,d4

  dbloop d5 = #ROWS
    trap #15				; draw line from d1,d2 to d3,d4
    add.w #ROWSIZE,d2
    move.w d2,d4
  unless
  
* Restore registers
  movem.l (a7)+,d0-d5
  rts

*------------------------------------------------------------
* Fill the screen grid with the data from grid1

drawGrid1
  movem.l d0-d4/d6-d7/a3,-(a7)
  lea  grid1,a3
  for.b d3 = #0 to #ROWS-1 do.s		; for each row
    for.b d4 = #0 to #COLS-1 do.s	; for each col
      move.w d3,d2
      move.w d4,d1
      bsr getColor
      if.l d0 <eq> #LTGRAY AND.b (A3,D4) <eq> #0 then.s
        SET_FILL BLACK
        move.w d3,d6
        move.w d4,d7
        bsr paintCell
      else.s
        if.l d0 <eq> #BLACK AND.b (A3,D4) <eq> #1 then.s
          SET_FILL LTGRAY
          move.w d3,d6
          move.w d4,d7
          bsr paintCell
        endi
      endi
    endf
    adda.l  #COLS,a3			; address of next row
  endf
  movem.l (a7)+,d0-d4/d6-d7/a3
  rts

*-----------------------------------------------------------
*
* Name      : paintCell
* Purpose   : Draws the gameGrid squares
* Registers : d0->trap code
*             d1->color/x1
*             d2->y1
*             d3->x2
*             d4->y2
*             d5->square value
*	      d6->row
*	      d7->col
  
paintCell
* Save working registers
            movem.l d0-d4,-(a7)

* figure out column and row info for square
            clr.l   d1
            move.b  #87,d0		; draw filled rectangle trap code

            move.b  d7,d1
            mulu    #COLSIZE,d1
            add.w   #GLEFT,d1

            move.w  d1,d3
            add.w   #COLSIZE,d3		; This line was changed by Aaron Curley            

            move.b  d6,d2
            mulu    #ROWSIZE,d2
            add.w   #GTOP,d2
            move.w  d2,d4
            add.w   #ROWSIZE,d4		; This line was changed by Aaron Curley
* display square
            trap    #15
  
* restore registers

            movem.l (a7)+,d0-d4
            rts


*-----------------------------------------------------------
cellOff:
  move.w  #COLS,d0
  mulu    d6,d0     			; multipy by row position
  add     d7,d0     			; add col position
  move.b   #0,(a3,d0)			; cell off
  move.b   #0,(a4,d0)			; cell off
  SET_FILL BLACK  			; set fill color to black
  bsr	paintCell			; clear cell at d6,d7
  rts

*-----------------------------------------------------------
cellOn:
  move.w  #COLS,d0
  mulu    d6,d0     			; multipy by row position
  add     d7,d0     			; add col position
  move.b   #1,(a3,d0)			; cell on
  move.b   #1,(a4,d0)			; cell on
  SET_FILL LTGRAY			; set fill color to ltGray
  bsr	paintCell			; set cell at d6,d7
  rts

*-----------------------------------------------------------
changeCell:
  move.w  #COLS,d0
  mulu    d6,d0     			; multipy by row position
  add     d7,d0     			; add col position
  if.b (a3,d0) <ne> #0 then.s		; if cell alive
    move.b   #0,(a3,d0)			; kill
    SET_FILL BLACK  			; set fill color to black
    bsr	paintCell			; clear cell at d6,d7
  else      				; else, cell dead
    move.b   #1,(a3,d0)			; cell is born
    SET_FILL LTGRAY			; set fill color to ltGray
    bsr	paintCell			; set cell at d6,d7
  endi
  rts


*-----------------------------------------------------------
* Saves pattern to user specified file
saveData:

* Save working registers
  movem.l d0-d2/d6-d7/a0-a3,-(a7)

  ; Save File Dialog
  move.b #1,d1				; Save file dialog
  lea    0,a1				; use default title
  lea    fileExt,a2			; file extensions
  lea    buffer,a3
  move.b #58,d0				; Display File Dialog
  trap   #15

  lea grid1,a2				; Load grid to a2

  if d1 <eq> #1 then			; if file selected
    lea buffer,a1			; Load file for output
    move.b #52,d0
    trap #15
  
    if.b d0 <eq> #0 then.s		; Continue if there was not an error opening the file
      for.b d6 = #0 to #ROWS-1 do.s	; Do Code for each row in grid
        move #1,d2			; # of bytes to write to file
        for.b d7 = #0 to #COLS-1 do.s	; Do code for each column in row
          move.b #54,d0
          if.b (a2) <eq> #0 then.s	; If the cell is dead then load zero to a1
            lea zero,a1
          else				; Else load blank to a1
            lea blank,a1
          endi
          trap #15    			; Write to file
          adda #1,a2  			; Move to next byte
        endf
        move.b #54,d0
        move.b #2,d2			; # of bytes to write to file
        lea crlf,a1			; Display carriage return and line feed
        trap #15
      endf
      move.b #50,d0			; Close all open files
      trap #15
    else
      SET_FILL BLACK			; set fill color to black
      bsr clearMenu
      DISPLAY_TEXT saveErrMsg
      REPEAT				; Wait until user presses a key
        READ_KEY
      UNTIL.L D1 <ne> #0 do
    endi
  endi

* Restore working registers
  movem.l (a7)+,d0-d2/d6-d7/a0-a3

  rts

*-----------------------------------------------------------
openFile:

* Save working registers
  movem.l d0-d2/d6-d7/a0-a3,-(a7)

  bsr clearData
  bsr drawGrid1
  
  ; Open File Dialog
  move.b #0,d1				; Open file dialog
  lea    0,a1				; use default open title
  lea    fileExt,a2			; file extensions
  lea    buffer,a3
  move.b #58,d0				; Display File Dialog
  trap   #15
  
  if d1 <eq> #1 then			; if file selected
    lea buffer,a1			; Open user file for input
    move.b #51,d0
    trap #15
  
    if.w d0 <eq> #0 then.s		; No error in opening file
      move #0,d2			; file position
      move #55,d0
      trap #15
  
      lea grid1,a1			; Point a1 to grid1
      for d6 = #0 to #ROWS-1 do.s
        for d7 = #0 to #COLS-1 do.s
          move.b #53,d0
          move.w #1,d2			; Get one byte of pattern
          trap #15
          if.b (a1) <eq> #$D then.s	; Carriage return encountered
            move.b #1,d2		; Get next value from file
            move.b #53,d0
            trap #15
            move.b #1,d2		; Get next value from file
            move.b #53,d0
            trap #15
          endi
          if.b (a1) <eq> #$30 then.s	; d1 != '0'
            move.b #0,(a1)+
          else
            move.b #1,(a1)+
          endi
        endf
      endf
      move.b #50,d0			; Close all open files
      trap #15
    else.s
      SET_FILL BLACK			; set fill color to black
      bsr clearMenu
      DISPLAY_TEXT openErrMsg
    endi
  endi
  
* Restore working registers
  movem.l   (a7)+,d0-d2/d6-d7/a0-a3
*
*  rts

*-----------------------------------------------------------
clearData:
  movem.l d6-d7/a1-a2,-(a7)
*  bsr drawCursor			; Turn cursor off
  lea grid1,a1
  lea grid2,a2
  for d6 = #0 to #ROWS-1 do.s
    for d7 = #0 to #COLS-1 do.s
      clr.b (a1)+
      clr.b (a2)+
    endf
  endf
  movem.l (a7)+,d6-d7/a1-a2
*  bsr drawCursor			; Turn cursor on
  rts

*-----------------------------------------------------------
* Returns fill color in square
getColor
  movem.l   d1-d2,-(a7)			; Save working registers

  * Find first pixel in upper left of square
  mulu #COLSIZE,d1
  add.w #GLEFT,d1
  add.w #1,d1
  mulu #ROWSIZE,d2
  add.w #GTOP,d2
  add.w #1,d2
  move.b #83,d0				; Get the fill color
  trap #15

  movem.l (a7)+,d1-d2			; Restore registers
  rts

  
*-----------------------------------------------------------
* Draw a button.
* (A1) points to button text null terminated string
* D1 is left
* D2 is top
* D3 is button number
* D4.b = 0 for normal, 1 for highlighted
drawButton
  movem.l d0-d4/a0,-(sp)
  * set font color
  movem.l   d1/d2,-(sp)
  move.l   #WHITE,d1
  clr.l    d2
  move.b   #21,d0
  trap     #15				; set font color
  movem.l   (sp)+,d1/d2
  SET_PEN  GREEN
  if.b d4 <eq> #0 then.s
    SET_FILL BLACK
  else
    SET_FILL LTGRAY
  endi
  *draw rectangle
  move.w   d1,d3
  add.w    #BUTTON_WIDTH,d3		; Right X
  move.w   d2,d4
  add.w    #BUTTON_HEIGHT,d4		; Bottom Y
  move.b   #87,d0
  trap     #15				; Draw filled rectangle
  *draw text
  add.w    #5,d1
  add.w    #3,d2
  move.b   #95,d0
  trap	   #15
  movem.l  (sp)+,d0-d4/a0
  rts


*-----------------------------------------------------------
dispMenu1:
  bsr  clearMenu
  button QUIT_BTN,QuitBtn,NORMAL
  button START_BTN,StartBtn,NORMAL
  button STOP_BTN,StopBtn,NORMAL
  button OPEN_BTN,OpenBtn,NORMAL
  button SAVE_BTN,SaveBtn,NORMAL
  button CLEAR_BTN,ClearBtn,NORMAL
  rts

clearMenu:
  movem.l  d0-d4,-(sp)
  SET_FILL BLACK
  SET_PEN  BLACK
  move.w   #0,d1
  move.w   #0,d2
  move.w   #639,d3
  move.w   #BUTTON_TOP+BUTTON_HEIGHT,d4
  move.b   #87,d0
  trap     #15				; draw filled rectangle
  movem.l  (sp)+,d0-d4
  rts

*-----------------------------------------------------------

col		dc.b    0
row		dc.b    0
squCol		ds.b    1
squRow		ds.b    1
quit		dc.b	0		; set to 1 to quit
life		dc.b	0		; 1 = life, 0 = stop
zero		dc.b    '0'
blank		dc.b    ' '
crlf		dc.w    $0D0A
QuitBtn		dc.b    ' Quit  ',0
StartBtn	dc.b    ' Start ',0
StopBtn		dc.b	' Stop  ',0
OpenBtn		dc.b    ' Open  ',0
SaveBtn		dc.b	' Save  ',0
ClearBtn	dc.b	' Clear ',0
saveMsg		dc.b    'Save current pattern as: ',0
saveErrMsg	dc.b    'An error occured while saving the file.',0
openErrMsg	dc.b    'An error occured while opening the file.',0
openMsg		dc.b    'Retrieve pattern from: ',0
fileExt		dc.b	'*.lif;*.bin',0
oldVerMsg	dc.b	'This program requires Sim68K version 4.0.0 or later.',$D,$A
		dc.b	'The latest version may be downloaded from www.easy68k.com',0

		ds.w	0
buffer		dcb     256,0
            ORG     $2000
* grid1 is the starting grid. Put default starting patterns here.
grid1       dcb     ROWS*COLS,0
* grid2 is used to toggle with grid1 between generations
grid2       dcb     ROWS*COLS,0

cursorX	dc.w	0
cursorY	dc.w	0


            END     START



























*~Font name~Fixedsys~
*~Font size~9~
*~Tab type~1~
*~Tab size~8~
