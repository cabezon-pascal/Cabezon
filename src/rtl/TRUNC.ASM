;	module	trunc.asm	90/08/12
;
;	runtime routine for Cabezon compiler 
;
;	Copyright (c) 1990 H.Tokumaru
;
;
dgroup		group	_DATA
		assume	cs: SYSTEM_TEXT, ds: dgroup

_DATA		segment	word public	'data'
flagForTruncate	dw	0fffh
_DATA		ends

SYSTEM_TEXT	segment	byte public	'code'
		public	_TRUNC
_TRUNC		proc	far
		push	bp
		mov	bp, sp
		sub	sp, 4
		fld	qword ptr [bp][6]
		fstcw	-4[bp]
		fldcw	flagForTruncate
		fistp	word ptr -2[bp]
		fldcw	-4[bp]
		mov	ax, -2[bp]
		mov	sp, bp
		pop	bp
		ret	8
_TRUNC		endp
SYSTEM_TEXT	ends

		end
