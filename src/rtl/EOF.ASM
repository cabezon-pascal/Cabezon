		include	deffcb_a.asm
dgroup		group	_DATA, _BSS
		assume	cs: SYSTEM_TEXT, ds: dgroup

_DATA		segment	word public 'DATA'
		extrn	__IORESULT_1: word
_DATA		ends
_BSS		segment	word public 'DATA'
_BSS		ends

		extrn	__GETDATA: far

SYSTEM_TEXT	segment	byte public 'CODE'

;function eof(var f : FCB) : boolean;
;begin
		public	_EOF
_EOF		proc	far
		push	bp
		mov	bp, sp
;    with f do begin
		les	di, 6[bp]
;	if rest <= 0 then
		cmp	es:[di].rest, 0
		jg	_80
;	    _getData(f);
		push	es
		push	di
		call	far ptr __GETDATA
_80:
;	if rest > 0 then
		les	di, 6[bp]
		cmp	es:[di].rest, 0
		jle	_82
;	    eof := ioBuffer[cptr] = chr($1a)
;	else
		mov	bx, es:[di].cptr
		cmp	byte ptr es:[di+bx].ioBuffer, 1AH
		jne	_84
		mov	al, 1
		jmp     short _85
_84:
		mov	al, 0
_85:
;	    eof := true
		jmp	short _83
_82:
;    end
		mov	al, 1
_83:
;end;
		pop	bp
		ret	4
_EOF		endp

SYSTEM_TEXT	ends

		end
