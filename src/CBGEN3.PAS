(* file = cbgen3.pas
 *
 * カベソンコンパイラ　：　コード生成（ＣＰＵ依存）
 *
 *
 * Copyright (C) 1990  Ockeghem
 *)

unit cbgen3;

interface
uses cbcom;

procedure genGoto(p : refIdentifier);
procedure genFor1(p1, p2, cp, cq : refEvalTree; toOrDownto : symbol; L1 : 
		integer);
procedure genFor2(cp, cq : refEvalTree; toOrDownto : symbol; L1 : integer);
procedure genCase(root : refCaseInformation; L1, caseMin, caseMax, numOfCase 
		: integer);
procedure flushCaseLabels;

procedure initCodeGen3;

implementation

uses cbgen4, cbexgen1, cbexgen2, cbexgen3, cbexgen4, cbeval, cblabel, cballoc, 
		cberror, cbdump;

procedure genGoto(p : refIdentifier);
var
	i : integer;
	q : refScopeLink;
begin
	with p^ do begin
		if level <> currentLevel then begin
			if level > 1 then begin
				q := topOfScope;
				for i := 1 to currentLevel - level do begin
					writeln(outFile, '	mov	bp, [bp+', staticLinkIndex(q^.
							procedurep), ']');
					q := q^.parentScope;
				end
			end else begin
				if lsiR86 then
					writeln(outFile, '	mov	bp, ', asmName(stackFrameSaver))
				else
					writeln(outFile, '	mov	bp, word ptr ', asmName(
							stackFrameSaver));
				q := topOfScope;
				for i := 1 to currentLevel - level do
					q := q^.parentScope;
			end;
			writeln(outFile, '	mov	ax, bp');
			write(outFile, '	sub	ax, ');
			outLabel1(q^.procedurep^.labelValue + 1);
			writeln(outFile, '	mov	sp, ax')
		end; { if }
		genJump(labelValue)
	end { with }
end; { genGoto }

procedure genFor1(p1, p2, cp, cq : refEvalTree; toOrDownto : symbol; L1 : 
		integer);
var
	forType : refStructure;
	reg1, reg2 : string[2];
	n, n1, n2, nx : integer;
begin
	forType := cp^.evalType;
	n := forType^.size;

	if isConstant(p1) and isConstant(p2) then begin
		n1 := p1^.const1^.intValue;
		n2 := p2^.const1^.intValue;
		if (toOrDownto = tosym) and (n1 > n2) or 
				(toOrDownto = downtosym) and (n1 < n2) then
			genJump(L1 + 1)
		else begin
			prepareAsmDataSpec(cp, false);
			writeln(outFile, '	mov	', asmDataSpec(0, n), ', ', n1);
			prepareAsmDataSpec(cq, false);
			write(outFile, '	mov	', asmDataSpec(0, n), ', ');

			if toOrDownto = tosym then
				nx := n2 - n1 + 1
			else
				nx := n1 - n2 + 1;
			if (n = targetByteSize) and (nx > targetMaxByte) then
				nx := 0;
			writeln(outFile, nx)
		end;
		disposeConstEvalTree(p1);
		disposeConstEvalTree(p2)
	end else begin
		genExpression(p2);
		genExpression(p1);
		genCode2(opCmp, forType, nil);
		if toOrDownto = tosym then
			genConJump(opLeq, forType, false, L1 + 1)
		else
			genConJump(opGeq, forType, false, L1 + 1);
		prepareAsmDataSpec(cp, false);
		writeln(outFile, '	mov	', asmDataSpec(0, n), ', ', alax[n]);
		prepareAsmDataSpec(cq, false);
		if toOrDownto = tosym then begin
			reg1 := alax[n];
			reg2 := blbx[n]
		end else begin
			reg2 := alax[n];
			reg1 := blbx[n]
		end;
		writeln(outFile, '	sub	', reg2, ', ', reg1);
		writeln(outFile, '	inc	', reg2);
		writeln(outFile, '	mov	', asmDataSpec(0, n), ', ', reg2)
	end
end; { genFor1 }

procedure genFor2(cp, cq : refEvalTree; toOrDownto : symbol; L1 : integer);
var
	n : integer;
begin
	n := cp^.evalType^.size;
	prepareAsmDataSpec(cp, false);
	if toOrDownto = tosym then
		write(outFile, '	inc')
	else
		write(outFile, '	dec');
	writeln(outFile, '	', asmDataSpec(0, n));
	prepareAsmDataSpec(cq, false);
	writeln(outFile, '	dec	', asmDataSpec(0, n));
	genConJump(opEql, intPtr, false, L1)
end; { genFor2 }

function nthCaseLink(p : refCaseInformation; n : integer) : 
		refCaseInformation;
var
	i : integer;
begin
	for i := 1 to n - 1 do
		p := p^.next;
	nthCaseLink := p
end; { nthCaseLink }

procedure genCase(root : refCaseInformation; L1, caseMin, caseMax, numOfCase 
		: integer);
var
	p : refCaseLink;
	n1, n2, n3 : integer;
	jk : caseKind;
(*********************************************************
    procedure genCase1(root : refCaseInformation);
    var
	p : refCaseInformation;
    begin
	p := root;
	while p <> nil do begin
	    writeln(outFile, '	cmp	ax, ', p^.caseValue);
	    genConJump(opEql, intPtr, true, p^.caseLabel);
	    p := p^.next;
	end
    end; { genCase1 }

    procedure genCase2(numOfCase, L1 : integer);
    begin
	write(outFile, '	mov	di, offset ');
	outLabel1(L1 + 3);
	writeln(outFile, '	mov	cx, ', numOfCase);
	writeln(outFile, '	push	cs');
	writeln(outFile, '	pop	es');
	writeln(outFile, '	cld');
	writeln(outFile, '	repne scasw');
	write(outFile, '	jne	'); outLabel1(L1 + 1);
	writeln(outFile, '	jmp	cs:', (numOfCase - 1) * 2, '[di]')
    end;
******************************************************************)

	procedure genCase3(L1, caseMin, caseMax : integer);
	begin
		writeln(outFile, '	mov	di, ax');
		if caseMin <> 0 then
			writeln(outFile, '	sub	di, ', caseMin);
		writeln(outFile, '	cmp	di, ', caseMax - caseMin);
		write(outFile, '	ja	');
		outLabel1(L1 + 1);
		writeln(outFile, '	shl	di, 1');
		write(outFile, '	jmp	cs:');
		outLabel0(L1 + 3);
		writeln(outFile, '[di]');
		diVariable := nil
	end;

	procedure genCase4(root : refCaseInformation; n, Lx : integer);
	var
		p : refCaseInformation;
		i, m, L : integer;
	begin
		if Lx > 0 then
			outLabel2(Lx);
		if n <= 4 then begin
			p := root;
			for i := 1 to n do begin
				writeln(outFile, '	cmp	ax, ', p^.caseValue);
				genConJump(opEql, intPtr, true, p^.caseLabel);
				p := p^.next
			end;
			if p <> nil then
				genJump(L1 + 1)
		end else begin
			m := (n + 1) div 2;
			p := nthCaseLink(root, m);
			L := genLabel(1);
			writeln(outFile, '	cmp	ax, ', p^.caseValue);

			genConJump(opGrt, intPtr, true, L);
			genConJump(opEql, intPtr, true, p^.caseLabel);

			genCase4(root, m - 1, 0);
			genCase4(p^.next, n - m, L)
		end
	end; { genCase4 }

begin
	n1 := 8 * numOfCase;
	n2 := 4 * numOfcase + 20;
	n3 := 2 * (caseMax - caseMin) + 19;
	if (n3 < 0) or ((n3 - 19) div 2 <> caseMax - caseMin) then
		n3 := targetMaxInt;	(* オーバーフロー対策 *)
	if (n1 <= n3) or (numOfCase <= 4) then begin
		genCase4(root, numOfCase, 0);
		jk := 1
	end else begin
		genCase3(L1, caseMin, caseMax);
		jk := 3
	end;
(***********************************************************
    if (n3 < n1) and (n3 < n2) then begin
		genCase3(L1, caseMin, caseMax);
		jk := 3
    end else if n2 < n1 then begin
		genCase2(numOfCase, L1);
		jk := 2
    end else begin
		genCase1(root);
		jk := 1
    end;
***********************************************************)
	isActive[AXreg] := false;
	p := newCaseLink;
	with p^ do begin
		jkind := jk;
		caseInformationPtr := root;
		labelOfCase := L1;
		minValueOfCase := caseMin;
		maxValueOfCase := caseMax;
		next := caseLabelsLink
	end;
	caseLabelsLink := p
end; { GenCase }

procedure flushCaseLabels;
var
	p, p1 : refCaseLink;

	procedure flushCase1(p : refCaseLink);
	var
		q, q1 : refCaseInformation;
	begin
		q := p^.caseInformationPtr;
		while q <> nil do begin
			q1 := q;
			q := q^.next;
			disposeCaseInformation(q1)
		end
	end; { flushCase1 }

	procedure flushCase2(p : refCaseLink);
	var
		q, q1 : refCaseInformation;
		z : integer;
	begin
		openSegment(InCode);
		with p^ do begin
			outLabel0(labelOfCase + 3);
			if lsiR86 then
				write(outFile, ':');
			z := 0;
			q := caseInformationPtr;
			while q <> nil do begin
				if z = 0 then
					write(outFile, '	dw	', q^.caseValue)
				else
					write(outFile, ', ', q^.caseValue);
				z := z + 1;
				if z > 7 then begin
					z := 0;
					writeln(outFile)
				end;
				q := q^.next
			end;
			q := caseInformationPtr;
			while q <> nil do begin
				if z = 0 then
					write(outFile, '	dw	')
				else
					write(outFile, ', ');
				outLabel0(q^.caseLabel);
				z := z + 1;
				if z > 7 then begin
					z := 0;
					writeln(outFile)
				end;
				q1 := q;
				q := q^.next;
				disposeCaseInformation(q1)
			end;
			if z <> 0 then
				writeln(outFile)
		end { with }
	end; { flushCase2 }

	procedure flushCase3(p : refCaseLink);
	var
		q, q1 : refCaseInformation;
		v, Lx : integer;
		z : integer;
	begin
		openSegment(InCode);
		with p^ do begin
			outLabel0(labelOfCase + 3);
			if lsiR86 then
				write(outFile, ':');
			z := 0;
			q := caseInformationPtr;
			for v := minValueOfCase to maxValueOfCase do begin
				if q^.caseValue < v then begin
					q1 := q;
					q := q^.next;
					disposeCaseInformation(q1)
				end;
				if q^.caseValue = v then
					Lx := q^.caseLabel
				else
					Lx := labelOfCase + 1;
				if z = 0 then
					write(outFile, '	dw	')
				else
					write(outFile, ', ');
				outLabel0(Lx);
				z := z + 1;
				if z > 7 then begin
					z := 0;
					writeln(outFile)
				end
			end;
			if z <> 0 then
				writeln(outFile);
			if q <> nil then
				disposeCaseInformation(q)
		end { with }
	end; { flushCase3 }

begin	{ FlushCaseLabels }
	p := caseLabelsLink;
	while p <> nil do begin
		case p^.jkind of
			1: flushCase1(p);
			2: flushCase2(p);
			3: flushCase3(p);
			otherwise
				sysError('FlushCaseLabels')
		end;
		p1 := p;
		p := p^.next;
		disposeCaseLink(p1)
	end
end; { FlushCaseLabels }

procedure initCodeGen3;
begin
	initCodeGen4
end;

end.
