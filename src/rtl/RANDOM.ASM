;	file = random.asm
;
;
;unsigned long next = 6789 * 65536 + 12345;
;
;int random(int n)
;{
;    next = next * 69069;	/* 69069ÇÃç™ãíÅÅÇjÇéÇïÇîÇàèÄêîíléZñ@p105 */
;    return (next >> 16) % n;
;}
;
dgroup		group	_DATA, _BSS
		assume	cs: SYSTEM_TEXT, ds: dgroup
_DATA		segment	word public 'DATA'
next		dw	12345, 6789
_DATA		ends

_BSS		segment	word public 'DATA'
_BSS		ends

SYSTEM_TEXT	segment	byte public 'CODE'
		public	_RANDOMIZE
_RANDOMIZE	proc	far
		mov	ah, 2ch			; éûçèÇÃì«Ç›ÇæÇµ
		int	21h
		inc	dx			; ÇOÇ…Ç»ÇÁÇ»Ç¢ÇÊÇ§Ç…
		mov	next, cx
		mov	next[2], dx
		ret
_RANDOMIZE	endp

		public	_RANDOM
_RANDOM		proc	far
		mov	si, next
		mov	ax, next[2]
		mov	cx, 3533		; 69069 = 65536 + 3533
		mul	cx			; ax <= A * D
		add	ax, si			; ax <= A * D + B * C
		mov	di, ax			; di <= A * D + B * C
		mov	ax, cx			; 69069 = 65536 + 3533
		mul	si			; dx-ax <= B * D
		mov	next, ax
		add	dx, di
		mov	next[2], dx
;
		mov	bx, sp
		mov	ax, dx
		xor	dx, dx
		div	word ptr ss:4[bx]
		mov	ax, dx
		ret	2
_RANDOM		endp

SYSTEM_TEXT	ends
		end
