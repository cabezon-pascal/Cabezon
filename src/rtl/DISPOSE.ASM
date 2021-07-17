;	module	dispose.asm	91/01/06]
;
;
INVALID_POINTER_OPERATION	=	204

_DATA		segment word public 'DATA'
		extrn	heap_head: word
		extrn	__ioresult_1: word
_DATA		ends

dgroup		group	_DATA

SYSTEM_TEXT	segment byte public 'CODE'
		assume	cs: SYSTEM_TEXT, ds: dgroup

		public	__dispose
__dispose	proc	far
		push	bp
		mov	bp, sp
;
		mov	ax, 10[bp]		; segment of ptr
		mov	bx, heap_head
L10:
		or	bx, bx
		jz	dispose_error
		mov	es, bx
		cmp	bx, ax
		jz	L30
		mov	bx, es:[2]
		jmp	L10
L30:
		mov	bx, 8[bp]		; offset of ptr
		xor	si, si
L40:
		mov	di, es:[si]
		or	di, di
		jz	L50
		cmp	bx, di
		jbe	L50
		mov	si, di
		jmp	L40
L50:
		mov	es:[si], bx
		mov	es:[bx], di
		mov	cx, 6[bp]		; size
		add	cx, 0003h
		and	cx, not 0003h		; ４単位に切上げ
		mov	es:[bx+2], cx
		or	si, si
		jz	L70
		mov	ax, es:[si+2]
		add	ax, si
		cmp	ax, bx
		jnz	L60
;
;		前のブロックと連続している
;
		add	es:[si+2], cx
		mov	es:[si], di
		mov	bx, si
		jmp	L70
L60:
		jnb	dispose_error
L70:
		or	di, di
		jz	exit_dispose
		mov	ax, es:[bx+2]
		add	ax, bx
		cmp	ax, di
		jnz	L80
		mov	ax, es:[di+2]
		add	es:[bx+2], ax
		mov	ax, es:[di]
		mov	es:[bx], ax
		jmp	exit_dispose
L80:
		jb	exit_dispose
dispose_error:
		mov	__ioresult_1, INVALID_POINTER_OPERATION
exit_dispose:
		mov	sp, bp
		pop	bp
		ret	6
__dispose	endp

SYSTEM_TEXT	ends
;
		end
