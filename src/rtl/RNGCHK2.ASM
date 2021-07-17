;	module	err.asm	91/02/17
;
;
_BSS		segment word public 'DATA'
_BSS		ends

_DATA		segment word public 'DATA'
_DATA		ends

dgroup		group	_DATA, _BSS

		extrn	error_print: near

SYSTEM_TEXT	segment word  public 'CODE'
		assume	cs: SYSTEM_TEXT, ds: dgroup

		public	__range@check2
__range@check2	proc	far
		cmp	ax, bx
		jl	L1
		cmp	ax, cx
		jg	L1
		ret
L1:
		mov	ax, 201
		jmp	error_print
__range@check2	endp

SYSTEM_TEXT	ends
;
		end
