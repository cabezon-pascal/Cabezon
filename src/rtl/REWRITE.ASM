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
		public	_rewrite
_rewrite	proc	far
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
;	    handle := standardOutput
		les	di, 6[bp]
		cmp	es:[di].fname, 0
		jne	_70
		mov	es: [di].handle, standardOutput
		jmp	_71
;	else
;	    handle := _bdosCall_1($3C00, dummy, dummy, fname[1]);
_70:
		push	ds
		mov	ax, 3C00H
		lea	dx, es:[di+2].fname
		push	es
		pop	ds
		assume	ds: nothing
		int	21h
		pop	ds
		assume	ds: dgroup
		jnc	L300
		mov	__ioresult_1, ax
L300:
		les	di, 6[bp]
		mov	es: [di].handle, ax
_71:
;	istty := isatty(handle);
		mov	bx, es:[di].handle
		mov	ax, 4400h
		int	21h
		mov	ax, dx
		and	ax, 0080h
		shl	ax, 1
		mov	es:[di].isatty, ah
;	rest := bufsize;
		mov	ax, es: [di].bufsize
		mov	es: [di].rest, ax
;	cptr := 0;
		mov	es: [di].cptr, 0
;	mode := fileOpenedForWrite
		mov	es: [di].mode, fileOpenedForWrite
;    end
;end; { _reset }
		pop	bp
L1:
		ret
_rewrite		endp
SYSTEM_TEXT	ends

		end
