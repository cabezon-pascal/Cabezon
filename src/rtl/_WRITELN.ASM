dgroup	group	_DATA
		assume	cs: SYSTEM_TEXT, ds: dgroup

_DATA		segment	word public 'DATA'
		extrn	__IORESULT_1: word
_DATA		ends

		extrn	__FLUSHBUFFERIFTTY: far, ___WRITECHAR: near

SYSTEM_TEXT	segment	byte public 'CODE'
		public	__WRITE@LN
__WRITE@LN	proc	far
		cmp	word ptr __IORESULT_1, 0
		jne	L1
		mov	bx, sp
		les	di, ss:4[bx]
		push	es
		push	di
		push	es
		push	di
		push	es
		push	di
		mov	al, 13
		push	ax
		call	___WRITECHAR
		mov	al, 10
		push	ax
		call	___WRITECHAR
		call	__FLUSHBUFFERIFTTY
L1:
		ret
__WRITE@LN	endp

SYSTEM_TEXT	ends
		end
