		assume	cs: SYSTEM_TEXT

SYSTEM_TEXT	segment	byte public 'CODE'
		public	_@STRCAT
_@STRCAT	proc	far
		push	bp
		mov	bp, sp
		push	ds

		lds	si, 10[bp]
		les	di, 14[bp]
		mov	dx, di			; di‚ð•Û‘¶
		add	di, 2
		cld
		lodsw
		mov	cx, ax
		mov	bx, ax
		rep movsb
		lds	si, 6[bp]
		lodsw
		mov	cx, ax
		add	bx, ax			; •¶Žš—ñ’·‚ÌŒvŽZ
		rep movsb
		mov	di, dx
		mov	es:[di], bx		; •¶Žš—ñ’·‚ÌŠi”[
		pop	ds
		pop	bp
		ret	8
_@STRCAT	endp
SYSTEM_TEXT	ends

		end
