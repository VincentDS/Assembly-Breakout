; ==============================================================================
; Empty example assembly file.
; ==============================================================================
.MODEL large ; one data and one code segment, stack and data segment are grouped
.STACK 2048  ; stack, 2048 bytes

; --- INCLUDES -----------------------------------------------------------------

include KEYB.INC

; --- MACROS AND CONSTANTS -----------------------------------------------------

	SCREENW			equ 320		;screenwidth
	SCREENH			equ 200		;screenheight
	
	PADDLEINITW		equ 35 
	PADDLEINITH		equ 5
	PADDLEINITPOSX	equ 135
	PADDLEINITPOSY	equ 170
	PADDLESPDINCX	equ 2
	
	BALLSIZE		equ 3
	BALLINITPOSX	equ 160
	BALLINITPOSY	equ 100
	BALLSPDINCX		equ 2
	BALLSPDINCY		equ	2	

; --- DATA SEGMENT -------------------------------------------------------------
.DATA	; data segment, variables
	
	palette     	db	0, 0, 0, 63, 63, 63  ; defines black (0,0,0) and white (63,63,63)
	startVideo		dw	0a000h 				;start of the video memory
	paddle_pos		dw	PADDLEINITPOSX	
	paddle_speed	dw	0	
	ball_pos		dw	BALLINITPOSX, BALLINITPOSY
	ball_speed		dw	BALLSPDINCX, BALLSPDINCY
	
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
	call 	handleInput
	call	moveBall
	call 	updateScreen
	jmp 	mainloop	
	
	; Exit to DOS
	mov	ax, 4c00h
	int	21h
main ENDP

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
	mov 	cx, 2				; set color 0 and 1 (2 indexes in total) (2 kleuren)
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
	
drawPaddle:
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

; Reads keyboard buffer and acts (returns non-zero if loop should end, 0 otherwise)
handleInput PROC NEAR
	push	es
	push	ax
	
	mov 	[paddle_speed], 0
	
	mov	ax, seg __keysActive
	mov	es, ax
	
	xor	ah, ah
	mov	al, es:[__keysActive]
	cmp	al, 0
	jz	@done		; no key pressed

	mov	al, es:[__keyboardState][SCANCODE_LEFT]	; test LEFT key
	cmp	al, 0
	jz @F	; jump next
	mov 	ax, [paddle_speed]
	sub 	ax, PADDLESPDINCX
	mov 	[paddle_speed], ax
@@:
	mov	al, es:[__keyboardState][SCANCODE_RIGHT]	; test RIGHT key
	cmp	al, 0
	jz @F	; jump next
	mov 	ax, [paddle_speed]
	add 	ax, PADDLESPDINCX
	mov 	[paddle_speed], ax
@@:
	
	; finally, let's put the ESC key status as return value in AX
	mov	al, es:[__keyboardState][SCANCODE_ESC]	; test ESC

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
	push	ax
	push	bx
	push	cx

	mov		ax, [ball_pos][0]
	mov		bx, [ball_speed][0]
	add 	ax, bx
left?:
	cmp		ax, 0
	jle leftfix ; future pos niet goed, custom pos wegschrijven
right?:
	mov		cx, SCREENW
	sub		cx, BALLSIZE
	cmp		ax, cx
	jge rightfix ; future pos niet goed, custom pos wegschrijven
	
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
cont:
	mov		ax, [ball_pos][2]
	mov		bx, [ball_speed][2]
	add 	ax, bx
top?:
	cmp		ax, 0
	jle topfix ; future pos niet goed, custom pos wegschrijven
bottom?:
	mov		cx, SCREENH
	sub		cx, BALLSIZE
	cmp		ax, cx
	jge bottomfix ; future pos niet goed, custom pos wegschrijven
	
	mov		[ball_pos][2], ax ;geen fix nodig, future pos gewoon wegschrijven
	jmp		next
topfix:
	mov		[ball_pos][2], 0
	neg		bx
	mov		[ball_speed][2], bx
	jmp		next
bottomfix:
	mov		[ball_pos][2], cx
	neg		bx
	mov		[ball_speed][2], bx
	jmp		next
	
next:
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
	pop		ax
	ret
moveBall ENDP

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
	
drawRectangle PROC NEAR
	;putting the arguments in constants
	argWidth 	EQU [bp + 4][6]
	argHeight 	EQU [bp + 4][4]
	argPosX 	EQU [bp + 4][2]
	argPosY 	EQU [bp + 4][0]
	retBytes 	EQU 8
	
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
    mov		al, 1        
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
	ret		retBytes
drawRectangle ENDP
	
; _------------------------------- END OF CODE ---------------------------------
END main