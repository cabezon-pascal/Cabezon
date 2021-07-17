(* file = cballoc.pas
 *
 * カベソンコンパイラ　：　メモリアロケーション
 *
 *
 * Copyright (C) 1990  Ockeghem
 *)
unit cballoc;

interface
uses cbcom;

var
	HashTable2 : array[0..HashSizeMinus1] of refIdentifier;
	localRootOfTypes : refStructure;
	localRootOfId, localRootOfLabels : refIdentifier;
	localRootOfReals, localRootOfStrings : refConstant;

procedure initAllocate;
procedure flushAllocate;
function newIdentifier : refIdentifier;
function newStructure : refStructure;
function newEvalTree : refEvalTree;
function newVarEvalTree(idType : refStructure) : refEvalTree;
function newConstant : refConstant;
function newCaseInformation : refCaseInformation;
function newCaseLink : refCaseLink;
function newWithLink : refWithLink;
function newArgsLink : refArgsLink;
procedure newScope;
procedure clearConstants;
procedure releaseScope;
procedure releaseGroupOfId(p : refIdentifier; d : boolean);
procedure disposeIdentifier(p : refIdentifier);
procedure disposeEvalTree(p : refEvalTree);
procedure disposeEvalTreeTree(p : refEvalTree);
procedure disposeWithLink(p : refWithLink);
procedure disposeArgsLink(p : refArgsLink);
procedure disposeConstant(p : refConstant);
procedure disposeConstEvalTree(p : refEvalTree);
procedure disposeCaseInformation(p : refCaseInformation);
procedure disposeCaseLink(p : refCaseLink);
procedure disposeGroupOfStructure;
procedure disposeGroupOfConstant;
procedure backupLocalRoot(var localRootSaver : localRootSaverType);
procedure restoreLocalRoot(var localRootSaver : localRootSaverType);

implementation

uses cbgen4, cberror;

var
	availEvalTree : refEvalTree;
	availIdentifier : refIdentifier;
	availStructure : refStructure;
	availConstant : refConstant;
	availCaseInformation : refCaseInformation;
	availCaseLink : refCaseLink;
	availArgsLink : refArgsLink;
	availScope : refScopeLink;
	availWithLink : refWithLink;

	(* 以下、デバッグ用 *)

	nEvalTree, nIdentifier, nStructure, nArgsLink, nCaseLink, 
			nCaseInformation, nConstant, nWithLink : integer;
	maxEvalTree, maxIdentifier, maxCaseInformation, maxArgsLink, maxCaseLink, 
			maxStructure, maxConstant, maxWithLink : integer;
	totalEvalTree, totalIdentifier, totalCaseInformation, totalArgsLink, 
			totalCaseLink, totalStructure, totalConstant, totalWithLink : 
			integer;


procedure inc(var x : integer);
begin
	x := x + 1
end;

procedure dec(var x : integer);
begin
	x := x - 1
end;

procedure clearLocalRoot;
begin
	localRootOfId := nil;
	localRootOfLabels := nil;
	localRootOfTypes := nil
end; { clearLocalRoot }

procedure clearConstants;
begin
	localRootOfStrings := nil;
	localRootOfReals := nil
end; { clearConstants }

procedure initAllocate;
begin
	availEvalTree := nil;
	availIdentifier := nil;
	availStructure := nil;
	availConstant := nil;
	availScope := nil;
	availWithLink := nil;
	availCaseInformation := nil;
	availCaseLink := nil;
	availArgsLink := nil;
	clearLocalRoot;

	(* 以下、デバッグ用 *)

	nEvalTree := 0;
	maxEvalTree := 0;
	totalEvalTree := 0;
	nIdentifier := 0;
	maxIdentifier := 0;
	totalIdentifier := 0;
	nStructure := 0;
	maxStructure := 0;
	totalStructure := 0;
	nArgsLink := 0;
	maxArgsLink := 0;
	totalArgsLink := 0;
	nConstant := 0;
	maxConstant := 0;
	totalConstant := 0;
	nWithLink := 0;
	maxWithLink := 0;
	totalWithLink := 0;
	nCaseInformation := 0;
	maxCaseInformation := 0;
	totalCaseInformation := 0;
	nCaseLink := 0;
	maxCaseLink := 0;
	totalCaseLink := 0;
end;

procedure newScope;
var
	w : refScopeLink;
begin
	if availScope = nil then
		new(w)
	else begin
		w := availScope;
		availScope := availScope^.parentScope
	end;
	w^.parentScope := topOfScope;
	w^.procedurep := currentRoutine;
	topOfScope := w
end; { newScope }

procedure releaseScope;
var
	w : refScopeLink;
begin
	w := topOfScope;
	topOfScope := topOfScope^.parentScope;
	currentRoutine := topOfScope^.procedurep;
	w^.parentScope := availScope;
	availScope := w
end; { releaseScope }

function newEvalTree : refEvalTree;
var
	p : refEvalTree;
begin
	if availEvalTree <> nil then begin
		newEvalTree := availEvalTree;
		availEvalTree := availEvalTree^.varIndex
	end else begin
		new(p);
		newEvalTree := p

		;
		inc(maxEvalTree)

	end;
	inc(nEvalTree);
	inc(totalEvalTree)

end; { newEvalTree }

function newVarEvalTree(idType : refStructure) : refEvalTree;
var
	p : refEvalTree;
begin
	p := newEvalTree;
	with p^ do begin
		evalType := idType;
		varIndex := nil;
		hugeIndex := nil;
		constIndex := 0		{ 初期値 }
	end;
	newVarEvalTree := p
end; { newEvalTree }

function newIdentifier : refIdentifier;
var
	p : refIdentifier;
begin
	if availIdentifier <> nil then begin
		newIdentifier := availIdentifier;
		availIdentifier := availIdentifier^.next
	end else begin
		new(p);
		newIdentifier := p

		;
		inc(maxIdentifier);

	end

	;
	inc(nIdentifier);
	inc(totalIdentifier)

end; { newIdentifier }

function newStructure : refStructure;
var
	p : refStructure;
begin
	if availStructure <> nil then begin
		p := availStructure;
		availStructure := availStructure^.next;
	end else begin
		new(p)

; inc(maxStructure);

	end;
	with p^ do begin
		next     := localRootOfTypes;
		isPacked := false;
		isHuge   := false
	end;
	localRootOfTypes := p;
	newStructure := p

; inc(nStructure);
	inc(totalStructure)

end; { newStructure }

function newConstant : refConstant;
var
	p : refConstant;
begin
	if availConstant <> nil then begin
		p := availConstant;
		availConstant := availConstant^.next
	end else begin
		new(p)

		;
		inc(maxConstant)

	end;
	p^.labelValue := undefinedLabel;
	newConstant := p;
	inc(nConstant);
	inc(totalConstant)

end; { newConstant }

function newCaseInformation : refCaseInformation;
var
	p : refCaseInformation;
begin
	if availCaseInformation <> nil then begin
		p := availCaseInformation;
		availCaseInformation := availCaseInformation^.next
	end else begin
		new(p)

		;
		inc(maxCaseInformation)

	end;
	newCaseInformation := p;
	inc(nCaseInformation);
	inc(totalCaseInformation)

end; { newCaseInformation }

function newCaseLink : refCaseLink;
var
	p : refCaseLink;
begin
	if availCaseLink <> nil then begin
		p := availCaseLink;
		availCaseLink := availCaseLink^.next
	end else begin
		new(p)

		;
		inc(maxCaseLink)

	end;
	newCaseLink := p;
	inc(nCaseLink);
	inc(totalCaseLink)

end; { newCaseLink }

function newWithLink : refWithLink;
var
	p : refWithLink;
begin
	if availWithLink <> nil then begin
		p := availWithLink;
		availWithLInk := availWithLink^.next
	end else begin
		new(p)

		;
		inc(maxWithLink)

	end;
	newWithLink := p;
	inc(nWithLink);
	inc(totalWithLink)

end; { newWithLink }

function newArgsLink : refArgsLink;
var
	p : refArgsLink;
begin
	if availArgsLink <> nil then begin
		p := availArgsLink;
		availArgsLink := availArgsLink^.next
	end else begin
		new(p)

		;
		inc(maxArgsLink)

	end;
	newArgsLink := p;
	inc(nArgsLink);
	inc(totalArgsLink)

end; { newArgsLink }

procedure disposeEvalTree(p : refEvalTree);
begin
	p^.varIndex := availEvalTree;
	availEvalTree := p

	;
	dec(nEvalTree)

end; { disposeEvalTree }

procedure disposeIdentifier(p : refIdentifier);
begin
	p^.next := availIdentifier;
	availIdentifier := p

	;
	dec(nIdentifier)

end; { disposeIdentifier }

procedure disposeTreeOfId(p : refIdentifier);
begin
	if p <> nil then begin
		disposeTreeOfId(p^.llink);
		disposeTreeOfId(p^.rlink);
		disposeIdentifier(p)
	end
end; { disposeTreeOfId }

procedure disposeStructure(p : refStructure);
begin
	with p^ do begin
		if form = records then
			disposeTreeOfId(firstField);
		next := availStructure;
		availStructure := p
	end

	;
	dec(nStructure)

end; { disposeStructure }

procedure disposeConstant(p : refConstant);
begin
	p^.next := availConstant;
	availConstant := p

	;
	dec(nConstant)
end; { disposeConstant }

procedure disposeConstEvalTree(p : refEvalTree);
begin
	disposeConstant(p^.const1);
	disposeEvalTree(p)
end; { disposeConstEvalTree }

procedure disposeCaseInformation(p : refCaseInformation);
begin
	p^.next := availCaseInformation;
	availCaseInformation := p

	;
	dec(nCaseInformation)

end; { disposeCaseInformation }

procedure disposeCaseLink(p : refCaseLink);
begin
	p^.next := availCaseLink;
	availCaseLink := p

	;
	dec(nCaseLink)

end; { disposeCaseLink }

procedure disposeWithLink(p : refWithLink);
begin
	p^.next := availWithLink;
	availWithLink := p

	;
	dec(nWithLink)

end; { disposeWithLink }

procedure disposeArgsLink(p : refArgsLink);
begin
	p^.next := availArgsLink;
	availArgsLink := p

	;
	dec(nArgsLink)

end; { disposeArgsLink }

procedure disposeEvalTreeTree(p : refEvalTree);
var
	a : refArgsLink;
begin
	with p^ do
		case nodeType of
			opVariable: if varIndex <> nil then
					disposeEvalTreeTree(varIndex);
			opConstant: if const1 <> nil then
					disposeConstant(const1);
			opProcedure, opFunction: begin
					a := args;
					while a <> nil do begin
						disposeEvalTreeTree(a^.exp);
						a := a^.next
					end
				end;
			opIndirect: begin
					disposeEvalTreeTree(ref1);
					if varIndex <> nil then
						disposeEvalTreeTree(varIndex)
				end;
			operator: begin
					disposeEvalTreeTree(operand1);
					if operand2 <> nil then
						disposeEvalTreeTree(operand2)
				end;
			opRangeCheck: disposeEvalTreeTree(expr);
			otherwise
				begin
					writeln('ord(nodeType) = ', ord(nodeType));
					sysError('disposeEvalTreeTree')
				end
		end; { case }
	disposeEvalTree(p)
end; { disposeEvalTreeTree }

(* 手続き名：realeaseId
 *
 * 目的：ハッシュテーブルから名前を取のぞく
 *
 * 引数：p : 名前のポインタ
 *)
procedure releaseId(p : refIdentifier);
var
	h : integer;
	q, r : refIdentifier;
begin
	with p^ do begin
		h := hashValue;
		q := HashTable2[h];
		r := nil;
		while q <> p do begin
			r := q;
			q := q^.hashNext
		end;
		if r = nil then
			HashTable2[h] := p^.HashNext
		else
			r^.HashNext := q^.HashNext
	end
end; { releaseId }

procedure disposeId(p : refIdentifier);
var
	u, ux : refIdentifier;
begin
	with p^ do begin
		case klass of
			procedures, functions: begin
					if (procOrFuncKind = declared) and forwardDec then
						errorName(37, name^, errors);
					if used and (idDeclareClass = extern) then
						genExternalProcedure(p);
					u := paramp;
					while u <> nil do begin
						ux := u^.next;
						disposeId(u);
						u := ux
					end
				end;
			constants: begin
					if used and (idDeclareClass = extern) and (idType = 
							realPtr) then
						aliasOfRealConst(p)
				end;
			vars: begin
					if used and (idDeclareClass = extern) then
						genStaticData(p, p^.idType)
				end;
			labels: begin
					case state of
						undefined: errorName(49, name^, warnings);
						forwardDeclared: errorName(49, name^, errors);
						defined, finished:;	(* 何もしない *)
					end
				end;
			otherwise
			(* 何もしない *)
		end; { case }
		dispose(name)
	end;
	disposeIdentifier(p)
end; { disposeId }

procedure releaseGroupOfId(p : refIdentifier; d : boolean);
var
	u, nx : refIdentifier;
begin
	u := p;
	while u <> nil do begin
		nx := u^.next;
		releaseId(u);
		if d then
			disposeid(u);
		u := nx
	end
end; { releaseGroupOfId }

procedure disposeGroupOfStructure;
var
	p, q : refStructure;
begin
	p := localRootOfTypes;
	while p <> nil do begin
		q := p^.next;
		disposeStructure(p);
		p := q
	end
end; { disposeGroupOfStructure }

procedure disposeGroupOfLabels;
var
	p, q : refIdentifier;
begin
	p := localRootOfLabels;
	while p <> nil do begin
		q := p^.next;
		disposeId(p);
		p := q
	end
end; { disposeGroupOfLabels }

procedure disposeGroupOfConstant;
var
	p, q : refConstant;
begin
	p := localRootOfReals;
	while p <> nil do begin
		with p^ do begin
			q := p^.next;
			genRealConst(p^);
			dispose(p^.strgValuePtr);
			disposeConstant(p)
		end; { with p^ }
		p := q
	end;
	p := localRootOfStrings;
	while p <> nil do begin
		with p^ do begin
			q := p^.next;
			genStringConst(p^);
			dispose(p^.strgValuePtr);
			disposeConstant(p)
		end; { with p^ }
		p := q
	end
end; { disposeGroupOfConstant }

procedure backupLocalRoot(var localRootSaver : localRootSaverType);
begin
	with localRootSaver do begin
		idSave := localRootOfId;
		labelsSave := localRootOfLabels;
		typeSave := localRootOfTypes
	end;
	clearLocalRoot
end; { backupLocalRoot }

procedure flushDataOfScope;
begin
	disposeGroupOfStructure;
	(*  disposeGroupOfLabels;	*)
	releaseGroupOfId(LocalRootOfLabels, true(* dispose *));
	releaseGroupOfId(LocalRootOfId, true(* dispose *))
end; { flushDataOfScope }

procedure restoreLocalRoot(var localRootSaver : localRootSaverType);
begin
	flushDataOfScope;

	with localRootSaver do begin
		localRootOfId := idSave;
		localRootOfLabels := LabelsSave;
		localRootOfTypes := typeSave
	end
end;

procedure flushAllocate;
begin
	flushDataOfScope;
	if debug then begin
		writeln('nEvalTree   = ', nEvalTree, ' maxEvalTree   = ', maxEvalTree, 
				' totalEvalTree   = ', totalEvalTree);
		writeln('nIdentifier = ', nIdentifier, ' maxIdentifier = ', 
				maxIdentifier, ' totalIdentifier = ', totalIdentifier);
		writeln('nStructure  = ', nStructure, ' maxStructure  = ', 
				maxStructure, ' totalStructure  = ', totalStructure);
		writeln('nConstant   = ', nConstant, ' maxConstant   = ', maxConstant, 
				' totalConstant   = ', totalConstant);
		writeln('nWithLink   = ', nWithLink, ' maxWithLink   = ', maxWithLink, 
				' totalWithLink   = ', totalWithLink);
		writeln('nArgsLink   = ', nArgsLink, ' maxArgsLink   = ', maxArgsLink, 
				' totalArgsLink   = ', totalArgsLink);
		writeln('nCaseInformation = ', nCaseInformation, 
				' maxCaseInformation= ', maxCaseInformation, 
				' totalCaseInformation = ', totalCaseInformation);
		writeln('nCaseLink = ', nCaseLink, ' maxCaseLink = ', maxCaseLink, 
				' totalCaseLink = ', totalCaseLink)
	end
end;

end.
