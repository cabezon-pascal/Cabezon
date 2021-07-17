;	module	iocheck2.asm	91/01/06
;
;
STDERR		= 2
;
_DATA		segment word public 'DATA'
		extrn __ioresult_1: word
_DATA		ends

dgroup		group	_DATA
;
SYSTEM_TEXT	segment byte public 'CODE'
		assume	cs: SYSTEM_TEXT, ds: dgroup

		extrn	error_print: near

		public	__iocheck2
__iocheck2	proc	far
		mov	ax, __ioresult_1
		or	ax, ax
		jz	no_error
		jmp	error_print
no_error:
		ret
__iocheck2	endp

SYSTEM_TEXT	ends

		end
