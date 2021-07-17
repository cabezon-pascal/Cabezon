;	module	c.asm	90/08/12
;
;	startup module for Cabezon compiler 
;
;	Copyright (c) 1990, 91 H.Tokumaru
;
;
dgroup		group	_DATA, _BSS
;
		extrn	@: far, __zzflush: far, __aainit: far
;
SYSTEM_TEXT	segment byte public 'CODE'
		assume	cs: SYSTEM_TEXT
		public	_@start, _halt
_@start:
		mov	ax, dgroup
		mov	ds, ax
;
		assume	ds: dgroup
;
		mov	pspSave, es
		mov	ax, seg @
		mov	startSegment, ax
;
		mov	bx, sp
		add	bx, 0Fh			; ラウンドアップ用
		mov	cl, 4
		shr	bx, cl
		add	bx, _STACK
		mov	cx, es
		sub	bx, cx			; bx + ss - es;
		mov	ah, 4ah			; メモリブロックの変更
		int	21h
;
		call	__aainit
		call	@
		xor	ax, ax
		push	ax
		jmp	short	halt_0
;
_HALT		label	far
		pop	bx		; リターンアドレスを捨てて、
		pop	bx		; 引数がpushされた状態にする
halt_0:
		call	__zzflush
		pop	ax
		mov	ah, 4ch
		int	21h
SYSTEM_TEXT	ends

_DATA		segment word public 'DATA'
_DATA		ends

_BSS		segment word public 'DATA'
		public	startSegment, pspSave
startSegment	dw	1 dup (?)
pspSave		dw	1 dup (?)
_BSS		ends
;
_STACK		segment	word stack 'STACK'
		dw	2000H dup (?)
_STACK		ends

		end	_@start
