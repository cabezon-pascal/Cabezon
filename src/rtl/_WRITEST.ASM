;procedure __write@string(var f : FCB; var s : alpha; w : integer);
;
_DATA		segment	word public 'DATA'
		extrn	__IORESULT_1: word
_DATA		ends
dgroup		group	_DATA

		extrn	__PUTSPACE: far, ___WRITECHAR: near

SYSTEM_TEXT	segment	byte public 'CODE'
		assume	cs: SYSTEM_TEXT, ds: dgroup
		public	__WRITE@STRING
__WRITE@STRING	proc	far
		cmp	__IORESULT_1, 0
		jne	Lexit
		push	bp
		mov	bp, sp
;
;	_putSpace(f, w - s.length);
;
		push	14[bp]
		push	12[bp]
		les	di, 8[bp]
		mov	ax, 6[bp]
		sub	ax, es:[di]
		push	ax
		call	__PUTSPACE
;
;	for i := 1 to s.length do
;
		les	di, 8[bp]
		mov	cx, es:[di]
		jcxz	L10
;
;	__writeChar(f, s[i]);
;
		inc	di
Loop_1:
		inc	di
		mov	es, 10[bp]
		mov	al, es:[di]
		push	di
		push	cx
;
		push	14[bp]
		push	12[bp]
		push	ax
		call	___WRITECHAR
;
		pop	cx
		pop	di
		loop	loop_1
;
L10:
		pop	bp
Lexit:
		ret	6
__WRITE@STRING	endp

SYSTEM_TEXT	ends


		end
