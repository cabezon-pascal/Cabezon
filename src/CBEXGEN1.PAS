(* file = cbexgen1.pas
 *
 * カベソンコンパイラ　：　式のコード生成（ＣＰＵ独立部）
 *
 *
 * Copyright (C) 1990  Ockeghem
 *)

unit cbexgen1;

interface
uses cbCom;

function temporaryVariable(vType : refStructure) : refIdentifier;
procedure genArgs(ap : refArgsLink);
procedure genOneArg(ex : refEvalTree; ik : idKind);
procedure initExprCodeGen;
procedure genExpression(p : refEvalTree);
procedure genReturnValue(x : refEvalTree);
procedure genCondition(p : refEvalTree; la : integer);
procedure genStore(opr : operators; p, q : refEvalTree);
procedure loadAddr(p : refEvalTree);

implementation

uses cbtable, cballoc, cbexgen2, cbexgen3, cbexgen4, cblabel, cbgen4, 
	 cberror, cbdump, cbeval, cbtype, cblex2;

procedure genLoad(p : refEvalTree; pointed : boolean); forward;
procedure genCtrlToBool(ope : refEvalTree); forward;
procedure genCond0(p : refEvalTree; rev : boolean; la : integer); forward;

(* 関数：temporaryVariable
 *
 * 目的：与えられた型の一時変数を作成する
 *
 * 引数：vType：一時変数の型
 *
 * 戻り値：一時変数のポインタ
 *)
function temporaryVariable(vType : refStructure) : refIdentifier;
var
	p : refIdentifier;
begin
	p := setId('@', vars, vType);
	with p^ do begin
		level := currentLevel + 1;	(* mainでもスタック上に取るため*)
		locationPtr := locationPtr + vType^.size;
		if locationPtr > maxLocation then
			maxLocation := locationPtr;
		variableAddress := -locationPtr;
		variableKind := actual
	end; { with p^ }
	temporaryVariable := p
end; { temporaryVariable }

(* 手続き：prepareLoadEtc
 *
 * 目的：変数のロードなどの前準備を行う
 *
 * 引数：p:変数を表す識別子へのポインタ
 *)
procedure prepareLoadEtc(p : refEvalTree);
begin
	with p^ do begin
		if hugeIndex <> nil then begin
			genExpression(hugeIndex);
			prepareHugeIndex(p);
		end;
		if varIndex <> nil then
			genExpression(varIndex);
		if nodeType = opIndirect then
			genLoad(ref1, true)
	end { with p^}
end;

(* 手続き：genLoad
 *
 * 目的：変数をレジスタにロードするコードを生成する
 *
 * 引数： p : 変数を表す識別子へのポインタ
 *        pointed : 
 *
 * 戻り値：一時変数のポインタ
 *)
procedure genLoad(p : refEvalTree; pointed : boolean);
begin
	prepareLoadEtc(p);
	genLoad2(p, pointed, p^.nodetype = opIndirect);
	disposeEvalTree(p)
end; { genLoad }

procedure genOneArg(ex : refEvalTree; ik : idKind);
var
	t : refStructure;
begin
	t := ex^.evalType;
	if not isRegisterLoadable(t) then
		genExpression(ex)
	else if ik = formal then begin
		loadAddr(ex);
		pushAddrReg
	end else if isLeftSideTerm(ex) then
		genStore(opPush, ex, nil)
	else
		genExpression(makeOpEvalNode(t, opPush, nil, ex));
end; { genOneArg }

procedure genArgs(ap : refArgsLink);
var
	q : refArgsLink;
begin
	while ap <> nil do begin
		genOneArg(ap^.exp, ap^.argKind);
		q := ap;
		ap := ap^.next;
		disposeArgsLink(q)
	end;
end; { genArgs }

procedure genCall(p : refEvalTree);
begin
	saveRegisters;
	with p^, func^ do begin
		if procOrFuncKind = standard then begin
			case key of
				strcatRn: begin
						locationPtr := locationPtr + size;
						if locationPtr > maxLocation then
							maxLocation := locationPtr;
						pushLocalBuffer(-locationPtr);
						genArgs(args);
						genCall2(func, evalType)
					end;
				otherwise
					sysError('genCall');
			end
		end else begin

			(* 構造型の関数戻り値のスペース確保 *)

			if (nodeType = opFunction) and not isRegisterLoadable(evalType) 
					then begin
				locationPtr := locationPtr + size;
				if locationPtr > maxLocation then
					maxLocation := locationPtr;
				pushLocalBuffer(-locationPtr)
			end;
			genArgs(args);
			genCall2(func, evalType)
		end
	end; { with }
	disposeEvalTree(p)
end; { genCall }

procedure genStore(opr : operators; p, q : refEvalTree);
begin
	prepareLoadEtc(p);
	genSave(opr, p, q, p^.nodeType = opIndirect);
	disposeEvalTree(p)
end; { genStore }

procedure genAssignment(p : refEvalTree);
var
	simple : boolean;
	opr : operators;
	operandX : refEvalTree;

	procedure disposeOpe2(q : refEvalTree);
	begin
		disposeEvalTreeTree(q^.operand1);
		disposeEvalTree(q)
	end;

begin
	with p^ do begin
		simple := isSimpleType(evalType);
		if simple and (operand2^.nodeType = operator) and isEqualSubTree(
				operand1, operand2^.operand1) then begin
			opr := operand2^.op;
			case opr of
				opNeg, opNot: begin
						genStore(opr, operand1, nil);
						disposeOpe2(operand2)
					end;
				opAdd, opSub, opAnd, opOr, opXor: begin
						operandX := operand2^.operand2;
						if isConstant(operandX) then begin
							genStore(opr, operand1, operandX);
							disposeEvalTree(operandX);
							disposeOpe2(operand2)
						end else begin
							genExpression(operandX);
							genStore(opr, operand1, nil);
							disposeOpe2(operand2)
						end
					end;
				otherwise
					begin
						genExpression(operand2);
						genStore(opMoveTo, operand1, nil)
					end
			end { case }
		end else if simple and isConstant(operand2) or 
					(operand2^.evalType^.form = stringConsts) then begin
			genStore(opMoveTo, operand1, operand2);
			disposeEvalTree(operand2)
		end else begin
			genExpression(operand2);
			genStore(opMoveTo, operand1, nil)
		end
	end; { with p^ }
	disposeEvalTree(p)
end; { genAssignment }

procedure gen1operandExpression(p : refEvalTree);
var
	type1, type2 : refStructure;
begin
	with p^ do begin
		if op <> opCast then begin
			genExpression(operand1);
			genCode1(op, evalType)
		end else begin
			type1 := operand1^.evalType;
			type2 := evalType;
			if (type1 = controlPtr) and (type2^.size = targetByteSize) then
				genCtrlToBool(operand1)
			else begin
				genExpression(operand1);
				genCast2(type1, type2)
			end
		end
	end;
	disposeEvalTree(p)
end; { gen1operandExpression }

procedure gen2operandExpression(p : refEvalTree);
begin
	with p^ do
		if isSimpleTerm(operand2) and isSimpleType(evalType) then begin
			genExpression(operand1);
			genCode2(op, evalType, operand2);
			disposeEvalTree(operand2)
		end else begin
			genExpression(operand2);
			genExpression(operand1);
			genCode2(op, evalType, nil)
		end;
	disposeEvalTree(p)
end; { gen2operandExpression }

procedure loadAddr(p : refEvalTree);
begin
	with p^ do begin
		case nodeType of
			opConstant: genLoadAddrOfConst(const1);
			opVariable, opIndirect: begin
					prepareLoadEtc(p);
					loadAddr2(p, p^.nodeType = opIndirect)
				end;
			opFunction: begin
					if not isRegisterLoadable(evalType) then
						genCall(p)
					else
						sysError('loadAddr-1')
				end;
			otherwise
				sysError('loadAddr-2')
		end { case }
	end; { with p^ }
	disposeEvalTree(p)
end; { loadAddr }

procedure genExpression(p : refEvalTree);
begin
	if p <> nil then
		with p^ do
			case nodeType of
				opVariable, opIndirect:
					genLoad(p, false);
				opConstant: begin
						genConst2(p);
						disposeEvalTree(p)
					end;
				opProcedure, opFunction:
					genCall(p);
				operator: begin
						if op = opMoveTo then
							genAssignment(p)
						else if operand2 = nil then
							gen1operandExpression(p)
						else
							gen2operandExpression(p)
					end; { operator: }
				opRangeCheck: begin
						genExpression(expr);
						genRangeCheck(p);
						disposeEvalTree(p)
					end;
				otherwise
					begin
						dumpEvalTree(p);
						sysError('genExpression')
					end
			end { case nodeType }
end; { genExpression }

procedure genReturnValue(x : refEvalTree);
begin
	genExpression(x);
	clearRegisters
end; { genReturnValue }

procedure genAnd(op1, op2 : refEvalTree; rev : boolean; la : integer);
var
	L1 : integer;
begin
	if rev then begin
		L1 := genLabel(1);
		genCond0(op1, false, L1);
		genCond0(op2, true, la);
		outLabel2(L1)
	end else begin
		genCond0(op1, false, la);
		genCond0(op2, false, la)
	end
end; { genAnd }

procedure genOr(op1, op2 : refEvalTree; rev : boolean; la : integer);
var
	L1 : integer;
begin
	if rev then begin
		genCond0(op1, true, la);
		genCond0(op2, true, la)
	end else begin
		L1 := genLabel(1);
		genCond0(op1, true, L1);
		genCond0(op2, false, la);
		outLabel2(L1)
	end
end; { genOr }

procedure genCmp(p : refEvalTree; rev : boolean; la : integer);
begin
	with p^ do begin
		with operand1^ do begin
			if isConstant(operand2) and scalarType(evalType) and 
					isLeftSideTerm(operand1) then begin
				genStore(op, operand1, operand2);
				disposeEvalTree(operand2);
			end else if isSimpleType(evalType) and 
						isSimpleTerm(operand2) then begin
				genExpression(operand1);
				genCode2(op, evalType, operand2);
				disposeEvalTree(operand2)
			end else begin
				genExpression(operand2);
				genExpression(operand1);
				genCode2(op, evalType, nil)
			end;
			genConJump(p^.op, evalType, rev, la)
		end;
		disposeEvalTree(operand1)
	end
end; { genCmp }

procedure genCtrlToBool(ope : refEvalTree);
var
	L1 : integer;
begin
	L1 := genLabel(2);
	genCond0(ope, false, L1);
	genCtoB(L1)
end; { genCtrlToBool }

procedure genBoolToCtrl(ope : refEvalTree; rev : boolean; la : integer);
begin
	genExpression(ope);
	genBtoC(rev, la);
end; { genBoolToCtrl }

procedure genCond0(p : refEvalTree; rev : boolean; la : integer);
begin
	with p^ do begin
		if nodeType = operator then
			case op of
				opAnd: genAnd(operand1, operand2, rev, la);
				opOr: genOr(operand1, operand2, rev, la);
				opNot: genCond0(operand1, not rev, la);
				opLeq, opLss, opEql, opNeq, opGeq, opGrt: genCmp(p, rev, la);
				opCast: genBoolToCtrl(operand1, rev, la);
				otherwise
					sysError('genCond0-2')
			end
		else if nodeType = opConstant then begin
			if rev = (const1^.intValue <> 0) then
				genJump(la);
			disposeConstant(const1)
		end else
			sysError('genCond0-1')
	end;
	disposeEvalTree(p)
end; { genCond0 }

procedure genCondition(p : refEvalTree; la : integer);
var
	q : refEvalTree;
	eType : refStructure;
begin
	p := autoChangeType2(p, eType, controlPtr);
	if eType <> controlPtr then
		errorType2(39, controlPtr, p^.evalType, disasters);
	genCond0(p, false, la)
end;

procedure initExprCodeGen;
begin
	initExprGen2;
	initExprGen3;
end;

end.
