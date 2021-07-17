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

		public	__range@check1
__range@check1	proc	far
		cmp	al, bl
		jb	L1
		cmp	al, cl
		ja	L1
		ret
L1:
		mov	ax, 201
		jmp	error_print
__range@check1	endp

SYSTEM_TEXT	ends
;
		end
