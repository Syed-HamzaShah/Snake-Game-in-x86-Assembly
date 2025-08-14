.386
.model flat, stdcall
.stack 4096
ExitProcess PROTO, dwExitCode: DWORD
INCLUDE Irvine32.inc
.data

; showPrompt: controls whether to display the startup prompt.
;   1 = show the "Do you want to play?" prompt at program start.
;   0 = skip the prompt and start immediately.
showPrompt BYTE 1  

; prompt and exit messages used by PromptScreen
promptMsg  BYTE "Do you want to play the game? 1 = Yes, 2 = No: ", 0
byeMsg     BYTE "Goodbye!", 0

; xWall: a simple prebuilt horizontal wall string used to draw the
;        top and bottom borders of the playing area quickly.
xWall BYTE 52 DUP("#"),0

; Score display text and numeric score variable.
; score is a byte that holds how many coins have been eaten.
strScore BYTE "Your score is: ",0
score BYTE 0

; Messages used when the player dies or is asked to retry.
strTryAgain BYTE "Try Again?  1=yes, 0=no",0
invalidInput BYTE "invalid input",0
strYouDied BYTE "you died ",0
strPoints BYTE " point(s)",0

; A blank string used to clear regions of the console when needed.
blank BYTE "                                     ",0

; Snake visual representation:
; - snake[0] is the head character.
; - Remaining entries represent the body/tail characters.
; - The array is pre-sized so the snake can grow without reallocation.
snake BYTE "X", 104 DUP("x")

; xPos and yPos arrays store console column (x) and row (y) for each
; snake segment. Index 0 is the head. The first five values provide
; the initial snake (5 units). Remaining slots are reserved for growth.
xPos BYTE 45,44,43,42,41, 100 DUP(?)
yPos BYTE 15,15,15,15,15, 100 DUP(?)

; Wall coordinates used by drawing routines and for collision limits:
; xPosWall: [leftX, rightXLeft???, rightX, ???] (keeps the same indices
;           as original code for compatibility with drawing logic).
; yPosWall: [topY, bottomY, topYDup, bottomYDup] (used in draws).
xPosWall BYTE 34,34,85,85
yPosWall BYTE 5,24,5,24

; Coin (food) position on screen (single cell).
xCoinPos BYTE ?
yCoinPos BYTE ?

; Input buffering:
; - inputChar: current input command character.
; - lastInputChar: previously processed input (used to prevent 180-degree turns).
inputChar BYTE "+"
lastInputChar BYTE ?

; Movement speed base value in milliseconds. Used with Delay.
speed DWORD 80  


.code


; PromptScreen PROC
;  - Show a startup prompt asking whether the user wants to play.
;  - If user chooses "1", set showPrompt=0 and return to start the game.
;  - If user chooses "2", show a goodbye message and exit the process.

PromptScreen PROC
    cmp showPrompt, 1
    jne SkipPrompt     ; If prompt not enabled, return immediately

    ; Clear the console and set text color to white-on-black.
    call Clrscr
    mov eax, white + (black * 16)
    call SetTextColor

    ; Position the cursor near the screen center and print the prompt.
    mov dl, 35
    mov dh, 12
    call Gotoxy
    mov edx, OFFSET promptMsg
    call WriteString

WaitInput:
    ; ReadInt returns the integer value in EAX.
    call ReadInt
    cmp eax, 1
    je PlayGame
    cmp eax, 2
    je ExitGame
    jmp WaitInput       ; ask again for any other input

PlayGame:
    ; Disable future prompts and return to caller to proceed to main.
    mov showPrompt, 0
    ret

ExitGame:
    ; Show goodbye message and wait before terminating the process.
    call Clrscr
    mov edx, OFFSET byeMsg
    call WriteString
    call Crlf
    call WaitMsg
    exit

SkipPrompt:
    ret
PromptScreen ENDP

; main PROC
; This is the program entry point and contains the main game setup and
; the primary game loop. The loop handles:
;  - reading key input
;  - validating direction changes (disallow 180-degree reversals)
;  - moving the head and shifting the body
;  - drawing updated visuals
;  - collision detection with walls and self
;  - coin collection and growth
; The structure uses labels to branch to movement handlers for each
; direction (moveUp, moveDown, moveLeft, moveRight).
main PROC
	call PromptScreen
	call ClrScr			; clear screen before drawing initial UI

	call DrawWall			; draw the rectangular wall boundaries
	call DrawScoreboard		; initialize and display the scoreboard

	; Draw the starting snake with 5 units. ESI indexes into snake arrays.
	mov esi,0
	mov ecx,5
drawSnake:
	call DrawPlayer			; draw the segment at xPos[esi], yPos[esi]
	inc esi
loop drawSnake

	; Seed random number generator and place the first coin.
	call Randomize
	call CreateRandomCoin
	call DrawCoin			; render the coin on the console

	; Main game loop label. Loop repeatedly until exit or death.
gameLoop::
	; Move cursor out of the way (used for ReadKey behavior).
	mov dl,106
	mov dh,1
	call Gotoxy

	; ReadKey sets AL if a key is available, otherwise returns zero.
	call ReadKey
    jz noKey                ; if no key pressed, skip input processing

processInput:
	; Preserve the prior buffered character and set inputChar to the new key.
	mov bl, inputChar
	mov lastInputChar, bl
	mov inputChar,al

noKey:
	; If the user presses 'x', exit the game immediately.
	cmp inputChar,"x"
	je exitgame

	; Evaluate movement intent and transfer control to appropriate checks.
	cmp inputChar,"w"
	je checkTop
	cmp inputChar,"s"
	je checkBottom
	cmp inputChar,"a"
	je checkLeft
	cmp inputChar,"d"
	je checkRight
	jne gameLoop			; If no recognized command, continue looping

	; Direction-change validation
	; Each check ensures the snake cannot reverse instantly into itself
	; (e.g., cannot go down immediately after going up).
	; Also checks are made against wall boundaries to determine collision.

	checkBottom:
		; Prevent downward motion if previous direction was up.
		cmp lastInputChar, "w"
		je dontChgDirection

		; Compute the row just above the bottom wall and compare head Y.
		mov cl, yPosWall[1]
		dec cl
		cmp yPos[0],cl
		jl moveDown
		je died				; collision with bottom wall

	checkLeft:
		; On game start, prevent impossible left move when lastInputChar is '+'
		cmp lastInputChar, "+"	
		je dontGoLeft
		; Prevent 180-degree turn from right to left.
		cmp lastInputChar, "d"
		je dontChgDirection
		mov cl, xPosWall[0]
		inc cl
		cmp xPos[0],cl
		jg moveLeft
		je died				; collision with left wall

	checkRight:
		; Prevent 180-degree turn from left to right.
		cmp lastInputChar, "a"
		je dontChgDirection
		mov cl, xPosWall[2]
		dec cl
		cmp xPos[0],cl
		jl moveRight
		je died				; collision with right wall

	checkTop:
		; Prevent 180-degree turn from down to up.
		cmp lastInputChar, "s"
		je dontChgDirection
		mov cl, yPosWall[0]
		inc cl
		cmp yPos,cl
		jg moveUp
		je died				; collision with top wall

	; Movement handlers
	; Each handler:
	;  - delays according to speed (creating frame timing)
	;  - erases the tail cell (UpdatePlayer called with ESI=0)
	;  - updates head position (xPos[0], yPos[0])
	;  - draws the head and then updates/draws the body segments
	;  - calls CheckSnake to detect self-collision after the move

	moveUp:
		mov eax, speed
		add eax, speed    ; small timing tweak (double)
		call delay
		mov esi, 0
		call UpdatePlayer	; erase where the head currently is
		mov ah, yPos[esi]
		mov al, xPos[esi]	; store current head coordinates in AH:AL
		dec yPos[esi]		; move head up by one row
		call DrawPlayer		; draw the new head
		call DrawBody		; shift and draw the body
		call CheckSnake		; detect self-collision
		jmp checkcoin

	moveDown:
		mov eax, speed
		add eax, speed
		call delay
		mov esi, 0
		call UpdatePlayer
		mov ah, yPos[esi]
		mov al, xPos[esi]
		inc yPos[esi]		; move head down
		call DrawPlayer
		call DrawBody
		call CheckSnake
		jmp checkcoin

	moveLeft:
		mov eax, speed
		call delay
		mov esi, 0
		call UpdatePlayer
		mov ah, yPos[esi]
		mov al, xPos[esi]
		dec xPos[esi]		; move head left
		call DrawPlayer
		call DrawBody
		call CheckSnake
		jmp checkcoin

	moveRight:
		mov eax, speed
		call delay
		mov esi, 0
		call UpdatePlayer
		mov ah, yPos[esi]
		mov al, xPos[esi]
		inc xPos[esi]		; move head right
		call DrawPlayer
		call DrawBody
		call CheckSnake
		jmp checkcoin

	; Check for coin collection: compare head coordinates with coin.
	; If both X and Y match, EatingCoin is called to grow the snake,
	; update the score, and spawn a new coin.
	checkcoin::
		mov esi,0
		mov bl,xPos[0]
		cmp bl,xCoinPos
		jne gameloop
		mov bl,yPos[0]
		cmp bl,yCoinPos
		jne gameloop

		call EatingCoin
		jmp gameLoop

	; Direction-change denial handlers:
	; - dontChgDirection: when a reverse turn is attempted, restore
	;   inputChar to the previous direction so the snake continues.
	; - dontGoLeft: special-case prevention of left move at startup.
	dontChgDirection:
		mov inputChar, bl		; restore previous direction
		jmp noKey

	dontGoLeft:
		mov	inputChar, "+"		; disallow left at start
		jmp gameLoop

	died::
		call YouDied
		; After YouDied, flow continues to playagn which reinitializes
	 
	playagn::
		call ReinitializeGame		; reset state and restart the game
	
	exitgame::
		exit
INVOKE ExitProcess,0
main ENDP

; DrawWall PROC
; Draws the top and bottom horizontal walls using xWall, and the left
; and right vertical walls by printing '#' characters down the columns.
; Coordinates are taken from xPosWall and yPosWall arrays.
DrawWall PROC	

	mov dl,xPosWall[0]
	mov dh,yPosWall[0]
	call Gotoxy	
	mov edx,OFFSET xWall
	call WriteString			; draw upper wall

	mov dl,xPosWall[1]
	mov dh,yPosWall[1]
	call Gotoxy	
	mov edx,OFFSET xWall		
	call WriteString			; draw lower wall

	; Draw right vertical wall by printing '#' down the right column
	mov dl, xPosWall[2]
	mov dh, yPosWall[2]
	mov eax,"#"	
	inc yPosWall[3]
L11: 
	call Gotoxy	
	call WriteChar	
	inc dh
	cmp dh, yPosWall[3]
	jl L11

	; Draw left vertical wall by printing '#' down the left column
	mov dl, xPosWall[0]
	mov dh, yPosWall[0]
	mov eax,"#"	
L12: 
	call Gotoxy	
	call WriteChar	
	inc dh
	cmp dh, yPosWall[3]
	jl L12

	ret
DrawWall ENDP

; DrawScoreboard PROC
; Positions the cursor near top-left and prints the "Your score is: "
; text followed by an initial 0. The numeric score is later updated by
; EatingCoin which explicitly rewrites the numeric value at a fixed
; cursor location.
DrawScoreboard PROC
	mov dl,2
	mov dh,1
	call Gotoxy
	mov edx,OFFSET strScore
	call WriteString
	mov eax,"0"
	call WriteChar
	ret
DrawScoreboard ENDP

; DrawPlayer PROC
; Draws the character for the snake segment indexed by ESI at the
; current xPos[ESI], yPos[ESI]. This routine expects ESI to be set by
; the caller (for example: 0 for head, >0 for body segments).
DrawPlayer PROC
	mov dl,xPos[esi]
	mov dh,yPos[esi]
	call Gotoxy
	mov dl, al			; temporarily save AL in DL (preserve AL across call)
	mov al, snake[esi]
	call WriteChar
	mov al, dl
	ret
DrawPlayer ENDP

; UpdatePlayer PROC
; Erases the character at the location of segment indexed by ESI by
; drawing a space. Used before moving a segment to avoid visual trails.
UpdatePlayer PROC
	mov dl, xPos[esi]
	mov dh,yPos[esi]
	call Gotoxy
	mov dl, al			; temporarily save AL in DL
	mov al, " "
	call WriteChar
	mov al, dl
	ret
UpdatePlayer ENDP

; DrawCoin PROC
; Sets text color to yellow, moves to the coin coordinates, and draws
; an 'X' representing the coin. Restores the text color to white-on-black
; after drawing the coin.
DrawCoin PROC
	mov eax,yellow (yellow * 16)
	call SetTextColor
	mov dl,xCoinPos
	mov dh,yCoinPos
	call Gotoxy
	mov al,"X"
	call WriteChar
	mov eax,white (black * 16)
	call SetTextColor
	ret
DrawCoin ENDP

; CreateRandomCoin PROC
; Generates a random coin position that lies within the playable area
; (columns 35..84 and rows 6..23 in this program). After generating a
; candidate, it checks the coin position against every current snake
; segment (head + body) and regenerates if the coin overlaps the snake.
CreateRandomCoin PROC
	; Generate X coordinate: RandomRange(0..49) then add 35 => 35..84
	mov eax,49
	call RandomRange
	add eax, 35
	mov xCoinPos,al

	; Generate Y coordinate: RandomRange(0..17) then add 6 => 6..23
	mov eax,17
	call RandomRange
	add eax, 6
	mov yCoinPos,al

	; Ensure coin does not fall on the snake body/head.
	; Loop through current snake segments (initially 5 + score).
	mov ecx, 5
	add cl, score			; total number of occupied segments
	mov esi, 0
checkCoinXPos:
	movzx eax,  xCoinPos
	cmp al, xPos[esi]
	je checkCoinYPos
continueloop:
	inc esi
loop checkCoinXPos
	ret						; coin position is valid (no overlap)

checkCoinYPos:
	movzx eax, yCoinPos
	cmp al, yPos[esi]
	jne continueloop			; y differs, keep checking remaining segments
	; If X and Y both match an existing segment, regenerate a coin.
	call CreateRandomCoin
CreateRandomCoin ENDP

; CheckSnake PROC
; Detects self-collision by comparing the head's coordinates against
; all body segments (starting from the 5th unit onward). If a match
; is found for both X and Y, the snake has collided with itself and
; the died label is executed.
CheckSnake PROC
	mov al, xPos[0]
	mov ah, yPos[0]
	mov esi,4				; start checking from the 5th unit (index 4)
	mov ecx,1
	add cl,score			; number of body segments to check beyond the initial 4
checkXposition:
	cmp xPos[esi], al
	je XposSame
contloop:
	inc esi
loop checkXposition
	jmp checkcoin
XposSame:
	; X matched, check Y too for a true collision.
	cmp yPos[esi], ah
	je died					; collision found
	jmp contloop

CheckSnake ENDP

; DrawBody PROC
; After moving the head, update each subsequent body segment such that
; each segment takes the previous segment's old position (classic snake).
; The routine uses AH:AL to hold the original head position and iterates
; through the body, shifting positions and redrawing each segment.
DrawBody PROC
	mov ecx, 4
	add cl, score		; number of body segments including growth
printbodyloop:
	inc esi				; step to the next body segment index
	call UpdatePlayer	; erase the old position of this segment
	mov dl, xPos[esi]
	mov dh, yPos[esi]	; save current coordinates into DL:DH temporarily
	mov yPos[esi], ah	; write the previous segment's Y into this segment
	mov xPos[esi], al	; write the previous segment's X into this segment
	mov al, dl
	mov ah, dh			; restore DL:DH back into AL:AH for the next iteration
	call DrawPlayer
	cmp esi, ecx
	jl printbodyloop
	ret
DrawBody ENDP

; EatingCoin PROC
; Called when the head overlaps a coin. This routine:
;  - increments the score
;  - appends a new tail segment (positions copied from previous tail)
;  - adjusts the new tail position based on the orientation of the
;    previous tail segment so the tail grows in the correct direction
;  - redraws the new tail, spawns a new coin, and updates the score
;    on the scoreboard.
EatingCoin PROC
	inc score
	mov ebx,4
	add bl, score
	mov esi, ebx
	; copy the previous tail position into the new tail slot
	mov ah, yPos[esi-1]
	mov al, xPos[esi-1]
	mov xPos[esi], al
	mov yPos[esi], ah

	; Determine how to place the new tail relative to the previous tail:
	; If the previous two segments share X, adjust Y; otherwise adjust X.
	cmp xPos[esi-2], al
	jne checky

	cmp yPos[esi-2], ah
	jl incy
	jg decy
incy:
	inc yPos[esi]
	jmp continue
decy:
	dec yPos[esi]
	jmp continue

checky:
	cmp yPos[esi-2], ah
	jl incx
	jg decx
incx:
	inc xPos[esi]
	jmp continue
decx:
	dec xPos[esi]

continue:
	call DrawPlayer
	call CreateRandomCoin
	call DrawCoin

	; Update the in-console numeric score at a fixed place.
	mov dl,17
	mov dh,1
	call Gotoxy
	mov al,score
	call WriteInt
	ret
EatingCoin ENDP

; YouDied PROC
; Presents the "you died" screen, shows the player's score, and asks
; whether to retry. If input is 1, execution falls through to
; ReinitializeGame; if 0, the program exits. Any other input produces
; a prompt for valid input and repeats.
YouDied PROC
	mov eax, 1000
	call delay
	Call ClrScr

	; Center and display "you died"
	mov dl,	57
	mov dh, 12
	call Gotoxy
	mov edx, OFFSET strYouDied
	call WriteString

	; Show numeric score followed by " point(s)"
	mov dl,	56
	mov dh, 14
	call Gotoxy
	movzx eax, score
	call WriteInt
	mov edx, OFFSET strPoints
	call WriteString

	; Prompt for retry
	mov dl,	50
	mov dh, 18
	call Gotoxy
	mov edx, OFFSET strTryAgain
	call WriteString

retry:
	mov dh, 19
	mov dl,	56
	call Gotoxy
	call ReadInt
	cmp al, 1
	je playagn
	cmp al, 0
	je exitgame

	; Invalid input: show an error message, clear the input area and repeat.
	mov dh,	17
	call Gotoxy
	mov edx, OFFSET invalidInput
	call WriteString
	mov dl,	56
	mov dh, 19
	call Gotoxy
	mov edx, OFFSET blank
	call WriteString
	jmp retry
YouDied ENDP

; ReinitializeGame PROC
; Reset the snake position, score, input buffers, and wall state back to
; their initial values, clear the screen, and restart the main routine.
ReinitializeGame PROC
	mov xPos[0], 45
	mov xPos[1], 44
	mov xPos[2], 43
	mov xPos[3], 42
	mov xPos[4], 41
	mov yPos[0], 15
	mov yPos[1], 15
	mov yPos[2], 15
	mov yPos[3], 15
	mov yPos[4], 15
	mov score,0
	mov lastInputChar, 0
	mov	inputChar, "+"		; reset input buffer to startup sentinel
	dec yPosWall[3]			; restore wall position if modified elsewhere
	Call ClrScr
	jmp main				; restart the game loop from the top
ReinitializeGame ENDP

END main