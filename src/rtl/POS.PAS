(* file = pos.pas
 *
 * pos : カベソンコンパイラ：ライブラリ
 *
 * ラストアップデート　'91/03/17  徳丸浩
 *
 * Copyright (C) 1990, 91  H.Tokumaru
 *)
unit system;

interface
type
    stringMax = string[255];

function pos(var word, line : stringMax) : integer;

implementation

function pos(var word, line : stringMax) : integer;
var
    i, j : integer;
begin
    i := 1; j := 1;
    while (i <= line.length) and (j <= word.length) do
	if line[i] = word[j] then begin
	    i := i + 1;
	    j := j + 1
	end else begin
	    i := i - j + 2;
	    j := 1
	end;
    if j > word.length then
	pos := i - word.length
    else
	pos := 0;
end;

end.
