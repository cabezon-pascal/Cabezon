;	module	dispose.asm	91/01/06]
;
;
INVALID_POINTER_OPERATION	=	204

_DATA		segment word public 'DATA'
		extrn	__ioresult_1: word
_DATA		ends

dgroup		group	_DATA

SYSTEM_TEXT	segment byte public 'CODE'
		assume	cs: SYSTEM_TEXT, ds: dgroup

		public	__dispose@huge
__dispose@huge	proc	far
		mov	bx, sp
		mov	es, ss:8[bx]		; segment of ptr
		mov	ah, 49h			; dispose memory
		int	21h
		jc	dispose_error
exit_dispose:
		ret	6
dispose_error:
		mov	__ioresult_1, INVALID_POINTER_OPERATION
		jmp	exit_dispose
__dispose@huge	endp

SYSTEM_TEXT	ends
;
		end
