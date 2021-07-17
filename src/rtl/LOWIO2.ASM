		include	deffcb_a.asm
dgroup		group	_DATA, _BSS
		assume	cs: SYSTEM_TEXT, ds: dgroup

_DATA		segment	word public 'DATA'
		extrn	__IORESULT_1: word
_DATA		ends
_BSS		segment	word public 'DATA'
_BSS		ends

		extrn	__FLUSHBUFFER: FAR

SYSTEM_TEXT	segment	byte public 'CODE'

;	procedure modeError(mode : integer);
		public	__MODEERROR
__MODEERROR	proc	near
		mov	bx, sp
		mov	ax, ss:2[bx]
		cmp	ax, fileClosed
		jne	L10
		mov	ax, FILE_NOT_OPEN
		jmp	short L40
L10:
		cmp	ax, fileOpenedForRead
		jne	L20
		mov	ax, FILE_NOT_OPEN_FOR_OUTPUT
		jmp	short L40
L20:
		cmp	ax, fileOpenedForWrite
		jne	L30
		mov	ax, FILE_NOT_OPEN_FOR_INPUT
		jmp	short L40
L30:
		mov	ax, FILE_NOT_ASSIGNED
L40:
		mov	__IORESULT_1, ax
		ret	2
__MODEERROR	endp

;procedure _close(var f : FCB);
;begin
		public	__CLOSE
__CLOSE		proc	far
		push	bp
		mov	bp, sp
;    with f do begin
		les	di, 6[bp]
;	if mode = fileOpenedForWrite then
		cmp	es:[di].mode, fileOpenedForWrite
		jne	L200
;	    _flushBuffer(f);
		push	es
		push	di
		call	far ptr __FLUSHBUFFER
L200:
;	case mode of
;	  fileOpenedForRead,
;	  fileOpenedForWrite,
;	  fileOpenedForReadWrite: begin
_67:
;		dummy := _bdosCall_1($3E00, handle, dummy, dumChar);
		les	di, 6[bp]
		mov	ax, es:[di].mode
		cmp	ax, fileOpenedForRead
		je	L210
		cmp	ax, fileOpenedForWrite
		je	L210
		cmp	ax, fileOpenedForReadWrite
		jne	L230
L210:
		mov	ax, 3e00h
		mov	bx, es:[di].handle
		int	21h
		jnc	L220
		mov	__ioresult_1, ax
L220:
;		mode := fileclosed
;	     end
		mov	es: [di].mode, fileClosed
L230:
;	end { case }
;    end { with }
;end; { _close }
		pop	bp
		ret	4
__CLOSE	endp

SYSTEM_TEXT	ends

		end
