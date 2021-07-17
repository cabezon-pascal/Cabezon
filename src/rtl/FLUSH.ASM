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


;procedure _flushBuffer(var f : FCB);
;var
;    nData, nWrite : integer;
;begin
		public	__FLUSHBUFFER
__FLUSHBUFFER	proc	far
		push	bp
		mov	bp, sp
		sub	sp, 4
;    with f do begin
		les	di, 6[bp]
;	if mode <> fileOpenedForWrite then begin
		cmp	es:[di].mode, fileOpenedForWrite
		je	L100
;	    modeError(mode);
;	    goto 99
		push	es:[di].mode
		call	__MODEERROR
		jmp	exit_flushBuffer
;	end;
;	nData := bufsize - rest;
L100:
		mov	ax, es:[di].bufsize
		sub	ax, es:[di].rest
		mov	-2[bp], ax
;	if nData > 0 then begin
		or	ax, ax
		jle	L120
;	    nWrite := _bdosCall_1($4000, handle, nData, ioBuffer[1]);
		push	ds
		mov	ax, 04000H
		mov	bx, es: [di].handle
		mov	cx, -2[bp]			; nData
		lea	dx, es:[di].ioBuffer
		push	es
		pop	ds
		assume	ds: nothing
		int	21h
		pop	ds
		assume	ds: dgroup
		jnc	L105
		mov	__ioresult_1, ax
L105:
		mov	-4[bp], ax		; nWrite
;	    if nData <> nWrite then begin
		cmp	ax, -2[bp]		; nData
		je	L110
;		_ioresult_1 := DISK_FULL;
;		goto 99
		mov	__IORESULT_1, DISK_FULL
		jmp	exit_flushBuffer
;	    end
;	end;
L110:
L120:
;	rest := bufsize;
		les	di, 6[bp]
		mov	ax, es:[di].bufsize
		mov	es:[di].rest, ax
;	cptr := 0
;    end;
		mov	es: [di].cptr, 0
; 99:
;end; { _flushBuffer }
exit_flushBuffer:
		mov	sp, bp
		pop	bp
		ret	4
__FLUSHBUFFER	endp

SYSTEM_TEXT	ends

		end
