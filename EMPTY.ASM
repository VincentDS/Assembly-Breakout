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
	
	up	db "up$"
	down db "down$"
	left db "left$"
	right db "right$"

.CODE        ; code segment


; ----------------------------- CODE STARTS HERE -------------------------------
main:
	
	; set the video mode 320x200, 256 colors
	mov ah, 0  ; function 0 (set video mode)
	mov al, 13h ; argument 13h (mode 13h to be set)
	int 10h ; call Video BIOS
	
	; initialize the colorpallete
	mov	ax, @data	; set data segment;
	mov	ds, ax		;in ds
	mov es, ax		; and in es
	mov dx, offset palette ; set the palette (DAC) (offset relative to es)
	xor bx, bx		; set bx to zero (start at color index 0)
	mov cx, 2		; set color 0 and 1 (2 indexes in total) (2 kleuren)
	mov ax, 1012h	; function 1012h of int 10h (set DAC palette)
	int 10h		; call Video BIOS
	
		;alle pushes
	push es
	push bx
	push ax
	push cx
	push dx
	push di
	
	;segment en argumenten
	mov es, startaddr
	mov bx, 135 ;x-coordinate
	mov al, 180 ;y-coordinate   ;omzetten naar 1 pixel= y-keer de breedte + x
	mov ch, USERH ;lijncounter 
	mov cl, 1 ;nu zit 1 in cx (kleur)

beginposition:
	mov	dx, SCREENW
	mul dx   ;doet ax*320 en zet result in dx:ax
	add ax, bx ;tel er de x-coordinate bij op
	mov di, ax ;zet het resultaat naar di. Dit is de beginpositie
	mov dx, di ;zet het resultaat ook in dx, zodat we de eindpositie kunnen berekenen van één lijn
	add dx, USERW ;eindpositie van een lijn

horizontal:
	mov es:[di], cx  ;set di register to color in cx
	inc di ;di met een verhogen, zodat je één pixel verderzit
	cmp di, dx ;kijken of je al aan de eindpositie van de lijn zit
	jnz horizontal

nextline:
	sub di, USERW 
	add di, SCREENW ;di terug op beginpositie zetten, maar een rij lager (+ SCREENW)
	add dx, SCREENW ;eindpositie van de lijn ook een rij lager zetten
	dec ch ;lijncounter één lager
	cmp ch, 0 ;kijken of je alle lijnen al hebt getekent
	jnz horizontal

	;alle pops
	pop di
	pop dx
	pop cx
	pop ax
	pop bx
	pop es
	
readInput:	
	mov ah, 00h 
	int 16h 
	cmp ah, 72
	jz uparrow
	cmp ah, 73
	jz downarrow
	cmp ah, 74
	jz leftarrow
	cmp ah, 75
	jz rightarrow
	
uparrow:
	mov ah, 09h 
	mov	dx, offset up	
	int 21h 
	jmp readInput
downarrow:
	mov ah, 09h 
	mov	dx, offset down	
	int 21h 
	jmp readInput
leftarrow:
	mov ah, 09h 
	mov	dx, offset left	
	int 21h 
	jmp readInput
rightarrow:
	mov ah, 09h 
	mov	dx, offset right	
	int 21h 
	jmp readInput


	

	
	; Exit to DOS
	mov	ax, 4c00h
	int	21h

; --- END

; _------------------------------- END OF CODE ---------------------------------
END main