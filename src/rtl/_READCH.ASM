dgroup		group	_DATA
		assume	cs: SYSTEM_TEXT, ds: dgroup

_DATA		segment	word public 'DATA'
		extrn	__IORESULT_1: word
_DATA		ends

		extrn	__GETC1: near

SYSTEM_TEXT	segment	byte public 'CODE'
		public	__READ@CHAR
__READ@CHAR	proc	far
		cmp	__IORESULT_1, 0
		jne	L1
		mov	bx, sp
		push	word ptr ss:6[bx]
		push	word ptr ss:4[bx]
		call	__GETC1
L1:
		ret
__READ@CHAR	endp

SYSTEM_TEXT	ends


	end
