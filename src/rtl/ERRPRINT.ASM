;	module	err.asm	91/02/17
;
;
STDERR		= 2
;
_BSS		segment word public 'DATA'
		extrn	startSegment: word
_BSS		ends

_DATA		segment word public 'DATA'
		extrn	__ioresult_1: word
iocheck_error_head	db	'Run time error 000'
iocheck_error_2		db	' at '
iocheck_error_3		db	'0000:0000', 0dh, 0ah
iocheck_error_tail	label	byte
_DATA		ends

dgroup		group	_DATA, _BSS
;
SYSTEM_TEXT	segment word  public 'CODE'
		assume	cs: SYSTEM_TEXT, ds: dgroup

		public	error_print
error_print	proc	far
		push	ds
		pop	es
		mov	cx, 3			; loop count
		mov	di, offset dgroup: iocheck_error_2[-1]
		std
outdecimal_loop:
		aam
		add	al, '0'
		stosb
		mov	al, ah
		loop	outdecimal_loop
;
		mov	di, offset dgroup: iocheck_error_3
		cld
		pop	si
		pop	dx
		sub	dx, startSegment
		call	__hex16
		mov	dx, si
		inc	di
		call	__hex16
;
		mov	bx, STDERR
		mov	cx, (iocheck_error_tail - iocheck_error_head)
		mov	dx, offset dgroup: iocheck_error_head
		mov	ah, 40h			; write to handle
		int	21h
		mov	ah, 4ch
		mov	al, byte ptr __ioresult_1
		int	21h
error_print	endp

__hex16		proc	near
		mov	bl, 4
		mov	cl, 4
hex16_loop:
		rol	dx, cl
		mov	al, dl
		and	al, 0fh
		add	al, '0'
		cmp	al, '9'
		jbe	hex16_decimal
		add	al, 'A' - '0' - 10
hex16_decimal:
		stosb
		dec	bl
		jnz	hex16_loop
		ret
__hex16		endp

SYSTEM_TEXT	ends
;
		end
