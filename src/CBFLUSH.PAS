(* file = cbflush.pas
 *
 * cbinit : カベソンコンパイラ
 *
 *
 * Copyright (C) 1990  Ockeghem
 *)
unit cbflush;interface
uses cbcom;

procedure Flush;
procedure FlushFiles;

implementation

uses cbtable, cballoc, cbdump, cbgen1;

procedure FlushFiles;
begin
	close(OutFile);
	close(inFile^)
end;

procedure Flush;
begin
	flushSearch;
	flushAllocate;
	flushCodegen;
	if errorExist then begin
		writeln;
		writeln('警告 : ', nErrors[warnings],
				'    エラー : ', nErrors[errors],
				'    致命的エラー : ', nErrors[disasters])
	end;
	FlushFiles;
	if errorExist then begin
		if nErrors[disasters] > 0 then
			halt(2);
		if nErrors[errors] > 0 then
			halt(1)
	end
end;

end.
