(* file = hugesamp.pas
 *
 * huge 配列のサンプルプログラム
 *)
program hugesamp;
const
	max = 300;
type
	(* huge 配列を使うには、配列宣言の前にhugeをつけるだけ *)

	bigarray = huge array[1..max, 1..max] of integer;

var
	a : bigarray;
	p : ^bigarray;
	i, j : integer;

(* huge 配列は必ずvar引数とする。値引数にはできない *)
procedure bar(var m : bigarray);
var
	x, i, j : integer;
begin
	for i := 1 to max do
		for j := 1 to max do
			if a[i, j] <> 10 * i + j then begin
				writeln('error');
				writeln(i, ' ', j, ' ', a[i, j]);
				halt(1)
			end
end;

procedure foo(i, j : integer; var x : integer);
begin
	if x <> 10 * i + j then begin
		writeln('error');
		writeln(i, ' ', j, ' ', a[i, j]);
		halt(1)
	end
end;

begin
	new(p);					{ huge配列のポインタも使用できる }
	for i := 1 to max do
		for j := 1 to max do
			a[i, j] := 10 * i + j;
	for i := 1 to max do
		for j := 1 to max do
			foo(i, j, a[i, j]);
	bar(a);
	for i := 1 to max do
		for j := 1 to max do
			if a[i, j] <> 10 * i + j then begin
				writeln('error');
				writeln(i, ' ', j, ' ', a[i, j]);
				halt(1)
			end
end.
