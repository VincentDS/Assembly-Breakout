; ==============================================================================
; Empty example assembly file.
; ==============================================================================
.MODEL large ; one data and one code segment, stack and data segment are grouped
.STACK 2048  ; stack, 2048 bytes

; --- INCLUDES -----------------------------------------------------------------

include KEYB.INC

; --- MACROS AND CONSTANTS -----------------------------------------------------

	SCREENW		equ 320    ;screenwidth
	SCREENH		equ 200		;screenheight
	
	USERW		equ 35 
	USERH		equ 25
	STARTPOSX	equ 135
	STARTPOSY	equ 150
	SPEED		equ 1

; --- DATA SEGMENT -------------------------------------------------------------
.DATA        ; data segment, variables
	
	palette     db 0, 0, 0, 63, 63, 63  ; defines black (0,0,0) and white (63,63,63)
	startaddr	dw	0a000h ;start of the video memory
	paddle_pos	dw	1	dup(?)
			
; ----------------------------- CODE STARTS HERE -------------------------------
.CODE        ; code segment

main PROC NEAR
	mov	ax, @data	; set data segment;
	mov	ds, ax		;in ds
	
	mov es, startaddr

	call	initializeScreen
	call	initializePalette
	call 	initializeEnvironment
	
mainloop:
	call handleInput
	jmp mainloop	
	
	; Exit to DOS
	mov	ax, 4c00h
	int	21h
main ENDP

initializeScreen PROC NEAR
	; set the video mode 320x200, 256 colors
	mov ah, 0  ; function 0 (set video mode)
	mov al, 13h ; argument 13h (mode 13h to be set)
	int 10h ; call Video BIOS
	ret	
initializeScreen ENDP
		
initializePalette PROC NEAR
	push ax
	push dx
	push bx
	push cx
	push es
	
	mov	ax, @data	; set data segment;
	mov	ds, ax		;in ds
	mov es, ax		; and in es
	mov dx, offset palette ; set the palette (DAC) (offset relative to es)
	xor bx, bx		; set bx to zero (start at color index 0)
	mov cx, 2		; set color 0 and 1 (2 indexes in total) (2 kleuren)
	mov ax, 1012h	; function 1012h of int 10h (set DAC palette)
	int 10h		; call Video BIOS
	
	pop es
	pop cx
	pop bx
	pop dx
	pop ax
	ret
initializePalette ENDP
	
initializeEnvironment PROC NEAR
	mov	ax, USERW 
	push	ax  ;pushing width on the stack
	mov	ax, USERH 
	push	ax  ;pushing height on the stack
	mov ax, STARTPOSX
	mov [paddle_pos], ax ;putting x-position in memory variable
	push 	ax	;pushing x-position on the stack
	mov ax,	STARTPOSY
	push	ax	;pushing y-position on the stack
	call drawRectangle
	ret
initializeEnvironment ENDP

handleInput PROC NEAR
	mov ah, 00h
	xor	ax, ax  ;same as mov, ax 0 but faster (only 2 bytes instead of 3)
	int	16h
	cmp	ah, 75	; test for left arrow key
	jz left
	cmp	ah, 77  ; test for right arrow key
	jz right
	jmp done
left:
	call goLeft
	jmp done
right:
	call goRight
	jmp done
done:
	ret
handleInput ENDP	
	
goLeft PROC NEAR
	mov	ax, USERW 
	push	ax  ;pushing width on the stack
	mov	ax, USERH 
	push	ax  ;pushing height on the stack
	mov ax, [paddle_pos]
	sub ax, SPEED
	mov [paddle_pos], ax
	push 	ax	;pushing x-position on the stack
	mov ax,	STARTPOSY
	push	ax	;pushing y-position on the stack
 	call drawRectangle
	ret
goLeft ENDP
	
goRight PROC NEAR
	mov	ax, USERW 
	push	ax  ;pushing width on the stack
	mov	ax, USERH 
	push	ax  ;pushing height on the stack
	mov ax, [paddle_pos]
	add ax, SPEED
	mov [paddle_pos], ax
	push 	ax	;pushing x-position on the stack
	mov ax, STARTPOSY
	push	ax	;pushing y-position on the stack
	call drawRectangle
	ret
goRight ENDP
	
drawRectangle PROC NEAR
	mov es, startaddr
	;putting the arguments in constants
	argWidth EQU	[bp + 4][6]
	argHeight EQU	[bp + 4][4]
	argPosX EQU		[bp + 4][2]
	argPosY EQU		[bp + 4][0]
	retBytes EQU 8
	
	push bp ; save old value of bp
	mov bp, sp ; make bp our reference point
	
	push	dx
	push	ax
	push	cx
	push	di
	
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
    	
	pop	di
	pop	cx
	pop	ax
	pop	dx

	pop	bp
	ret	retBytes
drawRectangle ENDP
	
; _------------------------------- END OF CODE ---------------------------------
END main