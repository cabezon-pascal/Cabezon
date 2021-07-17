		assume	cs: SYSTEM_TEXT
SYSTEM_TEXT	segment	byte public 'CODE'
		public	__STRING@COPY2
__STRING@COPY2	proc	far
		mov	si, sp
		mov	bx, ds
		lds	si, ss:[si+4]
		cld
		lodsw
		cmp	ax, cx
		jle	L1
		mov	ax, cx
L1:
		stosw
		mul	dx
		mov	cx, ax
		rep movsb
		mov	ds, bx
		ret
__STRING@COPY2	endp

SYSTEM_TEXT	ends

		end
