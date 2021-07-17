		assume	cs: SYSTEM_TEXT
SYSTEM_TEXT	segment	byte public 'CODE'
		public	__STRING@COPY1
__STRING@COPY1	proc	far
		mov	si, sp
		mov	bx, ds
		lds	si, ss:[si+4]
		cld
		lodsw
		cmp	ax, cx
		jle	L1
		mov	ax, cx
L1:
		mov	cx, ax
		stosw
		rep movsb
		mov	ds, bx
		ret
__STRING@COPY1	endp

SYSTEM_TEXT	ends

		end
