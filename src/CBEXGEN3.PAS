(* file = cbexgen3.pas
 *
 * カベソンコンパイラ　：　式のコード生成（ＣＰＵ依存部）
 *
 * Copyright (C) 1990, 91, 92  Ockeghem
 *)

unit cbexgen3;interface
uses cbcom;

procedure multiplyWithConstant(areg, destReg : regNameType; n : integer);
procedure pushAddrReg;
procedure pushRealValue;
procedure genCode2(opr : operators; opType : refStructure; 
				   operand : refEvalTree);
procedure loadAddr2(ope : refEvalTree; indirect : boolean);
procedure genLoad2(ope : refEvalTree; pointed, indirect : boolean);
procedure genZeroArgument;
procedure saveAcc;

implementation

uses cbexgen4, cbgen4, cbeval, cblabel, cballoc, cbdump, cberror;

procedure genZeroArgument;
begin
	writeln(outFile, '	xor	ax, ax');
	writeln(outFile, '	push    ax')
end; { genZeroArgument }

procedure genNilArgument;
begin
	writeln(outFile, '	xor	ax, ax');
	writeln(outFile, '	push    ax');
	writeln(outFile, '	push    ax')
end; { genZeroArgument }

(* 手続き：saveAcc
 *
 * 目的：アキュムレータの内容をスタックに保存する
 *
 * 引数：なし
 *)
procedure saveAcc;
begin
	if isActive[DXreg] then begin
		writeln(outFile, '	push	dx');
		writeln(outFile, '	push	ax');
		isActive[DXreg] := false;
		isActive[AXreg] := false
	end else if isActive[AXreg] then begin
		writeln(outFile, '	push	ax');
		isActive[AXreg] := false
	end
end; { saveAcc }

procedure genOperand(opr : operators; ope : refEvalTree; 
					 pointed, indirect : boolean);
var
	oprName : string[6];
	sz, ci : integer;

	function isHuge(ope : refEvalTree) : boolean;
	var
		orgType : refStructure;
	begin
		if ope^.evalType <> pointerPtr then
			orgType := ope^.evalType^.elementTypeOfPointer
		else if ope^.nodeType = opVariable then
			orgType := ope^.var1^.idType
		else
			orgType := ope^.ref1^.evalType;
		isHuge := orgType^.isHuge
	end; { isHuge }

begin {genOperand }
	oprName := opName[opr];
	prepareAsmDataSpec(ope, indirect);
	with ope^ do begin
		sz := evalType^.size;
		ci := constIndex;
		if pointed then begin
			if (ope^.nodeType = opVariable) and (ope^.var1 = diVariable) then
				(* なにもしない *)
			else if isHuge(ope) and hugeIndexed then begin
				writeln(outFile, '	mov	dx, ',
						asmDataSpec(ci + targetIntegerSize, 
									targetIntegerSize));
				writeln(outFile, '	mov	di, ',
						asmDataSpec(ci, targetIntegerSize));
				writeln(outFile, '	pop	cx');
				writeln(outFile, '	add	dx, cx');
				writeln(outFile, '	mov	es, dx');
				hugeIndexed := false;
				diVariable := nil
			end else begin
				writeln(outFile, '	les	di, ', asmDataSpec(ci, targetPtrSize));
				if (ope^.nodeType = opVariable) and isTemporary(var1) then
					diVariable := var1
				else
					diVariable := nil
			end
		end else if not isRegisterLoadable(evalType) then begin
			if (not simpleAddress) or (ci <> 0) then
				writeln(outFile, '	lea	di, ', asmDataSpec(ci, 
						targetIntegerSize));
			diVariable := nil;
			pushAddrReg
		end else if evalType = realPtr then
			writeln(outFile, '	fld	', asmDataSpec(ci, targetRealSize))
		else if sz = targetLongIntSize then begin
			if opr = opMoveTo then
				saveAcc;
			if opr = opPush then
				sysError('genOperand-1')
			else begin
				writeln(outFile, '	', oprName, '	dx, ', 
						asmDataSpec(ci + targetIntegerSize, 
									targetIntegerSize));
				writeln(outFile, '	', oprName, '	ax, ', 
						asmDataSpec(ci, targetIntegerSize));
				isActive[AXreg] := true;
				isActive[DXreg] := true
			end;
		end else if (sz = targetIntegerSize) or 
					(sz = targetByteSize) then begin
			case opr of
				opMul, opDiv, opMod: begin
						writeln(outFile, '	', oprName, '	', 
								asmDataSpec(ci, sz));
						isActive[AXreg] := true
					end;
				opPush:
						sysError('genOperand-2')
				otherwise begin
						if opr = opMoveTo then
							saveAcc;
						writeln(outFile, '	', oprName, '	', 
								alax[sz], ', ', asmDataSpec(ci, sz));
						isActive[AXreg] := true
					end
			end
		end else begin
			dumpType(evalType);
			sysError('genOperand-3')
		end { if }
	end { with ope^ }
end; { genOperand }

(*************************************************
procedure pushValue(t : refStructure);
begin
    if t = realPtr then begin
	writeln(outFile, '	sub	sp, 8');
	writeln(outFile, '	mov	bx, sp');
	writeln(outFile, '	fstp	qword ptr ss:[bx]')
    end else
	case t^.size of
	  targetCharSize,
	  targetIntegerSize,
	  targetPtrSize :
		saveAcc;
	  otherwise begin
		dumpType(t);
		sysError('pushValue')
	     end
	end { case }
end; { pushValue }
****************************************************)

procedure pushRealValue;
begin
	writeln(outFile, '	sub	sp, 8');
	writeln(outFile, '	mov	bx, sp');
	writeln(outFile, '	fstp	qword ptr ss:[bx]')
end;

procedure multiplyWithConstant(areg, destReg : regNameType; n : integer);
begin
	case n of
		1, 2, 4, 8: begin
				while n > 1 do begin
					writeln(outFile, '	shl	', areg, ', 1');
					n := n div 2
				end
			end;
		otherwise
			begin
				writeln(outFile, '	mov	', destReg, ', ', n);
				writeln(outFile, '	imul	', destReg)
			end
	end
end;

procedure genCode2(opr : operators; opType : refStructure; 
				   operand : refEvalTree);
var
	L1, x : integer;
	areg, breg : regNameType;

	procedure genCompFloat;
	begin
		writeln(outFile, '	fcompp');
		writeln(outFile, '	fstsw	word ptr ', asmName(i8087Work1));
		writeln(outFile, '	wait');
		writeln(outFile, '	mov	ah, ', asmName(i8087Work1), '[1]');
		writeln(outFile, '	sahf')
	end; { genCompFloat }

	procedure genCompPointer1(L1 : integer);
	begin
		writeln(outFile, '	pop	bx');
		writeln(outFile, '	pop	cx');
		writeln(outFile, '	cmp	ax, bx');
		write(outFile, '	jnz	');
		outLabel1(L1);
		writeln(outFile, '	cmp	dx, cx');
		outLabel2(L1)
	end;

	procedure genCompPointer2(L1 : integer; operand : refEvalTree);
	begin
		prepareAsmDataSpec(operand, false);
		writeln(outFile, '	cmp	ax, ', asmDataSpec(0, targetIntegerSize));
		write(outFile, '	jnz	');
		outLabel1(L1);
		writeln(outFile, '	cmp	dx, ', asmDataSpec(targetIntegerSize, 
				targetIntegerSize));
		outLabel2(L1)
	end;

begin
	if opType = realPtr then begin
		case opr of
			opAdd: writeln(outFile, '	fadd');
			opSub: writeln(outFile, '	fsubr');
			opMul: writeln(outFile, '	fmul');
			opDiv: writeln(outFile, '	fdivr');
			opCmp: genCompFloat;
			opPush: pushRealValue;
			otherwise
				sysError('genCode2-1')
		end; { case }
	end else if opType^.form = pointers then begin
		(****    end else if opType = pointerPtr then begin		**)
		if opr = opCmp then begin
			L1 := genLabel(1);
			if operand = nil then
				genCompPointer1(L1)
			else if operand^.nodeType = OpVariable then
				genCompPointer2(L1, operand)
			else begin	(* 定数 = nil を仮定 *)
				writeln(outFile, '	or	ax, dx');
				if operand^.const1 <> nil then
					disposeConstant(operand^.const1)
			end;
			isActive[AXreg] := false;
			isActive[DXreg] := false
		end else if (opr = opPush) and isConstant(operand) then
			genNilArgument
		else if (opr = opPush) and isActive[DXreg] then
			saveAcc
		else
			sysError('genCode2-2')
	end else if opType = stringPtr then begin
		if opr = opCmp then begin
			genCall2(strcmpPtr, nil);

			(* ↑　本来はintPtrだが、AX をすぐ使うので、nilとしている *)

			writeln(outFile, '	or	ax, ax')
		end else
			sysError('genCode2-3')
	end else begin
		areg := alax[opType^.size];
		breg := blbx[opType^.size];
		if (operand = nil) and (opr <> opPush) then
			writeln(outFile, '	pop	bx');
		case opr of
			opDiv, opMod: begin
					writeln(outFile, '	cwd');
					if operand = nil then
						writeln(outFile, '	idiv	bx')
					else if operand^.nodeType = OpVariable then
						genOperand(opr, operand, false, false)
					else begin	(* 定数 *)
						writeln(outFile, '	mov	bx, ', operand^.const1^.
								intValue);
						writeln(outFile, '	idiv	bx');
						disposeConstant(operand^.const1)
					end;
					if opr = opMod then
						writeln(outFile, '	mov	ax, dx')
				end;
			opMul: begin
					if operand = nil then
						writeln(outFile, '	imul	', breg)
					else
						with operand^ do
							if nodeType = OpVariable then
								genOperand(opr, operand, false, false)
							else
								with const1^ do begin	(* 定数 *)
									multiplyWithConstant(areg, breg, intValue);
									disposeConstant(const1)
								end
				end;
			opCmp: begin
					if operand = nil then
						writeln(outFile, '	cmp	', areg, ', ', breg)
					else if operand^.nodeType = OpVariable then
						genOperand(opr, operand, false, false)
					else begin	(* 定数 *)
						writeln(outFile, '	cmp	', areg, ', ', operand^.const1
								^.intValue);
						disposeConstant(operand^.const1)
					end;
					isActive[AXreg] := false
				end;
			otherwise
				begin
					if operand = nil then begin
						if opr = opPush then begin
							writeln(outFile, '	PusH	ax');
							isActive[AXreg] := false
						end else
							writeln(outFile, '	', opName[opr], '	', areg, 
									', ', breg)
					end else if operand^.nodeType = OpVariable then begin
						genOperand(opr, operand, false, false)
					end else begin	(* 定数 *)
						x := operand^.const1^.intValue;
						if (x = 1) and (opr = opAdd) then
							writeln(outFile, '	inc	', areg)
						else if (x = 1) and (opr = opSub) then
							writeln(outFile, '	dec	', areg)
						else if opr = opPush then begin
							writeln(outFile, '	mov	ax, ', x);
							writeln(outFile, '	push	ax')
						end else
							writeln(outFile, '	', opName[opr], '	', areg, 
									', ', x);
						disposeConstant(operand^.const1)
					end
				end
		end { case }
	end { if }
end; { genCode2 }

procedure genLoad2(ope : refEvalTree; pointed, indirect : boolean);
begin
	genOperand(opMoveTo, ope, pointed, indirect)
end; { genLoad2 }

procedure loadAddr2(ope : refEvalTree; indirect : boolean);
var
	n : integer;
begin
	prepareAsmDataSpec(ope, indirect);
	n := ope^.constIndex;

	if (not simpleAddress) or (n <> 0) then begin
		writeln(outFile, '	lea	di, ', asmDataSpec(n, targetIntegerSize));
		diVariable := nil
	end
end; { loadAddr2 }

procedure pushAddrReg;
begin
	writeln(outFile, '	push	', regName[whichSegment]);
	writeln(outFile, '	push	di')
end; { pushAddr }

end.
