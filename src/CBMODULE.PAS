(* file = cbmodule.pas
 *
 * カベソンコンパイラ　：　宣言の構文解析
 *
 *
 *  Copyright (C) 1990  Ockeghem
 *)

unit cbmodule;

interface
uses cbCom;

procedure usesOne(name : fileNameType; check : boolean);
procedure programOrUnit;
procedure anyDeclaration;
procedure body;
(**  procedure block;	**)

implementation

uses cbtype, cbstate, cbproc, cbtable, cblex, cberror, cballoc, cbexpr, 
		cbgen1, cbgen2, cbgen3, cbgen4, cbexgen4, cblabel;


procedure usesOne(name : fileNameType; check : boolean);
var
	saveListp : boolean;
begin
	saveListp := listp;
	listp := false;
	newFile(false(* not included *), makeFileName(name));
	getsym;	(* 空読み *)
	checkSym(unitsym, errors);
	checkId(errors);
	if check and (id <> name) then
		error(33, disasters)
	else
		getsym;
	checkSym(semicolon, errors);
	checkSym(interfacesym, errors);
	anyDeclaration;
	checkSym(implementationsym, errors);
	disposeFile;
	listp := saveListp
end;

procedure usesDeclaration;
var
	p, head, tail : refIdentifier;
	currentClassSave : declareClass;
begin
	head := nil;
	currentClassSave := currentClass;
	repeat
		checkId(disasters);
		p := searchSection(id);
		getsym;
		if p = nil then begin
			p := setId(id, units, nil);
			with p^ do begin
				procOrFuncKind := declared;
				paramp := nil;
				argumentSize := 0;
				next := head
			end; { with p^ }
			head := p;
			enterId(p)
		end else if p^.klass <> units then
			errorName(4, id, disasters)	{ duplicate }
	until isNot(comma);

	tail := head;
	reverseIdLink(head);
	currentClass := extern;

	p := head;
	while p <> nil do begin
		usesOne(p^.name^, true);
		p := p^.next
	end;
	checkSym(semicolon, errors);

	if head <> nil then begin
		tail^.next := localRootOfId;
		localRootOfId := head
	end;
	currentClass := currentClassSave;
end; { usesDeclaration }

procedure labelDeclaration;
var
	p : refIdentifier;
begin
	if currentClass <> private then
		error(21, disasters);
	repeat
		if sym = intConst then begin
			if (val.intValue < 0) or (val.intValue > 9999) then
				error(18, disasters);
			str(val.intValue, id)
		end else if sym <> ident then
			error2('number or identifier', disasters);
		p := setId(id, labels, nil(* dummy *));
		getsym;	(* ラベルの読み飛ばし *)
		with p^ do begin
			labelValue := genLabel(1);
			state := undefined;
			next := localRootOfLabels
		end;
		enterId(p);
		localRootOfLabels := p;
	until isNot(comma);
	checkSym(semicolon, errors)
end; { labelDeclaration }

procedure constDeclaration;
var
	p : refIdentifier;
begin
	checkId(disasters);
	repeat
		p := setId2(id, constants, nil(* dummy *));
		with p^ do begin
			getsym;
			checkSym(eql, disasters);
			idType := getConst(values);
			enterId(p);
			with values do begin
				labelValue := genLabel(1);
				if idType = realPtr then begin
					if currentClass = public then
						genRealConstWithName(p)
					else if currentClass = private then
						genRealConst(values)
				end else if idType^.form = stringConsts then
					genStringConst(values)
			end; { with values }
			if currentLevel > 1 then
				labelValue := genLabel(1);
		end; { with p^}
		checkSym(semicolon, errors)
	until sym <> ident
end; { constDeclaration }

procedure typeDeclaration;
var
	p, q, u : refIdentifier;
begin
	typeForwardLink := nil;
	repeat
		checkId(disasters);
		p := setId2(id, types, nil(* dummy *));
		getsym;	(* id の読み飛ばし *)
		checkSym(eql, disasters);
		p^.idType := typeDec(true(* forward ref *));
		enterId(p);
		checkSym(semicolon, errors)
	until sym <> ident;
	p := typeForwardLink;
	while p <> nil do begin
		u := searchId(p^.name^, disasters);
		with u^ do begin
			if klass <> types then
				error2('type name', disasters);
			p^.idType^.elementTypeOfPointer := idType
		end;
		q := p;
		p := p^.next;
		disposeIdentifier(q)
	end
end; { typeDeclaration }

procedure varDeclaration;
var
	p, head, tail : refIdentifier;
	variableType : refStructure;
	staticDec : boolean;
begin
	repeat
		head := nil;	{ 変数のつなぎ }
		repeat
			checkId(disasters);
			p := setId(id, vars, nil(* dummy *));
			with p^ do begin
				variableKind := actual;
				next := head
			end;
			getsym;
			head := p;
			enterId(p)
		until isNot(comma);
		checkSym(colon, disasters);
		variableType := typeDec(false(* not forward ref *));
		staticDec := (currentLevel <= 1) and (currentClass <> extern);
		alignment(variableType, staticDec, locationPtr);

		tail := head;	{ tail : 変数つなぎの末尾 }
		reverseIdLink(head);	{ head : 変数つなぎの先頭 }
		p := head;
		if (currentLevel > 1) and variableType^.isHuge then
			error(57, errors);
		while p <> nil do begin
			with p^ do begin
				idType := variableType;
				variableAddress := -locationPtr - variableType^.size
			end;
			if staticDec then
				genStaticData(p, variableType);
			locationPtr := locationPtr + variableType^.size;
			p := p^.next
		end;

		tail^.next := localRootOfId;
		localRootOfId := head;

		checksym(semicolon, errors)
	until sym <> ident
end; { varDeclaration }

procedure moveValueArgument;	(* 構造型の値引数のローカルコピーを行う *)
var
	p : refIdentifier;
	oldAddress, newAddress : integer;
begin
	p := currentRoutine^.paramp;
	while p <> nil do begin
		with p^ do begin

			(*  ↓　構造型でかつ値引数であることの判定  *)

			if (klass = vars) and (variableKind = actual) and not 
					isregisterloadable(idType) then begin
				alignment(idType, false(* not static *), locationPtr);
				locationPtr := locationPtr + idType^.size;
				oldAddress := variableAddress;
				newAddress := -locationPtr;
				genMoveDataOfArgument(oldAddress, newAddress, idType^.size);

				(* ↑ 引数１個文のコピー *)

				variableAddress := newAddress
			end; { if }
		end; { with p^ }
		p := p^.next
	end
end; { moveValueArgument }

procedure body;
var
	L1 : integer;
begin
	L1 := currentRoutine^.labelValue + 1;
	clearConstants;
	caseLabelsLink := nil;
	entryProc(currentRoutine, L1);
	currentRoutine^.forwardDec := false;	(* forwardフラグを外す *)
	checkSym(beginsym, disasters);
	moveValueArgument;	(* 構造型の値引数のローカルコピー *)
	maxLocation := locationPtr;

	nestLevel := 0;		(* nestLevel は cbstate からimport *)
	blockStatementList;
	exitProc(currentRoutine, L1);
	disposeGroupOfConstant;
	flushCaseLabels;
	checkSym(endsym, errors)
end; { body }

procedure anyDeclaration;
begin
	if sym = usessym then begin
		getsym;
		usesDeclaration
	end;
	if sym = labelsym then begin
		getsym;
		labelDeclaration
	end;
	if sym = constsym then begin
		getsym;
		constDeclaration
	end;
	if sym = typesym then begin
		getsym;
		typeDeclaration
	end;
	if sym = varsym then begin
		getsym;
		varDeclaration
	end;
	while (sym = proceduresym) or (sym = functionsym) do
		procedureOrFunctionDeclaration
end; { anyDeclaration }

procedure unitDeclaration;
var
	localRootSaver : localRootSaverType;	(* LocalRootの保存用 *)
begin
	checkSym(unitsym, errors);
	checkId(errors);
	programOrUnitName := id;
	currentRoutine := setId2(programOrUnitName, units, nil);
	with currentRoutine^ do begin
		paramp := nil;
		labelValue := genLabel(3);
		argumentSize := 0;
		procOrFuncKind := declared
	end;
	getsym;
	enterId(currentRoutine);
	checkSym(semicolon, errors);

	newScope;
	entryOfModule;
	checkSym(interfacesym, errors);
	currentClass := public;

	backupLocalRoot(localRootSaver);

	anyDeclaration;

	checkSym(implementationSym, errors);
	currentClass := private;
	anyDeclaration;
	restoreLocalRoot(localRootSaver);
	checkSym(endsym, errors)
end; { unitDeclaration }

procedure programDeclaration;
var
	localRootSaver : localRootSaverType;	(* localRootの保存用 *)

	procedure programHeader;
	begin
		checkSym(programsym, errors);
		checkId(errors);
		programOrUnitName := id;
		currentRoutine := setId2(programOrUnitName, programs, nil);
		with currentRoutine^ do begin
			paramp := nil;
			labelValue := genLabel(3);
			argumentSize := 0;
			procOrFuncKind := declared;
			idDeclareClass := public	(* programだけ例外として、 *)
		end; (* publicとする		   *)
		getsym;
		enterId(currentRoutine);
		if sym = lparen then begin
			repeat
				getsym;	(* 左括弧あるいはコンマの読み飛ばし *)
				checkId(errors);
				if id = 'FLOAT' then
					floatCall := true;
				getsym
			until sym <> comma;
			checkSym(rparen, disasters)
		end;
		checkSym(semicolon, errors)
	end; { programHeader }

begin
	backupLocalRoot(localRootSaver);

	programHeader;
	newScope;
	entryOfModule;
	genStaticData(stackFrameSaver, intPtr);
	currentClass := private;
	anyDeclaration;
	locationPtr := 0;	(* 再設定 *)
	body;
	restoreLocalRoot(localRootSaver)
end; { programDeclaration }

procedure programOrUnit;
begin
	currentLevel := currentLevel + 1;
	locationPtr := 0;
	topOfScope := nil;

	if sym = unitsym then
		unitDeclaration
	else
		programDeclaration;
	if sym <> period then
		error2('period', disasters);
	currentLevel := currentLevel - 1;
	releaseScope
end; { programOrUnit }

end.
