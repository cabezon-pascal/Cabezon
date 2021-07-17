(* file = cblabel.pas
 *
 * カベソンコンパイラ　：　ラベル生成（ＣＰＵ依存）
 *
 *
 * Copyright (C) 1990  Ockeghem
 *)

unit cblabel;

interface
uses cbcom;

var
	labelDeclared : boolean;

procedure initLabel;
function genLabel(n : integer) : integer;
function genLabel2(n : integer) : stringMax;
procedure outLabel0(lb : integer);
procedure outLabel1(lb : integer);
procedure outLabel2(lb : integer);

implementation

var
	labelOrg : integer;

function genLabel(n : integer) : integer;
var
	x : integer;
begin
	genLabel := labelOrg;
	labelOrg := labelOrg + n
end;

function genLabel2(n : integer) : stringMax;
var
	s : string[10];
begin
	str(n, s);
	genLabel2 := '_' + s
end;

procedure outLabel0(lb : integer);
begin
	write(OutFile, genLabel2(lb))
end;

procedure outLabel1(lb : integer);
begin
	outLabel0(lb);
	writeln(OutFile)
end;

procedure outLabel2(lb : integer);
begin
	outLabel0(lb);
	writeln(OutFile, ':');
	diVariable := nil				(* with 文の最適化のため *)
end;

procedure initLabel;
begin
	labelDeclared := false;
	labelOrg := 0;
	leaveLabel := undefinedLabel
end;

end.
