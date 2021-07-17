standardInput		= 0;
standardOutput		= 1;

dummy	   = 0;
textBufferSize = 512;
fnameSize      = 65;
fileClosed		  = 3C56H	; マジックナンバ 
fileOpenedForRead	  = 3C57H
fileOpenedForWrite	  = 3C58H
fileOpenedForReadWrite    = 3C59H

INPUT_PAST_END		= 100
DISK_FULL		= 101
FILE_NOT_ASSIGNED	= 102
FILE_NOT_OPEN		= 103
FILE_NOT_OPEN_FOR_INPUT	= 104
FILE_NOT_OPEN_FOR_OUTPUT = 105
fnameSize		= 65
textBufferSize		= 512

FCB	STRUC
	mode	dw	1 dup (?)
	handle	dw	1 dup (?)
	rest	dw	1 dup (?)
	cptr	dw	1 dup (?)
	bufsize dw	1 dup (?)
	fname	dw	1 dup (?)
		db	fnameSize dup (?)
	isatty	db	1 dup (?)
	iobuffer db	textBufferSize dup (?)
FCB	ends
