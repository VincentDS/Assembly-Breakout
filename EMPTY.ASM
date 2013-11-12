; ==============================================================================
; Empty example assembly file.
; ==============================================================================
.MODEL large ; one data and one code segment, stack and data segment are grouped
.STACK 2048  ; stack, 2048 bytes
.DATA        ; data segment, global variables

	SCREENW		equ 320    ;screenwidth
	SCREENH		equ 200		;screenheight
	
	USERW		equ 35 
	USERH		equ 5
	
	palette     db 0, 0, 0, 63, 63, 63  ; defines black (0,0,0) and white (63,63,63)
	startaddr	dw	0a000h ;start of the video memory
	
	;up = 72
	;down = 80
	;left = 75
	;right = 77
	;esc = 01
	
	
.CODE        ; code segment


	
; ----------------------------- CODE STARTS HERE -------------------------------
main:

	; set the video mode 320x200, 256 colors
	mov ah, 0  ; function 0 (set video mode)
	mov al, 13h ; argument 13h (mode 13h to be set)
	int 10h ; call Video BIOS
	
	mov	ax, @data	; set data segment;
	mov	ds, ax		;in ds
	mov es, ax		; and in es
	mov dx, offset palette ; set the palette (DAC) (offset relative to es)
	xor bx, bx		; set bx to zero (start at color index 0)
	mov cx, 2		; set color 0 and 1 (2 indexes in total) (2 kleuren)
	mov ax, 1012h	; function 1012h of int 10h (set DAC palette)
	int 10h		; call Video BIOS
		

Initialize:
	mov	ax, 50 
	push	ax  ;pushing width on the stack
	mov ax, 135
	push 	ax	;pushing x-position on the stack
	mov ax,	190
	push	ax	;pushing y-position on the stack
	jmp DrawHorinzontalline


	mov ah, 00h
waitForInput:
	xor	ax, ax  ;same as mov, ax 0 but faster (only 2 bytes instead of 3)
	int	16h
	cmp	al, 75	; test for left arrow key
	jz goLeft
	cmp	al, 77  ; test for right arrow key
	jz goRight
	jmp waitForInput
	
goLeft:
	blabla
	jmp DrawHorizontalline
	
goRight:
	blabla
	jmp DrawHorizontalline

DrawHorizontalline:	
	mov es, startaddr
	push bp ; save old value of bp
	mov bp, sp ; make bp our reference point
	sub sp, 8   ; make room for 8 bytes of temporary space on stack. (for local variables)

	
	;putting the arguments in constants
	argWidth EQU [bp + 6]  
	argPosX EQU [bp + 4]
	argPosY EQU [bp + 2]
	
	;calculate offset of top-left corner
	mov	dx, SCREENW
	mov ax, argPosY
	mul	dx		;doet argPosY*SCREENW en zet result in dx:ax
	add	ax, argPosX	;tel er de x-coordinate bij op
	
	;drawing a line
	mov	di, ax
	mov	cx, argWidth	
	mov	al, 1	
	rep	stosb
	
	jmp	waitForInput


	
	
	; Exit to DOS
	mov	ax, 4c00h
	int	21h

; --- END

; _------------------------------- END OF CODE ---------------------------------
END main