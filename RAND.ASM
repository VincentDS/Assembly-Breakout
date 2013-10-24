; ==============================================================================
; Random number generator example
; ==============================================================================
.MODEL small ; one data and one code segment, stack and data segment are grouped
.STACK 1024  ; stack, 1024 bytes

INCLUDE rand.inc

; ----------------------------- DATA STARTS HERE -------------------------------
.DATA        ; data segment, static variables

randSeed	dw	RAND_SEED		; initial random seed
randR250Idx	dw	0			; R250 index
randR250Buf	dw	250 dup(?)	; buffer for R250 random generator

; ----------------------------- CODE STARTS HERE -------------------------------
.CODE        ; code segment

; Generate a random number in AX (16 bits).
randLinear PROC NEAR
	push	bp	; save dynamic link
	mov	bp, sp	; update bp

	push	bx ; save used registers
	push	cx
	push	dx
	
	; Lehmer linear congruential random number generator
	; z = (a*z+b) mod m = (31*z+13)%19683
	; Rules for a, b, m by D. Knuth:
	; 1. b and m must be relatively prime
	; 2. a-1 must be divisible without remainder by all prime factors of m
	;    (19683 = 3^9), (31-1)%3=0
	; 3. if m is divisible by 4, a-1 must also be divisible by 4,
	;    19683%4 != 0, ok
	; 4. if conditions 1 to 3 met, period of {z1, z2, z3,...} is
	;    m-1 = 19682 (Donald says)

	mov ax, [randSeed]

	; prepare first generated number (range [0;19683[)
	mov	bx, 31		; 31D
	mul	bx		; 31 * z
	; result dx:ax, higher value in dx, lower value in ax
	add	ax, 13
	adc	dx, 0
	mov	bx, 19683
	div	bx		; div by 19683
	; result ax:dx, quotient in ax, remainder in dx
	mov	ax, dx

	; keep the number in cx and do some mixing
	mov	cx,	ax
	xchg	cl, ch
	rol	cx, 1

	; prepare second generated number (range [0;19683[)
	mov	bx, 31		; 31D
	mul	bx		; 31 * z
	; result dx:ax, higher value in dx, lower value in ax
	add	ax, 13
	adc	dx, 0
	mov	bx, 19683
	div	bx		; div by 19683
	; result ax:dx, quotient in ax, remainder in dx
	mov	ax, dx

	mov	[randSeed], ax	; store for next rand call

	xor	ax, cx	; combine the two rands into a 16-bit number
	
	pop	dx
	pop	cx
	pop	bx

	; return
	pop	bp
	ret	0
randLinear ENDP

; Initializes the R250 random number generator
; See PDF file
randInit PROC FAR
	push	bp	; save dynamic link
	mov	bp, sp	; update bp

	push	ax
	push	bx
	push	cx
	push	di
	
	; Clear index
	mov	[randR250Idx], 0
	
	; Fill the randR250Buf with simple rand values
	mov	cx, 250
	mov	di, offset randR250Buf
@randInit_fill:
	call	randLinear	; get a simple rand
	mov	[di], ax
	add	di, 2
	loop	@randInit_fill

	; Correct values
	mov	cx, 16
	mov	di, offset randR250Buf
	add	di, 6
	mov	ax,	0ffffh
	mov	bx, 08000h
@randInit_loop1:
	and	[di], ax
	or	[di], bx
	shr	ax, 1
	shr	bx, 1
	add	di, 22
	loop	@randInit_loop1
	
	; And we are done
	pop	di
	pop	cx
	pop	bx
	pop	ax
	
	; return
	pop	bp
	ret	0
randInit ENDP

; Use R250 random number generator and return a value in AX
; See PDF file
rand PROC FAR
	push	bp	; save dynamic link
	mov	bp, sp	; update bp

	push	bx
	push	di
	
	mov	di, offset randR250Buf
	
	; Calculate next index
	mov	ax, [randR250Idx]
	cmp	ax, 147
	jl	@rand_else1
	sub	ax, 147
	jmp	@rand_endif1
@rand_else1:
	add	ax, 103
@rand_endif1:
	mov	bx, ax
	shl	bx, 1
	
	mov	ax, [bx][di]	; ax = randR250Buf[bx]
	mov	bx, [randR250Idx]
	shl	bx, 1
	add	di, bx
	xor	[di], ax	; randR250Buf[randR250Idx] ^= ax (new rand)
	
	; generate new index
	mov	ax, bx
	inc	ax
	mov	bl, 250
	div	bl
	mov	al, ah
	xor	ah, ah
	mov	[randR250Idx], ax

	mov	ax, [di]	; return new rand
	
	pop	di
	pop	bx
	
	; return
	pop	bp
	ret	0
rand ENDP

; _------------------------------- END OF CODE ---------------------------------
END
