(* file = cbinit.pas
 *
 * cbinit : カベソンコンパイラ：初期化		機種依存有り（ＯＳ）
 *
 *
 * Copyright (C) 1990, 91 Ockeghem
 *)
unit cbinit;

interface
uses cbcom;

procedure Init;

implementation

uses cbmodule, cberror, cblex, cbtable, cballoc, cbgen1, cbexgen1, cblabel;

const
	VERSION = 'Cabezon Pascal Compiler Ver 0.08';
	COPYRIGHT = 'Copyright (C) 1990, 93  Ockeghem';

var
	standardRnName : array[standardRoutines] of alpha;
	standardRnType : array[standardRoutines] of refStructure;
	lastRoutine : refIdentifier;

procedure runTimeOption;
var
	i, p : integer;
	ps : string[64];
	workName : fileNameType;
begin
	jumpOptimization := false;
	debug := false;
	listp := true;
	lsiR86 := false;
	generateDebuggingData := false;
	InFileName := '';
	outFileName := '';

	for i := 1 to ParamCount do begin
		ps := ParamStr(i);
		if (ps[1] = '-') or (ps[1] = '/') then
			case ps[2] of
				'd', 'D': debug := true;
				'j', 'J': jumpOptimization := true;
				'g', 'G': generateDebuggingData := true;
				'r', 'R': begin
						lsiR86 := true;
						jumpOptimization := true
					end;
				'o', 'O': outFileName := copy(ps, 3, 255);
				otherwise
					begin
						writeln('エラー：不適切なオプションです：', ps);
						halt(1)
					end
			end else
			InFileName := ps
	end;
	if InFileName <> '' then begin
		p := cpos('.', InFileName);
		if p = 0 then begin
			workName := InFileName + '.asm';
			InFileName := InFileName + '.pas'
		end else
			workName := copy(InFileName, 1, p - 1) + '.asm';
		p := cpos(':', workName);
		if p > 0 then
			workName := copy(workName, p + 1, maxint)
	end else
		workName := '';
	if outFileName = '' then
		outFileName := workName
end; { runTimeOption }

procedure InitFiles;	{ ＯＳ依存 }
begin
	new(InFile);
	close(output);
	assign(output, 'con');
	rewrite(output);
	fname := inFileName;
	if fname = '' then
		fname := 'standard input';
	assign(InFile^, InFileName);
	assign(OutFile, OutFileName);
	{$I-}
	reset(InFile^);
	{$I+}
	if ioResult <> 0 then
		errorName(55, inFileName, disasters);
	rewrite(OutFile)
end; { InitFiles }

(*  手続き：message
 *
 *  目的：バージョン表示
 *)
procedure message;
begin
	writeln(VERSION);
	writeln(COPYRIGHT)
end;

(*  手続き：initScalar
 *
 *  目的：スカラー型の処理
 *)

function initScalar(typeSize, typeAlign : integer) : refStructure;
var
	p : refStructure;
begin
	p := newStructure;
	with p^ do begin
		size := typeSize;
		alignmentUnit := typeAlign;
		form := scalars;
		scalarKind := standard
	end;
	initScalar := p
end; { initScalar }

(*  手続き：InitStandardType
 *
 *  目的：組込型の処理（やや冗長で散漫である）
 *)
procedure InitStandardType;
begin
	intPtr := initScalar(targetIntegerSize, targetIntegerAlign);
	bytePtr := initScalar(targetByteSize, targetByteAlign);
	realPtr := initScalar(targetRealSize, targetRealAlign);
	charPtr := initScalar(targetCharSize, targetCharAlign);
	controlPtr := initScalar(targetBoolSize, targetBoolAlign);

	boolPtr := initScalar(targetBoolSize, targetBoolAlign);
	with boolPtr^ do begin
		scalarKind := declared;
		tailOfEnumration := nil
	end;

	pointerPtr := newStructure;	{ pointer }
	with pointerPtr^ do begin
		size := targetPtrSize;
		alignmentUnit := targetPtrAlign;
		form := pointers;
		elementTypeOfPointer := nil
	end;

	textPtr := newStructure;	{ text }
	with textPtr^ do begin
		size := targetTextSize;
		alignmentUnit := targetTextAlign;
		form := files;
		fileType := charPtr
	end;

	stringPtr := newStructure;	{ string }
	with stringPtr^ do begin
		size := 257;			{ ダミー }
		alignmentUnit := 1;		{ ダミー }
		form := strings;
		stringElementType := charPtr;
		stringSize := 255		{ ダミー }
	end
end; { InitStandardType }

(*  手続き：initStandardTypeNames
 *
 *  目的：標準的な型をハッシュテーブルに挿入する
 *)
procedure initStandardTypeNames;
begin
	enterId(setId2('INTEGER', types, intPtr));	{ integer }
	enterId(setId2('REAL', types, realPtr));	{ real }
	enterId(setId2('CHAR', types, charPtr));	{ char }
	enterId(setId2('BOOLEAN', types, boolPtr));	{ boolean }
	enterId(setId2('TEXT', types, textPtr))		{ text }
end; { initStandardTypeNames }

(*  手続き：stdRoutine
 *
 *  目的：組込関数・手続きの記号表を作成する
 *)
procedure stdRoutine(rnName : alpha; rnClass : idClass; k : standardRoutines);
begin
	lastRoutine := setId2(rnName, rnClass, nil(* dummy*));
	with lastRoutine^ do begin
		procOrFuncKind := standard;
		paramp := nil;	(* 初期値 *)
		key := k
	end;
	enterId(lastRoutine)
end; { stdRoutine }

(*  手続き：internalRoutine
 *
 *  目的：内部的に使用する関数・手続きの記号表を作成する
 *)
function internalRoutine(rnName : alpha) : refIdentifier;
var
	p : refIdentifier;
begin
	p := setId2(rnName, procedures, nil);
	with p^ do begin
		procOrFuncKind := declared;
		argumentSize := 0;
		paramp := nil;
		forwardDec := false;
		externDec := false;
	end;
	enterId(p);
	internalRoutine := p
end; { internalRoutine }

(*  手続き：externalRoutine
 *
 *  目的：外部関数・手続きの記号表を作成する
 *)
(********************************************************************
procedure externalRoutine(rnName : alpha; rnType : refStructure);
var
	rnClass : idClass;
begin
	if rnType = nil then
		rnClass := procedures
	else
		rnClass := functions;
	lastRoutine := setId2(rnName, rnClass, rnType);
	with lastRoutine^ do begin
		procOrFuncKind := declared;
		argumentSize := 0;
		paramp := nil;
		forwardDec := false;
		externDec := false;
	end;
	enterId(lastRoutine)
end; { externalRoutine }
**************************************************************************)

(*  手続き：addArgumentToExternalRoutine
 *
 *  目的：外部関数・手続きの引数の処理
 *)
procedure addArgumentToExternalRoutine(tp : refStructure; vk : idKind);
var
	p : refIdentifier;
begin
	p := setId('@1', vars, tp);
	p^.variableKind := vk;
	p^.idDeclareClass := private;
	p^.next := lastRoutine^.paramp;
	lastRoutine^.paramp := p

end; { addArgumentToExternalRoutine }

procedure initStandardRoutines;
var
	p : refIdentifier;
begin
	stdRoutine('READ', procedures, readRn);
	stdRoutine('READLN', procedures, readlnRn);
	stdRoutine('WRITE', procedures, writeRn);
	stdRoutine('WRITELN', procedures, writelnRn);

	stdRoutine('NEW', procedures, newRn);
	addArgumentToExternalRoutine(pointerPtr, actual);

	(* ↑ 型チェックの都合でactualと宣言する。formalの処理は内部的に行う *)

	stdRoutine('DISPOSE', procedures, disposeRn);
	addArgumentToExternalRoutine(pointerPtr, actual);

	stdRoutine('RESET', procedures, resetRn);
	addArgumentToExternalRoutine(textPtr, formal);

	stdRoutine('REWRITE', procedures, rewriteRn);
	addArgumentToExternalRoutine(textPtr, formal);

	stdRoutine('CLOSE', procedures, closeRn);
	addArgumentToExternalRoutine(textPtr, formal);
	stdRoutine('CHR', functions, chrRn);
	stdRoutine('ORD', functions, ordRn);
	stdRoutine('ABS', functions, absRn);

	stdRoutine('@STRCAT', functions, strcatRn);
	strcatPtr := lastRoutine;

	intToRealPtr := internalRoutine('@INTTOREAL');
	strcmpPtr := internalRoutine('_STRCMP');
	startUpPtr := internalRoutine('@START');

	readCharPtr := internalRoutine('_READ@CHAR');
	readIntPtr := internalRoutine('_READ@INT');
	readRealPtr := internalRoutine('_READ@REAL');
	readStringPtr := internalRoutine('_READ@STRING');
	skipNlPtr := internalRoutine('_READ@SKIPNL');
	writeBoolPtr := internalRoutine('_WRITE@BOOL');
	writeCharPtr := internalRoutine('_WRITE@CHAR');
	writeIntPtr := internalRoutine('_WRITE@INT');
	writeRealPtr := internalRoutine('_WRITE@REAL');
	writeStringPtr := internalRoutine('_WRITE@STRING');
	writeStringNewlineCheckPtr := internalRoutine('_WRITE@STRING@LNCK');
	writeLnPtr := internalRoutine('_WRITE@LN');
	flushOutPtr := internalRoutine('_WRITE@FLUSHOUT');
	newMemPtr := internalRoutine('_NEW');
	newHugeMemPtr := internalRoutine('_NEW@HUGE');
	newMemWithCheckPtr := internalRoutine('_NEW_WITH_CHECK');
	disposeMemPtr := internalRoutine('_DISPOSE');
	disposeHugeMemPtr := internalRoutine('_DISPOSE@HUGE');
	ioCheckerPtr := internalRoutine('_IOCHECK');
	ioChecker2Ptr := internalRoutine('_IOCHECK2');
	stringCopy1Ptr := internalRoutine('_STRING@COPY1');
	stringCopy2Ptr := internalRoutine('_STRING@COPY2');
	rangeCheck1Ptr := internalRoutine('_RANGE@CHECK1');
	rangeCheck2Ptr := internalRoutine('_RANGE@CHECK2');
end; { initStandardRoutines }

function standardConst(cName : alpha; cType : refStructure; cValue : integer) 
		: refIdentifier;
var
	p : refIdentifier;
begin
	p := setId2(cName, constants, cType);
	with p^.values do begin
		next := nil;
		strgValuePtr := nil;
		intValue := cValue;
		labelValue := UndefinedLabel
	end;
	enterId(p);
	standardConst := p
end;

procedure initStandardConst;
var
	p : refIdentifier;
begin
	p := standardConst('TRUE', boolPtr, 1);
	boolPtr^.tailOfEnumration := p;
	p := standardConst('FALSE', boolPtr, 0);
	p := standardConst('MAXINT', intPtr, targetMaxint);
end; { initStandardConst }

(*  手続き：workData
 *
 *  目的：内部的に使用する変数の記号表を作成する
 *)
function workData(rnName : alpha; tp : refStructure) : refIdentifier;
var
	p : refIdentifier;
begin
	p := setId2(rnName, vars, tp);
	with p^ do begin
		variableKind := actual;
	end;
	enterId(p);
	workData := p
end; { workData }

procedure initStandardVars;
begin
	inputPtr := workData('INPUT', textPtr);
	outputPtr := workData('OUTPUT', textPtr);
end; { initStandardVars }

procedure initWorkData;
begin
	i8087Work1 := workData('@8087WORK_1', intPtr)
end; { initWorkData }

procedure Init;
begin
	initAllocate;
	InitSym;
	initError;

	runTimeOption;
	InitFiles;
	if paramCount = 0 then
		message;

	InitSym;
	initSearch;

	currentLevel := 0;
	currentClass := extern;
	floatCall := false;	(* デフォルト＝浮動小数点演算を行わない *)
	ioCheck := true;	(* デフォルト＝ｉ／ｏチェックを行う　　 *)
	rangeCheck := false;	(* 範囲チェックを行わない *)

	initLabel;
	initCodeGen;
	initStandardType;
	initStandardTypeNames;
	initStandardRoutines;
	initStandardConst;
	initStandardVars;
	initWorkData;
	initExprCodeGen;

	usesOne(executePath + 'CABEZON.INI', false (* no check *));

	currentClass := private;
	stackFrameSaver := workData('@mainStackFrame', intPtr);

	getsym	{ 先読み }
end;

end.
