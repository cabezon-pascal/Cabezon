SYSTEM_TEXT	segment	byte public 'CODE'
SYSTEM_TEXT	ends

_DATA	segment	word public 'DATA'
_DATA	ends

DGROUP	group	_DATA, _BSS
	assume	cs: SYSTEM_TEXT, ds: DGROUP
;type
;    stringMax = string[255];
;
;function cpos(ch : char; var line : stringMax) : integer;
;
;implementation
;var
;    c : char;
_BSS	segment	word public 'DATA'
_C	db	1 dup (?)
;	s : stringMax;
_S	db	257 dup (?)
;
;function cpos(ch : char; var line : stringMax) : integer;
;begin
_BSS	ends

SYSTEM_TEXT	segment	byte public 'CODE'
		public	_CPOS
_CPOS	proc	far
		mov		bx, sp
		push	ds
		lds		si, ss:[bx+4]
		lodsw
		mov		cx, ax
		jcxz	not_exist
		push	ds
		pop		es
		mov		di, si
		mov		al, ss:[bx+8]
		repnz scasb
		je		exist
not_exist:
		xor		ax, ax
		jmp		short exit
exist:
		mov		ax, di
		sub		ax, si
exit:
		pop		ds
		ret	6
_CPOS	endp

;
;end.
SYSTEM_TEXT	ends

	extrn	__STRING@COPY1: far
	end
