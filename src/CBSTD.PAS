(* file = cbstd.pas
 *
 * カベソンコンパイラ　：　組込手続き／関数
 *
 *
 * Copyright (C) 1990  Ockeghem
 *)

unit cbstd;

interface
uses cbcom;

function readSt(k : standardRoutines) : refEvalTree;
function writeSt(k : standardRoutines) : refEvalTree;
function absSt : refEvalTree;
function ordSt : refEvalTree;
function chrSt : refEvalTree;
function newSt(ip : refIdentifier) : refEvalTree;
function disposeSt(ip : refIdentifier) : refEvalTree;
function stdIO(ip : refIdentifier) : refEvalTree;
function strcatSt(p1, p2 : refEvalTree) : refEvalTree;

implementation
uses cblex, cbexpr, cbtype, cberror, cbeval, cbexgen1, cbexgen3, cbexgen4, 
		cbgen2, cballoc, cbdump;

function readSt(k : standardRoutines) : refEvalTree;
var
	q : refEvalTree;
	type1 : refStructure;
	p : refIdentifier;
	n : integer;
begin	{ readSt }
	if sym <> lparen then begin
		if k <> readlnRn then
			error(8, disasters);
		genOneArg(variableNode(inputPtr), formal)
	end else begin
		n := 0;
		repeat
			n := n + 1;
			getsym;	(* 左括弧またはコンマの読み飛ばし *)
			q := expression;
			type1 := q^.evalType;
			if (q^.nodeType <> opVariable) and (q^.nodeType <> opIndirect) 
					then
				error(5, disasters);
			if (n = 1) and (type1 <> textPtr) then
				genOneArg(variableNode(inputPtr), formal);
			if (n = 1) and (type1 = textPtr) then
				genOneArg(q, formal)
			else if (type1 = intPtr) or (type1 = bytePtr) then begin
				genCall2(readIntPtr, intPtr);
				genStore(opMoveTo, q, nil)
			end else if type1 = charPtr then begin
				genCall2(readCharPtr, charPtr);
				genStore(opMoveTo, q, nil)
			end else if type1 = realPtr then begin
				genCall2(readRealPtr, realPtr);
				genStore(opMoveTo, q, nil)
			end else if type1^.form = strings then begin
				if type1^.stringElementType <> charPtr then
					errorType1(17, type1, disasters);
				genOneArg(q, formal);
				genCall2(readStringPtr, stringPtr)
			end else
				errorType1(17, type1, disasters);
			(* 現状では、不要： saveRegisters; *)
		until sym <> comma;
		checkSym(rparen, disasters)
	end;
	if k = readLnRn then
		genCall2(skipNlPtr, nil);
	if ioCheck then
		genCall2(ioCheckerPtr, nil)
	else
		genDisposePushValue(targetPtrSize);
	readSt := nil
end; { readSt }

function writeSt(k : standardRoutines) : refEvalTree;
label 9;
var
	q : refEvalTree;
	type1 : refStructure;
	p : refIdentifier;
	n : integer;

	procedure genPrintWidth;
	var
		q : refEvalTree;
	begin
		if sym = colon then begin
			getsym;
			q := autoChangeType(expression, intPtr);
			if q^.evalType <> intPtr then
				errorType1(17, q^.evalType, disasters);
			genOneArg(q, actual);
		end else
			genZeroArgument
	end; { genPrintWidth }

begin	{ writeSt }
	if sym <> lparen then begin
		if k <> writelnRn then
			error(8, disasters);
		genOneArg(variableNode(outputPtr), formal)
	end else begin
		n := 0;
		repeat
			n := n + 1;
			getsym;	(* 左括弧またはコンマの読み飛ばし *)
			q := autoChangeType(autoChangeType(valueExpression(nil), intPtr), 
					charPtr);
			type1 := q^.evalType;

			if (n = 1) and (type1 <> textPtr) then
				genOneArg(variableNode(outputPtr), formal);
			if (n = 1) and (type1 = textPtr) then
				genOneArg(q, formal)
			else begin
				genOneArg(q, actual);
				if (sym = rparen) and 
					((type1^.form = strings) or
					 (type1^.form = stringConsts)) and
					(k = writelnRn) and ioCheck then begin
					if type1^.stringElementType <> charPtr then
						errorType1(17, type1, disasters);
					getsym;		(* 右括弧の読み飛ばし *)
					genCall2(writeStringNewlineCheckPtr, nil);
					goto 9
				end;
				genPrintWidth;
				if type1 = intPtr then
					p := writeIntPtr
				else if type1 = charPtr then
					p := writeCharPtr
				else if type1 = boolPtr then
					p := writeBoolPtr
				else if type1 = realPtr then begin
					genPrintWidth;
					p := writeRealPtr
				end else if (type1^.form = strings) or (type1^.form = 
						stringConsts) then begin
					if type1^.stringElementType <> charPtr then
						errorType1(17, type1, disasters);
					p := writeStringPtr
				end else
					errorType1(17, type1, disasters);
				genCall2(p, nil)
			end
		until sym <> comma;
		checkSym(rparen, disasters)
	end;
	if k = writelnRn then
		genCall2(writeLnPtr, nil)
	else
		genCall2(flushOutPtr, nil);
	if ioCheck then
		genCall2(ioCheckerPtr, nil)
	else
		genDisposePushValue(targetPtrSize);
 9: writeSt := nil
end; { writeSt }

function ordSt : refEvalTree;
var
	a : refArgsLink;
	p : refStructure;
begin
	a := argument;
	if a = nil then
		error(8, disasters);
	with a^ do begin
		exp := autoChangeType(exp, boolPtr);
		p := exp^.evalType;
		if not scalarType(p) then
			errorType1(17, p, disasters);
		if next <> nil then
			error(8, disasters);

		if p^.size = targetByteSize then
			exp^.evalType := bytePtr
		else
			exp := changeType(exp, intPtr);
		ordSt := exp
	end;
	disposeArgsLink(a)
end; { ordSt }

function absSt : refEvalTree;
var
	a : refArgsLink;
	tp : refStructure;
begin
	a := argument;
	if a = nil then
		error(8, disasters);
	with a^ do begin
		tp := originalType(exp^.evaltype);
		if (tp <> intPtr) and (tp <> realPtr) then
			errorType1(17, tp, disasters);
		if next <> nil then
			error(8, disasters);
		absSt := makeOpEvalNode(tp, opAbs, exp, nil);
	end;
	disposeArgsLink(a);
end; { absSt }

function chrSt : refEvalTree;
var
	a : refArgsLink;
	p : refStructure;
begin
	a := argument;
	if a = nil then
		error(8, disasters);
	with a^ do begin
		p := originalType(exp^.evaltype);

		if p = intPtr then
			exp := changeType(exp, bytePtr)
		else if p <> bytePtr then
			errorType1(17, p, disasters);

		exp^.evalType := charPtr;
		if next <> nil then
			error(8, errors);
		chrSt := exp
	end;
	disposeArgsLink(a)
end; { chrSt }

function sizeOfType(t : refStructure) : integer;
var
	elementType, tagType : refStructure;
	tag : refTagField;
	p : refVariant;
	v, s : integer;
	value : constant;
	done : boolean;
begin
	elementType := t^.elementTypeOfPointer;
	s := elementType^.size;
	with elementType^ do begin
		if elementType^.form = records then begin
			tag := mainVariant;
			while sym = comma do begin
				getsym;	(* コンマの読み飛ばし *)
				if tag = nil then
					error(52, disasters);
				tagType := getConst(value);
				if not compatible(tag^.tagFieldType, tagType) then
					error(34, errors);
				v := value.intValue;
				p := tag^.firstVariant;
				done := false;
				repeat
					if p^.value >= v then
						done := true
					else
						p := p^.next
				until (p = nil) or done;
				if not done or (p^.value <> v) then
					error(52, disasters);
				s := p^.size;
				tag := p^.subVariant
			end { while }
		end { if }
	end; { while }
	sizeOfType := s
end; { sizeOfType }

function newSt(ip : refIdentifier) : refEvalTree;
var
	q : refEvalTree;
	newPtr : refIdentifier;
	type1 : refStructure;
	isHuge : boolean;
begin
	if sym <> lparen then
		error(8, disasters);
	getsym;	(* 左括弧の読み飛ばし *)
	q := expression;
	type1 := q^.evalType;
	if (q^.nodeType <> opVariable) and (q^.nodeType <> opIndirect) then
		error(5, disasters);
	if type1^.form <> pointers then
		error(51, disasters);
	isHuge := type1^.elementTypeOfPointer^.isHuge;
	genOneArg(integerConstantNode(sizeOfType(type1)), actual);
	if isHuge then
		newPtr := newHugeMemPtr
	else if ioCheck then
		newPtr := newMemWithCheckPtr
	else
		newPtr := newMemPTr;
	genCall2(newPtr, pointerPtr);
	genStore(opMoveTo, q, nil);
	if isHuge and ioCheck then
		genCall2(ioChecker2Ptr, nil);
	checkSym(rparen, disasters);
	newSt := nil
end; { newSt }

function disposeSt(ip : refIdentifier) : refEvalTree;
var
	q : refEvalTree;
	type1 : refStructure;
begin
	if sym <> lparen then
		error(8, disasters);
	getsym;	(* 左括弧の読み飛ばし *)
	q := expression;
	type1 := q^.evalType;
	if type1^.form <> pointers then
		error(51, disasters);
	genOneArg(q, actual);
	genOneArg(integerConstantNode(sizeOfType(type1)), actual);
	if type1^.elementTypeOfPointer^.isHuge then
		genCall2(disposeHugeMemPtr, nil)
	else
		genCall2(disposeMemPtr, nil);
	if ioCheck then
		genCall2(ioChecker2Ptr, nil);
	checkSym(rparen, disasters);
	disposeSt := nil
end; { disposeSt }

function stdIO(ip : refIdentifier) : refEvalTree;
var
	a : refArgsLink;
begin
	a := argument;
	checkArguments(ip^.paramp, a);
	genArgs(a);
	genCall2(ip, ip^.idType);
	if ioCheck then
		genCall2(ioCheckerPtr, nil)
	else
		genDisposePushValue(targetPtrSize);
	stdIO := nil
end;

function strcatSt(p1, p2 : refEvalTree) : refEvalTree;
var
	p : refEvalTree;
	a1, a2 : refArgsLink;
	n : integer;
begin
	p := newEvalTree;
	a1 := newArgsLink;
	a2 := newArgsLink;
	n := evalNodeSize(p1) + evalNodeSize(p2) - targetIntegerSize;
	with a1^ do begin
		exp := p1;
		next := a2;
		argKind := actual
	end;
	with a2^ do begin
		exp := p2;
		next := nil;
		argKind := actual
	end;
	with p^ do begin
		evalType := stringPtr;
		nodeType := opFunction;
		func := strcatPtr;
		args := a1;
		size := n
	end;
	strcatSt := p
end; { strcatSt }

end.
