(* file = cbgen4.pas
 *
 * カベソンコンパイラ　：　コード生成（ＣＰＵ依存）
 *
 * ラストアップデート　'90/07/25　オケゲム／松田晋
 *
 * Copyright (C) 1990, 91 Ockeghem
 *)

unit cbgen4;

interface
uses cbcom;

function isFarRoutine(p : refIdentifier) : boolean;
procedure genJump(la : integer);
procedure genDebugLineNo;

procedure openSegment(ns : inSeg);
procedure openSegmentIfNotUsed(ns : inSeg);
procedure closeSegment;

procedure genExternalProcedure(p : refIdentifier);
procedure genDummyData(n : integer);
procedure aliasOfRealConst(p : refIdentifier);
procedure genRealConst(var p : constant);
procedure genStringConst(var p : constant);
procedure genRealConstWithName(p : refIdentifier);
procedure genStaticData(p : refIdentifier; tp : refStructure);

procedure initCodeGen4;

implementation

uses cblabel, cbexgen4;

var
	segClass : array[inSeg] of string[4];
	segName : array[inSeg] of string[7];
	insegment : inSeg;
	segUsed : array[inSeg] of boolean;
	segNo   : integer;

function isFarRoutine(p : refIdentifier) : boolean;
begin
	isFarRoutine := p^.idDeclareClass <> private
end;

procedure genJump(la : integer);
begin
	write(outFile, '	jmp	');
	outLabel1(la)
end;

procedure closeSegment;
begin
	if not lsiR86 and (insegment <> inNothing) then begin
		if insegment = inCode then
			write(outFile, programOrUnitName, '_TEXT')
		else
			write(outFile, segName[insegment]);
		writeln(outFile, '	ends');
		writeln(outFile);
		insegment := inNothing
	end
end;

procedure openSegment(ns : inSeg);
begin
	if ns <> insegment then begin
		closeSegment;
		if ns = InCode then begin
			write(outFile, programOrUnitName, '_TEXT	');
			if lsiR86 then
				writeln(outFile, 'CSEG')
			else begin
				writeln(outFile, 'segment	byte public ''CODE''');
				if jumpOptimization and not lsiR86 then
					writeln(outFile, '	JUMPS')
			end
		end else begin
			segUsed[ns] := true;
			write(outFile, segName[ns]);
			if lsiR86 then
				writeln(outFile, '	DSEG')
			else
				writeln(outFile, '	segment	word public ''', 
						segClass[ns], '''')
		end;
		insegment := ns
	end
end; { openSegment }

procedure openSegmentIfNotUsed(ns : inSeg);
begin
	if not segUsed[ns] then
		openSegment(ns);
	closeSegment
end; { openSegmentIfNotUsed }

procedure genRealConst(var p : constant);
begin
	openSegment(inData);
	outLabel0(p.labelValue);
	writeln(outFile, '	dq	', p.strgValuePtr^)
end;

procedure genExternalProcedure(p : refIdentifier);
begin
	closeSegment;
	write(outFile, '	extrn	', asmName(p));
	p^.forwardDec := false;
	if lsiR86 then
		writeln(outFile)
	else if isFarRoutine(p) then
		writeln(outFile, ': far')
	else
		writeln(outFile, ': near')
end; { genExternalProcedure }

procedure genStringConst(var p : constant);
var
	i, n, n2, sz : integer;
begin
	openSegment(inCode);
	outLabel0(p.labelValue);
	if lsiR86 then
		write(outFile, ':');
	sz := p.strgValuePtr^.length;
	writeln(outFile, '	dw	', sz);
	n := 1;
	while n <= sz do begin
		n2 := min(n + 11, sz);
		write(outFile, '	db	');
		for i := n to n2 - 1 do
			write(outFile, ord(p.strgValuePtr^[i]), ', ');
		writeln(outFile, ord(p.strgValuePtr^[n2]));
		n := n2 + 1
	end
end; { genStringConst }

procedure genRealConstWithName(p : refIdentifier);
begin
	openSegment(inData);
	writeln(outFile, '	public	', asmName(p));	{未}
	writeln(outFile, asmName(p), '	label	qword');
	genRealConst(p^.values)
end; { genRealConstWithName }

procedure aliasOfRealConst(p : refIdentifier);	{未}
begin
	openSegment(inData);
	with p^ do begin
		writeln(outFile, '	extrn	', asmName(p), ': qword');
		outLabel0(values.labelValue);
		writeln(outFile, '	equ	', asmName(p));
	end
end; { aliasOfRealConst }

procedure genDummyData(n : integer);
begin
	if n <= 0 then
	(* なにもしない *)
	else if lsiR86 then
		writeln(outFile, '	RS	', n)
	else
		writeln(outFile, '	db	', n, ' dup (?)')
end;

procedure genDebugLineNo;
begin
	if insegment = inCode then
		writeln(outFile, '	?debug	L ', lineNo)
end;

procedure openFarSeg;
begin
	closeSegment;
	if lsiR86 then
		writeln(outFile, programOrUnitName, segNo, '_FAR	eseg	para')
	else
		writeln(outFile, programOrUnitName, segNo,
				'_FAR	segment para public ''EXTRA''')
end;

procedure closeFarSeg;
begin
	if not lsiR86 then
		writeln(outFile, programOrUnitName, segNo, '_FAR	ends');
	insegment := inNothing;
	segNo := segNo + 1
end;

procedure genStaticData(p : refIdentifier; tp : refStructure);
var
	para : integer;
	first : boolean;

	procedure putLabel(p : refIdentifier);
	begin
		if lsiR86 then begin
			write(outFile, asmName(p), ':');
			if p^.idDeclareClass = public then
				write(outFile, ':');
		end else begin
			if p^.idDeclareClass = public then
				writeln(outFile, '	public	', asmName(p));
			write(outFile, asmName(p))
		end
	end;

begin
	if tp^.isHuge then begin
		if p^.idDeclareClass = extern then begin
			closeSegment;
			write(outFile, '	extrn	', asmName(p));
			if not lsiR86 then
				write(outFile, ': byte');
			writeln(outFile)
		end else begin
			para := tp^.size;
			first := true;
			while para > 0 do begin
				openFarSeg;
				if first then
					putLabel(p);
				genDummyData(min(para, 2048) * 8);
				genDummyData(min(para, 2048) * 8);
				closeFarSeg;
				first := false;
				para := para - 2048
			end
		end
	end else begin
		openSegment(inBss);
		if p^.idDeclareClass = extern then begin
			write(outFile, '	extrn	', asmName(p));
			if not lsiR86 then
				write(outFile, ': byte');
			writeln(outFile)
		end else begin
			putLabel(p);
			genDummyData(tp^.size)
		end
	end
end; { genStaticData }

procedure initCodeGen4;
begin
	segClass[inCode] := 'CODE';
	segClass[inData] := 'DATA';
	segClass[inBss] := 'DATA';

	segName[InNothing] := 'nothing';
	segName[InCode] := '_TEXT';
	segName[InData] := '_DATA';
	segName[InBss] := '_BSS';

	insegment := inNothing;

	segUsed[inData] := false;
	segUsed[inBss] := false;

	segNo := 1
end;

end.
