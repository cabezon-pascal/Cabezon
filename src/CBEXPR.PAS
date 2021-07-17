(* file = cbexpr.pas
 *
 * カベソンコンパイラ　：　式の構文解析
 *
 *
 * Copyright (C) 1990  Ockeghem
 *)

unit cbexpr;

interface
uses cbCom;

function argument : refArgsLink;
function call(ip : refIdentifier) : refEvalTree;
procedure checkArguments(p : refIdentifier; argu : refArgsLink);
procedure assignStatement(ip : refIdentifier);
function expression : refEvalTree;
function valueExpression(targetType : refStructure) : refEvalTree;
function getConst(var valueOfConst : constant) : refStructure;

implementation

uses cbeval, cbstd, cblex, cbtable, cberror, cbtype, cbdump, cballoc, 
		cbexgen1;

(* 関数：argument
 *
 * 目的：関数・手続きの引数について、構文木を作成する
 *
 * 引数：なし
 *
 * 戻り値：argument
 *)
function argument : refArgsLink;
var
	q : refEvalTree;
	firstArg, lastArg, arg : refArgsLink;
begin
	firstArg := nil;
	if sym = lparen then begin
		lastArg := nil;
		repeat
			getsym;	(* 左括弧またはコンマの読み飛ばし *)
			arg := newArgsLink;
			q := expression;
			with arg^ do begin
				exp := q;
				argKind := actual;	(* とりあえずactualにして、 *)
				next := nil			(* checkArgumentsで調整する *)
			end;
			if lastArg = nil then
				firstArg := arg
			else
				lastArg^.next := arg;
			lastArg := arg
		until sym <> comma;
		checkSym(rparen, disasters)
	end;
	argument := firstArg
end; { argument }

(* 手続き：checkArguments
 *
 * 目的：引数の型と個数をチェックする
 *
 * 引数：p : 関数・手続きのポインタ
 *	 argu : 引数の構文木
 *)
procedure checkArguments(p : refIdentifier; argu : refArgsLink);
var
	q : refEvalTree;
begin
	while p <> nil do begin
		if argu = nil then
			error(8, disasters);
		q := argu^.exp;
		with p^ do begin
			if variableKind = formal then begin	(* 変数引数 *)
				case q^.nodeType of
					opVariable, opIndirect:;
					otherwise
						errorName(5, 'argument:' + p^.name^, disasters)
				end;
				argu^.argKind := formal;	(* argumentではactual     *)
				if idType <> q^.evalType then	(* と設定しているので修正 *)
					errorType2(17, idType, q^.evalType, disasters)
			end else begin						(* 値引数 *)

				(* 値引数の場合は   *)
				(* 自動型変換を行う *)

				q := autoChangeType(q, idType);
				if not compatible(idType, q^.evalType) then
					errorType2(17, idType, q^.evalType, disasters);
				argu^.exp := q
			end
		end; { with p^ }
		p := p^.next;
		argu := argu^.next
	end;
	if argu <> nil then
		error(8, disasters)
end; { checkArguments }

(* 関数：call
 *
 * 目的：関数・手続きの呼出の処理を行う
 *
 * 引数：ip : 関数・手続きへのポインタ
 *	 k : 関数／手続きのどちらを処理するかの区別
 *
 * 戻り値：関数・手続き呼出の構文木
 *)
function call(ip : refIdentifier) : refEvalTree;
var
	e : refEvalTree;
	a : refArgsLink;
begin
	with ip^ do begin
		if (klass <> functions) and (klass <> procedures) then
			errorName(40, name^, disasters);
		if procOrFuncKind = standard then begin
			case key of
				readRn, readlnRn: e := readSt(key);
				writeRn, writelnRn: e := writeSt(key);
				chrRn: e := chrSt;
				ordRn: e := ordSt;
				absRn: e := absSt;
				newRn: e := newSt(ip);
				disposeRn: e := disposeSt(ip);
				resetRn, rewriteRn, closeRn: e := stdIO(ip);
				otherwise
					sysError('call')
			end { case }
		end else begin
			e := newEvalTree;
			with e^ do begin
				evalType := idType;
				if klass = functions then begin
					size := idType^.size;
					nodeType := opFunction
				end else begin
					size := 0;
					nodeType := opProcedure
				end;
				func := ip;
				args := argument;
				checkArguments(paramp, args)
			end
		end { if }
	end; { with }
	call := e
end; { call }

(* 関数：getConst
 *
 * 目的：定数の処理を行う
 *
 * 引数：valueOfConst : 定数の値
 *
 * 戻り値：定数の型
 *)
function getConst(var valueOfConst : constant) : refStructure;
var
	isMinus, isPlus : boolean;
	typeOfConst : refStructure;
	p : refIdentifier;
begin
	isMinus := false;
	isPlus := false;
	if sym = stringConst then begin
		typeOfConst := newStructure;
		with typeOfConst^ do begin
			stringSize := val.strgValuePtr^.length;
			size := stringSize + targetIntegerSize;
			alignmentUnit := targetCharAlign;
			form := stringConsts;
			stringElementType := charPtr
		end;
		val.labelValue := undefinedLabel;
		valueOfconst := val;
		valueOfConst.intValue := ord(val.strgValuePtr^[1]);
		getsym
	end else if sym = nilsym then begin
		with valueOfConst do begin
			new(strgValuePtr);
			strgValuePtr^ := 'nil'
		end;
		typeOfConst := pointerPtr;
		getsym
	end else begin
		if sym = plus then begin
			isPlus := true;
			getsym
		end else if sym = minus then begin
			isMinus := true;
			getsym
		end;
		if sym = intConst then begin
			with val do begin
				if isMinus then
					intValue := -intValue;
				typeOfConst := intPtr;
				valueOfConst := val
			end;
			getsym
		end else if sym = realConst then begin
			with val do begin
				if isMinus then
					strgValuePtr^[1] := '-';
				labelValue := undefinedLabel;
				typeOfConst := realPtr;
				valueOfConst := val
			end;
			getsym
		end else if sym = ident then begin
			p := searchId(id, disasters);
			getsym;
			with p^ do begin
				if klass <> constants then
					error(28, disasters);
				typeOfConst := idType;
				valueOfConst := values;
				if idType = intPtr then begin
					if isMinus then
						valueOfConst.intValue := -values.intValue
				end else if idType = realPtr then begin
					if isMinus then
						valueOFConst.strgValuePtr^[1] := '-'
				end else if isMinus or isPlus then
					error(32, disasters)
			end { with }
		end else
			error(28, disasters)
	end;
	getConst := typeOfConst
end; { getConst }

(* 関数：selector
 *
 * 目的：修飾を伴う変数の処理
 *
 * 引数：ip : 変数へのポインタ
 *
 * 戻り値：変数の構文木
 *)
function selector(ip : refIdentifier) : refEvalTree;
var
	p, q : refEvalTree;
	x : refIdentifier;

	(* 手続き：indexExpression
     *
     * 目的：配列の添字の処理を行う
     *
     * 引数：なし
     *)
	procedure indexExpression;
	var
		q, r, u : refEvalTree;
		sourceIndexType, elementType : refStructure;
		mi, ma, s, sz : integer;
		c : refConstant;
	begin
		with p^ do begin
			getsym;	(* [ の読み飛ばし *)
			repeat
				with evalType^ do begin
					case form of
						arrays: begin
								sourceIndexType := indexType;
(* maとszは       *)			elementType := arrayElementType;
(* 使用していない *)			boundOfType(indexType, mi, ma, sz)
							end;
						strings: begin
								sourceIndexType := intPtr;
								elementType := stringElementType;
								mi := 1	(* string の下限は１固定 *)
							end
						otherwise
							error2('array or string', disasters)
					end; { case }
					q := valueExpression(sourceIndexType);
					if not compatible(sourceIndexType, q^.evalType) then
						errorType2(34, sourceIndexType, q^.evalType, 
								   disasters);
					q := changeToInteger(q);
					s := elementType^.size;
					if isHuge then begin
						s := (s + 15) div 16;
						if mi <> 0 then
							q := makeTree2(minus, q, integerConstantNode(mi));
						if s <> 1 then
							q := makeTree2(mulsym, q, integerConstantNode(s));
						hugeIndex := q
					end else begin
						constIndex := constIndex - mi * s;
						if form = strings then
							constIndex := constIndex + targetIntegerSize;
						if s > 1 then
							q := makeTree2(mulsym, q, integerConstantNode(s));
						if isConstant(q) then begin
							constIndex := constIndex + q^.const1^.intValue;
							disposeConstEvalTree(q)
						end else if varIndex = nil then
							varIndex := q
						else
							varindex := makeTree2(plus, varIndex, q)
					end
				end; { with evalType^ }
				evalType := elementType
			until isNot(comma);
			checkSym(rbracket, disasters)
		end { with p^ }
	end; { indexExpression }

begin	{ selector }
	if ip^.klass = vars then
		p := variableNode(ip)
	else if ip^.klass = fields then
		with currentWithLink^ do begin
			p := variableNode(withVar);
			with p^ do begin
				constIndex := offset + ip^.fieldAddress;
				evalType := ip^.idType
			end
		end
	else
		error(5, disasters);
	while opkind[sym] = indexop do begin
		case sym of
			lbracket: indexExpression;
			period:
				with p^, evalType^ do begin
					getsym;	(* ピリオドの読みとばし *)
					checkId(disasters);
					case form of
						records: begin
								x := searchField(id, firstField);
								if x = nil then
									error(42, disasters);
								constIndex := constIndex + x^.fieldAddress;
								evalType := x^.idType
							end;
						strings: begin
								if id <> 'LENGTH' then
									error2('length', disasters);
								evalType := intPtr
							end;
						otherwise
							error2('record variable', disasters);
					end; { case }
					getsym	(* フィールド名の読み飛ばし *)
				end; { with p^, evalType^ }
			arrow: begin
					getsym;	(* ^の読みとばし *)
					with p^, evalType^ do begin
						if form <> pointers then
							error2('pointer variable', disasters);
						q := newVarEvalTree(elementTypeOfPointer);
						with q^ do begin
							nodeType := opIndirect;
							ref1 := p
						end
					end; { with }
					p := q
				end;
			otherwise
				sysError('selector');
		end { case }
	end; { while }
	selector := p
end; { selector }

(* 手続き：assignStatement
 *
 * 目的：代入文の処理を行う
 *
 * 引数：ip : 代入文の左辺の変数名へのポインタ
 *)
procedure assignStatement(ip : refIdentifier);
var
	x : refScopeLink;
	p : refEvalTree;
	saveLocationPtr : integer;	{ ロケーションポインタの保存用 }
begin
	saveLocationPtr := locationPtr;	{ ロケーションポインタを保存 }
	if ip^.klass = functions then begin
		x := topOfScope;
		while x^.procedurep <> ip do begin
			if x = nil then
				error(43, disasters);
			x := x^.parentScope
		end;
		ip := x^.returnValue
	end;

	p := selector(ip);
	if p^.evalType^.isHuge then
		error(58, errors);
	checkSym(becomes, disasters);
	p := makeTree2(becomes, p, valueExpression(p^.evalType));
	genExpression(p);
	locationPtr := saveLocationPtr	{ ロケーションポインタを復帰 }
end; { AssignStatement }

(* 関数：factor
 *
 * 目的：式の因子の処理を行う
 *
 * 引数：なし
 *
 * 戻り値：因子の構文木
 *)
function factor : refEvalTree;
var
	ip : refIdentifier;
	p : refEvalTree;
begin
	case sym of
		ident: begin
				ip := searchid(id, disasters);
				getsym;
				with ip^ do
					case klass of
						functions, procedures:
							(***	p := call(ip, functions);	***)
							p := call(ip);
						vars, fields: p := selector(ip);
						constants: begin
								p := newEvalTree;
								with p^ do begin
									nodeType := opConstant;
									const1 := newConstant;
									const1^ := values;
									evalType := idType
								end; (* 定数名の使用は	*)
								used := true	(* ここでないと分らない *)
							end;
						otherwise
							error2('variable or function', disasters);
					end { case klass }
			end; { ident: }
		intConst, realConst, stringConst: begin
				p := newEvalTree;
				with p^ do begin
					nodeType := opConstant;
					const1 := newConstant;
					evalType := getConst(const1^)
				end;
			end;
		lparen: begin
				getsym;
				p := expression;
				checkSym(rparen, disasters)
			end;
		lbracket: begin	(* 集合は構文解析のみ *)
				getsym;
				repeat
					p := expression;
					if sym = fromTo then begin
						getsym;
						p := expression
					end;
				until isNot(comma);
				checkSym(rbracket, disasters)
			end;
		notsym: begin
				getsym;
				p := makeTree1(notsym, factor)
			end;
		nilsym: begin
				getsym;
				p := newEvalTree;
				with p^ do begin
					nodeType := opConstant;
					evalType := pointerPtr;
					const1 := nil
				end
			end;
		otherwise
			error(7, disasters)
	end; { case }
	factor := p
end; { factor }

(* 関数：term
 *
 * 目的：式の項の処理を行う
 *
 * 引数：なし
 *
 * 戻り値：項の構文木
 *)
function term : refEvalTree;
var
	symSave : symbol;
	p, q : refEvalTree;
begin
	p := factor;
	while opkind[sym] = mulop do begin
		symSave := sym;
		getsym;
		q := factor;
		p := makeTree2(symSave, p, q)
	end;
	term := p
end; { term }

(* 関数：simpleExpression
 *
 * 目的：単純式の処理を行う
 *
 * 引数：なし
 *
 * 戻り値：単純式の構文木
 *)
function simpleExpression : refEvalTree;
var
	symSave : symbol;
	p, q : refEvalTree;
begin
	if (sym = plus) or (sym = minus) then begin
		symSave := sym;
		getsym;
		p := term;
		if symSave = minus then
			p := makeTree1(minus, p)
	end else
		p := term;
	while opkind[sym] = addop do begin
		symSave := sym;
		getsym;
		q := term;
		p := makeTree2(symSave, p, q)
	end;
	simpleexpression := p
end; { simpleExpression }

(* 関数：expression
 *
 * 目的：式の処理を行う
 *
 * 引数：なし
 *
 * 戻り値：式の構文木
 *)
function expression : refEvalTree;
var
	symSave : symbol;
	p, q : refEvalTree;
begin
	p := simpleExpression;
	if (opkind[sym] = relop) or (sym = becomes) then begin
		if sym = becomes then begin
			error(1, errors);
			sym := eql
		end;
		symSave := sym;
		getsym;
		q := simpleExpression;
		p := makeTree2(symSave, p, q)
	end;
	expression := p
end; { expression }

function valueExpression(targetType : refStructure) : refEvalTree;
var
	p, q : refEvalTree;
	n, min, max, dummy : integer;
begin
	p := autoChangeType(expression, boolPtr);
	if rangeCheck and (targetType <> nil) and (targetType <> intPtr) and 
			scalarType(targetType) then begin
		boundOfType(targetType, min, max, dummy);
		if isConstant(p) then begin
			n := p^.const1^.intValue;
			if (n < min) or (n > max) then
				error(54, errors)
		end else begin
			q := newEvalTree;
			with q^ do begin
				evalType := p^.evalType;
				nodeType := opRangeCheck;
				expr := p;
				minValue := min;
				maxValue := max
			end;
			p := q
		end
	end;
	valueExpression := p
end; { valueExpression }

end.
