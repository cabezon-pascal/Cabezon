dgroup		group	_DATA, _BSS
		assume	cs: SYSTEM_TEXT, ds: dgroup

_DATA		segment	word public 'DATA'
		extrn	__IORESULT_1: word
_DATA		ends
_BSS		segment	word public 'DATA'
_BSS		ends

		extrn	__close: far

SYSTEM_TEXT	segment	byte public 'CODE'
		public	_close
_close		proc	far
		cmp	word ptr __IORESULT_1, 0
		jne	L1
		mov	bx, sp
		push	ss:6[bx]
		push	ss:4[bx]
		call	far ptr __close
L1:
		ret
_close		endp
SYSTEM_TEXT	ends

		end
