dgroup		group	_DATA
		assume	cs: SYSTEM_TEXT, ds: dgroup

_DATA		segment	word public 'DATA'
		extrn	__IORESULT_1: word
_DATA		ends

SYSTEM_TEXT	segment	byte public 'CODE'
		extrn	__UNGETC: near, __GETC1: near

		public	__READ@STRING
__READ@STRING	proc	far
		cmp	__IORESULT_1, 0
		jne	exit_read_string
		push	bp
		mov	bp, sp
		sub	sp, 2
		mov	word ptr [bp-2], 0
getst_loop:
		push	word ptr [bp+12]
		push	word ptr [bp+10]
		call	__GETC1
		jc	readstring_tail
		cmp	al, 13
		je	exit_readst_loop
		inc	word ptr [bp-2]

		mov	bx, word ptr [bp-2]
		les	di, dword ptr [bp+6]
		mov	byte ptr es:[di+bx+1], al
		jmp	getst_loop
exit_readst_loop:
		mov	ax, word ptr [bp-2]
		les	di, dword ptr [bp+6]
		mov	word ptr es:[di], ax

		push	word ptr [bp+12]
		push	word ptr [bp+10]
		mov	al, 13
		push	ax
		call	__UNGETC
readstring_tail:
		mov	sp, bp
		pop	bp
exit_read_string:
		ret	4		; don't pop file ptr
__READ@STRING	endp

;
;procedure _skipnl(var f : FCB);
;var
;    c : char;
;begin
		public	__READ@SKIPNL
__READ@SKIPNL	proc	far
		cmp	__IORESULT_1, 0
		jne	exit_skip_nl
		push	bp
		mov	bp, sp
loop_skipnl:
		push	word ptr [bp+8]
		push	word ptr [bp+6]
		call	__GETC1
		jc	normal_exit_skipnl
		cmp	al, 13
		jne	loop_skipnl

		push	word ptr [bp+8]
		push	word ptr [bp+6]
		call	__GETC1
		cmp	al, 10
		je	normal_exit_skipnl
		push	word ptr [bp+8]
		push	word ptr [bp+6]
		push	ax
		call	__UNGETC
normal_exit_skipnl:
		pop	bp
exit_skip_nl:
		ret			; don't pop file ptr
__READ@SKIPNL	endp

;
;end.
SYSTEM_TEXT	ends

		end
