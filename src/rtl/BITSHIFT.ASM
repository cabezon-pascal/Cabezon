;	function bitShift(x, y : integer) : integer;
;
SYSTEM_TEXT		segment	byte public 'CODE'
				assume	cs: SYSTEM_TEXT

				public	_BITSHIFT
_BITSHIFT		proc	far
				mov		bx, sp
				mov		ax, ss:6[bx]		; x
				mov		cx, ss:4[bx]		; y
				or		cx, cx
				jl		right_shift
;; lefth_shift
				shl		ax, cl
				jmp		short exit_bitshift
right_shift:
				neg		cx
				shr		ax, cl
exit_bitshift:
				ret		4
_BITSHIFT		endp

SYSTEM_TEXT		ends
				end
