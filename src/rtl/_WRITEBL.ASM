;procedure _write@Bool(var f : text; b : boolean; w : integer);
;
;
		extrn	__WRITE@STRING: far

_DATA		segment	word public 'DATA'
		extrn	__IORESULT_1: word
_DATA		ends
dgroup		group	_DATA

SYSTEM_TEXT	segment	byte public 'CODE'
		assume	cs: SYSTEM_TEXT, ds: dgroup
		public	__WRITE@BOOL
__WRITE@BOOL	proc	far
;;;;;;;;;	cmp	__IORESULT_1, 0		; _write@string でやっている
;;;;;;;;;	jne	Lexit			; ので、ここでは省略
		push	bp
		mov	bp, sp
		mov	di, offset FALSE_STR
		cmp	byte ptr 8[bp], 0
		je	L1
		mov	di, offset TRUE_STR
L1:
		push	12[bp]
		push	10[bp]
		push	cs
		push	di
		push	6[bp]
		call	far ptr __WRITE@STRING
		mov	sp, bp
;
;	 spをいじってないので上記のmovは本来必要ないはずだが、
; 	__write@string が引数を完全にはがさないための処置
;
		pop	bp
Lexit:
		ret	4		; FCB を残して引数をはがす
__WRITE@BOOL	endp

FALSE_STR	dw	5
		db	'FALSE'
TRUE_STR	dw	4
		db	'TRUE'
;
;end.
SYSTEM_TEXT	ends

		end
;
;unit system;
;
;interface
;
;procedure _writeBool(var f : text; b : boolean; w : integer);
;
;implementation
;
;procedure _writeBool(var f : text; b : boolean; w : integer);
;begin
;    {$I-}
;    if b then
;	write(f, 'TRUE': w)
;    else
;	write(f, 'FALSE': w)
;end; { _writeBool }
;
;end.
