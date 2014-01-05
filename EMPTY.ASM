;==============================================================================
; Empty example assembly file.
; ==============================================================================
.MODEL large ; one data and one code segment, stack and data segment are grouped
.STACK 2048  ; stack, 2048 bytes
; --- INCLUDES -----------------------------------------------------------------
include KEYB.INC
; --- MACROS AND CONSTANTS -----------------------------------------------------
	SCREENW			equ 320		;screenwidth
	SCREENH			equ 200		;screenheight
	
	BLACK			equ 0
	RED				equ 1
	ORANGE			equ	2
	YELLOW			equ 3
	GREEN			equ 4
	BLUE			equ 5
	WHITE			equ 6
	
	PADDLEINITW		equ 40 
	PADDLEINITH		equ 5
	PADDLEINITPOSX	equ 140
	PADDLEINITPOSY	equ 170
	PADDLESPDINCX	equ 3
	
	BALLSIZE		equ 3
	BALLHALFSIZE	equ 1
	BALLINITPOSX	equ 159
	BALLINITPOSY	equ 165
	BALLSPDINCX		equ 2
	BALLSPDINCY		equ	2	
	
	;We definiëren een grid waarin onze bricks getekend worden. Deze heeft een initiële X- en Y-positie en een breedte. 
	;De hoogte van de grid hangt af van hoeveel bricks er getekend moeten worden. 
	GRIDOFFSETX		equ 19    
	GRIDOFFSETY		equ 19       
	GRIDWIDTH		equ 282      
	GRIDGAPX		equ 19 ;Het aantal pixels tussen 2 bricks (horizontaal)       
	GRIDGAPY		equ 8 ;Het aantal pixels tussen 2 bricks (verticaal)
	
	BRICKWIDTH		equ 24
	BRICKHEIGHT		equ 5
	
	LIFESIZE		equ	5 ;De grootte van het life-symbool
	LIFEINITPOSX	equ 300
	LIFEINITPOSY	equ	185 
	LIFEGAP			equ 10 ;Het aantal pixels tussen twee life-symbolen
	
	ARRAYSIZE		equ 70 ;16*2 (dw) - 2
; --- DATA SEGMENT -------------------------------------------------------------
.DATA	; data segment, variables
	
	palette     	db	0, 0, 0, 60, 0, 0, 60, 30, 0, 60, 60, 0, 0, 60, 0, 0, 0, 60, 63, 63, 63  ; defines black (0,0,0) and white (63,63,63)
	startVideo		dw	0a000h 				;start of the video memory
	gamemode		dw	0
	paddle_pos		dw	PADDLEINITPOSX	
	paddle_speed	dw	0	
	ball_pos		dw	BALLINITPOSX, BALLINITPOSY
	ball_speed		dw	BALLSPDINCX, BALLSPDINCY
	brickarray		dw	5, 5, 5, 5, 5, 5, 5, 
						4, 4, 4, 4, 4, 4, 4, 
						3, 3, 3, 3, 3, 3, 3, 
						2, 2, 2, 2, 2, 2, 2,
						1, 1, 1, 1, 1, 1, 1
	bricksperline	dw	0
	lives			dw	3
	
; --- SCREEN BUFFER ------------------------------------------------------------
.FARDATA?	; segment that contains the screenBuffer for mode 13h drawing
	screenBuffer	db	64000 dup(?)			; the 64000 bytes for the screen
			
; ----------------------------- CODE STARTS HERE -------------------------------
.CODE        ; code segment
main PROC NEAR
	mov	ax, @data	; set data segment;
	mov	ds, ax		;in ds
	; clear video buffer
	call	installKeyboardHandler
	call	clearScreenBuffer
	mov 	es, startVideo
	call	initializeScreen
	call	initializePalette
	call 	initializeEnvironment
	call 	updateScreen
mainloop:
	call	clearScreenBuffer
	call 	drawGrid
	call 	handleInput
	call	moveBall
	call	drawLives
	call 	updateScreen
	jmp 	mainloop	
	
	; Exit to DOS
	mov	ax, 4c00h
	int	21h
main ENDP
endGame PROC NEAR
	call	clearScreenBuffer
	call	updateScreen
	; Exit to DOS
	mov		ax, 4c00h
	int		21h
	ret
endGame ENDP
initializeScreen PROC NEAR
	; set the video mode 320x200, 256 colors
	mov ah, 0		; function 0 (set video mode)
	mov al, 13h		; argument 13h (mode 13h to be set)
	int 10h 		; call Video BIOS
	ret	
initializeScreen ENDP
		
initializePalette PROC NEAR
	push 	ax
	push 	dx
	push 	bx
	push 	cx
	push 	es
	
	mov		ax, @data			; set data segment;
	mov		ds, ax				; in ds
	mov 	es, ax				; and in es
	mov 	dx, offset palette	; set the palette (DAC) (offset relative to es)
	xor 	bx, bx				; set bx to zero (start at color index 0)
	mov 	cx, 7				; set color 0 and 1 (2 indexes in total) (2 kleuren)
	mov 	ax, 1012h			; function 1012h of int 10h (set DAC palette)
	int 	10h					; call Video BIOS
	
	pop 	es
	pop 	cx
	pop 	bx
	pop 	dx
	pop 	ax
	ret	
initializePalette ENDP
	
initializeEnvironment PROC NEAR
	push	ax

drawBricks:
	call 	drawGrid
	call 	setBricks
drawPaddle:
	mov		ax, WHITE
	push	ax
	mov		ax, PADDLEINITW
	push	ax  				;pushing width on the stack
	mov		ax, PADDLEINITH
	push	ax  				;pushing height on the stack
	mov 	ax, PADDLEINITPOSX
	push 	ax					;pushing x-position on the stack
	mov 	ax,	PADDLEINITPOSY
	push	ax					;pushing y-position on the stack
	call 	drawRectangle
drawBall:	
	mov		ax, WHITE
	push	ax
	mov		ax, BALLSIZE
	push	ax  				;pushing width on the stack
	mov		ax, BALLSIZE
	push	ax  				;pushing height on the stack
	mov 	ax, BALLINITPOSX
	push 	ax					;pushing x-position on the stack
	mov 	ax, BALLINITPOSY
	push 	ax					;pushing y-position on the stack
	call 	drawRectangle
	
	pop		ax
	ret
initializeEnvironment ENDP

clearScreenBuffer PROC NEAR
	push	ax
	push	cx
	push	di
	push	es
	
	cld
	mov		ax, seg screenBuffer
	mov		es, ax
	mov		di, offset screenBuffer
	mov		cx, 64000 / 2
	xor		ax, ax
	rep		stosw
	
	pop		es
	pop		di
	pop		cx
	pop		ax
	ret		0
clearScreenBuffer ENDP

drawGrid PROC NEAR
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	
	mov		ax, GRIDOFFSETX
	mov		bx, GRIDOFFSETY
	mov		di, 0
	mov		cx, ARRAYSIZE
lp:
	cmp		di, cx
	jge		done
	mov		dx, brickarray[di]
	cmp		dx, 0
	jz		updatevariables
	;mov		dx, GREEN
	push	dx
	mov		dx, BRICKWIDTH
	push	dx  ;pushing width on the stack
	mov		dx, BRICKHEIGHT
	push	dx  ;pushing height on the stack
	push 	ax	;pushing x-position on the stack
	push	bx	;pushing y-position on the stack
	call 	drawRectangle	
updatevariables:
	add		di, 2
	add		ax, BRICKWIDTH
	add		ax, GRIDGAPX
	mov		dx,	GRIDWIDTH
	add		dx, GRIDOFFSETX
	add		ax, BRICKWIDTH 
	cmp		ax, dx
	jle		cont
	mov		ax, GRIDOFFSETX
	add		ax, BRICKWIDTH
	add		bx, GRIDGAPY
	add		bx, BRICKHEIGHT
cont:
	sub		ax, BRICKWIDTH
	jmp 	lp	
done:
	pop		di
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	
	ret
drawGrid ENDP

setBricks PROC NEAR
	mov		ax, GRIDWIDTH
	mov		bx,	BRICKWIDTH
	add		bx, GRIDGAPX
	xor		dx, dx
	div		bx
	mov		bx, BRICKWIDTH
	cmp 	bx, dx
	jg		done		
	add		ax, 1
done:
	mov 	[bricksperline], ax
	ret
setBricks ENDP

; Reads keyboard buffer and acts (returns non-zero if loop should end, 0 otherwise)
handleInput PROC NEAR
	push	es
	push	ax
	
	mov 	[paddle_speed], 0
	
	mov		ax, seg __keysActive
	mov		es, ax
	
	xor		ah, ah
	mov		al, es:[__keysActive]
	cmp		al, 0
	jz		@done		; no key pressed

	mov		al, es:[__keyboardState][SCANCODE_LEFT]	; test LEFT key
	cmp		al, 0
	jz 		@F	; jump next
	mov 	ax, [paddle_speed]
	sub 	ax, PADDLESPDINCX
	mov 	[paddle_speed], ax
	mov		ax, [gamemode][0]
	cmp		ax, 0
	jnz		@F
	mov		ax, [ball_pos][0]
	sub 	ax, PADDLESPDINCX
	mov		[ball_pos][0], ax
	
@@:
	mov		al, es:[__keyboardState][SCANCODE_RIGHT]	; test RIGHT key
	cmp		al, 0
	jz		@F	; jump next
	mov 	ax, [paddle_speed]
	add 	ax, PADDLESPDINCX
	mov 	[paddle_speed], ax
	mov		ax, [gamemode][0]
	cmp		ax, 0
	jnz		@F
	mov		ax, [ball_pos][0]
	add 	ax, PADDLESPDINCX
	mov		[ball_pos][0], ax

@@:	
	mov		al, es:[__keyboardState][SCANCODE_SPACE]	; test SPACE
	cmp		al, 0
	jz		@F	; jump next
	mov		[gamemode], 1
	
@@:
	; finally, let's put the ESC key status as return value in AX
	mov		al, es:[__keyboardState][SCANCODE_ESC]	; test ESC
	cmp		al, 0
	jz		@done	; jump next
	call	clearScreenBuffer
	call	updateScreen
	; Exit to DOS
	mov		ax, 4c00h
	int		21h

@done:
	call	movePaddle
	pop		ax
	pop		es
	ret 
handleInput ENDP	
	
movePaddle PROC NEAR
	push	ax
	push	bx
	
	mov 	ax, [paddle_pos]
	add 	ax, [paddle_speed]
left?:
	cmp		ax, 0
	jle leftfix	; future pos niet goed, custom pos wegschrijven
right?:
	mov		bx, SCREENW
	sub		bx, PADDLEINITW
	cmp		ax, bx
	jge rightfix ; future pos niet goed, custom pos wegschrijven
	
	mov		[paddle_pos], ax    ;geen fix nodig, future pos gewoon wegschrijven
	jmp		next
leftfix:
	mov		[paddle_pos], 0
	jmp		next
rightfix:
	mov		[paddle_pos], bx
	jmp		next
next:	
	mov		ax, WHITE
	push	ax
	mov		ax, PADDLEINITW 
	push	ax  ;pushing width on the stack
	mov		ax, PADDLEINITH 
	push	ax  ;pushing height on the stack
	mov 	ax, [paddle_pos]
	push 	ax	;pushing x-position on the stack
	mov 	ax, PADDLEINITPOSY
	push	ax	;pushing y-position on the stack
	call 	drawRectangle
	
	pop		bx
	pop		ax	
	ret
movePaddle ENDP

moveBall PROC NEAR
	push	dx
	push	bx
	push	cx
	
	mov		ax, [gamemode][0]
	cmp		ax, 0
	jz		almostdone
	
	;boundarie collision
	;x-future pos
	mov		ax, [ball_pos][0]
	mov		bx, [ball_speed][0]
	add 	ax, bx	
left?:
	cmp		ax, 0
	jle		leftfix ; future pos niet goed, custom pos wegschrijven
right?:
	mov		cx, SCREENW
	sub		cx, BALLSIZE
	cmp		ax, cx
	jge		rightfix ; future pos niet goed, custom pos wegschrijven
	
	mov		[ball_pos][0], ax ;geen fix nodig, future pos gewoon wegschrijven
	jmp		cont
leftfix:
	mov		[ball_pos][0], 0
	neg		bx
	mov		[ball_speed][0], bx
	jmp		cont
rightfix:
	mov		[ball_pos][0], cx
	neg		bx
	mov		[ball_speed][0], bx
	jmp		cont 
	;y-future pos
cont:
	mov		ax, [ball_pos][2]
	mov		bx, [ball_speed][2]
	add 	ax, bx
top?:
	cmp		ax, 0
	jle		topfix ; future pos niet goed, custom pos wegschrijven
bottom?:
	mov		cx, SCREENH
	sub		cx, 1
	sub		cx, BALLSIZE
	cmp		ax, cx
	jg		bottomfix ; future pos niet goed, custom pos wegschrijven
	
	mov		[ball_pos][2], ax ;geen fix nodig, future pos gewoon wegschrijven
	jmp		next
topfix:
	mov		[ball_pos][2], 0
	neg		bx
	mov		[ball_speed][2], bx
	jmp		next
	
almostdone:
	jmp 	done
	
bottomfix:
	;mov		[ball_pos][2], cx
	;neg		bx
	;mov		[ball_speed][2], bx
	;jmp		next
			
	mov		ax, [lives]
	sub		ax, 1
	mov		[lives], ax
	cmp		ax, 0
	jz		einde
	mov		[gamemode], 0
	mov		[ball_pos][0], BALLINITPOSX
	mov		[ball_pos][2], BALLINITPOSY
	mov		[paddle_pos], PADDLEINITPOSX
	jmp		next

einde:
	call 	endGame
	

next:
;uppercollision:
	;check collision for upper-edge
	mov 	bx, [ball_pos][0]
	add		bx, BALLHALFSIZE
	push 	bx	;pushing x-position on the stack
	mov 	dx, [ball_pos][2]
	push	dx	;pushing y-position on the stack
	call	checkCollision
	cmp		ax, 0  ;geen collision
	jz		lowercollision	
	;collision, dus y-speed aanpassen
	push	bx
	push	dx
	call	handleCollision
	mov		ax, [ball_speed][2]
	neg		ax
	mov 	[ball_speed][2], ax	
fixuppercollision:	
	push 	bx
	push 	dx
	call 	checkCollision
	cmp		ax, 0
	jz	 	almostfixed
	mov		cx, [ball_pos][2]
	add		cx, 1
	mov		[ball_pos][2], cx
	add		dx, 1	
	jmp 	fixuppercollision

lowercollision:
	;check collision for lower-edge
	mov 	bx, [ball_pos][0]
	add		bx, BALLHALFSIZE
	push 	bx	;pushing x-position on the stack
	mov 	dx, [ball_pos][2]
	add		dx, BALLSIZE
	push	dx	;pushing y-position on the stack
	call	checkCollision
	cmp		ax, 0  ;geen collision
	jz		leftcollision		
	;collision, dus y-speed aanpassen
	push	bx
	push	dx
	call	handleCollision
	mov		ax, [ball_speed][2]
	neg		ax
	mov 	[ball_speed][2], ax
fixlowercollision:	
	push 	bx
	push 	dx
	call 	checkCollision
	cmp		ax, 0
	jz	 	almostfixed
	mov		cx, [ball_pos][2]
	sub		cx, 1
	mov		[ball_pos][2], cx
	sub		dx, 1	
	jmp 	fixlowercollision
	
almostfixed:
	jmp		done
	
leftcollision:
	;check collision for lower-edge
	mov 	dx, [ball_pos][0]
	push 	dx	;pushing x-position on the stack
	mov 	bx, [ball_pos][2]
	add		bx, BALLHALFSIZE
	push	bx	;pushing y-position on the stack
	call	checkCollision
	cmp		ax, 0  ;geen collision
	jz		rightcollision		
	;collision, dus y-speed aanpassen
	push	dx
	push	bx
	call	handleCollision
	mov		ax, [ball_speed][0]
	neg		ax	
	mov 	[ball_speed][0], ax
fixleftcollision:	
	push 	bx
	push 	dx
	call 	checkCollision
	cmp		ax, 0
	jz	 	done
	mov		cx, [ball_pos][0]
	add		cx, 1
	mov		[ball_pos][0], cx
	add		dx, 1	
	jmp 	fixleftcollision
	
rightcollision:
	;check collision for lower-edge
	mov 	dx, [ball_pos][0]
	add		dx, BALLSIZE
	push 	dx	;pushing x-position on the stack
	mov 	bx, [ball_pos][2]
	add		bx, BALLHALFSIZE
	push	bx	;pushing y-position on the stack
	call	checkCollision
	cmp		ax, 0  ;geen collision
	jz		done		
	;collision, dus y-speed aanpassen
	push	dx
	push	bx
	call	handleCollision
	mov		ax, [ball_speed][0]
	neg		ax	
	mov 	[ball_speed][0], ax 
fixrightcollision:	
	push 	bx
	push 	dx
	call 	checkCollision
	cmp		ax, 0
	jz	 	done
	mov		cx, [ball_pos][0]
	sub		cx, 1
	mov		[ball_pos][0], cx
	sub		dx, 1	
	jmp 	fixrightcollision
	
done:
	mov		ax, WHITE
	push	ax
	mov		ax, BALLSIZE 
	push	ax  ;pushing width on the stack
	mov		ax, BALLSIZE
	push	ax  ;pushing height on the stack
	mov 	ax, [ball_pos][0]
	push 	ax	;pushing x-position on the stack
	mov 	ax, [ball_pos][2]
	push	ax	;pushing y-position on the stack
	call 	drawRectangle
	
	pop		cx
	pop		bx
	pop		dx
	ret
moveBall ENDP

getColor PROC NEAR
	Xpos	EQU [bp + 4][2]
	Ypos 	EQU [bp + 4][0]

	push 	bp ; save old value of bp
	mov 	bp, sp ; make bp our reference point
	
	push	dx
	push	es
	
	; set segment
	mov		ax, seg screenBuffer
	mov		es, ax
	
	;calculate offset of top-left corner
	mov		dx, SCREENW
	mov		ax, Ypos
	mul		dx		;doet Ypos*SCREENW en zet result in dx:ax
	add		ax, Xpos	;tel er de x-coordinate bij op
	
	mov		di, ax
	mov		dx, es:[di]
	mov		ax, dx

	pop 	es
	pop		dx
	pop		bp
	ret		4
getColor ENDP

checkCollision PROC NEAR
	argX 	EQU [bp + 4][2]
	argY 	EQU [bp + 4][0]
	
	push 	bp ; save old value of bp
	mov 	bp, sp ; make bp our reference poin
	
	mov		ax, argX
	push	ax	
	mov		ax, argY
	push	ax
	call	getColor  ;dx geeft de kleur de meegegeven pixel terug
	
	cmp		ax, 0  ;als de pixel zwart is, is er geen collision false(0) teruggeven
	jz		done
	mov		ax, 1 ;de pixel is niet zwart, we hebben collision. we geven true(1) terug.
done:
	pop		bp
	
	ret		4
checkCollision ENDP

handleCollision PROC NEAR
	colX 	EQU [bp + 4][2]
	colY 	EQU [bp + 4][0]
	
	push 	bp ; save old value of bp
	mov 	bp, sp ; make bp our reference point
		
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	
	mov		ax, colY
	mov		bx, PADDLEINITPOSY
	sub		bx, BALLSIZE
	sub		bx, 1
	cmp		ax, bx
	jge		done ;we hebben een collision met de paddle. er moet geen brick verwijderd worden.
	
	mov		ax, colY
	sub		ax, GRIDOFFSETY
	mov		bx, BRICKHEIGHT
	add		bx, GRIDGAPY
	xor		dx, dx
	div		bx  ;div ax door bx, resultaat in ax
	xor		dx, dx
	mov		bx,	[bricksperline][0]
	mul		bx   ;de lijn (ax) maal het aantal bricks per lijn = geeft het aantal bricks voor zijn huidige lijn terug
	mov		cx, ax	;resultaat in cx zetten
	
	mov		ax, colX
	sub		ax, GRIDOFFSETX
	add		ax, 1 
	mov		bx, BRICKWIDTH
	add		bx, GRIDGAPX
	xor		dx, dx
	div		bx  ;div ax door bx, resultaat in ax
	add		cx, ax
	add		cx, cx
	mov		di, cx
	mov		ax, [brickarray][di]
	cmp		ax, 0
	jz		removeblock
	sub		ax, 1
	mov		[brickarray][di], ax
	jmp 	done
removeblock:
	mov		[brickarray][di], 0
done:
	pop		di
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	pop		bp
	ret		4
handleCollision ENDP

updateScreen PROC NEAR
	push	ax
	push	cx
	push	si
	push	di
	push	ds
	push	es
	
	; setup source and dest segments
	mov		ax, seg screenBuffer
	mov		ds, ax
	mov		si, offset screenBuffer
	mov		ax, 0a000h	; video memory
	mov		es, ax
	xor		di, di
	
	cld
	mov		cx, 64000 / 2
	;waitVBlank	; wait for a VB (modifies AX and DX)
	rep		movsw	; blit to screen	
	
	pop		es
	pop		ds
	pop		di
	pop		si
	pop		cx
	pop		ax
	ret		0
updateScreen ENDP

drawLives PROC NEAR
	push	ax
	push	bx
	push	cx
	
	mov		cx, [lives]
	mov		bx, LIFEINITPOSX
lp:
	cmp		cx, 0
	jz		done
	mov		ax, RED
	push	ax
	mov		ax, LIFESIZE 
	push	ax  ;pushing width on the stack
	mov		ax, LIFESIZE
	push	ax  ;pushing height on the stack
	push	bx
	mov 	ax, LIFEINITPOSY
	push	ax	;pushing y-position on the stack
	call 	drawRectangle
	sub		bx, LIFEGAP
	sub		cx, 1
	jmp 	lp
	
done:
	pop 	cx
	pop 	bx
	pop		ax
	ret
drawLives ENDP
	
drawRectangle PROC NEAR
	;putting the arguments in constants
	argColor	EQU	[bp + 4][8]
	argWidth 	EQU [bp + 4][6]
	argHeight 	EQU [bp + 4][4]
	argPosX 	EQU [bp + 4][2]
	argPosY 	EQU [bp + 4][0]
	
	push 	bp ; save old value of bp
	mov 	bp, sp ; make bp our reference point
	
	push	dx
	push	ax
	push	cx
	push	di
	
	; set segment
	mov	ax, seg screenBuffer
	mov	es, ax
	
	;calculate offset of top-left corner
	mov		dx, SCREENW
	mov		ax, argPosY
	mul		dx		;doet argPosY*SCREENW en zet result in dx:ax
	add		ax, argPosX	;tel er de x-coordinate bij op
	
	;drawing a recangle
	mov		cx, argHeight 
    mov		di, ax ;put start offset in di
heightLoop:
	push	cx ;cx is used as counter in loop(height) & rep(width). pushing loop counter, so counter gets free for rep.
    mov		cx, argWidth      
    mov		al, argColor        
    rep		stosb  ;draws pixels until cx is zero
	pop		cx
	add 	di, SCREENW 
	sub 	di, argWidth ;put the starting offset on the nextline
	loop	heightLoop
    	
	pop		di
	pop		cx
	pop		ax
	pop		dx

	pop		bp
	ret		10
drawRectangle ENDP

	
; _------------------------------- END OF CODE ---------------------------------
END main