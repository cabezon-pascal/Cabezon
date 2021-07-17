		include	deffcb_a.asm
dgroup		group	_DATA, _BSS
		assume	cs: SYSTEM_TEXT, ds: dgroup

_DATA		segment	word public 'DATA'
		extrn	__IORESULT_1: word
_DATA		ends
_BSS		segment	word public 'DATA'
_BSS		ends

		extrn	__CLOSE: far

SYSTEM_TEXT	segment	byte public 'CODE'
		public	_RESET
_RESET		proc	far
		cmp	word ptr __IORESULT_1, 0
		jne	L1
		push	bp
		mov	bp, sp
;    with f do begin
;	_close(f);
		push	8[bp]
		push	6[bp]
		call	__CLOSE
;	if fname.length = 0 then
;	    handle := standardInput
		les	di, 6[bp]
		cmp	es:[di].fname, 0
		jne	L250
		mov	es: [di].handle, standardInput
		jmp	L260
;	else
;	    handle := _bdosCall_1($3D00, dummy, dummy, fname[1]);
L250:
		push	ds
		mov	ax, 3D00H
		lea	dx, es: [di+2].fname
		push	es
		pop	ds
		assume	ds: nothing
		int	21h
		pop	ds
		assume	ds: dgroup
		jnc	L255
		mov	__ioresult_1, ax
L255:
		les	di, 6[bp]
		mov	es:[di].handle, ax
L260:
;	rest := 0;
		mov	es: [di].rest, 0
;	mode := fileOpenedForRead
		mov	es: [di].mode, fileOpenedForRead
;    end
;end; { _reset }
		pop	bp
L1:
		ret
_RESET		endp
SYSTEM_TEXT	ends

		end
