(* file = copy.pas
 *
 * copy : カベソンコンパイラ：ライブラリ
 *
 * ラストアップデート　'91/03/17  徳丸浩
 *
 * Copyright (C) 1990, 91  H.Tokumaru
 *)
unit system;

interface
type
    stringMax = string[255];

function copy(var s : stringMax; n1, n2 : integer) : stringMax;

implementation

function copy(var s : stringMax; n1, n2 : integer) : stringMax;
var
    i, j, n : integer; 
begin
    n := n1 + n2 - 1;
    if n > s.length then
	n := s.length;
    j := 0;
    for i := n1 to n do begin
	j := j + 1;
	copy[j] := s[i]
    end;
    copy.length := j
end;

end.
