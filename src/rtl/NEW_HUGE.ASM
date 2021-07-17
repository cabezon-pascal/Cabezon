;	module	new_huge.asm	93/01/02
;
;
HEAP_OVERFLOW_ERROR	=	203

_DATA		segment word public 'DATA'
		extrn	__ioresult_1: word
_DATA		ends

_BSS		segment	byte public 'DATA'
_BSS		ends

dgroup		group	_DATA, _BSS

SYSTEM_TEXT	segment byte public 'CODE'
		assume	cs: SYSTEM_TEXT, ds: dgroup

		public	__new@huge
__new@huge	proc	far
		mov	bx, sp
		mov	bx, ss:4[bx]	; bx <= paragraph
		mov	ah, 48h		; get memory
		int	21h		; ms-dos
		jc	new_error
		mov	dx, ax
		xor	ax, ax
exit_new:
		ret	2
new_error:
		mov	__ioresult_1, HEAP_OVERFLOW_ERROR
		jmp	exit_new
__new@huge	endp

SYSTEM_TEXT	ends

		end
