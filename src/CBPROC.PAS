(* file = cbproc.pas
 *
 * カベソンコンパイラ　：　手続き宣言の構文解析
 *
 *
 *  Copyright (C) 1990  Ockeghem
 *)

unit cbproc;

interface
uses cbcom;

procedure procedureOrFunctionDeclaration;

implementation

uses cballoc, cbtype, cblex, cbtable, cberror, cbmodule, cbgen2, cbexgen4, 
		cblabel, cbdump;

procedure setReturnValueId;
var
	p : refIdentifier;
begin
	p := setId('@returnValue', vars, currentRoutine^.idType);
	with p^ do begin
		level := currentLevel;
		if isRegisterLoadable(idType) then begin
			alignment(idType, false(* not static *), locationPtr);
			locationPtr := locationPtr + idType^.size;

			(* ここでアラインメントの調整が必要だが、怠っている *)

			variableAddress := -locationPtr;
			variableKind := actual
		end else begin
			variableAddress := lengthOfStackFrame(currentRoutine) + 
					currentRoutine^.argumentSize;
			variableKind := formal
		end
	end; { with p^ }
	topOfScope^.returnValue := p
end; { setReturnValueId }

procedure block;
var
	localRootSaver : localRootSaverType;	(* localRootの保存用 *)
begin
	if currentRoutine^.klass = functions then
		setReturnValueId;
	backupLocalRoot(localRootSaver);
	anyDeclaration;
	body;
	restoreLocalRoot(localRootSaver)
end; { block }

procedure procedureOrFunctionDeclaration;
var
	procOrFunc : symbol;
	saveLocationPtr : integer;

	function checkTypeName : refStructure;
	begin
		checkId(disasters);
		checkTypeName := checkType(id);
		getsym
	end; { checkTypeName }

	function procOrFuncHeader(isParam : boolean) : symbol;
	var
		MySym : symbol;
		cr : refIdentifier;

	(*  手続き名：enterArgument
	 *
	 *  目的：手続きの引数の名前表への挿入
	 *)
		procedure enterArguments;
		var
			p : refIdentifier;
		begin
			p := currentRoutine^.paramp;
			while p <> nil do begin
				enterId(p);
				p := p^.next
			end
		end; { enterArguments }

	(*  手続き名：checkArgumentList
	 *
	 *  目的：forward宣言された手続きの引数のチェック
	 *)
		procedure checkArgumentList;
		var
			p, head, tail : refIdentifier;
			ik : idKind;
			argType : refStructure;
		begin
			p := currentRoutine^.paramp;
			repeat
				head := p;
				getsym;	{ 左括弧あるいはセミコロンの読み飛ばし }
				case sym of
					proceduresym, functionsym: 
						procOrFunc := procOrFuncHeader(true);	{ 未実装 }
					otherwise
						begin
							if sym = varsym then begin
								ik := formal;
								getsym
							end else
								ik := actual;

							repeat
								checkId(disasters);
								if p = nil then
									error(36, disasters);
								if (p^.name^ <> id) or 
									(p^.variableKind <> ik) then
									error(36, disasters);
								enterId(p);
								p := p^.next;
								getsym;
							until isNot(comma);
							checkSym(colon, disasters);
							argType := checkTypeName;

							tail := p;
							p := head;
							while p <> tail do begin
								if p^.idType <> argType then
									error(36, disasters);
								p := p^.next
							end { while }
						end { else }
				end { case }
			until sym <> semicolon;
			if p <> nil then
				error(36, disasters);
			checkSym(rparen, disasters)
		end; { checkArgumentList }

	(*  手続き名：argumentList
	 *
	 *  目的：手続きの引数の処理
	 *)
		procedure argumentList(var params : refIdentifier);
		var
			procOrFunc : symbol;
			head, tail, p, insertPos : refIdentifier;
			saveLocationPtr : integer;
			ik : idKind;
			sizeOnStack : integer;
			argType : refStructure;
		begin
			insertPos := nil;
			params := nil;
			repeat
				getsym;	{ 左括弧あるいはセミコロンの読み飛ばし }
				case sym of
					proceduresym, functionsym: begin
							saveLocationPtr := locationPtr;
							procOrFunc := procOrFuncHeader(true);
							releaseGroupOfId(currentRoutine^.paramp,
											 false(* no dispose *));
							currentLevel := currentLevel - 1;
							head := currentRoutine;
							tail := currentRoutine;
							head^.next := nil;
							releaseScope;
							locationPtr := saveLocationPtr;
						end;
					otherwise
						begin
							if sym = varsym then begin
								ik := formal;
								getsym
							end else
								ik := actual;

							head := nil;
							repeat
								checkId(disasters);
								p := setId(id, vars, nil(* dummy *));
								with p^ do begin
									next := head;
									variableKind := ik
								end;
								getsym;
								head := p;
								enterId(p)
							until isNot(comma);
							checkSym(colon, disasters);
							argType := checkTypeName;
							if (ik = actual) and (argType^.isHuge) then
								error(57, errors)
							else if (ik = formal) or 
									not isRegisterLoadable(argType) then begin
								sizeOnStack := targetPtrSize;
								alignment(pointerPtr, false, locationPtr)
							end else begin
								sizeOnStack := argType^.size;
								alignment(argType, false, locationPtr)
							end;
							tail := head;			{ tail : 変数つなぎの末尾 }
							reverseIdLink(head);	{ head : 変数つなぎの先頭 }
							p := head;
							while p <> nil do begin
								with p^ do begin
									idType := argType;
									variableAddress := locationPtr
								end;
								locationPtr := alignment0(targetArgumentAlign, 
										locationPtr + sizeOnStack);
								p := p^.next
							end
						end
				end; { case }
				if insertPos = nil then
					params := head
				else
					insertPos^.next := head;
				insertPos := tail
			until sym <> semicolon;
			checkSym(rparen, disasters)
		end; { argumentList }

		procedure reallocateOfArguments;
		var
			p : refIdentifier;
			stackFrame, sizeOnStack : integer;
		begin
			with currentRoutine^ do begin
				stackFrame := lengthOfStackFrame(currentRoutine) + 
						argumentSize;
				p := paramp;
				while p <> nil do begin
					with p^ do begin
						if (variableKind = formal) or not isregisterloadable(
								idType) then
							sizeOnStack := targetPtrSize
						else
							sizeOnStack := alignment0(targetArgumentAlign, 
									idType^.size);
						variableAddress := stackFrame - variableAddress - 
								sizeOnStack
					end;
					p := p^.next
				end
			end
		end; { reallocateOfArguments }

	begin	{ procOrFuncHeader }
		MySym := sym;
		getsym;	(* "procedure"または"function"の読み飛ばし *)
		checkId(disasters);

		cr := searchSection(id);	(* forward宣言のチェック *)
		if cr <> nil then begin

			(* forward宣言されている場合の処理 *)

			with cr^ do begin
				currentRoutine := cr;
				getsym;
				if (klass <> procedures) and (klass <> functions) then
					errorName(4, id, disasters)
				else if not forwardDec then
					errorName(4, id, disasters);

				(* スコープのレベルを上げる *)

				newScope;
				currentLevel := currentLevel + 1;

				(* 引数のチェック *)

				if sym <> lparen then
					enterArguments
				else
					checkArgumentList;

				(* 関数の戻り値のチェック *)

				if (MySym = functionsym) and (sym = colon) then begin
					getsym;
					if idType <> checkTypeName then
						error(36, disasters)
				end
			end { with }
		end else begin
			(* forward宣言されてない場合の処理 *)

			if isParam then
				cr := setId(id, procedures, nil)
			else
				cr := setId2(id, procedures, nil);

			(* ↑↑　とりあえずprocedureで宣言 *)

			with cr^ do begin
				procOrFuncKind := declared;
				forwardDec := false;	{ default }
				externDec := false;		{ default }
				if isParam then
					variableKind := formal
				else
					variableKind := actual;

				(* ３つのラベルを生成
				 *	L+0 : 手続きの入口
				 *  L+1 : ローカル変数の大きさを示すラベル
				 *  L+2 : 手続きの出口
				 *)
				labelValue := genLabel(3);
				if MySym = functionsym then	(* で、関数だったら修正 *)
					klass := functions;

				currentRoutine := cr;
				getsym;
				enterId(currentRoutine);

				(* スコープのレベルを上げる *)

				newScope;
				currentLevel := currentLevel + 1;
				locationPtr := 0;

				if sym = lparen then
					argumentList(paramp)
				else
					paramp := nil;

				argumentSize := locationPtr;

				(* 関数の戻りのチェック *)

				if MySym = functionsym then begin
					checkSym(colon, disasters);
					idType := checkTypeName;
					if idType^.isHuge then
						error(57, errors)
				end;
				reallocateOfArguments
			end { with cr^ }
		end; { if }

		procOrFuncHeader := MySym
	end; { procOrFuncHeader }

begin	{ procedureOrFunctionDeclaration }
	saveLocationPtr := locationPtr;
	procOrFunc := procOrFuncHeader(false);
	locationPtr := 0;

	checkSym(semicolon, disasters);
	if currentClass = private then begin
		if sym <> ident then
			block
		else if id = 'FORWARD' then begin
			currentRoutine^.forwardDec := true;
			getsym
		end else if id = 'EXTERNAL' then begin
			currentRoutine^.externDec := true;
			currentRoutine^.forwardDec := false;
			getsym
		end else
			error(9, disasters);
		checkSym(semicolon, disasters)
	end else if currentClass = public then	(* publicというのは	     *)
		currentRoutine^.forwardDec := true;	(* interface節での宣言のこと *)

	(* externの場合はとくに処理なし *)

	releaseGroupOfId(currentRoutine^.paramp, false(* no dispose *));
	currentLevel := currentLevel - 1;
	releaseScope;
	locationPtr := saveLocationPtr

end; { procedureOrFunctionDeclaration }

end.
