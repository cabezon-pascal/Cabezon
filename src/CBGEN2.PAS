(* file = cbgen2.pas
 *
 * カベソンコンパイラ　：　コード生成（ＣＰＵ依存）
 *
 *
 * Copyright (C) 1990  Ockeghem
 *)

unit cbgen2;

interface
uses cbcom;

function lengthOfStackFrame(p : refIdentifier) : integer;

procedure entryOfModule;
procedure endOfModule;
procedure entryProc(tp : refIdentifier; la : integer);
procedure exitProc2(tp : refIdentifier; la : integer);
procedure genMoveDataOfArgument(oldAddress, newAddress, nByte : integer);

procedure genDisposePushValue(n : integer);
procedure initCodeGen2;

implementation
uses cbtype, cbtable, cballoc, cblabel, cbexgen4, cbgen3, cbgen4;

var
	asmProcName : alpha;

function lengthOfStackFrame(p : refIdentifier) : integer;
var
	L : integer;
begin
	L := targetDynamicLinkSize;
	if p^.level >= 2 then
		L := L + targetStaticLinkSize;
	if isFarRoutine(p) then
		L := L + targetFarCallSize
	else
		L := L + targetNearCallSize;
	lengthOfStackFrame := L
end; { lengthOfStackFrame }

procedure entryOfModule;
begin
	if (not lsiR86) and generateDebuggingData then begin
		writeln(outFile, '	ifndef	??version');
		writeln(outFile, '?debug	macro');
		writeln(outFile, '	endm');
		writeln(outFile, '	endif');
		writeln(outFile, '	?debug	S "', fname, '"')
	end;
	openSegment(inCode);
	openSegment(inData);
	closeSegment;
	writeln(outFile, 'DGROUP	group	_DATA, _BSS');
	if not lsiR86 then
		writeln(outFile, '	assume	cs: ', programOrUnitName, 
				'_TEXT, ds: DGROUP')
end;

procedure endOfModule;
begin
	openSegmentIfNotUsed(inData);
	openSegmentIfNotUsed(inBss);
	writeln(outFile, '	end')
end;

procedure entryProc(tp : refIdentifier; la : integer);
begin
	openSegment(InCode);
	asmProcName := asmName(tp);
	if lsiR86 then begin
		write(outFile, asmProcName, ':');
		if tp^.idDeclareClass = public then
			write(outFile, ':');
		writeln(outFile)
	end else begin
		if tp^.idDeclareClass = public then
			writeln(outFile, '	public	', asmProcName);
		if isFarRoutine(tp) then
			writeln(outFile, asmProcName, '	proc	far')
		else
			writeln(outFile, asmProcName, '	proc	near')
	end;
	if tp^.klass = programs then begin
		if lsiR86 then
			writeln(outFile, '@::')
		else begin
			writeln(outFile, '	public	@');
			writeln(outFile, '@	label	far')
		end;
		startUpPtr^.used := true;
		if floatCall then
			writeln(outFile, '	finit')
	end;
	writeln(outFile, '	push	bp');
	writeln(outFile, '	mov	bp, sp');
	if tp^.klass = programs then begin
		if lsiR86 then
			writeln(outFile, '	mov	[', asmName(stackFrameSaver), '].W, bp')
		else
			writeln(outFile, '	mov	word ptr ', asmName(stackFrameSaver), 
					', bp')
	end;
	write(outFile, '	sub	sp, ');
	outLabel1(la)
end;

procedure genMoveDataOfArgument(oldAddress, newAddress, nByte : integer);
begin
	writeln(outFile, '	mov	dx, ds');
	writeln(outFile, '	mov	cx, ss');
	writeln(outFile, '	lds	si, [BP+', oldAddress, ']');
	writeln(outFile, '	lea	di, [bp+', newAddress, ']');
	writeln(outFile, '	mov	es, cx');
	writeln(outFile, '	mov	cx, ', nByte div 2);
	writeln(outFile, '	cld');
	writeln(outFile, '	rep movsw');
	if nByte mod 2 = 1 then
		writeln(outFile, '	movsb');
	writeln(outFile, '	mov	ds, dx');
	diVariable := nil				(* with 文の最適化のため *)
end; { genMoveDataOfArgument }

procedure exitProc2(tp : refIdentifier; la : integer);
var
	n : integer;
begin
	n := currentRoutine^.argumentSize;
	if currentLevel >= 3 then
		n := n + targetStaticLinkSize;
	outLabel2(la + 1);
	writeln(outFile, '	mov	sp, bp');
	outLabel0(la);
	writeln(outFile, '	equ	', alignment0(targetArgumentAlign, maxLocation));
	writeln(outFile, '	pop	bp');
	if lsiR86 and isFarRoutine(tp) then
		write(outFile, '	retf	')
	else
		write(outFile, '	ret	');
	if n > 0 then
		write(outFile, n);
	writeln(outFile);
	if not lsiR86 then begin
		writeln(outFile, asmProcName, '	endp');
		writeln(outFile)
	end
end; { exitProc2 }

procedure genDisposePushValue(n : integer);
begin
	while n > 0 do begin
		writeln(outFile, '	pop	dx');
		n := n - targetIntegerSize
	end
end;

procedure initCodeGen2;
begin
	initCodeGen3
end;

end.
