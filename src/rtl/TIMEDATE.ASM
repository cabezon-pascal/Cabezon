;unit dos;				; by maquiwo

SYSTEM_TEXT	segment	byte public 'CODE'
SYSTEM_TEXT	ends

_DATA	segment	word public 'DATA'
_DATA	ends

DGROUP	group	_DATA, _BSS
	assume	cs: SYSTEM_TEXT, ds: DGROUP
;
;  procedure getdate(var year, mon, day, dayofweek: integer);
;
SYSTEM_TEXT	segment	byte public 'CODE'
	public	_GETDATE
_GETDATE	proc	far
	push	bp
	mov	bp, sp
; get date
	mov	ah, 2Ah		; DOS function 2Ah
	int	21h		; (get date)

; year
	les	di, dword ptr [bp+18]
	mov	word ptr es:[di], cx
; mon
	xor	bh, bh
	mov	bl, dh
	les	di, dword ptr [bp+14]
	mov	word ptr es:[di], bx
; day
	xor	dh, dh
	les	di, dword ptr [bp+10]
	mov	word ptr es:[di], dx
; day of week
	xor	ah, ah
	les	di, dword ptr [bp+6]
	mov	word ptr es:[di], ax
	mov	sp, bp
	pop	bp
	ret	16
_GETDATE	endp

;
;procedure gettime(var hour, min, sec: integer);
;
	public	_GETTIME
_GETTIME	proc	far
	push	bp
	mov	bp, sp
; get time
	mov	ah, 2Ch		; DOS function 2Ch
	int	21h		; (get time)
; hour
	mov	bl, ch
	xor	bh, bh
	les	di, dword ptr [bp+18]
	mov	word ptr es:[di], bx
; min
	xor	ch, ch
	les	di, dword ptr [bp+14]
	mov	word ptr es:[di], cx
; sec
	mov	bl, dh
	xor	bh, bh
	les	di, dword ptr [bp+10]
	mov	word ptr es:[di], bx
; sec100
	mov	bl, dl
	les	di, dword ptr [bp+6]
	mov	word ptr es:[di], bx
	mov	sp, bp
	pop	bp
	ret	12
_GETTIME	endp

SYSTEM_TEXT	ends

_BSS	segment	word public 'DATA'
_BSS	ends

	end
