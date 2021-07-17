_DATA		segment	word public 'DATA'
_DATA		ends
_BSS		segment	word public 'DATA'
		extrn	__IORESULT_1: word
_BSS		ends
dgroup		group	_DATA, _BSS
		assume	cs: SYSTEM_TEXT, ds: dgroup


		extrn	__WRITEINT: far

SYSTEM_TEXT	segment	byte public 'CODE'
		public	__WRITE@INT
__WRITE@INT	proc	far
		cmp	__IORESULT_1, 0
		jne	L1
		push	bp
		mov	bp, sp
		push	12[bp]		; file ptr
		push	10[bp]
		push	 8[bp]		; n
		push	 6[bp]		; w
		call	__WRITEINT
		pop	bp
L1:
		ret	4		; file ptr ÇÕÇêÇèÇêÇµÇ»Ç¢
__WRITE@INT	endp
SYSTEM_TEXT	ends

		end
