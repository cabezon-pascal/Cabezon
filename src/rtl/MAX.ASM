SYSTEM_TEXT	segment	byte public 'CODE'
SYSTEM_TEXT	ends

	assume	cs: SYSTEM_TEXT

SYSTEM_TEXT	segment	byte public 'CODE'
	public	_MAX
_MAX	proc	far
	mov	bx, sp
	mov	ax, word ptr ss:6[bx]
	mov	bx, word ptr ss:4[bx]
	cmp	ax, bx
	jge	L10
	mov	ax, bx
L10:
	ret	4
_MAX	endp

SYSTEM_TEXT	ends

	end
