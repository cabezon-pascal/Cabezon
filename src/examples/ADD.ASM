_DATA		segment	word public 'DATA'
_DATA		ends

_BSS		segment	word public 'DATA'
_BSS		ends

DGROUP		group	_DATA, _BSS

EXTERNAL_TEXT	segment	byte public 'CODE'
		assume	cs: EXTERNAL_TEXT, ds: DGROUP
		public	_ADD
_ADD		proc	near
		push	bp
		mov	bp, sp
		mov	ax, 6[bp]
		add	ax, 4[bp]
		pop	bp
		ret	4
_ADD		endp

EXTERNAL_TEXT	ends

		end
