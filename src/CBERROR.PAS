(* file = cberror.pas
 *
 * カベソンコンパイラ　：　エラー表示
 *
 *
 * Copyright (C) 1990  Ockeghem
 *)
unit cberror;

interface
uses cbcom;

function executePath : fileNameType;
procedure initError;
procedure errorFlush;
procedure error(n : integer; errKind : errorKind);
procedure errorName(n : integer; s : stringMax; errKind : errorKind);
procedure errorType1(n : integer; p : refStructure; errKind : errorKind);
procedure errorType2(n : integer; p1, p2 : refStructure; errKind : errorKind);
procedure error2(s : StringBuf; errKind : errorKind);
procedure notAvailable(s : stringBuf);
procedure sysError(s : StringBuf);

implementation

uses cblex, cbflush, cbdump;

const
	errorMessageFile = 'cabezon.err';
type
	Message = string[80];
var
	errmsg : array[0..100] of ^Message;
	errorKindName : array[errorKind] of string[12];

function executePath : fileNameType;
label 9;
var
	s : fileNameType;
	i : integer;
begin
	s := paramStr(0);
	for i := s.length downto 1 do
		if s[i] = '\' then
			goto 9;
	i := 0;
 9:	executePath := copy(s, 1, i)
end;

procedure initError;
var
	f : text;
	n : integer;
	ch : char;
	st : Message;

	procedure readError;
	begin
		writeln('read failed : ', fname);
		halt(1)
	end;
begin
	errorExist := false;

	nErrors[warnings] := 0;
	nErrors[errors] := 0;
	nErrors[disasters] := 0;

	errorKindName[warnings] := 'Warning';
	errorKindName[errors] := 'Syntax error';
	errorKindName[disasters] := 'Fatal error';

	fname := '';
	listp := false;
	debug := false;
	new(errmsg[55]);
	errmsg[55]^ := 'cannot open input file';
	newFile(false, executePath + errorMessageFile);
	getsym;
	while sym <> rdiv do begin
		if sym <> intConst then
			readError;
		n := val.intValue;
		getsym;
		if sym <> stringConst then
			readError;
		st := val.strgValuePtr^;
		dispose(val.strgValuePtr);
		new(errmsg[n]);
		errmsg[n]^ := st;
		getsym
	end;
	disposeFile;
end; { initError }

(* 関数：putspc
 *
 * 目的：スペースを指定された数だけ出力する
 *
 * n: スペース数
 * fp: ファイルポインタ
 *)
procedure putspc(n : integer; var fp : text);
begin
	write(fp, ' ':n)
end; { putspc }

procedure errorFlush;
begin
	if debug then
		dumpSymbols;
	flushFiles;
	halt(1)
end; { errorFlush }

procedure printErrorPoint;
begin
	writeln(Rbuf);
	putspc(cp - 3, output);
	writeln('↑');
	write(fname, '[', LineNo, ']')
end; { printErrorPoint }

procedure error0(errKind : errorKind; n : integer);
begin
	if n <> 55 then				(* ファイルのオープンエラー以外の場合 *)
		printErrorPoint;
	write(errorKindName[errKind], '(', n, '): ', errmsg[n]^);
end; { error0 }

procedure errorFlush1(errKind : errorKind);
begin
	nErrors[errKind] := nErrors[errKind] + 1;
	errorExist := true;
	if errKind = disasters then
		errorFlush
end; { errorFlush1 }

procedure error(n : integer; errKind : errorKind);
begin
	error0(errKind, n);
	writeln;
	errorFlush1(errKind)
end; { error }

procedure errorName(n : integer; s : stringMax; errKind : errorKind);
begin
	error0(errKind, n);
	writeln('(', s, ')');
	errorFlush1(errKind)
end; { errorName }

procedure errorType1(n : integer; p : refStructure; errKind : errorKind);
begin
	error0(errKind, n);
	writeln;
	write('type = ');
	dumpType(p);
	writeln;
	errorFlush1(errKind)
end; { errorType1 }

procedure errorType2(n : integer; p1, p2 : refStructure; errKind : errorKind);
begin
	error0(errKind, n);
	writeln;
	write('type1 = ');
	dumpType(p1);
	writeln;
	write('type2 = ');
	dumpType(p2);
	writeln;
	errorFlush1(errKind)
end; { errorType2 }

procedure error2(s : StringBuf; errKind : errorKind);
begin
	printErrorPoint;
	writeln('Syntax error(101): ', s, ' expected.');
	errorFlush1(errKind)
end; { error }

procedure notAvailable(s : stringBuf);
begin
	printErrorPoint;
	writeln('Fatal error(102): Sorry, ', s, ' is not implemented.');
	errorFlush
end;

procedure sysError(s : StringBuf);
begin
	writeln;
	printErrorPoint;
	writeln('System error(', s, ')：コンパイラの誤り');
	flushFiles;
	halt(1)
end;

end.
