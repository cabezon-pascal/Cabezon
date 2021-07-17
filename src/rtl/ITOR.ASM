dgroup		group	_DATA, _BSS
_DATA		segment	word public 'DATA'
_DATA		ends

_BSS		segment	word public 'DATA'
intData		dw	1 dup (?)
_BSS		ends

SYSTEM_TEXT	segment	byte public 'CODE'
		assume	cs: SYSTEM_TEXT, ds: dgroup
		public	_@inttoreal
_@inttoreal	proc	far
		mov	intData, ax
		fild	intData
		ret
_@inttoreal	endp

SYSTEM_TEXT	ends

		end
