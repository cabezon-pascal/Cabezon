(* file = cbstate.pas
 *
 * カベソンコンパイラ　：　文の処理
 *
 *
 * Copyright (C) 1990  Ockeghem
 *)

unit cbstate;

interface
uses cbcom;
var
	nestLevel : integer;

procedure blockStatementList;

implementation

uses cballoc, cberror, cblex, cbtype, cbtable, cbexpr, cbdump, cbeval,
	 cbgen1, cbgen3, cbgen4, cbexgen1, cbexgen2, cblabel;

procedure statement; forward;

procedure StatementList;
begin
	statement;
	while sym = semicolon do begin
		getsym;
		statement
	end
end;

procedure labelFlush1;
var
	p : refIdentifier;
begin
	p := localRootOfLabels;
	while p <> nil do
		with p^ do begin
			if referenceLevel = nestLevel then
				case state of
					forwardDeclared: begin
							labelDeclared := true;
							referenceLevel := referenceLevel - 1
						end;
					defined: state := finished;
				end; { case }
			p := next
		end { with p^ }
end; { labelFlush1 }

procedure blockStatement;
var
	labelDeclaredSave : boolean;
begin
	labelDeclaredSave := labelDeclared;
	labelDeclared := false;
	nestLevel := nestLevel + 1;

	statement;

	if labelDeclared then begin
		labelDeclared := labelDeclaredSave;
		labelFlush1
	end else
		labelDeclared := labelDeclaredSave;
	nestLevel := nestLevel - 1
end; { blockStatement }

procedure blockStatementList;
var
	labelDeclaredSave : boolean;
begin
	labelDeclaredSave := labelDeclared;
	labelDeclared := false;
	nestLevel := nestLevel + 1;

	statementList;

	if labelDeclared then begin
		labelDeclared := labelDeclaredSave;
		labelFlush1
	end else
		labelDeclared := labelDeclaredSave;
	nestLevel := nestLevel - 1
end; { blockStatementList }

procedure ifStatement;
var
	L1 : integer;
	p : refEvalTree;
begin
	getsym;	(* ifの読み飛ばし *)
	L1 := genLabel(2);
	p := expression;
	if debug then
		dumpEvalTree(p);
	genCondition(p, L1);
	checkSym(thensym, errors);
	blockStatement;
	if sym = elsesym then begin
		getsym;
		genJump(L1 + 1);
		outLabel2(L1);
		blockStatement;
		outLabel2(L1 + 1)
	end else
		outLabel2(L1)
end; { ifStatement }

procedure whileStatement;
var
	L1 : integer;
	saveLeaveLabel : integer;
begin
	getsym;	(* whileの読み飛ばし *)
	L1 := genLabel(2);
	saveLeaveLabel := leaveLabel;
	leaveLabel := L1 + 1;
	outLabel2(L1);
	genCondition(expression, L1 + 1);
	checkSym(dosym, errors);
	blockStatement;
	genJump(L1);
	outLabel2(L1 + 1);
	leaveLabel := saveLeaveLabel
end; { WhileStatement }

procedure repeatStatement;
var
	p : refEvalTree;
	L1 : integer;
	saveLeaveLabel : integer;
begin
	L1 := genLabel(2);
	saveLeaveLabel := leaveLabel;
	leaveLabel := L1 + 1;
	getsym;	(* repeatの読み飛ばし *)
	outLabel2(L1);
	blockStatementList;
	checkSym(untilsym, disasters);
	genCondition(expression, L1);
	outLabel2(L1 + 1);
	leaveLabel := saveLeaveLabel
end; { RepeatStatement }

procedure forStatement;
var
	saveLocationPtr, L1 : integer;
	minValue, maxValue, sizeOfType : integer;
	ip, iq : refIdentifier;
	cp, cq, p1, p2 : refEvalTree;
	tp : refStructure;
	toOrDownto : symbol;
	saveLeaveLabel : integer;
begin
	saveLocationPtr := locationPtr;
	L1 := genLabel(2);
	saveLeaveLabel := leaveLabel;
	leaveLabel := L1 + 1;
	getsym;	(* forの読み飛ばし *)
	checkId(disasters);
	ip := searchId(id, disasters);
	getsym;

	with ip^ do begin
		if klass <> vars then
			error2('variable', disasters);
		if level <> currentLevel then
			error(45, errors);
		if not scalarType(idType) then
			errorType1(29, idType, errors);
		cp := variableNode(ip);
		iq := temporaryVariable(idType);
		cq := variableNode(iq)
	end;

	case sym of
		becomes, eql: begin
				checkSym(becomes, disasters);
				p1 := autoChangeType(expression, ip^.idType);
				if ip^.idType <> p1^.evalType then
					error(50, errors);
				toOrDownto := sym;
				if (sym = tosym) or (sym = downtosym) then
					getsym
				else
					error2('"to" or "downto"', disasters);
				p2 := autochangeType(expression, ip^.idType);
				if ip^.idType <> p2^.evalType then
					error(50, errors)
			end;
		everysym: begin
				getsym;	(* everyの読み飛ばし *)
				checkId(disasters);
				tp := checkType(id);
				getsym;	(* 型名の読み飛ばし *)
				if ip^.idType <> tp then
					error(50, errors);
				boundOfType(ip^.idType, minValue, maxValue, sizeOftype);
				p1 := integerConstantNode(minValue);
				p2 := integerConstantNode(maxValue);
				toOrDownto := tosym
			end;
		otherwise
			error2('":=" or "every"', disasters);
	end; { case }

	genFor1(p1, p2, cp, cq, toOrDownto, L1);

	if sym = dosym then
		getsym
	else
		error2('do', errors);
	outLabel2(L1);	(* ループの入口のラベル *)
	blockStatement;
	genFor2(cp, cq, toOrDownto, L1);
	outLabel2(L1 + 1);	(* ループの出口のラベル *)
	disposeEvalTree(cp);
	disposeEvalTree(cq);
	disposeIdentifier(iq);
	locationPtr := saveLocationPtr;
	leaveLabel := saveLeaveLabel
end; { ForStatement }

procedure caseStatement;
var
	L1, Lx : integer;
	caseMax, caseMin : integer;
	value : constant;
	v : integer;
	numOfCase : integer;
	exitLoop : boolean;
	Ltype, caseType : refStructure;
	p : refEvalTree;
	root : refCaseInformation;

	procedure dumpCaseLabel(p : refCaseInformation);
	begin
		while p <> nil do begin
			with p^ do
				writeln('v = ', caseValue:7, '  L = ', caseLabel:7);
			p := p^.next
		end
	end; { DumpCaseLabel }

	procedure InsertCaseLabel(var cp : refCaseInformation; v, L : integer);
	var
		cp3 : refCaseInformation;
	begin
		cp3 := newCaseInformation;
		with cp3^ do begin
			caseValue := v;
			caseLabel := L;
			next := cp
		end;
		cp := cp3
	end;

	procedure setNewCaseLabel(v, L : integer);
	var
		cp1, cp2 : refCaseInformation;
	begin
		if (root = nil) or (root^.caseValue > v) then
			InsertCaseLabel(root, v, L)
		else if root^.next = nil then
			with root^ do
				if caseValue = v then
					error(20, errors)
				else
					InsertCaseLabel(next, v, L)
		else begin
			cp2 := root;
			cp1 := cp2^.next;
			while (cp1^.caseValue < v) and (cp1^.next <> nil) do begin
				cp2 := cp1;
				cp1 := cp2^.next
			end;
			if cp1^.caseValue = v then
				error(20, errors)
			else begin
				if cp1^.caseValue < v then begin
					cp2 := cp1;
					cp1 := nil
				end;
				InsertCaseLabel(cp2^.next, v, L)
			end
		end
	end; { setNewCaseLabel }

begin
	getsym;	(* "case" の読みとばし *)

	{ ４個のラベルを生成 : L1   .. テーブルジャンプに飛ぶためのラベル	}
	{			 : L1+1 .. else節のためのラベル 		}
	{			 : L1+2 .. 処理後にジャンプするためのラベル	}
	{			 : L1+3 .. ジャンプテーブルの名前		}

	L1 := genLabel(4);
	p := expression;
	caseType := p^.evalType;
	p := changeToInteger(p);
	checkSym(ofsym, errors);
	genJump(L1);

	root := nil;
	caseMax := targetMinInt;
	numOfCase := 0;

	exitLoop := false;
	repeat
		Lx := genLabel(1);	(* 各ケースのラベルを準備 *)
		repeat
			Ltype := getConst(value);
			if not compatible(caseType, Ltype) then
				error(34, errors);
			v := value.intValue;
			setNewCaseLabel(v, Lx);
			numOfCase := numOfCase + 1;
			if v > CaseMax then
				CaseMax := v
		until isNot(comma);
		checkSym(colon, errors);
		outLabel2(Lx);	(* 各ケースのラベルを生成 *)
		blockStatement;
		genJump(L1 + 2);	(* caseの末尾に飛ぶjmp *)
		if sym = semicolon then begin
			getsym;
			case sym of
				otherwisesym, endsym: exitLoop := true
			end
		end else
			exitLoop := true
	until exitLoop;

	caseMin := root^.caseValue;
	if debug then
		dumpCaseLabel(root);
	outLabel2(L1);
	genExpression(p);
	genCase(root, L1, caseMin, caseMax, numOfCase);	(* テーブルジャンプ *)
	outLabel2(L1 + 1);	(* otherwise節のラベルを生成 *)
	if sym = otherwisesym then begin
		getsym;
		blockStatement;
		if sym = semicolon then
			getsym
	end;
	checkSym(endsym, errors);

	outLabel2(L1 + 2)
end; { caseStatement }

procedure withStatement;
var
	i, n, saveLocationPtr : integer;
	iq : refIdentifier;
	rt : refStructure;
	p, cq : refEvalTree;
	x : refWithLink;
begin
	n := 0;	(* n : with文に現れる構造体式の数 *)
	saveLocationPtr := locationPtr;
	repeat
		getsym;	(* with またはコンマの読み飛ばし *)
		n := n + 1;
		p := expression;
		if debug then
			dumpEvalTree(p);
		with p^ do begin
			rt := evaltype;
			if rt^.form <> records then
				error(46, errors);
			x := newWithLink;
			with x^ do begin
				if (nodeType = opVariable) and (varIndex = nil) and 
						(hugeIndex = nil) then begin
					withVar := newIdentifier;
					withVar^ := p^.var1^;
					p^.var1^.used := true;	(* 使用済みとする *)
					offset := constIndex;
					disposeEvalTree(p)
				end else begin
					iq := temporaryVariable(pointerPtr);
					cq := variableNode(iq);
					withVar := iq;
					iq^.variableKind := formal;
					offset := 0;
					loadAddr(p);
					genSaveAddr(cq);
					disposeEvalTree(cq);

(***** @@@ *****
			writeln('with name = ', iq^.name^);
			writeln('with addr = ', iq^.variableAddress);
(***** @@@ *****)

					diVariable := iq
				end;
				next := topOfWithLink;
				topOfField := rt^.firstField
			end
		end;
		topOfWithLink := x
	until sym <> comma;
	checkSym(dosym, errors);
	blockStatement;
	for i := 1 to n do begin	(* withのリンクをはがす *)
		x := topOfWithLink;
		disposeIdentifier(x^.withVar);
		topOfWithLink := topOfWithLink^.next;
		disposeWithLink(x)
	end;
	locationPtr := saveLocationPtr
end; { withStatement }

procedure gotoStatement;
var
	p : refIdentifier;
begin
	getsym;	(* gotoの読み飛ばし *)
	if sym = intConst then
		with val do begin
			if (intValue < 0) or (intValue > 9999) then
				error(18, errors);
			str(intValue, id)
		end else if sym <> ident then
		error2('number or identifier', disasters);
	p := searchId(id, errors);
	if p <> nil then begin
		with p^ do begin
			case state of
				undefined: begin
						referenceLevel := nestLevel;
						state := forwardDeclared;
					end;
				forwardDeclared: if referenceLevel > nestLevel then
						referenceLevel := nestLevel;
				defined:;
				finished: error(48, errors);
				otherwise
					sysError('gotoStatement')
			end;
			genGoto(p)
		end;
		labelDeclared := true
	end;
	getsym	(* ラベルの読み飛ばし *)
end; { gotoStatement }

procedure leaveStatement;
begin
	getsym;
	if leaveLabel = undefinedLabel then
		error(65, errors)
	else
		genJump(leaveLabel)
end; { leaveStatement }

procedure returnStatement;
var
	p : refEvalTree;
begin
	getsym;
	with currentRoutine^ do begin
		if klass = functions then begin
			p := autoChangeType(valueExpression(idType), idType);
			if not compatible(p^.evalType, idType) then
				error(34, errors);
		end else
			p := nil;
		genReturnStatement(p)
	end
end; { returnStatement }

procedure statement;
var
	idSave : alpha;
	ip : refIdentifier;

	procedure labelDefinition;
	var
		ip : refIdentifier;
	begin
		ip := searchSection(idSave);
		if ip <> nil then
			with ip^ do begin
				case state of
					undefined: state := defined;
					forwardDeclared: begin
							state := defined;
							if referenceLevel < nestLevel then
								error(48, errors)
						end;
					otherwise
						error(47, errors)
				end;
				referenceLevel := nestLevel;
				outLabel2(labelValue)
			end else
			errorName(3, idSave, errors);
		labelDeclared := true;
		getsym
	end; { labelDefinition }

	procedure idStatement;
	var
		e : refEvalTree;
	begin
		case sym of
			lparen, elsesym, endsym, untilsym, semicolon: begin
					(* 左括弧か、文の終りであれば手続き。  *)
					(* otherwise の前には必ずセミコロンが  *)
					(* あるはずなので、上記に加えていない。*)
					e := call(ip);
					if (e <> nil) and (e^.evaltype <> nil) then
						error(41, errors);
					genExpression(e)
				end
			otherwise	(* その他であれば、代入文を仮定 *)
				assignStatement(ip)
		end
	end; { idStatement }

	procedure statementBody;
	begin
		case sym of	(* 文の先頭の記号で分岐 *)
			ident: begin
					ip := searchId(id, disasters);	(* 名前を保存 *)
					getsym;							(* 一記号先読み *)
					idStatement;					(* 名前で始まる場合 *)
				end;
			beginsym: begin
					getsym;
					statementList;
					checkSym(endsym, disasters)
				end;
			casesym: caseStatement;
			whilesym: whileStatement;
			repeatsym: repeatStatement;
			ifsym: ifStatement;
			forsym: forStatement;
			withsym: withStatement;
			gotosym: gotoStatement;
			leavesym: leaveStatement;
			returnsym: returnStatement;
			otherwise	(* 空文 *)
		end
	end; { statementBody }

begin

	if generateDebuggingData then
		genDebugLineNo;

	{ ラベルの処理 }

	if sym = ident then begin
		idSave := id;
		getsym;
		if sym = colon then begin
			labelDefinition;
			statementBody
		end else begin
			ip := searchId(idSave, disasters);
			idStatement
		end
	end else begin
		if sym = intConst then begin
			with val do begin
				if (intValue < 0) or (intValue > 9999) then
					error(18, errors);
				str(intValue, idSave)
			end;
			labelDefinition;
			checkSym(colon, disasters)
		end;
		statementBody	(* 文本体の処理 *)
	end;
end; { statement }

end.
