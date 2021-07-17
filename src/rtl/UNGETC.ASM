		include	deffcb_a.asm
		assume	cs: SYSTEM_TEXT

SYSTEM_TEXT	segment	byte public 'CODE'

;procedure 	_ungetc(var f : FCB; ch : char);
;begin
		public	__UNGETC
__UNGETC	proc	near
		mov	si, sp
;    with f do begin
		les	di, ss: 4[si]
;	rest := rest + 1;
		inc	es:[di].rest
;	cptr := cptr - 1;
		mov	bx, es:[di].cptr
		dec	bx
		mov	es:[di].cptr, bx
;	ioBuffer[cptr] := ch;
		mov	al, ss:2[si]
		mov	es:[di+bx].ioBuffer, al
;    end
;end;
		ret	6
__UNGETC	endp

SYSTEM_TEXT	ends

		end
