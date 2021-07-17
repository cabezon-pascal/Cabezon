;	module	round.asm	90/08/12
;
;	runtime routine for Cabezon compiler 
;
;	Copyright (c) 1990 H.Tokumaru
;
;
		assume	cs: SYSTEM_TEXT

SYSTEM_TEXT	segment	byte public	'code'
		public	_ROUND
_ROUND		proc	far
		push	bp
		mov	bp, sp
		sub	sp, 2
		fld	qword ptr [bp][6]
		fistp	word ptr -2[bp]
		wait
		mov	ax, -2[bp]
		mov	sp, bp
		pop	bp
		ret	8
_ROUND		endp
SYSTEM_TEXT	ends

		end
