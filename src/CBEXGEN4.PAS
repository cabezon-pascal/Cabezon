(* file = cbexgen4.pas
 *
 * カベソンコンパイラ　：　式のコード生成（ＣＰＵ依存部）
 *
 * Copyright (C) 1990, 91, 92  Ockeghem
 *)

unit cbexgen4;

interface
uses cbcom;

var
	simpleAddress : boolean;
	hugeIndexed : boolean;
	alax, blbx, clcx : array[1..2] of regNameType;
	whichSegment : registers;

procedure genCall2(func : refIdentifier; funcType : refStructure);
procedure prepareHugeIndex(p : refEvalTree);
function staticLinkIndex(p : refIdentifier) : integer;
function isRegisterLoadable(p : refStructure) : boolean;
function asmName(p : refIdentifier) : alpha;
function asmDataSpec(constIndex, size : integer) : stringBuf;

procedure initExprGen2;
procedure initExprGen3;
procedure clearRegisters;
procedure prepareAsmDataSpec(p : refEvalTree; indirect : boolean);

implementation
uses cbgen4, cbdump, cberror;

var
	dataOffset : integer;
	dataSpecBuffer : stringBuf;
	lBranquetted : boolean;
	sizeName1 : array[1..4] of string[10];	{ 1, 2, 4, 8 の分 }
	sizeName2 : array[1..4] of string[3];

function staticLinkIndex(p : refIdentifier) : integer;
begin
	if isFarRoutine(p) then
		staticLinkIndex := targetDynamicLinkSize + targetFarCallSize
	else
		staticLinkIndex := targetDynamicLinkSize + targetNearCallSize;
end; { staticLinkIndex }

procedure prepareHugeIndex(p : refEvalTree);
begin
	if p^.nodeType <> opIndirect then
		writeln(outFile, '	add	ax, seg ', asmName(p^.var1));
	writeln(outFile, '	push	ax');
	hugeIndexed := true;
	isActive[AXreg] := false
end;

function procSpec(p : refIdentifier) : stringMax;
begin
	if lsiR86 or (p^.procOrFuncKind = declared) and not p^.forwardDec and 
			(p^.idDeclareClass <> extern) then
		procSpec := asmName(p)
	else if isFarRoutine(p) then
		procSpec := 'far ptr ' + asmName(p)
	else
		procSpec := 'near ptr ' + asmName(p)
end; { procSpec }

procedure genCall2(func : refIdentifier; funcType : refStructure);
var
	p : refScopeLink;	(* refIdentifier; *)
	i : integer;
begin
	with func^ do begin

		(* スコープ・レベルが２以上の場合は、静鎖のｐｕｓｈを行う *)

		if level >= 2 then begin
			if level = currentLevel then
				writeln(outFile, '	push	bp')
			else if currentLevel - level = 1 then begin
				writeln(outFile, '	push	', 
						staticLinkIndex(currentRoutine), '[bp]')
			end else begin
				writeln(outFile, '	mov	bx, ', 
						staticLinkIndex(currentRoutine), '[bp]');
				p := topOfScope^.parentScope;
				for i := 1 to currentLevel - level - 2 do begin
					writeln(outFile, '	mov	bx, ss: ', staticLinkIndex(p^.
							procedurep), '[bx]');
					p := p^.parentScope
				end;
				writeln(outFile, '	push	ss: ', 
						staticLinkIndex(p^.procedurep), '[bx]')
			end
		end;

		if not used and (procOrFuncKind = declared) and externDec then begin
			write(outFile, '	extrn	', asmName(func));
			if lsiR86 then
				writeln(outFile)
			else if isFarRoutine(func) then
				writeln(outFile, ': far')
			else
				writeln(outFile, ': near');
			used := true;
			forwardDec := false;
			externDec := false
		end;

		if lsiR86 and isFarRoutine(func) then
			write(outFile, '	callf	')
		else
			write(outFile, '	call	');
		writeln(outFile, procSpec(func));

		if (funcType <> nil) and isRegisterLoadable(funcType) then
			case funcType^.size of
				targetLongIntSize: begin
						isActive[AXreg] := true;
						isActive[DXreg] := true
					end;
				targetIntegerSize, targetCharSize: isActive[AXreg] := true
				otherwise
				(* do nothing *)
			end { case funcType^.size }
	end; { with func^ }
	diVariable := nil				(* with 文の最適化のため *)
end; { genCall2 }

procedure clearRegisters;
var
	r : registers;
begin
	for r := AXreg to CSreg do
		isActive[r] := false
end;

(* 関数：isRegisterLoadable
 *
 * 目的：型がレジスタに格納可能かどうかを返す
 *
 * 引数：p : 型
 *
 * 戻り値：レジスタに可能かどうかの判定(true/false)
 *)
function isRegisterLoadable(p : refStructure) : boolean;
begin
	case p^.form of
		records, arrays: case p^.size of
				targetByteSize, targetIntegerSize, targetLongIntSize: 
						isRegisterLoadable := true;
				otherwise
					isRegisterLoadable := false
			end;
		scalars, subranges, pointers: 
			isRegisterLoadable := true;
		otherwise
			isRegisterLoadable := false
	end { case }
end; { isRegisterLoadable }

function asmName(p : refIdentifier) : alpha;
var
	i : integer;
	s : alpha;
	q : refScopeLink;
begin
	with p^ do begin
		if level <= 1 then begin
			asmName := '_' + name^;
			whichSegment := DSreg;
			lBranquetted := false
		end else if klass = vars then begin
			if currentLevel > level then begin
				writeln(outFile, '	mov	bx, [bp+', staticLinkIndex(
						currentRoutine), ']');
				q := topOfScope^.parentScope;
				for i := 1 to currentLevel - level - 1 do begin
					writeln(outFile, '	mov	bx, ss:[bx+', 
							staticLinkIndex(q^.procedurep), ']');
					q := q^.parentScope
				end;
				asmName := 'ss:[bx'
			end else
				asmName := '[bp';
			dataOffset := variableAddress;
			lBranquetted := true;
			whichSegment := SSreg
		end else begin
			str(labelValue, s);
			asmName := '_' + s + '_' + name^
		end;
		used := true
	end
end; { asmName }

procedure prepareAsmDataSpec(p : refEvalTree; indirect : boolean);
var
	indexRegister : registers;
begin
	dataOffset := 0;
	if indirect then
		indexRegister := BXreg
	else
		indexRegister := SIreg;

	simpleAddress := false;
	with p^ do begin
		if (varIndex <> nil) and (isActive[AXreg]) then begin
			writeln(outFile, '	mov	', regName[indexRegister], ', ax');
			isActive[AXreg] := false
		end else if varIndex <> nil then
			writeln(outFile, '	pop	', regName[indexRegister]);

		if indirect then begin
			dataSpecBuffer := 'es:[di';
			whichSegment := ESreg;
			simpleAddress := true;
			lBranquetted := true
		end else if (var1^.variableKind = actual) and
				(var1^.idType^.isHuge) then begin
			if hugeIndex = nil then begin
				writeln(outFile, '	mov	ax, seg ', asmName(p^.var1));
				writeln(outFile, '	mov	es, ax')
			end else
				writeln(outFile, '	pop	es');
			dataSpecBuffer := 'es:[0';
			whichSegment := ESreg;
			lBranquetted := true;
			hugeIndexed  := false;
			diVariable   := nil
		end else begin
			dataSpecBuffer := asmName(var1);
			if lsiR86 and not lBranquetted then begin
				dataSpecBuffer := '[' + dataSpecBuffer;
				lBranquetted := true
			end
		end;
		if varIndex <> nil then begin
			if lBranquetted then
				dataSpecBuffer := dataSpecBuffer + '+' + regName[indexRegister]
			else begin
				dataSpecBuffer := dataSpecBuffer + '['
										+ regName[indexRegister];
				lBranquetted := true
			end;
			simpleAddress := false
		end
	end { with ope^ }
end; { prepareAsmDataSpec }

function asmDataSpec(constIndex, size : integer) : stringBuf;
var
	k, n, sizeIndex : integer;
	s : string[6];
	work : stringBuf;
begin
	n := dataOffset + constIndex;
	case size of
		1, 2: sizeIndex := size;
		4: sizeIndex := 3;
		8: sizeIndex := 4;
		otherwise
			sysError('asmDataSpec')
	end;

	str(n, s);
	if n > 0 then
		s := '+' + s;
	if lsiR86 then begin
		if n = 0 then
			asmDataSpec := dataSpecBuffer + sizeName2[sizeIndex]
		else begin
			work := dataSpecBuffer;
			k := cpos('[', work);
			asmDataSpec := copy(work, 1, k) + s + '+' + copy(work, k + 1, 255)
					+ sizeName2[sizeIndex]
		end
	end else begin
		work := sizeName1[sizeIndex] + dataSpecBuffer;
		if n <> 0 then begin
			if lBranquetted then
				asmDataSpec := work + s + ']'
			else
				asmDataSpec := work + '[' + s + ']'
		end else if lBranquetted then
			asmDataSpec := work + ']'
		else
			asmDataSpec := work
	end
end; { asmDataSpec }

procedure initExprGen2;
begin
	clearRegisters;
	hugeIndexed := false;

	alax[1] := 'al';			alax[2] := 'ax';
	blbx[1] := 'bl';			blbx[2] := 'bx';
	clcx[1] := 'cl';			clcx[2] := 'cx';

	regName[AXreg] := 'ax';		regName[BXreg] := 'bx';
	regName[CXreg] := 'cx';		regName[DXreg] := 'dx';
	regName[SIreg] := 'si';		regName[DIreg] := 'di';
	regName[BPreg] := 'bp';		regName[SPreg] := 'sp';
	regName[DSreg] := 'ds';		regName[SSreg] := 'ss';
	regName[ESreg] := 'es';		regName[CSreg] := 'cs';

	opName[opMoveTo] := 'mov';
	opName[opAdd] := 'add';		opName[opSub] := 'sub';
	opName[opMul] := 'imul';	opName[opDiv] := 'idiv';
	opName[opMod] := 'idiv';	opName[opNot] := 'not';
	opName[opAnd] := 'and';		opName[opOr] := 'or';
	opName[opXor] := 'xor';		opName[opNeg] := 'neg';
	opName[opCmp] := 'cmp';		opName[opPush] := 'push'
end;

procedure initExprGen3;
begin
	condJmpName1[false, opLeq] := 'jle';	condJmpName1[true, opLeq] := 'jg';
	condJmpName1[false, opLss] := 'jl';		condJmpName1[true, opLss] := 'jge';
	condJmpName1[false, opEql] := 'je';		condJmpName1[true, opEql] := 'jne';
	condJmpName1[false, opNeq] := 'jne';	condJmpName1[true, opNeq] := 'je';
	condJmpName1[false, opGeq] := 'jge';	condJmpName1[true, opGeq] := 'jl';
	condJmpName1[false, opGrt] := 'jg';		condJmpName1[true, opGrt] := 'jle';

	condJmpName2[false, opLeq] := 'jbe';	condJmpName2[true, opLeq] := 'ja';
	condJmpName2[false, opLss] := 'jb';		condJmpName2[true, opLss] := 'jae';
	condJmpName2[false, opEql] := 'je';		condJmpName2[true, opEql] := 'jne';
	condJmpName2[false, opNeq] := 'jne';	condJmpName2[true, opNeq] := 'je';
	condJmpName2[false, opGeq] := 'jae';	condJmpName2[true, opGeq] := 'jb';
	condJmpName2[false, opGrt] := 'ja';		condJmpName2[true, opGrt] := 'jbe';

	sizeName1[1] := 'byte ptr ';			sizeName1[2] := 'word ptr ';
	sizeName1[3] := 'dword ptr ';			sizeName1[4] := 'qword ptr ';

	sizeName2[1] := '].B';					sizeName2[2] := '].W';
	sizeName2[3] := '].D';					sizeName2[4] := '].Q';
end;

end.
