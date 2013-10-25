; ==============================================================================
; Empty example assembly file.
; ==============================================================================
.MODEL large ; one data and one code segment, stack and data segment are grouped
.STACK 2048  ; stack, 2048 bytes
.DATA        ; data segment, global variables

	SCREENW		equ 320    ;screenwidth
	SCREENH		equ 200		;screenheight
	palette     db 0, 0, 0, 63, 63, 63 ; defines black (0,0,0) and white (63,63,63)
	startaddr	dw	0a000h ;start of the video memory
	

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
	
	;blokje tekenen op 40x150 met lengte 30 en breedte 8
	;segment en argumenten
	mov ax, startaddr
	mov es, ax
	mov bh, 60 ;x-coordinate
	mov bl, 180 ;y-coordinate   ;omzetten naar 1 pixel= y-keer de breedte + x
	mov ch, 5
	mov cl, 1 ;nu zit 1 in cx (kleur)

beginposition:
	mov	dx, SCREENW
	mov al, bl ;y-coordinate in ax zetten
	mul dx   ;doet ax*320 en zet result in dx:ax
	add al, bh ;tel er de x-coordinate bij op
	mov di, ax ;zet het resultaat naar di. Dit is de beginpositie
	mov dx, di ;zet het resultaat ook in dx, zodat we de eindpositie kunnen berekenen van één lijn
	add dx, 30 ;eindpositie van een lijn

horizontal:
	mov es:[di], cx  ;set di register to color in cx
	inc di 
	cmp di, dx
	jnz horizontal

nextline:
	sub di, 30
	add di, SCREENW
	add dx, SCREENW
	cmp ch, 0
	dec ch
	jnz horizontal

	
	; Exit to DOS
	mov	ax, 4c00h
	int	21h

; --- END

; _------------------------------- END OF CODE ---------------------------------
END main