		include	deffcb_a.asm
dgroup		group	_DATA, _BSS
		assume	cs: SYSTEM_TEXT, ds: dgroup

_DATA		segment	word public 'DATA'
		extrn	__IORESULT_1: word
_DATA		ends
_BSS		segment	word public 'DATA'
_BSS		ends

		extrn	__FLUSHBUFFER: far

SYSTEM_TEXT	segment	byte public 'CODE'

;procedure __writechar(var f : FCB; ch : char);
;begin
		public	___WRITECHAR
___WRITECHAR	proc	near
		push	bp
		mov	bp, sp
;    with f do begin
		les	di, 6[bp]
;	if rest = 0 then
		cmp	es:[di].rest, 0
		jne	_86
;	    _flushBuffer(f);
		push	es
		push	di
		call	far ptr __FLUSHBUFFER
		les	di, 6[bp]		; es:di ‚ð–ß‚µ‚Ä‚¨‚­
_86:
;	ioBuffer[cptr] := ch;
		mov	al, 4[bp]
		mov	bx, es:[di].cptr
		mov	es:[di+bx].ioBuffer, al
;	cptr := cptr + 1
		inc	bx
		mov	es:[di].cptr, bx
;	rest := rest - 1;
		dec	es:[di].rest
;    end
;end; { __writechar }
		pop	bp
		ret	6
___WRITECHAR	endp

SYSTEM_TEXT	ends

		end
