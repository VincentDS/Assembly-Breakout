; ==============================================================================
; Generic video functionality.
; ==============================================================================
.MODEL large	; multiple data segments and multiple code segments

; --- INCLUDES -----------------------------------------------------------------

INCLUDE video.inc

; --- MACROS AND CONSTANTS -----------------------------------------------------

; VGA DAC ports
PORT_VGA_DAC_READ	equ 03c7h	; write
PORT_VGA_DAC_WRITE	equ 03c8h	; write
PORT_VGA_DAC_DATA	equ 03c9h	; read/write

FADESTEPS	equ	32
FADESTEPSB	equ	5	; 5 bits

; --- DATA SEGMENT -------------------------------------------------------------
.DATA?

; The following buffer is used to keep 16-bit fixed point palette values during fading
paletteFader	dw 2 * 768 dup(?)
paletteStepsC	dw ?

; --- CODE SEGMENT -------------------------------------------------------------
.CODE

; Set the video mode and returns the previous mode in AL.
setVideoMode PROC FAR
	push	bp				; save dynamic link
	mov		bp, sp			; update bp
	push	bx
	
	mov		ah, 0fh			; get current video mode in al
	int		10h
	
	mov		bx, ax
	
	mov		ax, [bp + 6][0]	; get requested mode
	xor		ah, ah			; function 0
	int		10h
	
	mov		ax, bx
	
	pop		bx
	pop		bp	
	retf	2				; return
setVideoMode ENDP

; Immediately set a new VGA palette
;
; Arguments are SEGMENT and OFFSET of destination palette (points to 768 bytes)
setPalette PROC FAR
	push	bp
	mov		bp, sp
	
	push	cx
	push	dx
	push	si
	push	ds
	
	mov		ax, [bp + 6][2]		; get data segment argument
	mov		ds, ax				; and set it as DS
	
	mov		ax, [bp + 6][0]		; get the offset argument
	mov		si, ax				; and set it as source index

	cli							; disable interrupts
	
	mov		dx, PORT_VGA_DAC_WRITE
	xor		ax, ax
	out		dx, al				; start at color 0
	mov		dx, PORT_VGA_DAC_DATA
	mov		cx, 768				; we need to write 768 channel color bytes
@@:								; local loop label
	lodsb						; load next channel color byte into al
	out		dx, al				; write the byte in al to DAC DATA port
	dec		cx					; decrement loop counter
	jnz		@B					; loop if more todo (@B is the first @@ label before this point)
	
	sti							; enable interrupts
	
	pop		ds
	pop		si
	pop		dx
	pop		cx
	
	pop		bp
	retf	4
setPalette ENDP

; Call this function to start a palette fade,
; starting with the currently active palette
; (uses paletteFader and paletteSteps)
; (defaults to 32 steps)
; Arguments are SEGMENT and OFFSET of destination palette (points to 768 bytes)
paletteInitFade PROC FAR
	push	bp
	mov		bp, sp

	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	
	cld
	
	; setup segment registers
	mov		ax, [bp + 6][2]	; get data segment
	mov		ds, ax

	; one palette color uses 6 bits, these are shifted 9 left to get
	; a 15 bit fixed point number with an extra sign bit (= 16 bits total)
	
	; paletteFader contains 16 bit palette RGB values and steps used for
	; fading (interleaved)

	; get the active palette into paletteFader (shifted left 9 bits)
	; and create the array of delta (step values) in 16-bit FP arithm.
	mov		ax, seg paletteFader
	mov		es, ax
	mov		ax, FADESTEPS		; initialize steps
	mov		es:[paletteStepsC], ax
	mov		si, [bp + 6][0]		; get the offset of target
	mov		di, offset paletteFader
	xor		ch, ch				; 256 RGB colors (uses wrapping)

	cli							; disable interrupts

	xor		ax, ax
	mov		dx, PORT_VGA_DAC_READ
	out		dx, al				; set color index 0
	mov		dx, PORT_VGA_DAC_DATA
@@:
	; RED
	lodsb						; al := ds:[si] (load dest value in al)
	mov		bl, al				; put it in bl
	in		al, dx				; read active color in al
	sub		bl, al				; get difference (can be negative)
	mov		cl, 9				; prepare for 9 bit shift left
	sal		bx, cl				; make 16 bit fixed point
	shl		ax, cl				; make 16 bit fixed point
	mov		cl, FADESTEPSB		; prepare for step division
	sar		bx, cl				; steps (div by number of steps)
	stosw						; store active color (16 bit)
	mov		ax, bx
	stosw						; store step value (16 bit)
	; GREEN
	lodsb						; al := ds:[si] (load dest value in al)
	mov		bl, al				; put it in bl
	in		al, dx				; read active color in al
	sub		bl, al				; get difference (can be negative)
	mov		cl, 9				; prepare for 9 bit shift left
	sal		bx, cl				; make 16 bit fixed point
	shl		ax, cl				; make 16 bit fixed point
	mov		cl, FADESTEPSB		; prepare for step division
	sar		bx, cl				; steps (div by number of steps)
	stosw						; store active color (16 bit)
	mov		ax, bx
	stosw						; store step value (16 bit)
	; BLUE
	lodsb						; al := ds:[si] (load dest value in al)
	mov		bl, al				; put it in bl
	in		al, dx				; read active color in al
	sub		bl, al				; get difference (can be negative)
	mov		cl, 9				; prepare for 9 bit shift left
	sal		bx, cl				; make 16 bit fixed point
	shl		ax, cl				; make 16 bit fixed point
	mov		cl, FADESTEPSB		; prepare for step division
	sar		bx, cl				; steps (div by number of steps)
	stosw						; store active color (16 bit)
	mov		ax, bx
	stosw						; store step value (16 bit)
	inc		ch
	jnz 	@B

	sti							; enable interrupts
	
	pop		es
	pop		ds
	pop		di
	pop		si
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	
	pop		bp					; restore original BP
	retf 	4					; return and free 2 args
paletteInitFade ENDP

; Perform the next palette fading step
; More steps are needed when return value (AX) is non-zero
paletteNextFade PROC FAR
	push	bp
	
	push	bx
	push	cx
	push	dx
	push	di
	push	ds
	push	es
	
	cld
	
	mov		ax, seg paletteFader
	mov		ds,	ax
	mov		es, ax
	
	cli							; disable interrupts	
	
	; add deltas and set new palette
	xor		ax, ax
	mov		dx, PORT_VGA_DAC_WRITE
	out		dx, al				; start at index 0
	mov		si, offset paletteFader
	mov		di, si
	xor		ch, ch				; 256 color indexes
	mov		dx, PORT_VGA_DAC_DATA
	mov		cl, 9
@@:
	; RED
	lodsw						; load active color in ax
	mov		bx, ax
	lodsw						; load step in ax
	add		ax, bx				; add active color and step
	stosw						; store new active color
	add		di, 2	
	add		ax, 256				; rounding (9 bits fraction, so add 0.5 in decimals = 2^8 = 256)
	shr		ax, cl				; convert 16 bit FP to 6 bit int
	out		dx, al				; write active color
	; GREEN	
	lodsw						; load active color in ax
	mov		bx, ax
	lodsw						; load step in ax
	add		ax, bx				; add active color and step
	stosw						; store new active color
	add		di, 2
	add		ax, 256				; rounding
	shr		ax, cl				; convert 16 bit FP to 6 bit int
	out		dx, al				; write active color
	; BLUE	
	lodsw						; load active color in ax
	mov		bx, ax	
	lodsw						; load step in ax
	add		ax, bx				; add active color and step
	stosw						; store new active color
	add		di, 2
	add		ax, 256				; rounding
	shr		ax, cl				; convert 16 bit FP to 6 bit int
	out		dx, al				; write active color	
	inc		ch
	jnz		@B
	
	sti							; enable interrupts
	
	; one step less todo
	mov		ax, [paletteStepsC]
	dec		ax
	mov		[paletteStepsC], ax
	
	pop		es
	pop		ds
	pop		di
	pop		dx
	pop		cx
	pop		bx
	
	pop		bp
	retf	0
paletteNextFade ENDP

; _------------------------------- END OF CODE ---------------------------------
END
