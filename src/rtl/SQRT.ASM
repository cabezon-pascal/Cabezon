;	function sqrt(a : real) : real;
;
	assume	cs: SYSTEM_TEXT

SYSTEM_TEXT	segment	byte public 'CODE'
	public	_SQRT
_SQRT	proc	far
	push	bp
	mov	bp, sp
	fld	qword ptr [bp][6]	; fld  x
	fsqrt
	pop	bp
	ret	8
_SQRT	endp

SYSTEM_TEXT	ends

	end
