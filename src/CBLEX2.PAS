(* file = cblex2.pas
 *
 * カベソンコンパイラ　：　記号読取り部の初期化
 *
 *
 * Copyright (C) 1990  Ockeghem
 *)

unit cblex2;interface
uses cbcom;

procedure initSym0;

implementation

uses cblex, cberror;

procedure initSym2;
var
	s : symbol;
begin
	for s every symbol do
		symName[s] := '';

	symName[ident] := '名前';
	symName[intConst] := '整定数';
	symName[realConst] := '実定数';
	symName[stringConst] := '文字列定数';
	symName[notSym] := 'not';
	symName[fromTo] := '..';
	symName[plus] := '+';
	symName[minus] := '-';
	symName[orsym] := 'or';
	symName[xorsym] := 'xor';
	symName[mulsym] := '*';
	symName[divsym] := 'div';
	symName[rdiv] := '/';
	symName[modsym] := 'mod';
	symName[andsym] := 'and';
	symName[leq] := '<=';
	symName[lss] := '<';
	symName[eql] := '=';
	symName[neq] := '<>';
	symName[geq] := '>=';
	symName[grt] := '>';
	symName[lparen] := '(';
	symName[rparen] := ')';
	symName[lbracket] := '[';
	symName[rbracket] := ']';
	symName[beginsym] := 'begin';
	symName[endsym] := 'end';
	symName[comma] := ',';
	symName[semicolon] := ';';
	symName[colon] := ':';
	symName[period] := '.';
	symName[becomes] := ':=';
	symName[stringsym] := 'string';
	symName[everysym] := 'every';
	symName[otherwisesym] := 'otherwise';
	symName[stepsym] := 'step';
	symName[leavesym] := 'leave';
	symName[withsym] := 'with';
	symName[programsym] := 'program';
	symName[returnsym] := 'return';
	symName[arraysym] := 'array';
	symName[arrow] := '^';
	symName[nilsym] := 'nil';
	symName[insym] := 'in';
	symName[recordsym] := 'record';
	symName[filesym] := 'file';
	symName[unitsym] := 'unit';
	symName[interfacesym] := 'interface';
	symName[implementationsym] := 'implementation';
	symName[usessym] := 'uses';
	symName[gotosym] := 'goto';
	symName[ifsym] := 'if';
	symName[thensym] := 'then';
	symName[elsesym] := 'else';
	symName[whilesym] := 'while';
	symName[dosym] := 'do';
	symName[packedsym] := 'packed';
	symName[setsym] := 'set';
	symName[casesym] := 'case';
	symName[ofsym] := 'of';
	symName[repeatsym] := 'repeat';
	symName[untilsym] := 'until';
	symName[forsym] := 'for';
	symName[tosym] := 'to';
	symName[downtosym] := 'downto';
	symName[labelsym] := 'label';
	symName[constsym] := 'const';
	symName[typesym] := 'type';
	symName[varsym] := 'var';
	symName[proceduresym] := 'procedure';
	symName[functionsym] := 'function';
	symName[hugesym] := 'huge';
	symName[othersym] := 'その他';
	for s every symbol do
		if symName[s] = '' then begin
			writeln('sym : ', ord(s));
			sysError('initSym5')
		end

end; { intSym2 }

procedure initSym3;
var
	ch : char;
begin
	for ch every char do begin
		ssy[ch] := othersym;
		csy[ch] := otherChar
	end;
	for ch := 'A' to 'Z' do
		csy[ch] := Alphabet;
	for ch := 'a' to 'z' do
		csy[ch] := Alphabet;
	csy['_'] := Alphabet;
	for ch := '0' to '9' do
		csy[ch] := Numeric;

	for ch := chr($81) to chr($85) do
		csy[ch] := kanji1;
	for ch := chr($88) to chr($9f) do
		csy[ch] := kanji1;
	for ch := chr($e0) to chr($ea) do
		csy[ch] := kanji1;

	csy[' '] := WhiteSpace;
	csy[chr(9)] := WhiteSpace;
	csy[chr(10)] := WhiteSpace;
	csy['('] := lparenChar;			csy['{']  := lbraquetChar;
	csy['$'] := dollerChar;			csy[''''] := quoteChar;
	csy['.'] := periodChar;			csy[':']  := colonChar;
	csy['<'] := lessChar;			csy['>']  := grtChar;

	ssy['+'] := plus;			ssy['-'] := minus;
	ssy['*'] := mulsym;			ssy['/'] := rdiv;
	ssy['('] := lparen;			ssy[')'] := rparen;
	ssy['['] := lbracket;		ssy[']'] := rbracket;
	ssy['='] := eql;			ssy[','] := comma;
	ssy['.'] := period;			ssy[';'] := semicolon;
	ssy['^'] := arrow
end; { initSym3 }

procedure initSym4;
var
	s : symbol;
begin
	for s every symbol do
		opkind[s] := noop;
	opkind[plus] := addop;
	opkind[minus] := addop;
	opkind[orsym] := addop;
	opkind[xorsym] := addop;
	opkind[mulsym] := mulop;
	opkind[divsym] := mulop;
	opkind[rdiv] := mulop;
	opkind[modsym] := mulop;
	opkind[andsym] := mulop;

	opkind[leq] := relop;
	opkind[lss] := relop;
	opkind[geq] := relop;
	opkind[grt] := relop;
	opkind[eql] := relop;
	opkind[neq] := relop;
	opkind[insym] := relop;

	opkind[period] := indexop;
	opkind[lbracket] := indexop;
	opkind[arrow] := indexop;
end; { initSym4 }

procedure initSym5;
begin
	c := ' ';
	Rbuf := ' ';
	cp := 1;
	LineNo := 0;
	chMode := inProgram;
	include := false;
	fileInfoSaveLink := nil;
end; { initSym5 }

procedure initIdClassName;	(* デバッグ用 *)
begin
	IdClassName[labels] := 'ラベル宣言子';
	IdClassName[types] := '型宣言子';
	IdClassName[constants] := '定数';
	IdClassName[vars] := '変数';
	IdClassName[fields] := 'フィールド';
	IdClassName[procedures] := '手続き';
	IdClassName[functions] := '関数';
	IdClassName[units] := 'ユニット';
	IdClassName[programs] := 'プログラム';
end; { initIdClassName }

procedure initFormName;
begin
	formName[scalars] := 'スカラー';
	formName[subranges] := '範囲型';
	formName[pointers] := 'ポインタ';
	formName[powers] := '集合';
	formName[arrays] := '配列';
	formName[strings] := 'ストリング';
	formName[stringConsts] := '文字定数';
	formName[records] := 'レコード';
	formName[files] := 'ファイル';
end; { initFormName }

procedure initIdKindName;
begin
	idKindName[actual] := 'actual';
	idKindName[formal] := 'formal'
end; { initIdKindName }

procedure InitopKindName;
begin
	opKindName[opVariable] := 'variable';
	opKindName[opConstant] := 'constant';
	opKindName[opIndirect] := 'indirect';
	opKindName[opFunction] := 'function';
	opKindName[operator] := 'operator';
end; { InitopKindName }

procedure InitopesName;
begin
	opesName[opMoveTo] := ':=';
	opesName[opNeg] := 'neg';
	opesName[opNot] := 'not';
	opesName[opCast] := 'cast';
	opesName[opAdd] := '+';
	opesName[opSub] := '-';
	opesName[opMul] := '*';
	opesName[opDiv] := 'div';
	opesName[opMod] := 'mod';
	opesName[opAnd] := 'and';
	opesName[opOr] := 'or';
	opesName[opXor] := 'xor';
	opesName[opCmp] := 'cmp';
	opesName[opLeq] := '<=';
	opesName[opLss] := '<';
	opesName[opEql] := '=';
	opesName[opNeq] := '<>';
	opesName[opGeq] := '>=';
	opesName[opGrt] := '>';
	opesName[opPush] := 'push';
	opesName[opOthers] := '???';
end; { InitOpesName }

procedure InitSym0;
begin
	initSym2;
	initSym3;
	initSym4;
	initSym5;
	initIdClassName;	(* デバッグ用 *)
	initFormName;		(* デバッグ用 *)
	initIdKindName;		(* デバッグ用 *)
	initOpKindName;		(* デバッグ用 *)
	initOpesName;		(* デバッグ用 *)
end; { InitSym0 }

end.
