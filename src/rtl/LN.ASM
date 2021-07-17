;	function ln(a : real) : real;
;
	assume	cs: SYSTEM_TEXT

SYSTEM_TEXT	segment	byte public 'CODE'
	public	_LN
_LN	proc	far
	push	bp
	mov	bp, sp
	fldln2				; fld  ln(2)
	fld	qword ptr [bp][6]	; fld  x
	fyl2x				; log2(x)
	pop	bp
	ret	8
_LN	endp

SYSTEM_TEXT	ends

	end
