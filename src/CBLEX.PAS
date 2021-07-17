(* file = cblex.pas
 *
 * カベソンコンパイラ　：　字句解析ルーチン
 *
 *
 * Copyright (C) 1990  Ockeghem
 *)
unit cblex;

interface
uses cbcom;

var
	ssy : array[char] of symbol;
	csy : array[char] of charKind;
	chMode : (inProgram, inString, inComment, inErrorTable);

function makeFileName(f : fileNameType) : fileNameType;
function isNot(chksym : symbol) : boolean;
procedure InitSym;
procedure getsym;
procedure checkSym(csym : symbol; errKind : errorKind);
procedure checkId(errKind : errorKind);
procedure newFile(incl : boolean; fileName : fileNameType);
procedure disposeFile;

implementation

uses cberror, cblex1, cblex2, cbtable, cbgen2, cbdump;

(* 変数宣言 *)

const
	standardExtent = '.pas';	{ ＯＳ依存 }
var
	ip : integer;
	lengthOfCabezonString : integer;	{ 文字列定数の大きさ }
	CabezonString : stringOfCabezon;	{ 文字列定数の大きさ }
	num : integer;						{ 整定数値 }

(* －－－－－－－－－－－－－－　関数定義　－－－－－－－－－－－－－ *)

procedure InitSym;
begin
	InitSym1;
	InitSym0
end;

function makeFileName(f : fileNameType) : fileNameType;
begin
	if cpos('.', f) > 0 then
		makeFileName := f
	else
		makeFileName := f + standardExtent
end; { makeFileName }

procedure newFile(incl : boolean; fileName : fileNameType);
var
	p : refFileInfoSave;
begin
	new(p);
	with p^ do begin
		saveSym := sym;
		saveLineNo := LineNo;
		saveC := c;
		saveCp := cp;
		saveRbuf := Rbuf;
		saveInFile := InFile;
		saveFname := Fname;
		saveInclude := include
	end;
	new(inFile);
	c := ' ';
	Rbuf := ' ';
	cp := 1;
	LineNo := 0;
	include := incl;
	fname := fileName;

	assign(inFile^, fileName);
	{$I-}
	reset(inFile^);
	{$I+}
	if ioResult <> 0 then
		errorName(55, fileName, disasters);

	p^.next := fileInfoSaveLink;
	fileInfoSaveLink := p
end; { newFile }

procedure disposeFile;
var
	p : refFileInfoSave;
begin
	close(inFile^);
	dispose(inFIle);
	p := fileInfoSaveLink;
	with p^ do begin
		sym := saveSym;
		LineNo := saveLineNo;
		c := saveC;
		cp := saveCp;
		Rbuf := saveRbuf;
		InFile := saveInFile;
		Fname := saveFname;
		include := saveInclude
	end;

	if debug then begin
		writeln('line = ', Rbuf);
		writeln('cp   = ', cp);
		writeln('c    = ', c);
		writeln('sym = ', symName[sym])
	end;
	fileInfoSaveLink := p^.next;
	dispose(p)
end; { disposeFile }

procedure unReadCh;
begin
	cp := cp - 1
end;

procedure readch;
begin
	while cp > Rbuf.length do
		if not eof(InFile^) then begin
			readln(InFile^, Rbuf);
			if listp then
				writeln(OutFile, ';', Rbuf);
			LineNo := LineNo + 1;
			Rbuf := Rbuf + ' ';
			cp := 1
		end else if include then begin
			disposeFile;
			unreadch
		end else
			case chMode of
				inProgram: error(22, disasters);
				inString: error(23, disasters);
				inComment: error(24, disasters);
				inErrorTable: begin
						writeln('unexpected eof in error table');
						halt(1)
					end;
				otherwise
					sysError('readch');
			end;
	c := Rbuf[cp];
	cp := cp + 1
end; { readch }

function isKanji1(ch : char) : boolean;
begin
	isKanji1 := csy[ch] = kanji1
end;

function isKanji2(ch : char) : boolean;
begin
	if (ch >= chr($40)) and (ch <= chr($7e)) then
		isKanji2 := true
	else if (ch >= chr($80)) and (ch <= chr($fc)) then
		isKanji2 := true
	else
		isKanji2 := false
end;

procedure compilerOption(m : boolean); forward;

procedure SkipComment1;
begin
	readch;
	if c = '$' then
		compilerOption(true)
	else begin
		chMode := inComment;
		while c <> '}' do begin
			if isKanji1(c) then
				readch;	{ 漢字対応 }
			readch
		end;
		chMode := inProgram;
		readch
	end
end; { SkipComment1 }

procedure SkipComment2;
begin
	readch;	{ １文字目の＊の読み飛ばし }
	if c = '$' then
		compilerOption(false)
	else begin
		chMode := inComment;
		repeat
			while c <> '*' do
				readch;	{ 漢字で*)が出てくることはないので }
			readch;		{ こちらの漢字対応は不要 	   }
		until c = ')';
		chMode := inProgram;
		readch
	end
end; { SkipComment2 }

procedure compilerOption(m : boolean);
var
	includeFileName : fileNameType;
	i : integer;
	include : boolean;
begin
	include := false;
	readch;
	case c of
		'i', 'I': begin
				readch;
				case c of
					'+': ioCheck := true;
					'-': ioCheck := false;
					otherwise
						begin
							include := true;
							while csy[c] = WhiteSpace do
								readch;
							i := 0;
							while (c <> '*') and (c <> '}') do begin
								i := i + 1;
								includeFileName[i] := c;
								readch
							end;
							includeFileName.length := i;
							unReadch
						end
				end
			end;
		'r', 'R': begin
				readch;
				case c of
					'+': rangeCheck := true;
					'-': rangeCheck := false;
					otherwise;	{ 何もしない }
				end
			end;
		't', 'T': dumpSymbols;
		otherwise;				{ 何もしない }
	end;
	if m then
		skipComment1
	else
		skipComment2;
	if include then
		newFile(true, includeFileName);
end; { compilerOption }

procedure identification;
var
	i, L, h : integer;
begin

	(* 名前をidにセット *)

	i := 0;
	repeat
		if i < idsize then begin
			i := i + 1;
			id[i] := upCase(c)
		end;
		readch
	until (csy[c] <> Alphabet) and (csy[c] <> Numeric);
	L := i;
	id.length := L;

	(* これ以降は予約語検索の完全ハッシュサーチ *)

	h := L + HashTable[id[1]] + HashTable[id[L]];	{ 完全ハッシュ関数 }
	if h > HashMax then
		sym := ident
	else if id = word[h] then
		sym := wsym[h]
	else
		sym := ident
end; { identification }

procedure kanjiIdentification;
var
	i : integer;
begin

	(* 名前をidにセット *)

	i := 0;
	repeat
		if i < idsize then begin
			i := i + 1;
			id[i] := c
		end;
		readch;
		i := i + 1;
		id[i] := c;
		readch
	until csy[c] <> kanji1;
	id.length := i;
	sym := ident
end; { kanjiIdentification }

procedure charSet;
begin
	if ip >= MaxLengthOfCabezonString then
		error(11, disasters);
	ip := ip + 1;
	CabezonString[ip] := c
end;

procedure getString;
var
	exitLoop : boolean;

begin

	(* 文字列をstrにセット *)

	chMode := inString;
	ip := 0;
	readch;	{ ' の読み飛ばし }
	exitLoop := false;
	repeat
		if c <> '''' then begin
			charSet;
			if isKanji1(c) then begin
				readch;
				if not isKanji2(c) then
					error(13, disasters);
				charSet
			end;
			readch
		end else begin
			readch;
			if c = '''' then begin
				charSet;
				readch
			end else
				exitLoop := true
		end
	until exitLoop;
	CabezonString.length := ip;
	lengthOfCabezonString := ip;

	with val do begin
		new(strgValuePtr);
		strgValuePtr^ := CabezonString
	end;
	chMode := inProgram;
	sym := stringConst
end; { getString }

procedure fixOrFloatNum;
var
	floatNum : boolean;
	numOfFixNum : integer;

	procedure setNum;
	begin
		repeat
			charSet;
			readch
		until csy[c] <> Numeric
	end; { setNum }

	procedure fixnum;
	var
		i, n : integer;
		cn : char;
	begin
		num := 0;
		for i := 2 to numOfFixNum do begin
			cn := CabezonString[i];
			n := ord(cn) - ord('0');
			if num > (targetMaxint - n) div 10 then
				error(26, disasters);
			num := num * 10 + n
		end;
		sym := intConst;
		val.strgValuePtr := nil;
		val.intValue := num
	end; { fixnum }

begin
	floatNum := false;
	ip := 1;
	CabezonString[1] := ' ';
	setNum;
	numOfFixNum := ip;
	if c = '.' then begin
		charSet;
		readch;
		if c = '.' then
			unReadCh
		else if csy[c] = Numeric then begin
			floatNum := true;
			SetNum
		end else
			error(25, disasters)
	end;
	if (c = 'E') or (c = 'e') then begin
		floatNum := true;
		charSet;
		readch;
		if (c = '+') or (c = '-') then begin
			charSet;
			readch
		end;
		if csy[c] <> Numeric then
			error(25, disasters);
		SetNum;
	end;
	CabezonString.length := ip;
	lengthOfCabezonString := ip;

	if floatNum then begin
		sym := realConst;
		with val do begin
			new(strgValuePtr);
			strgValuePtr^ := CabezonString;
			labelValue := undefinedLabel
		end
	end else
		fixnum
end; { fixOrFloatNum }

procedure HexDecimal;
var
	k, n : integer;
	exitLoop : boolean;
begin
	readch;	{ $の読み飛ばし }
	if not ((csy[c] = Numeric) or 
			(c >= 'a') and (c <= 'f') or (c >= 'A') and (c <= 'F')) then
		error(27, disasters);
	num := 0;
	k := 0;
	exitLoop := false;
	repeat
		if csy[c] = Numeric then
			n := ord(c) - ord('0')
		else if (c >= 'a') and (c <= 'f') then
			n := ord(c) - ord('a') + 10
		else if (c >= 'A') and (c <= 'F') then
			n := ord(c) - ord('A') + 10
		else
			exitLoop := true;
		if not exitLoop then begin
			k := k + 1;
			if k > maxHexDigit then
				error(26, disasters);
			num := num * 16 + n;
			readch
		end
	until exitLoop;
	val.strgValuePtr := nil;
	val.intValue := num;
	sym := intConst
end; { HexDecimal }

(*  手続き：getsym
 *
 *  記号（シンボル）の読み出し
 *)
procedure getsym;
begin
	while csy[c] = WhiteSpace do
		readch;
	case csy[c] of
		lparenChar: begin				(* '(' *)
				readch;
				if c = '*' then begin
					SkipComment2;
					getsym	{ コメントは空白と同じ扱い }
				end else
					sym := lparen
			end;
		lbraquetChar: begin			(* '{' *)
				skipComment1;
				getsym	{ コメントは空白と同じ扱い }
			end;
		Alphabet: identification;
		Numeric: FixOrFloatNum;
		dollerChar: HexDecimal;		(* '$' *)
		quoteChar: getString;		(* '''' *)
		periodChar: begin			(* '.' *)
				readch;
				if c = '.' then begin
					sym := fromTo;
					readch
				end else
					sym := period
			end;
		colonChar: begin		(* ':' *)
				readch;
				if c = '=' then begin
					sym := becomes;
					readch
				end else
					sym := colon;
			end;
		lessChar: begin			(* '<' *)
				readch;
				if c = '>' then begin
					sym := neq;
					readch
				end else if c = '=' then begin
					sym := leq;
					readch
				end else
					sym := lss;
			end;
		grtChar: begin			(* '>' *)
				readch;
				if c = '=' then begin
					sym := geq;
					readch
				end else
					sym := grt
			end;
		kanji1:
			kanjiIdentification;
		otherwise begin
				sym := ssy[c];
				readch
			end
	end
end; { end getsym }

(*  関数：isNot
 *
 *  記号（シンボル）の読み出し
 *
 *  引数　sy : 継続するシンボル
 *
 *  戻り値 : 現在のsym がchksymでなかったら、真
 *  　　　　　さもなければ、偽を返すついでに次のシンボルを読みだす
 *)
function isNot(chksym : symbol) : boolean;
begin
	if sym = chksym then begin
		getsym;
		isNot := false
	end else
		isNot := true

end; { isNot }

procedure checkSym(csym : symbol; errKind : errorKind);
begin
	if sym <> csym then
		case csym of
			eql: begin
					if sym = becomes then begin
						error(1, errors);
						getsym
					end else
						error2('=', errKind)
				end;
			becomes: begin
					if sym = eql then begin
						error(2, errors);
						getsym
					end else
						error2('":="', errKind)
				end;
			otherwise
				error2(symName[csym], errKind);
		end else
		getsym
end;

procedure checkId(errKind : errorKind);
begin
	if sym <> ident then
		error2('identifier', errKind)
end;

end.
