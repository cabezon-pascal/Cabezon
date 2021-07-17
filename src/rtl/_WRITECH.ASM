_DATA		segment	word public 'DATA'
		extrn	__IORESULT_1: word
_DATA		ends

dgroup		group	_DATA

		extrn	___WRITECHAR: near, __PUTSPACE: far

SYSTEM_TEXT	segment	byte public 'CODE'
		assume	cs: SYSTEM_TEXT, ds: dgroup
		public	__WRITE@CHAR
__WRITE@CHAR	proc	far
		cmp	__IORESULT_1, 0
		jne	L2
		push	bp
		mov	bp, sp
;    _putSpace(f, n - 1);
		mov	ax, 6[bp]
		dec	ax
		jle	L1
		push	12[bp]
		push	10[bp]
		push	ax
		call	__PUTSPACE
L1:
;    __writeChar(f, c)
;end;
		push	12[bp]
		push	10[bp]
		push	8[bp]
		call	___WRITECHAR
		pop	bp
L2:
		ret	4
__WRITE@CHAR	endp

SYSTEM_TEXT	ends

		end
