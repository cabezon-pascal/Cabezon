;	module	input.asm	91/01/20
;
;
_DATA		segment word public 'DATA'
_DATA		ends

_BSS		segment word public 'DATA'
		public	_input
_input		dw	590/2 dup (?)
_BSS		ends
dgroup		group	_DATA, _BSS
;
		end
