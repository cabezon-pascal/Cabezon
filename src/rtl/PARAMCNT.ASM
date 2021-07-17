dgroup		group	_DATA, _BSS
SYSTEM_TEXT	segment	byte public 'CODE'
SYSTEM_TEXT	ends

_DATA		segment	byte public 'DATA'
zero		db	0
_DATA		ends

_BSS		segment	word public 'DATA'
			extrn	pspSave: word
_BSS		ends


SYSTEM_TEXT	segment	byte public 'CODE'
		assume	cs: SYSTEM_TEXT, ds: dgroup
param_count	proc	near
		cld
		xor	cx, cx
		mov	dx, cx		; dx : in word
		mov	bx, cx		; bx : param count
		mov	ds, pspSave
		assume	ds: nothing
		mov	si, 80h
		lodsb
		mov	cl, al
		jcxz	L4
loop_10:
		lodsb
		cmp	al, ' '
		ja	L2
;
;		ch <= ' ' �̏ꍇ
;
		xor	dx, dx		; reset in word flag
		jmp	short	L3
L2:
;
;		ch > ' ' �̏ꍇ
;
		or	dx, dx
		jnz	L3
		inc	dx
		inc	bx
		cmp	bx, di
		je	L4
L3:
		loop	loop_10
L4:
		ret
param_count	endp

		public	_PARAMCOUNT
		assume	cs: SYSTEM_TEXT, ds: dgroup
_PARAMCOUNT	proc	far
		push	ds
		mov	di, 0ffffh
		call	param_count
		pop	ds
		mov	ax, bx		; return paramCount
		ret
_PARAMCOUNT	endp

		public	_PARAMSTR
_PARAMSTR	proc	far
		push	bp
		mov	bp, sp
		push	ds
		mov	di, 6[bp]
		or	di, di
		jnz		L10
		mov	ah, 30h
		int	21h				; get dos version
		lea	si, zero
		cmp	al, 3
		jc	L15				; 
		mov	ds, pspSave
		mov	ds, ds:[2ch]
		xor	si, si
Loop_15:
		mov	ax, ds:[si]
		inc	si
		or	ax, ax
		jnz	Loop_15
		add	si, 3
		lodsb
		jmp	short L15
L10:
		call	param_count
		assume	ds: nothing
		jcxz	L20
L15:
		xor	cx, cx
		les	bx, 8[bp]
		mov	di, bx
		add	di, 2
Loop_20:
		stosb
		inc	cx
		lodsb
		cmp	al, ' '
		jg	Loop_20
;
		mov	es:[bx], cx
L20:
		pop	ds
		pop	bp
		ret	2
_PARAMSTR	endp

SYSTEM_TEXT	ends

		end
