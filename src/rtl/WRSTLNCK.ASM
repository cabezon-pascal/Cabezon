;procedure __write@string(var f : FCB; var s : alpha);
;
_DATA		segment	word public 'DATA'
			extrn	__IORESULT_1: word
_DATA		ends
dgroup		group	_DATA

			extrn	___WRITECHAR: near
			extrn	error_print: near
			extrn	__FLUSHBUFFERIFTTY: far

SYSTEM_TEXT	segment	byte public 'CODE'

		assume	cs: SYSTEM_TEXT, ds: dgroup
		public	__WRITE@STRING@LNCK
__WRITE@STRING@LNCK		proc	far
		push	bp
		cmp	__IORESULT_1, 0
		jne	Lexit
		mov	bp, sp
;
;	for i := 1 to s.length do
;
		les		di, 6[bp]
		mov		cx, es:[di]
		jcxz	L10
;
;	__writeChar(f, s[i]);
;
		inc		di
Loop_1:
		inc		di
		mov		es, 8[bp]
		mov		al, es:[di]
		push	di
		push	cx
;
		push	12[bp]
		push	10[bp]
		push	ax
		call	___WRITECHAR
;
		pop	cx
		pop	di
		loop	loop_1
;
L10:
		les		di, 10[bp]
		push	es
		push	di
		push	es
		push	di
		push	es
		push	di
		mov		al, 13
		push	ax
		call	___WRITECHAR
		mov		al, 10
		push	ax
		call	___WRITECHAR
		call	__FLUSHBUFFERIFTTY
Lexit:
		pop		bp
		mov		ax, __ioresult_1
		or		ax, ax
		jz		no_error
		jmp		error_print
no_error:

		ret		8
__WRITE@STRING@LNCK	ENDP

SYSTEM_TEXT	ends
			end
