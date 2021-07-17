_DATA		segment	word public 'DATA'
		extrn	__IORESULT_1: word
_DATA		ends
dgroup		group	_DATA
		extrn	__WRITEREAL: far
		assume	cs: SYSTEM_TEXT, ds: dgroup

SYSTEM_TEXT	segment	byte public 'CODE'
		public	__WRITE@REAL
__WRITE@REAL	proc	far
		push	bp
		mov	bp, sp
		push	20[bp]		; file ptr
		push	18[bp]
		push	16[bp]		; real value
		push	14[bp]
		push	12[bp]
		push	10[bp]
		push	 8[bp]		; w1
		push	 6[bp]		; w2
		call	__WRITEREAL
		pop	bp
		ret	12		; file ptr ÇÕÇêÇèÇêÇµÇ»Ç¢
__WRITE@REAL	endp

SYSTEM_TEXT	ends

		end
