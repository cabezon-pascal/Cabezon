		include	deffcb_a.asm
dgroup		group	_DATA, _BSS
		assume	cs: SYSTEM_TEXT, ds: dgroup

_DATA		segment	word public 'DATA'
		extrn	__IORESULT_1: word
_DATA		ends
_BSS		segment	word public 'DATA'
_BSS		ends

SYSTEM_TEXT	segment	byte public 'CODE'
		public	_ASSIGN
_ASSIGN		proc	far

;procedure assign(var f : FCB; var fileName : fnameType);
;begin
		push	bp
		mov	bp, sp
;    with f do begin
		les	di, 10[bp]
;	mode  := fileClosed;
;	bufsize := textBufferSize;
;	fname := fileName;
		mov	es: [di].mode, fileClosed
		mov	es:[di].bufsize, textBufferSize
		push	ds
		assume	ds: nothing
		lea	di, es:[di].fname
		lds	si, 6[bp]
		cld
		lodsw
		stosw
		mov	cx, ax
		rep movsb
		pop	ds
		assume	ds: dgroup
;	fname[fileName.length + 1] := chr(0)	(* ターミネータ *)
;    end
		les	di, 6[bp]
		mov	bx, es:[di]
		inc	bx
		les	di, 10[bp]
		mov	byte ptr es:[di+bx+1].fname, 0
;end; { assign }
		pop	bp
		ret	8
_ASSIGN	endp

SYSTEM_TEXT	ends

		end
