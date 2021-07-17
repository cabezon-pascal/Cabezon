;	module	iocheck.asm	91/01/06
;
;
STDERR		= 2
;
_DATA		segment word public 'DATA'
		extrn __ioresult_1: word
_DATA		ends

_BSS		segment word public 'DATA'
_BSS		ends
dgroup		group	_DATA, _BSS
;
SYSTEM_TEXT	segment byte public 'CODE'
		assume	cs: SYSTEM_TEXT, ds: dgroup

		extrn	error_print: near

		public	__iocheck
__iocheck	proc	far
		mov	ax, __ioresult_1
		or	ax, ax
		jz	no_error
		jmp	error_print
no_error:
		ret	4
__iocheck	endp

SYSTEM_TEXT	ends

;
		end
