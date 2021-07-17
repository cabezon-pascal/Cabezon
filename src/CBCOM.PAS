(* file = cbcom.pas
 *
 * cbcom : カベソンコンパイラ：共通部		機種依存有り（ＯＳ、ＣＰＵ）
 *
 *
 * Copyright (C) 1990, 91, 92  Ockeghem
 *)

unit cbcom;

interface

const
	idsize = 31;	{ 名前の最大長 }
	maxstr = 255;
	HashSize = 997;
	HashSizeMinus1 = 996;	{ HashSize - 1 }
	MaxFileName = 64;
	MaxLengthOfCabezonString = 255;
	maxHexDigit = 4;
	minChar = 0;			{ 機種依存 }
	maxChar = 255;			{ 機種依存 }
	YES = 1;
	NO = 0;
	UndefinedLabel = -1;

	(************************ ここから後は機種依存 *************************)

	targetMinint = $8000;
	targetMaxint = 32767;
	targetMinByte = 0;
	targetMaxByte = 255;

	targetNearCallSize = 2;
	targetFarCallSize = 4;

	targetBoolSize = 1;
	targetByteSize = 1;
	targetCharSize = 1;
	targetIntegerSize = 2;
	targetLongIntSize = 4;
	targetPtrSize = 4;
	targetRealSize = 8;
	targetTextSize = 590;

	targetBoolAlign = 1;
	targetByteAlign = 1;
	targetCharAlign = 1;
	targetIntegerAlign = 2;
	targetPtrAlign = 2;
	targetRealAlign = 2;
	targetArgumentAlign = 2;
	targetTextAlign = 2;

	targetDynamicLinkSize = 2;
	targetStaticLinkSize = 2;

(************************ 機種依存部終り *************************)

type
	refText = ^text;

	alpha = string[idsize];
	stringMax = string[maxstr];
	refAlpha = ^alpha;
	fileNameType = string[MaxFileName];
	refStringOfCabezon = ^StringOfCabezon;
	stringOfCabezon = string[MaxLengthOfCabezonString];

	stringBuf = string[maxstr];

	symbol = (ident, intConst, realConst, stringConst, notSym, fromTo, plus, 
			minus, orsym, xorsym, mulsym, divsym, rdiv, modsym, andsym, 

			(* leqからqrtに他のシンボルを挿入してはならない *)

			leq, lss, eql, neq, geq, grt, lparen, rparen, lbracket, rbracket, 
			beginsym, endsym, comma, semicolon, colon, period, becomes, 
			stringsym, everysym, otherwisesym, stepsym, leavesym, withsym, 
			programsym, returnsym, arraysym, arrow, nilsym, insym, recordsym, 
			filesym, unitsym, interfacesym, usessym, implementationsym, 
			gotosym, ifsym, thensym, elsesym, whilesym, dosym, packedsym, 
			setsym, casesym, ofsym, repeatsym, untilsym, forsym, tosym, 
			downtosym, labelsym, constsym, typesym, varsym, proceduresym, 
			functionsym, hugesym, othersym);

	charKind = (Alphabet, Numeric, WhiteSpace, kanji1, 
				lparenChar, lbraquetChar, dollerChar, quoteChar, periodChar, 
				colonChar, lessChar, grtChar, otherChar);

	operation = (noop, addop, mulop, relop, indexop);
	idClass = (labels, types, constants, vars, fields, procedures, functions, 
			units, programs);
	idKind = (actual, formal);
	declareClass = (private, public, extern);
	declareKind = (standard, declared);
	structureForm = (scalars, subranges, pointers, powers, arrays, strings, 
			stringConsts, records, files);
	standardRoutines = (readRn, readlnRn, writeRn, writelnRn, newRn, 
			disposeRn, resetRn, rewriteRn, closeRn, eofRn, chrRn, ordRn, 
			absRn, strcatRn);
	operatorKinds = (opVariable, opConstant, opIndirect, opProcedure, 
			opFunction, operator, opRangeCheck);
	operators = (opMoveTo, opNeg, opNot, opCast, opAbs, opAdd, opSub, opMul, 
			opDiv, opMod, opAnd, opOr, opXor, opCmp, opLeq, opLss, opEql, 
			opNeq, opGeq, opGrt, opPush, opOthers);
	labelState = (undefined, forwardDeclared, defined, finished);
	errorKind = (warnings, errors, disasters);

	refConstant = ^constant;
	constant = record
		next : refConstant;
		strgValuePtr : refStringOfCabezon;
		intValue : integer;
		labelValue : integer
	end; { constant }

	refTagField = ^tagField;
	refVariant = ^variant;
	refStructure = ^structure;
	refIdentifier = ^identifier;
	refWithLink = ^withLink;
	refCaseInformation = ^caseInformation;
	refCaseLink = ^caseLink;
	refArgsLink = ^argsLink;
	refEvalTree = ^evalTree;

	tagField = record
		tagFieldType : refStructure;
		firstVariant : refVariant
	end;

	variant = record
		value : integer;
		size : integer;
		next : refVariant;
		subVariant : refTagField
	end;

	structure = record
		size : integer;
		alignmentUnit : integer;
		next : refStructure;
		isPacked, isHuge : boolean;
		case form : structureForm of
			scalars : (case scalarKind : declareKind of
					declared : (tailOfEnumration : refIdentifier);
					standard : ());	(* 空 *)
			subranges : 
				(rangeType : refStructure;
				 minValueOfSubrange, maxValueOfSubrange : integer);
			pointers : (elementTypeOfPointer : refStructure);
			powers : (elementTypeOfSet : refStructure);
			arrays : (arrayElementType, indexType : refStructure);
			stringConsts, strings : 
				(stringElementType : refStructure;
				 stringSize : integer);
			records : 
				(firstField : refIdentifier;
				 mainVariant : refTagField);
			files : (fileType : refStructure)
	end; { structure }

	identifier = record
		name : refAlpha;				{ 名前 }
		idType : refStructure;			{ idの型 }
		level : integer;				{ スコープ・レベル }
		hashNext, next : refIdentifier;	{ ハッシュの次の要素 }
		hashValue : integer;			{ ハッシュ関数値 }
		labelValue : integer;			{ privateの場合のラベル値 }
		variableAddress : integer;		{ 引数になるのは   }
										{ 手続きもあり得る }
		idDeclareClass : declareClass;	{ private, public, extern }
		used : boolean;					{ 使用済みか否か }
		variableKind : idkind;			{ actual or formal }
		case klass : idClass of
			labels : (referenceLevel : integer;
				state : labelState);
			constants : (values : constant);
			vars : ();
			fields : (fieldAddress : integer;
				llink, rlink : refIdentifier);
			procedures, functions, units, programs : (paramp : refIdentifier;
				argumentSize : integer;
				case procOrFuncKind : declareKind of
					standard : (key : standardRoutines);
					declared : (forwardDec : boolean;
						externDec : boolean));

						(* 注意：externDecは *)
						(* 機械語という意味  *)

			types : ();	(* 空 *)
	end; { identifier }

	refScopeLink = ^scopeLink;
	scopeLink = record
		parentScope : refScopeLink;
		procedurep : refIdentifier;
		returnValue : refIdentifier
	end;

	argsLink = record
		next : refArgsLink;
		exp : refEvalTree;
		argKind : idKind
	end; { argsLink }

	withLink = record
		next : refWithLink;
		offset : integer;
		withVar : refIdentifier;
		topOfField : refIdentifier
	end;

	caseInformation = record
		caseValue : integer;
		caseLabel : integer;
		next : refCaseInformation
	end;

	evalTree = record
		evalType : refStructure;
		case nodeType : operatorKinds of
			opVariable, opIndirect : (
				varIndex : refEvalTree;
				hugeIndex : refEvalTree;
				constIndex : integer;
				case boolean of
					false : (var1 : refIdentifier);	{ 直接参照 }
					true : (ref1 : refEvalTree));	{ 間接参照 }
			opConstant : (const1 : refConstant);
			opProcedure, opFunction : (func : refIdentifier;
				args : refArgsLink;
				size : integer);
			operator : (op : operators;
				operand1, operand2 : refEvalTree);
			opRangeCheck : (expr : refEvalTree;
				minValue, maxValue : integer)
	end; { evalTree }

	refFileInfoSave = ^fileInfoSave;
	fileInfoSave = record
		next : refFileInfoSave;
		saveSym : symbol;
		saveLineNo : integer;
		saveC : char;
		saveCp : integer;
		saveRbuf : stringBuf;
		saveInFile : refText;
		saveFname : fileNameType;
		saveInclude : boolean
	end;

	localRootSaverType = record
		idSave : refIdentifier;
		labelsSave : refIdentifier;
		typeSave : refStructure
	end;

	(* コード生成用：ＣＰＵ依存 *)

	caseKind = 1..3;	(*  1 : ２分ジャンプ	     *)
						(*  2 : 定数と飛び先の組の表 *)
						(*  3 : テーブルジャンプ     *)
	caseLink = record
		jkind : caseKind;
		caseInformationPtr : refCaseInformation;
		labelOfCase, minValueOfCase, maxValueOfCase : integer;
		next : refCaseLink
	end;

	inSeg = (inNothing, inCode, inData, inBss);
	registers = (AXreg, BXreg, CXreg, DXreg, SIreg, DIreg, BPreg, SPreg, 
			DSreg, SSreg, ESreg, CSreg);

	regNameType = string[2];

var

	(* 記号 *)

	sym : symbol;	{ 現在のシンボル }
	id : alpha;		{ 現在の名前 }
	val : constant;	{ 最後の定数 }
	programOrUnitName : alpha;

	(* 字句 *)

	LineNo : integer;	{ 現在の行番号 }
	c : char;			{ 現在の文字 }
	cp : integer;		{ 現在の行中の文字の位置 }
	Rbuf : stringBuf;	{ 現在の行 }
	InFile : refText;
	fname : fileNameType;	{ 現在の入力ファイル名 }
	inFileName, OutFileName : fileNameType;
	include, ioCheck, rangeCheck : boolean;

	fileInfoSaveLink : refFileInfoSave;	{ 古いファイル名を記憶するリスト }
	currentLevel : integer;				{ 現在のレベル }
	OutFile : text;						{ 入出力ファイル }

	topOfScope : refScopeLink;
	currentRoutine : refIdentifier;		{ 現在コンパイル中の手続き }
	locationPtr : integer;				{ 現在のロケーション・カウンタ   }
	maxLocation : integer;				{ ロケーション・カウンタの最大値 }
	topOfWithLink : refWithLink;		{ with のリンクの先頭 }
	caseLabelsLink : refCaseLink;		{ caseのジャンプテーブルの先頭 }
	nErrors : array[errorKind] of integer;	{ エラーの個数 }
	errorExist : boolean;
	leaveLabel : integer;

	(* 標準の型 *)

	intPtr, bytePtr, realPtr, charPtr, stringPtr, boolPtr, controlPtr, 
			pointerPtr, textPtr : refStructure;

	(* 組込関数・手続きのポインタ *)

	startUpPtr, intToRealPtr, strcmpPtr, strcatPtr, readCharPtr,
	readIntPtr, readRealPtr, readStringPtr, writeCharPtr, writeIntPtr,
	writeRealPtr, writeStringPtr, writeBoolPtr, skipNlPtr, writeLnPtr,
	writeStringNewlineCheckPtr, flushOutPtr, newMemPtr, newHugeMemPtr,
	newMemWIthCheckPtr, disposeMemPtr, disposeHugeMemPtr, ioCheckerPtr,
	ioChecker2Ptr, stringCopy1Ptr, stringCopy2Ptr, rangeCheck1Ptr,
	rangeCheck2Ptr : refIdentifier;

	(* 組込変数 *)

	inputPtr, outputPtr : refIdentifier;

	(* 実行時に使用する補助変数：ＣＰＵ依存 *)

	stackFrameSaver, i8087Work1 : refIdentifier;

	(* 補助の表 *)

	symName : array[symbol] of string[14];	{ 予約語の印字名 }
	opkind : array[symbol] of operation;	{ シンボルとオペレーションの対応表 }
	(* 実行時オプション *)

	listp : boolean;						{ リスト出力を行う }
	generateDebuggingData : boolean;		{ デバッグ用出力を行う }
	debug : boolean;				{ コンパイラ自身のデバッグ出力を行う }
	jumpOptimization : boolean;		{ jmpのオプティマイズ }
	lsiR86 : boolean;				{ LSI-Japen のｒ８６を使用する }

	(* コード生成：ＣＰＵ依存 *)

	floatCall : boolean;
	diVariable : refIdentifier;
	isActive : array[registers] of boolean;
	regName : array[registers] of string[2];
	opName : array[operators] of string[6];
	condJmpName1, condJmpName2 : array[boolean, opLeq..opGrt] of string[5];

	(* デバッグ表示用の配列 *)

	idClassName : array[idClass] of string[12];
	formName : array[structureForm] of string[10];
	idKindName : array[idKind] of string[6];
	opKindName : array[operatorKinds] of string[10];
	opesName : array[operators] of string[4];

implementation

end.
