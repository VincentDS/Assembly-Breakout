; ==============================================================================
; Empty example assembly file.
; ==============================================================================
.MODEL large ; one data and one code segment, stack and data segment are grouped
.STACK 2048  ; stack, 2048 bytes
.DATA        ; data segment, global variables

	palette     db 20, 20, 20, 63, 63, 63 ; defines black (0,0,0) and white (63,63,63)
	startaddr	dw	0a000h ;start of the video memory
	

.CODE        ; code segment

drawFillRectangle PROC NEAR
	
	mov ax, startaddr
	mov es, ax
	mov bh, 40 ;x-coordinate
	mov bl, 50 ;y-coordinate   ;omzetten naar 1 pixel= y-keer de breedte + x
	
	mov dx, 0  ;multiply requirement
	mov al, bl ;y-coordinate in ax zetten
	mov cx, 320 ;320 in register zetten, want mul accepteert geen naked value
	mul cx   ; doet ax*320 en zet result in dx:ax
	add al, bh ;tel er de x-coordinate bij op
	mov di, ax ;zet het resultaat naar di
	
firsthorizontal:
	mov cx,   ;set color to a register
	mov es:[di], cx  ;set di register to color in cx

drawFillRectangle ENDP
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
	
	call drawFillRectangle
	
	; Exit to DOS
	mov	ax, 4c00h
	int	21h

; --- END

; _------------------------------- END OF CODE ---------------------------------
END main