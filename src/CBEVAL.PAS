(* file = cbeval.pas
 *
 * カベソンコンパイラ　：　式の型チェックと構文木の作成を行う。
 *
 *
 * Copyright (C) 1990, 91, 92  Ockeghem
 *)
unit cbeval;

interface
uses cbcom;

function isSimpleTerm(p : refEvalTree) : boolean;
function isLeftSideTerm(p : refEvalTree) : boolean;
function isEqualSubTree(p, q : refEvalTree) : boolean;
function isConstant(p : refEvalTree) : boolean;
function isTemporary(id : refIdentifier) : boolean;
function makeOpEvalNode(eType : refStructure; ope : operators;
					    op1, op2 : refEvalTree) : refEvalTree;
function variableNode(ip : refIdentifier) : refEvalTree;
function integerConstantNode(n : integer) : refEvalTree;
function changeType(u : refEvalTree; cType : refStructure) : refEvalTree;
function autoChangeType(sourcePtr : refEvalTree; 
						referType : refStructure) : refEvalTree;
function autoChangeType2(sourcePtr : refEvalTree; 
						 var resultType : refStructure; 
						 referType : refStructure) : refEvalTree;
function changeToInteger(p : refEvalTree) : refEvalTree;
function makeTree1(sy : symbol; p : refEvalTree) : refEvalTree;
function makeTree2(sy : symbol; p, q : refEvalTree) : refEvalTree;
function evalNodeSize(p : refEvalTree) : integer;

implementation

uses cbtype, cbdump, cberror, cballoc, cbstd;

(* 関数：isSimpleTerm
 *
 * 目的：単純な項（単純変数か定数）かどうかを判定する
 *
 * 引数：p：式
 *
 * 戻り値：単純な変数ならtrue、さもなければfalse
 *)
function isSimpleTerm(p : refEvalTree) : boolean;
begin
	isSimpleTerm := (p <> nil) and 
					((p^.nodeType = opVariable) and 
					 (p^.varIndex = nil) and (p^.hugeIndex = nil) or 
					 (p^.nodeType = opConstant))
end; { isSimpleTerm }

(* 関数：isLeftSideTerm
 *
 * 目的：左辺値になりうるかどうかを判定する
 *
 * 引数：p：式
 *
 * 戻り値：単純な変数ならtrue、さもなければfalse
 *)
function isLeftSideTerm(p : refEvalTree) : boolean;
begin
	case p^.nodeType of
		opVariable, opIndirect: isLeftSideTerm := true;
		otherwise
			isLeftSideTerm := false
	end
end; { isLeftSideTerm }

(* 関数：isConstant
 *
 * 目的：式が定数かどうかを判定する
 *
 * 引数：p：式
 *
 * 戻り値：定数ならtrue、さもなければfalse
 *)
function isConstant(p : refEvalTree) : boolean;
begin
	isConstant := (p <> nil) and (p^.nodeType = opConstant)
end; { isConstant }

function makeOpEvalNode(eType : refStructure; ope : operators;
					    op1, op2 : refEvalTree) : refEvalTree;
var
	t : refEvalTree;
begin
	t := newEvalTree;
	with t^ do begin
		evalType := eType;
		nodeType := operator;
		op := ope;
		operand1 := op1;
		operand2 := op2
	end;
	makeOpEvalNode := t
end; { makeOpEvalNode }

(* 関数：variableNode
 *
 * 目的：変数のポインタを与えて、構文木のノードを作成する
 *
 * 引数：ip : 変数のポインタ
 *
 * 戻り値：変数の構文木
 *)
function variableNode(ip : refIdentifier) : refEvalTree;
var
	p : refEvalTree;
begin
	p := newVarEvalTree(ip^.idType);
	with ip^, p^ do begin
		if variableKind = formal then begin	{ 変数引数の処理 }
			nodeType := opIndirect;
			ref1 := newVarEvalTree(pointerPtr);
			with ref1^ do begin
				nodeType := opVariable;
				var1 := ip
			end
		end else begin
			nodeType := opVariable;
			var1 := ip
		end { if }
	end; { with ip^, p^ }
	variableNode := p
end; { variableNode }

function isTemporary(id : refIdentifier) : boolean;
begin
	isTemporary := id^.name^[1] = '@';
end;

function isEqualSubTree(p, q : refEvalTree) : boolean;
begin
	if p = q then
		isEqualSubTree := true
	else if (p = nil) or (q = nil) then
		isEqualSubTree := false
	else if p^.nodeType <> q^.nodeType then
		isEqualSubTree := false
	else
		case p^.nodeType of
			opVariable:
				isEqualSubTree := (p^.var1 = q^.var1) and 
								  (p^.constIndex = q^.constIndex) and 
								  isEqualSubTree(p^.varIndex, q^.varIndex) and
								  isEqualSubTree(p^.hugeIndex, q^.hugeIndex);
			opIndirect:
				isEqualSubTree := (p^.constIndex = q^.constIndex) and
								  isEqualSubTree(p^.ref1, q^.ref1) and
								  isEqualSubTree(p^.varIndex, q^.varIndex) and
								  isEqualSubTree(p^.hugeIndex, q^.hugeIndex);
			opConstant:
				isEqualSubTree := (p^.evalType = q^.evalType) and 
								  isSimpleType(p^.evalType) and 
								  (p^.const1^.intvalue = q^.const1^.intValue);
			opProcedure, opFunction:
				isEqualSubTree := false;
			operator: 
				isEqualSubTree := (p^.op = q^.op) and 
								  isEqualSubTree(p^.operand1, q^.operand1) and
								  isEqualSubTree(p^.operand2, q^.operand2);
			opRangeCheck:
				isEqualSubTree := false;
			otherwise
				sysError('isEqualSubTree')
		end { case }
end; { isEqualSubTree }

(* 関数：integerConstantNode
 *
 * 目的：整数の定数の構文木のノードを作成する
 *
 * 引数：n：整数値
 *
 * 戻り値：定数の構文木
 *)
function integerConstantNode(n : integer) : refEvalTree;
var
	u : refEvalTree;
	c : refConstant;
begin
	c := newConstant;	(* 新しい定数を作る *)
	with c^ do begin
		strgValuePtr := nil;
		intValue := n
	end;

	u := newEvalTree;	(* 定数のノードを作成する *)
	with u^ do begin
		evalType := intPtr;
		nodeType := opConstant;
		const1 := c
	end;
	integerConstantNode := u
end; { integerConstantNode }

function changeType(u : refEvalTree; cType : refStructure) : refEvalTree;
begin
	if isConstant(u) and scalarType(u^.evalType) and scalarType(cType) then 
			begin
		u^.evalType := cType;
		changeType := u
	end else
		changeType := makeOpEvalNode(cType, opCast, u, nil);
end; { changeType }

(* 関数：autoChangeType
 *
 * 目的：代入文と値引数の場合の、自動型変換を行う
 *
 * 引数：sourcePtr : 元の構文木
 *	 referType : 参照している型（この型に合わせる）
 *
 * 戻り値：型変換を含む構文木
 *)
function autoChangeType(sourcePtr : refEvalTree; 
						referType : refStructure) : refEvalTree;
var
	sourceType : refStructure;
begin
	sourceType := originalType(sourcePtr^.evalType);
	referType := originalType(referType);

	if sourceType = bytePtr then begin
		if referType = intPtr then
			sourcePtr := changeType(sourcePtr, intPtr)
		else if referType = realPtr then
			sourcePtr := changeType(changeType(sourcePtr, intPtr), realPtr)
	end else if sourceType = intPtr then begin
		if referType = bytePtr then
			sourcePtr := changeType(sourcePtr, bytePtr)
		else if referType = realPtr then
			sourcePtr := changeType(sourcePtr, realPtr)
	end else if sourceType = controlPtr then begin
		if referType = boolPtr then
			sourcePtr := changeType(sourcePtr, boolPtr)
	end else if (sourceType^.form = stringConsts) and (referType = charPtr) 
			then begin
		if (sourceType^.stringElementType = charPtr) and (sourceType^.
				stringSize = 1) then
			sourcePtr^.evalType := charPtr
	end;
	autoChangeType := sourcePtr
end; { autoChangeType }

(* 関数：autoChangeType2
 *
 * 目的：演算時の自動型整合を行う（型の大きい方にのみあわせる）
 *
 * 引数：sourcePtr  : 元の構文木
 *	 resuleType : 型変換後の型
 *	 referPtr   : 演算の相手の型（この型に合わせる）
 *
 * 戻り値：型変換を含む構文木
 *)
function autoChangeType2(sourcePtr : refEvalTree; 
						 var resultType : refStructure;
						 referType : refStructure) : refEvalTree;
var
	sourceType : refStructure;
begin
	sourceType := originalType(sourcePtr^.evalType);
	referType := originalType(referType);

	if sourceType = bytePtr then begin
		if referType = intPtr then
			sourcePtr := changeType(sourcePtr, intPtr)
		else if referType = realPtr then
			sourcePtr := changeType(changeType(sourcePtr, intPtr), realPtr)
	end else if sourceType = intPtr then begin
		if referType = realPtr then
			sourcePtr := changeType(sourcePtr, realPtr)
	end else if sourceType = boolPtr then begin
		if referType = controlPtr then
			sourcePtr := changeType(sourcePtr, controlPtr)
	end else if sourceType = controlPtr then begin
		if referType = boolPtr then
			sourcePtr := changeType(sourcePtr, boolPtr)
	end else if (sourceType^.form = stringConsts) and (referType = charPtr) 
			then begin
		if (sourceType^.stringElementType = charPtr) and (sourceType^.
				stringSize = 1) then
			sourcePtr^.evalType := charPtr
	end;
	resultType := originalType(sourcePtr^.evalType);
	autoChangeType2 := sourcePtr
end; { autoChangeType2 }

(* 関数：matchTypes
 *
 * 目的：演算時の相互の型整合を行う（型の大きい方にのみあわせる）
 *
 * 引数：p  : 元の構文木
 *		 q  :
 *		 type1 : 型変換後の型
 *		 type2 : 
 *)
procedure matchTypes(var p, q : refEvalTree; var type1, type2 : refStructure);
begin
	p := autoChangeType2(p, type1, type2);
	q := autoChangeType2(q, type2, type1)
end;

(* 関数：changeToInteger
 *
 * 目的：式がスカラー型かどうかチェックして、整数型に変換する。
 *
 * 引数：式のポインタ
 *
 * 戻り値：作成した構文木
 *)
function changeToInteger(p : refEvalTree) : refEvalTree;
begin
	with p^ do begin
		if not scalarType(evalType) then
			error(39, errors);
		if evalType^.form = stringConsts then	(* 文字定数なら *)
			p := autoChangeType(p, charPtr);	(* 文字型にする *)

		if evalType^.size = targetByteSize then begin
			evalType := bytePtr;				(* 必要であれば *)
			p := changeType(p, intPtr);			(* 整数型に変換 *)
		end else
			evalType := intPtr
	end; { with p^ }
	changeToInteger := p
end; { changeToInteger }

(* 関数：foldExpression1
 *
 * 目的：単項演算の定数の畳み込み演算を行う
 *
 * 引数：opr : 演算子
 *	 x   : 被演算数
 *
 * 戻り値：定数演算の結果
 *)
function foldExpression1(opr : operators; x : integer) : integer;
begin
	case opr of
		opNeg: foldExpression1 := -x;
		opNot: foldExpression1 := 1 - x;	{ 0 ←→ 1 }
		otherwise
			sysError('foldExpression1');
	end;
end; { foldExpression1 }

(* 関数：foldExpression2
 *
 * 目的：２項演算の定数の畳み込み演算を行う
 *
 * 引数：opr : 演算子
 *	 x, y  : 被演算数
 *
 * 戻り値：定数演算の結果
 *)
function foldExpression2(opr : operators; x, y : integer) : integer;
begin
	case opr of
		opAdd: foldExpression2 := x + y;
		opSub: foldExpression2 := x - y;
		opMul: foldExpression2 := x * y;
		opDiv: foldExpression2 := x div y;
		opMod: foldExpression2 := x mod y;
		opAnd: foldExpression2 := x and y;
		opOr: foldExpression2 := x or y;
		opXor: foldExpression2 := x xor y;
		opCmp: sysError('foldExpression2-1');
		opLeq: foldExpression2 := ord(x <= y);
		opLss: foldExpression2 := ord(x < y);
		opEql: foldExpression2 := ord(x = y);
		opNeq: foldExpression2 := ord(x <> y);
		opGeq: foldExpression2 := ord(x >= y);
		opGrt: foldExpression2 := ord(x > y);
		otherwise
			sysError('foldExpression2-2');
	end
end; { foldExpression2 }

(* 関数：makeTree1
 *
 * 目的：１項演算子から構文木を作成する
 *
 * 引数：sy : 演算子
 *	 p  : 第１オペランド
 *
 * 戻り値：作成した部分木
 *)
function makeTree1(sy : symbol; p : refEvalTree) : refEvalTree;
var
	type1 : refStructure;
	opr : operators;
begin
	type1 := originalType(p^.evalType);

	case sy of
		minus: begin
				if (type1 = bytePtr) or (type1 = intPtr) or (type1 = realPtr) 
						then
					opr := opNeg
				else
					errorType1(39, type1, errors)
			end;
		notsym: begin
				if (type1 = boolPtr) or (type1 = controlPtr) or (type1 = 
						bytePtr) or (type1 = intPtr) then
					opr := opNot
				else
					errorType1(39, type1, errors)
			end;
		otherwise
			sysError('makeTree1')
	end; { case }

	if scalarType(type1) and isConstant(p) then begin
		p^.const1^.intValue := foldExpression1(opr, p^.const1^.intValue);
		makeTree1 := p
	end else
		makeTree1 := makeOpEvalNode(type1, opr, p, nil);
end; { makeTree1 }

(* 関数：makeTree2
 *
 * 目的：２項演算子から構文木を作成する
 *
 * 引数：sy : 演算子
 *	 p  : 第１オペランド
 *	 q  : 第２オペランド
 *
 * 戻り値：作成した部分木
 *)
function makeTree2(sy : symbol; p, q : refEvalTree) : refEvalTree;
label 9;
var
	t : refEvalTree;
	type1, type2, treeType : refStructure;
	opr : operators;
begin
	type1 := originalType(p^.evalType);
	type2 := originalType(q^.evalType);

	case sy of
		plus, minus, mulsym: begin
				matchTypes(p, q, type1, type2);		(* 相手の型に合わせる *)
				p := autoChangeType2(p, type1, intPtr);	(* バイト→ワード *)
				q := autoChangeType2(q, type2, intPtr);
				if not compatible(type1, type2) then
					errorType2(38, type1, type2, errors);
				if (type1 <> bytePtr) and (type1 <> intPtr) and (type1 <> 
						realPtr) then begin
					if ((type1^.form = strings) or 
								(type1^.form = stringConsts)) and 
							(sy = plus) then begin
						t := strcatSt(p, q);
						goto 9
					end else
						errorType1(39, type1, errors)
				end;
				case sy of
					plus: opr := opAdd;
					minus: opr := opSub;
					mulsym: opr := opMul
				end; { case }
				treeType := type1
			end;
		leq, lss, eql, neq, geq, grt: begin
				p := autoChangeType2(p, type1, boolPtr);
				q := autoChangeType2(q, type2, boolPtr);
				matchTypes(p, q, type1, type2); (* 相手の型に合わせる *)
				if not compatible(type1, type2) then
					errorType2(38, type1, type2, errors);
				with type1^ do begin
					if (form = scalars) and 
						((scalarKind = declared) or (type1 = charPtr)) then
						case size of
							targetByteSize:
								type1 := bytePtr;
							targetIntegerSize:
								type1 := intPtr
						end { case }
				end; { with }
				with type1^ do begin
					case form of
						strings, stringConsts: 
							if stringElementType = charPtr then
								type1 := stringPtr
							else
								errorType1(39, type1, errors);
						pointers: if (sy = eql) or (sy = neq) then
								type1 := pointerPtr
							else
								errorType1(39, type1, errors);
						arrays, records, files:

							(* array of charだけは比較の対象にすべきである *)
							(* のだが、怠っている					       *)

							errorType1(39, type1, errors);
						powers: sysError('makeTree2-1');
					end; { case }
				end; { with }
				case sy of
					leq: opr := opLeq;
					lss: opr := opLss;
					eql: opr := opEql;
					neq: opr := opNeq;
					geq: opr := opGeq;
					grt: opr := opGrt
				end;
				if scalarType(type1) and isConstant(p) and isConstant(q) 
						then begin
					p^.const1^.intValue := foldExpression2(opr, p^.const1^.
							intValue, q^.const1^.intValue);
					p^.evalType := boolPtr;
					t := p;
					disposeConstEvalTree(q);
					goto 9
				end else begin
					p := makeOpEvalNode(type1, opCmp, p, q);
					q := nil;
					treeType := controlPtr
				end
			end;
		divsym, modsym: begin
				p := autoChangeType2(p, type1, intPtr);	(* バイト→ワード *)
				q := autoChangeType2(q, type2, intPtr);
				if type1 <> type2 then
					errorType2(38, type1, type2, errors);
				if type1 <> intPtr then
					errorType1(39, type1, errors);
				if sy = divsym then
					opr := opDiv
				else
					opr := opMod;
				treeType := type1
			end;
		rdiv: begin
				p := autoChangeType2(p, type1, realPtr);
				q := autoChangeType2(q, type2, realPtr);
				if type1 <> type2 then
					errorType2(38, type1, type2, errors);
				if type1 = realPtr then
					opr := opDiv
				else
					errorType1(39, type1, errors);
				treeType := type1	(* 現状では、realPtrのみ *)
			end;
		andsym, orsym, xorsym: begin
				matchTypes(p, q, type1, type2);
				if sy = xorsym then begin
					p := autoChangeType2(p, type1, boolPtr);
					q := autoChangeType2(q, type2, boolPtr)
				end else begin
					p := autoChangeType2(p, type1, controlPtr);
					q := autoChangeType2(q, type2, controlPtr)
				end;
				if type1 <> type2 then
					errorType2(38, type1, type2, errors);
				if (type1 <> controlPtr) and (type1 <> boolPtr) and (type1 
						<> bytePtr) and (type1 <> intPtr) then
					errorType1(39, type1, errors);
				case sy of
					andsym: opr := opAnd;
					orsym: opr := opOr;
					xorsym: opr := opXor
				end;
				treeType := type1
			end;
		becomes: begin
				q := autoChangeType(q, type1);
				type2 := q^.evalType;
				if not compatible(type1, type2) then
					errorType2(38, type1, type2, errors);
				opr := opMoveTo;
				treeType := type1
			end;
		otherwise
			sysError('makeTree2-2')
	end; { case sy }

	if scalarType(treeType) and isConstant(p) and isConstant(q) then begin
		p^.const1^.intValue := foldExpression2(opr, p^.const1^.intValue, q^.
				const1^.intValue);
		t := p;
		if treeType = controlPtr then
			t^.evalType := boolPtr;
		disposeConstEvalTree(q)
	end else
		t := makeOpEvalNode(treeType, opr, p, q);
 9: makeTree2 := t
end; { makeTree2 }

function evalNodeSize(p : refEvalTree) : integer;
begin
	with p^ do begin
		case nodeType of
			opVariable, opIndirect, operator: evalNodeSize := evalType^.size;
			opConstant: case evalType^.form of
					strings, stringConsts: evalNodeSize := const1^.
							strgValuePtr^.length + targetIntegerSize;
					otherwise
						evalNodeSize := evalType^.size;
				end;
			opProcedure, opFunction: evalNodeSize := size;
			otherwise
				sysError('evalNodeSize')
		end { case }
	end { with }
end;

end.
