; ==============================================================================
; Generic video functionality.
; ==============================================================================

; --- EXPORTS ------------------------------------------------------------------

externdef setVideoMode:FAR
externdef setPalette:FAR, paletteInitFade:FAR, paletteNextFade:FAR

; --- MACROS AND CONSTANTS -----------------------------------------------------

; Waits for the next start of a vertical blank (VB) period by the video card
waitVBlank MACRO
	LOCAL @waitVBlank_wait1, @waitVBlank_wait2
	push	ax
	push	dx
	mov	dx, 03dah	; VGA status port
@waitVBlank_wait1:		; if already in VB, then wait until VB finishes
	in	al, dx		; read status
	and	al, 8		; test bit 3
	jnz	@waitVBlank_wait1	; busy wait if in VB
@waitVBlank_wait2:		; wait until begin of a new VB
	in	al, dx		; read status
	and	al, 8		; test bit 3
	jz	@waitVBlank_wait2	; busy wait if NOT in VB
	pop	dx
	pop	ax
	ENDM

