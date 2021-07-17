(* file = cbexgen2.pas
 *
 * カベソンコンパイラ　：　式のコード生成（ＣＰＵ依存部）
 *
 * Copyright (C) 1990, 91, 92  Ockeghem
 *)

unit cbexgen2;

interface

uses cbcom;

procedure genSave(opr : operators; ope, sou : refEvalTree; indirect : boolean);
procedure genSaveAddr(ope : refEvalTree);
procedure genConst2(p : refEvalTree);
procedure genLoadAddrOfConst(c : refConstant);
procedure genCast2(type1, type2 : refStructure);
procedure genCode1(opr : operators; opType : refStructure);
procedure genConJump(opr : operators; eType : refStructure; 
					 rev : boolean; la : integer);
procedure genCtoB(la : integer);
procedure genBtoC(rev : boolean; la : integer);
procedure saveRegisters;
procedure pushLocalBuffer(n : integer);
procedure genRangeCheck(p : refEvalTree);

implementation

uses cbexgen3, cbexgen4, cbgen4, cbtype, cbdump, cberror, cballoc, cblabel;

procedure genSaveAddr(ope : refEvalTree);
var
	ws : registers;
begin
	ws := whichSegment;
	prepareAsmDataSpec(ope, false(* not indirect *));
	with ope^ do begin
		writeln(outFile, '	mov	', 
				asmDataSpec(constIndex + targetIntegerSize, targetIntegerSize),
				', ', regName[ws]);
		writeln(outFile, '	mov	', 
				asmDataSpec(constIndex, targetIntegerSize), ', di')
	end { with ope^ }
end; { genSaveAddr }

procedure genConst2(p : refEvalTree);
var
	L1 : integer;
	cSize : integer;
begin
	with p^, const1^ do begin
		cSize := evalType^.size;

		if evalType^.form = stringConsts then begin
			genLoadAddrOfConst(const1);
			pushAddrReg
		end else if (cSize = targetByteSize) or (cSize = targetIntegerSize) 
				then begin
			saveAcc;
			writeln(outFile, '	mov	', alax[cSize], ', ', intValue);
			disposeConstant(const1);
			isActive[AXreg] := true
		end else if evalType = pointerPtr then begin
			saveAcc;
			writeln(outFile, '	xor	ax, ax');	(* nilのロード *)
			writeln(outFile, '	mov	dx, ax');
			if const1 <> nil then
				disposeConstant(const1);
			isActive[AXreg] := true;
			isActive[DXreg] := true
		end else if evalType = realPtr then begin
			if labelValue = undefinedLabel then begin
				L1 := genLabel(1);
				labelValue := L1;
				next := localRootOfReals;
				localRootOfReals := const1
			end else begin
				L1 := labelValue;
				disposeConstant(const1)
			end;
			if lsiR86 then begin
				write(outFile, '	fld	[');
				outLabel0(L1);
				writeln(outFile, '].Q')
			end else begin
				write(outFile, '	fld	qword ptr ');
				outLabel1(L1)
			end
		end else
			sysError('genConst2')
	end { with }
end; { genConst2 }

procedure genLoadAddrOfConst2(c : refConstant; reg : registers);
var
	L1 : integer;
begin
	with c^ do begin
		if labelValue = undefinedLabel then begin
			L1 := genLabel(1);
			labelValue := L1;
			next := localRootOfStrings;
			localRootOfStrings := c
		end else begin
			L1 := labelValue;
			disposeConstant(c)
		end;
		write(outFile, '	mov	', regName[reg]);
		if lsiR86 then
			write(outFile, ', ')
		else
			write(outFile, ', offset ');
		outLabel1(L1);
		whichSegment := CSreg
	end { with }
end; { genLoadAddrOfConst2 }

procedure genLoadAddrOfConst(c : refConstant);
begin
	genLoadAddrOfConst2(c, DIreg)
end; { genLoadAddrOfConst }

procedure genCast2(type1, type2 : refStructure);
	procedure castError;
	begin
		errorType2(44, type1, type2, disasters)
	end;
begin
	if type1^.size = targetIntegerSize then begin
		if type2 = realPtr then begin
			genCall2(intToRealPtr, realPtr);
			isActive[AXreg] := false
		end else if type2^.size <> targetByteSize then
			castError
		(* else なにもしない *)
	end else if type1^.size = targetByteSize then begin
		if type2^.size = targetIntegerSize then
			writeln(outFile, '	xor	ah, ah')
		else
			castError
	end else
		castError
end; { genCast2 }

procedure genCode1(opr : operators; opType : refStructure);
var
	L1 : integer;
begin
	case opr of
		opNeg: begin
				if opType = realPtr then
					writeln(outFile, '	fchs')
				else
					writeln(outFile, '	neg	', alax[opType^.size])
			end;
		opNot: begin
				if opType = boolPtr then
					writeln(outFile, '	xor	al, 1')
				else
					writeln(outFile, '	not 	', alax[opType^.size])
			end;
		opAbs: begin
				if opType = realPtr then
					writeln(outFile, '	fabs')
				else begin
					L1 := genLabel(1);
					writeln(outFile, '	or	ax, ax');
					write(outFile, '	jns	');
					outLabel1(L1);
					writeln(outFile, '	neg	ax');
					outLabel2(L1)
				end
			end
		otherwise
			writeln(outFile, '	', opName[opr], '	', alax[opType^.size])
	end { case }
end; { genCode1 }

(* 手続き：loadAddressToDIandES;
 *
 * 目的：アドレスをＥＳ：ＤＩにロード
 *
 * 引数：なし
 *
 * 前提：prepareAsmDataSpec を前もって呼んでおくこと
 *)
procedure loadAddressToDIandES(constInd : integer);
begin
	if (not simpleAddress) or (constInd <> 0) then begin
		writeln(outFile, '	lea	di, ', 
				asmDataSpec(constInd, targetIntegerSize));
		diVariable := nil
	end;
	if whichSegment <> ESreg then begin
		writeln(outFile, '	mov	bx, ', regName[whichSegment]);
		writeln(outFile, '	mov	es, bx')
	end
end; { loadAddressToDIandES }

procedure copyingStructuredData(constInd, n : integer);	{ genSave の下請 }
begin
	loadAddressToDIandES(constInd);
	if whichSegment <> DSreg then
		writeln(outFile, '	mov	bx, ds');
	writeln(outFile, '	pop	si');
	writeln(outFile, '	pop	ds');
	writeln(outFile, '	cld');

	writeln(outFile, '	mov	cx, ', n div 2);
	writeln(outFile, '	rep movsw');
	if n mod 2 = 1 then
		writeln(outFile, '	movsb');
	writeln(outFile, '	mov	ds, bx');		{ ｄｓの復帰 }
	diVariable := nil
end; { copyingStructuredData }

(* 手続き：restoreRegister
 *
 * 目的：アキュムレータに値を戻す。既に値があれば、何もしない
 *
 * 引数：r : レジスタ名
 *)
procedure restoreRegister(r : registers);
begin
	if not isActive[r] then begin
		if r = DXreg then begin	(* DXの場合はDXだけでなく、*)
			writeln(outFile, '	pop	ax');	(* AXも戻す必要がある。    *)
			isActive[AXreg] := true
		end;
		writeln(outFile, '	pop	', regName[r]);
		isActive[r] := true
	end
end; { restoreRegister }

procedure genSave(opr : operators; ope, sou : refEvalTree; indirect : boolean);
var
	destSize, sourceSize, n : integer;
	oprName : string[6];
begin
	oprName := opName[opr];
	prepareAsmDataSpec(ope, indirect);
	with ope^, evalType^ do begin
		destSize := size;
		if (form = strings) or (form = stringConsts) then begin
			loadAddressToDIandES(constIndex);
			if sou <> nil then begin
				genLoadAddrOfConst2(sou^.const1, SIreg);
				sourceSize := sou^.evalType^.size;
				writeln(outFile, '	cld');
				if destSize >= sourceSize then
					writeln(outFile, '	mov	cx, ', sourceSize)
				else begin
					error(53, warnings);
					writeln(outFile, '	mov	cx, ', 
							destSize - targetIntegerSize);
					writeln(outFile, '	mov	ax, cx');
					writeln(outFile, '	stosw');
					writeln(outFile, '	inc	si');
					writeln(outFile, '	inc	si')
				end;
				writeln(outFile, '	db	2eh		; cs:');
				writeln(outFile, '	rep movsb');
				diVariable := nil
			end else begin
				writeln(outFile, '	mov	cx, ', stringSize div 
						stringElementType^.size);
				if stringElementType^.size = 1 then
					genCall2(stringCopy1Ptr, nil)
				else begin
					writeln(outFile, '	mov	dx, ', stringElementType^.size);
					genCall2(stringCopy2Ptr, nil)
				end
			end
		end else if not isRegisterLoadable(evalType) then
			copyingStructuredData(constIndex, destSize)
		else if evalType = realPtr then
			if opr = opPush then begin
				writeln(outFile, '	fld	', asmDataSpec(constIndex, 
						targetRealSize));
				pushRealValue
			end else
				writeln(outFile, '	fstp	', 
						asmDataSpec(constIndex, targetRealSize))
		else if (destSize = targetCharSize) or (destSize = targetIntegerSize) 
				then begin
			if sou <> nil then begin
				n := sou^.const1^.intValue;
				if (opr = opAdd) and (n = 1) or (opr = opSub) and (n = -1) 
						then
					writeln(outFile, '	inc	', 
							asmDataSpec(constIndex, destSize))
				else if (opr = opAdd) and (n = -1) or 
						(opr = opSub) and (n = 1) then
					writeln(outFile, '	dec	', 
							asmDataSpec(constIndex, destSize))
				else begin
					writeln(outFile, '	', oprName, '	', 
							asmDataSpec(constIndex, destSize), ', ', n)
				end;
				disposeConstant(sou^.const1)
			end else
				case opr of
					opNot, opNeg: if (opr = opNot) and 
									 (evalType = boolPtr) then
							writeln(outFile, '	xor	', 
									asmDataSpec(constIndex, destSize), ', 1')
						else
							writeln(outFile, '	', oprName, '	', 
									asmDataSpec(constIndex, destSize));
					opPush: begin
							writeln(outFile, '	push	', 
									asmDataSpec(constIndex, targetIntegerSize));
						end;
					otherwise begin
							restoreRegister(Axreg);
							writeln(outFile, '	', oprName, '	', 
									asmDataSpec(constIndex, destSize), 
									', ', alax[destSize])
						end
				end; { case }
			isActive[AXreg] := false
		end else if destSize = targetLongIntSize then begin
			if sou <> nil then begin
				writeln(outFile, '	xor	ax, ax');
				writeln(outFile, '	mov	', 
						asmDataSpec(constIndex, targetIntegerSize), ', ax');
				writeln(outFile, '	mov	', asmDataSpec(constIndex + 
						targetIntegerSize, targetIntegerSize), ', ax');
				if sou^.const1 <> nil then
					disposeConstant(sou^.const1)
			end else if opr = opPush then begin
				writeln(outFile, '	push	', 
						asmDataSpec(constIndex + targetIntegerSize, 
									targetIntegerSize));
				writeln(outFile, '	push	', 
						asmDataSpec(constIndex, targetIntegerSize))
			end else begin
				restoreRegister(DXreg);
				writeln(outFile, '	mov	', asmDataSpec(constIndex + 
						targetIntegerSize, targetIntegerSize), ', dx');
				writeln(outFile, '	mov	', asmDataSpec(constIndex, 
						targetIntegerSize), ', ax')
			end;
			isActive[AXreg] := false;
			isActive[DXreg] := false
		end else begin
			dumpType(evalType);
			sysError('genSave')
		end;
	end { with ope^ }
end; { genSave }

procedure genConJump(opr : operators; eType : refStructure; 
					 rev : boolean; la : integer);
var
	L1 : integer;
begin
	if jumpOptimization then
		rev := not rev;
	if (eType = bytePtr) or (eType = realPtr) then
		write(outFile, '	', condJmpName2[rev, opr], '	')
	else
		write(outFile, '	', condJmpName1[rev, opr], '	');
	if not jumpOptimization then begin
		L1 := genLabel(1);
		outLabel1(L1);
		write(outFile, '	jmp	');
		outLabel1(la);
		outLabel2(L1)
	end else
		outLabel1(la)
end; { genConJump }

procedure genCtoB(la : integer);
begin
	writeln(outFile, '	mov	al, 1');
	write(outFile, '	jmp     ');	{ shortでよいところ }
	outLabel1(la + 1);
	outLabel2(la);
	writeln(outFile, '	mov	al, 0');
	outLabel2(la + 1);
	isActive[AXreg] := true
end; { genCtoB }

procedure genBtoC(rev : boolean; la : integer);
begin
	writeln(outFile, '	or	al, al');
	isActive[AXreg] := false;
	genConJump(opNeq, intPtr, rev, la)
end; { genBtoC }

procedure pushLocalBuffer(n : integer);
begin
	writeln(outFile, '	lea	di, [bp+', n, ']');
	whichSegment := SSreg;
	diVariable := nil;				(* with 文の最適化のため *)
	pushAddrReg
end; { pushLocalBuffer }

(* 手続き：saveRegisters;
 *
 * 目的：関数・手続きの呼出の前に、レジスタを保存する。
 *
 * 引数：なし
 *)
procedure saveRegisters;
begin
	saveAcc
end; { saveRegisters }

procedure genRangeCheck(p : refEvalTree);
var
	n : integer;
begin
	with p^ do begin
		n := evalType^.size;
		writeln(outFile, '	mov	', blbx[n], ', ', minValue);
		writeln(outFile, '	mov	', clcx[n], ', ', maxValue);
		if n = 1 then
			genCall2(rangeCheck1Ptr, bytePtr)
		else
			genCall2(rangeCheck2Ptr, intPtr)
	end
end; { genRangeCheck }

end.
