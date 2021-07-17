(* file = cbtype.pas
 *
 * カベソンコンパイラ　：　型宣言の構文解析
 *
 *
 * Copyright (C) 1990  Ockeghem
 *)
unit cbtype;

interface
uses cbcom;
var
	typeForwardLink : refIdentifier;

function isSimpleType(t : refStructure) : boolean;
function scalarType(p : refStructure) : boolean;
function originalType(p : refStructure) : refStructure;
function alignment0(alignUnit, location : integer) : integer;
procedure alignment(tp : refStructure; isStatic : boolean; var location : 
		integer);
function compatible(a, b : refStructure) : boolean;
function checkType(var id : alpha) : refStructure;
function typeDec(forwardRef : boolean) : refStructure;
function elementTypeDec(forwardRef : boolean) : refStructure;
procedure boundOfType(p : refStructure;
					  var minValue, maxValue, sizeOftype : integer);

		implementation

uses cbmodule, cbexpr, cberror, cblex, cbtable, cballoc, cbgen4, cbdump;

(* 関数：isSimpleType
 *
 * 目的：単純な型かどうかを判定する
 * 　　：単純な型とは、スカラーかポインタのこと
 *
 * 引数：p：型
 *
 * 戻り値：単純な型ならtrue、さもなければfalse
 *)
function isSimpleType(t : refStructure) : boolean;
begin
	with t^ do
		case form of
			scalars: isSimpleType := t <> realPtr;
			subranges, pointers: isSimpleType := true;
			otherwise
				isSimpleType := false
		end
end; { isSimpleType }

function originalType(p : refStructure) : refStructure;
begin
	if p^.form = subranges then
		originalType := p^.rangeType
	else
		originalType := p
end; { originalType }

function scalarType(p : refStructure) : boolean;
var
	f : structureForm;
begin
	f := p^.form;
	if f = subranges then
		scalarType := true
	else if f = scalars then
		scalarType := p <> realPtr
	else if f = stringConsts then
		scalarType := p^.stringSize = 1	(* １文字の文字定数 *)
	else
		scalarType := false
end; { scalarType }

function alignment0(alignUnit, location : integer) : integer;
var
	L : integer;
begin
	L := location + alignUnit - 1;
	alignment0 := L - L mod alignUnit
end;

procedure alignment(tp : refStructure; isStatic : boolean; var location : 
		integer);
var
	L1 : integer;
begin
	L1 := alignment0(tp^.alignmentUnit, location);
	if isStatic then
		genDummyData(L1 - location);
	location := L1
end;

function compatible(a, b : refStructure) : boolean;
var
	aForm, bForm : structureForm;
begin
	if a = b then
		compatible := true
	else begin
		a := originalType(a);
		b := originalType(b);
		aForm := a^.form;
		bForm := b^.form;
		if (aForm = stringConsts) and (b = charPtr) then
			compatible := (a^.stringSize = 1)
		else if (bForm = stringConsts) and (a = charPtr) then
			compatible := (b^.stringSize = 1)
		else if ((aForm = strings) or (aForm = stringConsts)) and ((bForm = 
				strings) or (bForm = stringConsts)) then
			compatible := compatible(a^.stringElementType, b^.
					stringElementType)
		else if (a = pointerPtr) and (bForm = pointers) or (b = pointerPtr) 
				and (aForm = pointers) or (a = bytePtr) and (b = intPtr) or (
				a = intPtr) and (b = bytePtr) then
			compatible := true
		else
			compatible := (a = b)
	end
end; { compatible }

function checkType(var id : alpha) : refStructure;
var
	p : refIdentifier;
begin
	p := searchId(id, disasters);
	with p^ do begin
		if klass <> types then
			error2('type name', disasters);
		checkType := idType
	end
end; { checkType }

procedure boundOfType(p : refStructure; 
					  var minValue, maxValue, sizeOfType : integer);
begin
	with p^ do begin
		case form of
			scalars: begin
					minValue := 0;
					if p = intPtr then begin
						minValue := targetMinint;
						maxValue := targetMaxint
					end else if p = charPtr then begin
						minValue := targetMinByte;
						maxValue := targetMaxByte
					end else if scalarKind = declared then begin
						minValue := 0;
						maxValue := tailOfEnumration^.values.intValue
					end else begin
						dumpType(p);
						sysError('boundOfType #1')
					end
				end;
			subranges: begin
					minValue := minValueOfSubrange;
					maxValue := maxValueOfSubrange
				end;
			otherwise
				begin
					dumpType(p);
					sysError('boundOfType #2')
				end;
		end { case }
	end; { with }
	sizeOfType := maxValue - minValue + 1
end; { boundOfType }

function elementTypeDec(forwardRef : boolean) : refStructure;
var
	p : refStructure;
begin
	p := typeDec(forwardRef);
	if p^.isHuge then
		error(59, errors);
	elementTypeDec := p
end;

function typeDec(forwardRef : boolean) : refStructure;
var
	TypePtr, elementType, stringSizeType : refStructure;
	strSize : constant;
	p : refIdentifier;
	hugeType, packedType : boolean;

	function simpleType : refStructure;
	var
		typePtr : refStructure;
		p, head, tail : refIdentifier;
		enumCounter : integer;

		function subrangeType : refStructure;
		var
			typePtr, type1, type2 : refStructure;
			value1, value2 : constant;
		begin
			type1 := getConst(value1);
			if not scalarType(type1) then
				errorType1(29, type1, disasters);
			if type1^.form = stringConsts then
				type1 := charPtr;
			typePtr := newStructure;
			with typePtr^ do begin
				form := subranges;
				size := type1^.size;
				alignmentUnit := type1^.alignmentUnit;
				rangeType := type1;

				checkSym(fromTo, disasters);
				type2 := getConst(value2);
				if not scalarType(type2) then
					errorType1(29, type2, disasters);
				if type2^.form = stringConsts then
					type2 := charPtr;
				if type1 <> type2 then
					errorType2(30, type1, type2, disasters);

				minValueOfSubRange := value1.intValue;
				maxValueOfSubRange := value2.intValue;

				if minValueOfSubRange > maxValueOfSubRange then
					error(31, disasters);
				if (type1 = intPtr) and (minValueOfSubRange >= targetMinByte) 
						and (maxValueOfSubRange <= targetMaxByte) then begin
					size := targetByteSize;
					alignmentUnit := targetByteAlign;
					rangeType := bytePtr
				end
			end;
			subrangeType := typePtr
		end; { subrangeType }

	begin	{ simpleType }
		if sym = lparen then begin
			typePtr := newStructure;
			head := nil;
			enumCounter := 0;
			repeat
				getsym;	(* 左括弧またはコンマの読み飛ばし *)
				checkId(disasters);
				p := setId(id, constants, typePtr);
				with p^ do begin
					next := head;
					values.strgValuePtr := nil;
					values.intValue := enumCounter
				end;
				getsym;
				head := p;
				enterId(p);
				enumCounter := enumCounter + 1
			until sym <> comma;
			tail := head;
			reverseIdLink(head);
			tail^.next := localRootOfId;
			localRootOfId := head;
			with typePtr^ do begin
				tailOfEnumration := tail;
				if enumCounter <= targetMaxByte then begin
					size := targetByteSize;
					alignmentUnit := targetByteAlign
				end else begin
					size := targetIntegerSize;
					alignmentUnit := targetIntegerAlign
				end;
				form := scalars;
				scalarKind := declared
			end;
			checkSym(rparen, disasters)
		end else if sym = ident then begin
			p := searchId(id, disasters);
			if p^.klass = types then begin
				typePtr := p^.idType;
				getsym
			end else
				typePtr := subrangeType
		end else
			typePtr := subrangeType;
		simpleType := typePtr
	end; { simpleType }

	(*	array[　より後の処理を行う		*)
	(*	多次元配列は、再帰呼出で処理している	*)

	function arrayType(hugeType, packedType : boolean) : refStructure;
	var
		typePtr : refStructure;
		minValue, maxValue, sizeOftype : integer;
	begin
		typePtr := newStructure;
		with typePtr^ do begin
			form := arrays;
			isPacked := packedType;
			isHuge   := hugeType;
			indexType := simpleType;
			boundOfType(indexType, minValue, maxValue, sizeOfType);
			if sym = comma then begin
				getsym;
				arrayElementType := arrayType(false, false);
											(* 多次元配列の再帰呼出 *)
				if arrayElementType^.isHuge then
					error(59, errors)
			end else begin
				checkSym(rbracket, disasters);
				checkSym(ofsym, errors);
				arrayElementType := elementTypeDec(forwardRef)
			end;
			if hugeType then begin
				size := sizeOfType * ((arrayElementType^.size + 15) div 16);
				alignmentUnit := 1			{ dummy }
			end else begin
				size := sizeOfType * arrayElementType^.size;
														(* 配列のサイズ *)
				alignmentUnit := arrayElementType^.alignmentUnit;

				(* オーバーフローチェック *)

				if (sizeOfType <= 0) or
				   (size div sizeOfType <> arrayElementType^.size) then
					error(19, disasters)
			end
		end; { with }
		arrayType := typePtr
	end; { arrayType }

	function fieldList : refStructure;
	var
		typePtr : refStructure;

		(* 関数：subFieldList			*)
		(* 目的：レコードの中身を処理する	*)
		(* 戻り値：レコードのサイズ		*)

		function subFieldList(location : integer; var variantPtr : 
				refTagField; var align : integer) : integer;
		var
			maxSize, al : integer;

			procedure fixedPart;
			var
				fieldType : refStructure;
				p, root : refIdentifier;
				exitLoop : boolean;
			begin
				exitLoop := false;
				repeat
					root := nil;
					repeat
						checkId(disasters);
						p := setId(id, fields, nil(* dummy *));
						p^.next := root;
						root := p;
						getsym;
						enterField(p, typePtr^.firstField)
					until isNot(comma);
					checkSym(colon, disasters);
					fieldType := elementTypeDec(forwardRef);
					with fieldType^ do
						if alignmentUnit > align then
							align := alignmentUnit;
					alignment(fieldType, false, location);
					reverseIdLink(root);
					p := root;
					while p <> nil do begin
						with p^ do begin
							idType := fieldType;
							fieldAddress := Location
						end;
						location := location + fieldType^.size;
						p := p^.next
					end;
					if sym = semicolon then begin
						getsym;
						if (sym = casesym) or (sym = endsym) then
							exitLoop := true
					end else
						exitLoop := true
				until exitLoop
			end; { fixedPar }

			procedure variantPart;
			var
				id1 : alpha;
				tagValue : constant;
				variantVar : refIdentifier;
				tagType, variantType : refStructure;
				subVariant1 : refTagField;
				p, q, head, variant1 : refVariant;
				exitLoop : boolean;
				subSize : integer;

				procedure setNewTag(var root : refVariant; p : refVariant);
				var
					cp1, cp2 : refVariant;
				begin
					with p^ do begin
						if (root = nil) or (root^.value >= value) then begin
							if root^.value = value then
								error(35, disasters);
							next := root;
							root := p
						end else if root^.next = nil then
							if root^.value = value then
								error(35, disasters)
							else begin
								next := nil;
								root^.next := p
							end else begin
							cp2 := root;
							cp1 := cp2^.next;
							while (cp1^.value < value) and (cp1^.next <> nil) 
									do begin
								cp2 := cp1;
								cp1 := cp2^.next
							end;
							if cp1^.value = value then
								error(35, disasters)
							else begin
								if cp1^.value < value then begin
									cp2 := cp1;
									cp1 := nil
								end;
								cp2^.next := p;
								p^.next := cp1
							end { if }
						end { if }
					end { with }
				end; { setNewTag }

			begin	{ variantPart }
				getsym;	{ caseの読み飛ばし }

				checkId(disasters);
				id1 := id;
				getsym;	(* タグの処理 *)
				if sym = colon then begin
					getsym;	(* ：の読み飛ばし *)
					checkId(disasters);
					variantType := checkType(id);
					with variantType^ do
						if alignmentUnit > align then
							align := alignmentUnit;
					alignment(variantType, false, location);
					variantVar := setId(id1, fields, variantType);
					variantVar^.fieldAddress := location;
					enterField(variantVar, typePtr^.firstField);
					location := location + variantType^.size;
					getsym
				end else
					variantType := checkType(id1);

				new(variantPtr);
				with variantPtr^ do begin
					tagFieldType := variantType;
					firstVariant := nil;
					checkSym(ofsym, errors);

					exitLoop := false;	(* ここから各ケースの処理 *)
					repeat
						head := nil;
						repeat
							new(variant1);
							with variant1^ do begin
								next := head;
								tagType := getConst(tagValue);
								if not compatible(tagType, variantType) then
									errorType2(34, tagType, variantType, 
											disasters);
								value := tagValue.intValue
							end;
							head := variant1
						until isNot(comma);
						checkSym(colon, disasters);
						checkSym(lparen, errors);
						subSize := subFieldList(location, subVariant1, align);

						p := head;	(* 各タグにサイズと副可変部を書込む *)
						while p <> nil do begin
							with p^ do begin
								size := subsize;
								subvariant := subVariant1;
								q := next
							end;
							setNewTag(firstVariant, p);
							p := q
						end;

						if subSize > maxSize then	(* 可変部の最大値が *)
							maxSize := subSize;		(* 構造体の大きさ　 *)
						checkSym(rparen, errors);
						if sym = semicolon then begin	(* 終了判定 *)
							getsym;
							if (sym = casesym) or (sym = endsym) then
								exitLoop := true
						end else
							exitLoop := true
					until exitLoop
				end { with variantPtr^ }
			end; { variantPart }

		begin	{ subFieldList }
			if sym = ident then
				fixedPart;
			maxSize := location;
			if sym = casesym then
				variantPart
			else
				variantPtr := nil;
			subFieldList := alignment0(align, maxsize);
		end; { subFieldList }

	begin { fieldList }
		typePtr := newStructure;
		with typePtr^ do begin
			form := records;
			firstField := nil;	(* 初期化 *)
			mainVariant := nil;	(* dummy *)
			alignmentUnit := 1;	(* 初期化 *)
			size := subFieldList(0, mainVariant, alignmentUnit)
		end;
		fieldList := typePtr
	end; { fieldList }

begin	{ typeDec }
	hugeType := false;
	packedType := false;
	if sym = hugesym then begin
		getsym;
		if sym <> arraysym then
			error(56, errors);
		hugetype := true
	end;
	if sym = packedsym then begin
		getsym;
		packedType := true
	end;
	case sym of
		arrow: begin	{ ポインタ }
				getsym;
				checkId(disasters);	{ 型名 }
				typePtr := newStructure;
				if not forwardRef then
					p := searchId(id, disasters)
				else
					p := searchSection(id);
				if p <> nil then
					with p^ do begin
						if klass = types then
							elementType := idType
						else
							error2('type name', disasters)
					end else begin
					p := setId(id, types, typePtr);
					p^.next := typeForwardLink;
					typeForwardLink := p;
					elementType := nil
				end;
				getsym;
				with typePtr^ do begin
					form := pointers;
					size := targetPtrSize;
					alignmentUnit := targetPtrAlign;
					elementTypeOfPointer := elementType
				end;
				typeDec := typePtr
			end;
		stringsym: begin
				getsym;	(* string の読み飛ばし *)
				checkSym(lbracket, disasters);
				stringSizeType := getConst(strSize);

				(* stringSizeType の型チェックを怠っている *)

				checkSym(rbracket, disasters);
				if sym = ofsym then begin
					getsym;	(* of の読み飛ばし *)
					elementType := elementTypeDec(forwardRef)
				end else
					elementType := charPtr;
				typePtr := newStructure;
				with typePtr^ do begin
					form := strings;
					stringSize := strSize.intValue * elementType^.size;
					size := targetIntegerSize + stringSize;
					alignmentUnit := elementType^.alignmentUnit;   { 8086依存 }
					stringElementType := elementType;
					if (stringSize div strSize.intValue <> 
							elementType^.size) or (size <= 0) then
						error(19, disasters)
				end;
				typeDec := typePtr
			end;
		arraysym: begin
				getsym;
				checksym(lbracket, disasters);
				typeDec := arrayType(hugeType, packedType)
			end;
		filesym: begin
				getsym;
				checkSym(ofsym, errors);
				typePtr := newStructure;
				with typePtr^ do begin
					form := files;
					size := 0;	{ dummy }
					fileType := elementTypeDec(forwardRef)
				end;
				typeDec := typePtr
			end;
		setsym: begin
				getsym;
				checkSym(ofsym, errors);
				typePtr := newStructure;
				with typePtr^ do begin
					form := powers;
					size := 0;	{ dummy }
					elementTypeOfSet := simpleType
				end;
				typeDec := typePtr
			end;
		recordsym: begin
				getsym;
				typeDec := fieldList;
				checkSym(endsym, errors)
			end;
		otherwise begin
				if hugeType or packedType then
					error(56, errors);
				typeDec := simpleType
			end
	end { case }
end; { typeDec }

end.
