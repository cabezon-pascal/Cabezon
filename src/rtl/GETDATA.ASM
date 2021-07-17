		include	deffcb_a.asm
dgroup		group	_DATA, _BSS
		assume	cs: SYSTEM_TEXT, ds: dgroup

_DATA		segment	word public 'DATA'
		extrn	__IORESULT_1: word
_DATA		ends
_BSS		segment	word public 'DATA'
_BSS		ends

		extrn	__MODEERROR: near

SYSTEM_TEXT	segment	byte public 'CODE'

;procedure _getData(var f : FCB);
;label 99;
;var
;    nRead : integer;
;begin
		public	__GETDATA
__GETDATA	proc	far
		push	bp
		mov	bp, sp
;    with f do begin
;	if mode <> fileOpenedForRead then begin
		les	di, 6[bp]
		mov	ax, es:[di].mode	; ax ‚ÍŒã‚Å‚àŽg‚¤
		cmp	ax, fileOpenedForRead
		je	_73
;	    modeError(mode);
;	    goto 99
		push	ax
		call	__MODEERROR
		jmp	_72
;	end;
_73:
;	nRead := _bdosCall_1($3F00, handle, bufsize, ioBuffer[1]);
		push	ds
		mov	ax, 3F00H
		mov	bx, es:[di].handle
		mov	cx, es:[di].bufsize
		lea	dx, es:[di].ioBuffer
		push	es
		pop	ds
		assume	ds: nothing
		int	21h
		pop	ds
		assume	ds: dgroup
		jnc	L320
		mov	__ioresult_1, ax
L320:
;	rest := nRead;
		mov	es:[di].rest, ax
;	cptr := 0
;    end;
		mov	es:[di].cptr, 0
;  99:
_72:
;end; { _getData }
		pop	bp
		ret	4
__GETDATA	endp

SYSTEM_TEXT	ends

		end
