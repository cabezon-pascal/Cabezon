(* file = cbtable.pas
 *
 * カベソンコンパイラ　：　記号表
 *
 *
 * Copyright (C) 1990  Ockeghem
 *)
unit cbtable;interface

uses cbcom;

var
	currentClass : declareClass;
	currentWithLink : refWithLink;

function setId(id : alpha; k : idClass; tp : refStructure) : refIdentifier;
function setId2(id : alpha; k : idClass; tp : refStructure) : refIdentifier;
function searchId(var id : alpha; errKind : errorKind) : refIdentifier;
function searchSection(var id : alpha) : refIdentifier;
function searchField(var id : alpha; p : refIdentifier) : refIdentifier;
procedure initSearch;
procedure reverseIdLink(var root : refIdentifier);
procedure enterField(p : refIdentifier; var top : refIdentifier);
procedure enterId(p : refIdentifier);
procedure FlushSearch;

implementation

uses cbError, cbdump, cballoc;

procedure initSearch;
var
	i : integer;
begin
	for i := 0 to HashSizeMinus1 do
		HashTable2[i] := nil;
	topOfWithLink := nil
end;

function setId(id : alpha; k : idClass; tp : refStructure) : refIdentifier;
var
	p : refIdentifier;
begin
	p := newIdentifier;
	with p^ do begin
		new(name);
		name^ := id;
		used := false;
		variableKind := actual;
		idType := tp;
		klass := k;
		idDeclareClass := currentClass
	end;
	setId := p
end; { setId }

(* 関数名：setId2
 *
 * 目的：idの値をセットし、localRootOfId のリンクに繋げる。
 *
 * 戻り値：idの値
 *)
function setId2(id : alpha; k : idClass; tp : refStructure) : refIdentifier;
var
	p : refIdentifier;
begin
	p := setId(id, k, tp);
	p^.next := localRootOfId;
	localRootOfid := p;
	setId2 := p;
end;

function hash(id : alpha) : integer;
var
	i, t : integer;
begin
	t := 0;
	for i := 1 to id.length do
		t := (t + ord(id[i])) * 29;	{ オーバーフローは無視 }
	t := (t and $7fff) mod HashSize;
	hash := t
end;

procedure enterId(p : refIdentifier);
var
	nm : alpha;
	h : integer;
	u : refIdentifier;
begin
	h := hash(p^.name^);
	u := HashTable2[h];
	with p^ do begin
		hashNext := u;
		hashValue := h;
		level := currentLevel
	end;
	while u <> nil do begin
		with u^ do begin
			if level < currentLevel then
				u := nil
			else if name^ = p^.name^ then begin
				errorName(4, p^.name^, errors);
				u := nil
			end else
				u := HashNext
		end
	end;
	HashTable2[h] := p
end;

function searchId(var id : alpha; errKind : errorKind) : refIdentifier;
label 9;
var
	x : refWithLink;
	p, s : refIdentifier;
begin
	x := topOfWithLink;
	s := nil;
	while x <> nil do begin
		s := searchField(id, x^.topOfField);
		if s <> nil then begin
			CurrentWithLink := x;
			goto 9
		end;
		x := x^.next
	end;
	p := hashTable2[hash(id)];
	while p <> nil do begin
		if p^.name^ = id then begin
			s := p;
			p := nil
		end else
			p := p^.hashNext
	end;
	if s = nil then
		errorName(3, id, errKind);
 9: searchId := s
end; { searchId }

function searchSection(var id : alpha) : refIdentifier;
var
	p : refIdentifier;
begin
	p := hashTable2[hash(id)];
	searchSection := nil;
	while p <> nil do begin
		if p^.name^ = id then begin
			if p^.level = currentLevel then	{ 現在のレベルのみ対象とする }
				searchSection := p;
			p := nil
		end else
			p := p^.hashNext
	end
end; { searchSection }

procedure enterField(p : refIdentifier; var top : refIdentifier);
var
	nm : alpha;

	procedure enter(var q : refIdentifier);
	begin
		if q = nil then begin
			q := p;
			with p^ do begin
				level := 0;
				llink := nil;
				rlink := nil
			end
		end else if q^.name^ = nm then
			errorName(4, nm, errors)
		else if q^.name^ < nm then
			enter(q^.rlink)
		else
			enter(q^.llink)
	end;

begin
	nm := p^.name^;
	enter(top)
end; { enterField }

function searchField(var id : alpha; p : refIdentifier) : refIdentifier;
begin
	searchField := nil;
	while p <> nil do begin
		if id = p^.name^ then begin
			searchField := p;
			p := nil
		end else if id < p^.name^ then
			p := p^.llink
		else
			p := p^.rlink
	end
end; { searchField }

procedure reverseIdLink(var root : refIdentifier);
var
	p, q, w : refIdentifier;
begin
	p := root;
	q := nil;
	while p <> nil do begin
		w := p^.next;
		p^.next := q;
		q := p;
		p := w
	end;
	root := q
end; { reverseIdLink }

procedure FlushSearch;
begin
end; { FlushSearch }

end.
