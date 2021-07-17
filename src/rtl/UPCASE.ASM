		assume	cs: SYSTEM_TEXT
SYSTEM_TEXT	segment	byte public 'CODE'
		public	_UPCASE
_UPCASE		proc	far
		mov	bx, sp
		mov	al, ss: 4[bx]
		cmp	al, 'a'
		jb	L1
		cmp	al, 'z'
		ja	L1
		sub	al, 'a' - 'A'
L1:
		ret	2
_UPCASE		endp

SYSTEM_TEXT	ends

		end
