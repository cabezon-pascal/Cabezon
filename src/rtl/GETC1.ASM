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

;function _getc1(var f : FCB) : char;
;label 99;
;begin
		public	__GETC1
__GETC1		proc	near
		mov	si, sp
;    with f do begin
		les	di, ss:2[si]
;	if rest = 0 then begin
		cmp	es:[di].rest, 0
		jne	_76
;	    _getData(f);
		push	es
		push	di
		call	__GETDATA
;	    if rest = 0 then begin
		les	di, ss:2[si]
		cmp	es:[di].rest, 0
		jne	_78
;		_ioresult_1 := INPUT_PAST_END;
;		goto 99
		mov	__IORESULT_1, INPUT_PAST_END
		stc
		jmp	_75
;	    end
;	end;
_78:
_76:
;	_getc1 := ioBuffer[cptr];
		mov	bx, es:[di].cptr
		mov	al, es:[di+bx].ioBuffer		; al –ß‚è’l
		inc	bx
;	cptr := cptr + 1;
		mov	es:[di].cptr, bx
;	rest := rest - 1
;    end;
		dec	es:[di].rest
; 99:
_75:
;end;
		ret	4
__GETC1		endp

SYSTEM_TEXT	ends

		end
