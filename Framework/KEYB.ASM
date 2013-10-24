; ==============================================================================
; Keyboard functionality.
; ==============================================================================
.MODEL large	; multiple data segments and multiple code segments

; --- INCLUDES -----------------------------------------------------------------

INCLUDE keyb.inc

; --- MACROS AND CONSTANTS -----------------------------------------------------

; --- DATA SEGMENT -------------------------------------------------------------
.DATA?

PUBLIC __keyboardState, __rawScanCode, __keysActive

__originalKeyboardHandler	dw 2 dup(?)		; SEG/OFF of original keyboard handler
__keyboardState				db 128 dup(?)	; state for all 128 keys
__rawScanCode				db ?			; scan code of last pressed key
__keysActive				db ?			; number of actively pressed keys

; --- CODE SEGMENT -------------------------------------------------------------
.CODE

; Installs the custom keyboard handler
installKeyboardHandler PROC FAR
    push	bp
    mov		bp, sp

	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	push	ds
	push	es
		
	mov		ax, seg __originalKeyboardHandler
	mov		ds, ax
	mov		es, ax
	
	; clear state buffer and the two state bytes
	cld
	mov		cx, (128 / 2) + 1
	mov		di, offset __keyboardState
	xor		ax, ax
	rep		stosw
	
	; store current handler
	mov		ax, 3509h			; get current interrupt handler 09h
	int		21h					; in ES:BX
			
	mov		ax, es
	mov		[__originalKeyboardHandler][0], ax	; store SEG
	mov		[__originalKeyboardHandler][2], bx	; store OFF
		
	; set new handler
	mov		ax, seg keyboardHandler		; new SEG
	mov		dx, offset keyboardHandler	; new OFF
	mov		ds, ax
	
	mov		ax, 2509h			; set custom interrupt handler 09h
	int		21h					; uses DS:DX
	
	pop		es
	pop		ds
	pop		di
	pop		dx
	pop		cx
	pop		bx
	pop		ax	
    
    pop		bp
    ret
installKeyboardHandler ENDP

; Restores the original keyboard handler
uninstallKeyboardHandler PROC FAR
    push	bp
    mov		bp, sp

	push	ax
	push	dx
	push	ds
	
	mov		ax, seg __originalKeyboardHandler
	mov		ds, ax
	
	mov		ax, [__originalKeyboardHandler][0]	; retrieve SEG
	mov		dx, [__originalKeyboardHandler][2]	; retrieve OFF
	mov		ds, ax
	
	mov		ax, 2509h			; set original interrupt handler 09h
	int		21h					; uses DS:DX
	
	pop		ds
	pop		dx
	pop		ax
	
    pop		bp
    ret
uninstallKeyboardHandler ENDP

; Keyboard handler (Interrupt function, DO NOT CALL MANUALLY!)
keyboardHandler PROC FAR
	KEY_BUFFER	EQU 60h			; the port of the keyboard buffer
	KEY_CONTROL	EQU 61h			; the port of the keyboard controller
	PIC_PORT	EQU 20h			; the port of the peripheral

	push	ax
	push	bx
	push	si
	push	ds
	
	; setup DS for access to data variables
	mov		ax, seg __originalKeyboardHandler
	mov		ds, ax
	
	; handle the keyboard input
	sti							; re-enable CPU interrupts
	in		al, KEY_BUFFER		; get the key that was pressed from the keyboard
	mov		bl, al				; store scan code for later use
	mov		[__rawScanCode], al	; store the key in global variable
	in		al, KEY_CONTROL		; set the control register to reflect key was read
	or		al, 82h				; set the proper bits to reset the keyboard flip flop
	out		KEY_CONTROL, al		; send the new data back to the control register
	and		al, 7fh				; mask off high bit
	out		KEY_CONTROL, al		; complete the reset
	mov		al, 20h				; reset command
	out		PIC_PORT, al		; tell PIC to re-enable interrupts

	; process the retrieved scan code and update __keyboardState and __keysActive
	; scan codes of 128 or larger are key release codes
	mov		al, bl				; put scan code in al
	shl		ax, 1				; bit 7 is now bit 0 in ah
	not		ah
	and		ah, 1				; ah now contains 0 if key released, and 1 if key pressed
	shr		al, 1				; al now contains the actual scan code ([0;127])
	xor		bx, bx	
	mov		bl, al				; bl now contains the actual scan code ([0;127])
	lea		si, [__keyboardState][bx]	; load address of key relative to __keyboardState in bx
	mov		al, [si]			; load the keyboard state of the scan code in al
	; al = tracked state (0 or 1) of pressed key (the value in memory)
	; ah = physical state (0 or 1) of pressed key
	neg		al
	add		al, ah				; al contains -1, 0 or +1 (-1 on key release, 0 on no change and +1 on key press)
	add		[__keysActive], al	; update __keysActive counter
	mov		al, ah
	mov		[si], al			; update tracked state
	
	pop		ds
	pop		si
	pop		bx
	pop		ax
	
	iret
keyboardHandler ENDP

; _------------------------------- END OF CODE ---------------------------------
END
