(* file = cbgen1.pas
 *
 * カベソンコンパイラ　：　コード生成（ＣＰＵ独立）
 *
 *
 * Copyright (C) 1990  Ockeghem
 *)

unit cbgen1;

interface
uses cbcom;

procedure initCodeGen;
procedure genReturnStatement(p : refEvalTree);
procedure exitProc(tp : refIdentifier; la : integer);
procedure flushCodeGen;

implementation

uses cbexgen1, cbeval, cballoc, cbexgen4, cbgen2, cbgen4, cbdump;

procedure exitProc(tp : refIdentifier; la : integer);
var
	n : integer;
begin

	(* 関数の戻り値の処理 *)

	with currentRoutine^ do
		if klass = functions then begin
			if isRegisterLoadable(idType) then
				genReturnValue(variableNode(topOfScope^.returnValue));
			disposeIdentifier(topOfScope^.returnValue)
		end;
	exitProc2(tp, la)
end; { exitProc }

procedure genReturnStatement(p : refEvalTree);
begin
	with currentRoutine^ do begin
		if p <> nil then begin
			if isRegisterLoadable(idType) then
				genReturnValue(p)
			else
				genExpression(makeTree2(becomes,
										variablenode(topOfScope^.returnValue),
										p))
		end;
		genJump(labelValue + 2)
	end
end;

procedure initCodeGen;
begin
	initCodeGen2
end;

procedure flushCodeGen;
begin
	endOfModule
end;

end.
