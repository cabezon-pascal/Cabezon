_DATA		segment	word public 'DATA'
		extrn	__IORESULT_1: word
_DATA		ends

dgroup		group	_DATA

		extrn	___WRITECHAR: near

SYSTEM_TEXT	segment	byte public 'CODE'
		assume	cs: SYSTEM_TEXT, ds: dgroup

;procedure _putNChar(var f : FCB; c : char; n : integer);
;var
;    i : integer;
;begin
		public	__PUTNCHAR
__PUTNCHAR	proc	far
		push	bp
		mov	bp, sp
;    for i := 1 to n do
		mov	cx, 6[bp]
		or	cx, cx
		jle	exit_loop
Loop1:
;	__writeChar(f, c)
		push	cx
		push	12[bp]
		push	10[bp]
		push	8[bp]
		call	___WRITECHAR
		pop	cx
		loop	Loop1
exit_loop:
		pop	bp
		ret	8
__PUTNCHAR	endp

;
;procedure _putSpace(var f : FCB; n : integer);
;begin
		public	__PUTSPACE
__PUTSPACE	proc	far
		push	bp
		mov	bp, sp
;    _putNChar(f, ' ', n)
;end;
		push	10[bp]
		push	8[bp]
		mov	al, ' '
		push	ax
		push	6[bp]
		call	far ptr __PUTNCHAR
		pop	bp
		ret	6
__PUTSPACE	endp

SYSTEM_TEXT	ends

		end
