dgroup	group	_DATA
		assume	cs: SYSTEM_TEXT, ds: dgroup

_DATA		segment	word public 'DATA'
		extrn	__IORESULT_1: word
_DATA		ends

		extrn	__FLUSHBUFFERIFTTY: far

SYSTEM_TEXT	segment	byte public 'CODE'
		public	__WRITE@FLUSHOUT
__WRITE@FLUSHOUT proc	far
		cmp	word ptr __IORESULT_1, 0
		jne	L1
		mov	bx, sp
		push	ss: 6[bx]		; FCB
		push	ss: 4[bx]
		call	__FLUSHBUFFERIFTTY
L1:
		ret
__WRITE@FLUSHOUT endp

SYSTEM_TEXT	ends
		end
