;	function log10(a : real) : real;
;
	assume	cs: SYSTEM_TEXT

SYSTEM_TEXT	segment	byte public 'CODE'
	public	_LOG10
_LOG10	proc	far
	push	bp
	mov	bp, sp
	fldlg2				; fld  log10(2)
	fld	qword ptr [bp][6]	; fld  x
	fyl2x				; log2(x)
	pop	bp
	ret	8
_LOG10	endp

SYSTEM_TEXT	ends

	end
