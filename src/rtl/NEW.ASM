;	module	new.asm	91/01/06
;
;
HEAP_OVERFLOW_ERROR	=	203
YES					= 1
NO					= 0

_DATA		segment word public 'DATA'
heap_head	dw	0
		public	heap_head
		extrn	__ioresult_1: word
_DATA		ends

_BSS		segment	byte public 'DATA'
iocheck_flag	db		1 dup (?)
_BSS		ends

dgroup		group	_DATA, _BSS

SYSTEM_TEXT	segment byte public 'CODE'
		assume	cs: SYSTEM_TEXT, ds: dgroup

		extrn	__iocheck2: far

		public	__new, __new_with_check
__new_with_check	proc	far
		mov		iocheck_flag, YES
		jmp		short L05
__new	label	far
		mov		iocheck_flag, NO
L05:
		push	bp
		mov	bp, sp
		mov	cx, 6[bp]		; cx <= size
		add	cx, 0003h
		and	cx, not 0003h		; ‚S’PˆÊ‚ÉØã‚°
L10:
		mov	dx, heap_head
L20:
		or	dx, dx
		jz	L60
		mov	es, dx
		xor	si, si
L25:
		mov	di, es:[si]
		or	di, di
		jz	L50
		mov	ax, es:[di+2]
		cmp	cx, ax
		jnz	L30
		mov	ax, es:[di]
		mov	es:[si], ax
		mov	ax, di
		jmp	exit_new
L30:
		ja	L40
		sub	ax, cx
		mov	es:[di+2], ax
		add	ax, di
		jmp	exit_new
L40:
		mov	si, di
		jmp	L25
L50:
		mov	dx, es:[2]
		jmp	L20
L60:
		mov	ah, 48h		; get memory
		mov	bx, 4096	; 64k / 16
		int	21h		; ms-dos
		jnc	L70
		or	ax, ax
		jz	new_error
		mov	bx, ax
		mov	ah, 48h		; get memory
		int	21h		; ms-dos
		jc	new_error
L70:
		shl	bx, 1
		shl	bx, 1
		shl	bx, 1
		shl	bx, 1
		sub	bx, 4
		mov	es, ax
		mov	dx, heap_head
		mov	heap_head, ax
		mov	word ptr es:[0], 4	; avail
		mov	word ptr es:[2], dx	; next segment
		mov	word ptr es:[4], 0	; terminator
		mov	word ptr es:[6], bx	; size
		jmp	L10
new_error:
		mov	__ioresult_1, HEAP_OVERFLOW_ERROR
		cmp	iocheck_flag, YES
		jne	exit_new
		pop	bp
		jmp	__iocheck2
exit_new:
		mov	sp, bp
		pop	bp
		ret	2
__new_with_check	endp

SYSTEM_TEXT	ends

;
		end
