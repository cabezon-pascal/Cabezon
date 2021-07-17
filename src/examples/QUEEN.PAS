(* file = queen.ock
 *
 * ‚WƒNƒB[ƒ“‚Ì‰ğ–@ƒvƒƒOƒ‰ƒ€
 *
 * ì¬Fockeghem@f‚W‚X”N‚P‚QŒ‚Q‚V“ú
 *)
program queen;
const
    nq = 8;
    nqPlus1 = 9;	(*	nq + 1		*)
    doubleNq = 16;	(*	2 * nq		*)
    doubleNqPlus1 = 17;	(*	2 * nq + 1	*)
    geta  = nq;

var 
    n : integer;
    a : array[0..nq] of boolean;
    x : array[0..nq] of integer;
    b, c : array[0..doubleNq] of boolean;
    i : integer;

procedure print;
var k : integer;
begin
    n := n + 1;
    write(n, ' : ');
    for k := 1 to nq do
	write(x[k], ' ');
    writeln
end;

procedure try(i : integer);
var j : integer;
begin
    for j := 1 to nq do begin
	if a[j] and b[i+j] and c[i-j+geta] then begin 
	    x[i] := j;
	    a[j] := false; 
	    b[i+j] := false; 
	    c[i-j+geta] := false;
	    if i < nq then try(i+1) 
	    else print;
	    a[j] := true; 
	    b[i+j] := true; 
	    c[i-j+geta] := true
	end;
    end
end;

begin
    n := 0;
    for i := 1 to nq do
	a[i] := true;
    for i := 2 to 2 * nq do
	b[i] := true;
    for i := -nq to nq do
	c[i+geta] := true;
    try(1);
    writeln('‰ğ‚ÌŒÂ” ', n)
end.
