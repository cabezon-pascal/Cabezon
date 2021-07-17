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
;
;procedure _flushBufferIfTty(var f : FCB);
;begin
		public	__FLUSHBUFFERIFTTY
__FLUSHBUFFERIFTTY	proc	far
		mov	bx, sp
;    if f.istty then
		les	di, ss:4[bx]
		mov	al, es: [di].isatty
		or	al, al
		je	exit_flushBufferIfTty
;	_flushBuffer(f)
;end; { _flushBufferIfTty }
		push	es
		push	di
		call	far ptr __FLUSHBUFFER
exit_flushBufferIfTty:
		ret	4
__FLUSHBUFFERIFTTY	endp

SYSTEM_TEXT	ends

		end
