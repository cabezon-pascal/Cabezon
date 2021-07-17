unit SYSTEM;
interface
uses deffcb;

procedure _writereal(var f : FCB; x : real; w1, w2 : integer);
procedure _writeInt(var f : FCB; n, w : integer);

implementation

procedure _writeInt(var f : FCB; n, w : integer); external;
procedure __writechar(var f : FCB; ch : char); external;
procedure _writereal(var f : FCB; x : real; w1, w2 : integer);
var
    e, s, n : integer;

    procedure writeOneDigit(var a : real);
    var
	j : integer;
    begin
	j := trunc(a);
	__writechar(f, chr(ord('0') + j));
	a := (a - j) * 10.0
    end;

begin
    e := 0;
    s := 1;
    if x < 0.0 then begin
	x := -x;
	s := -1
    end;
    if x <> 0.0 then begin
	while x >= 10.0 do begin
	    x := x / 10.0;
	    e := e + 1
	end;
	while x < 1.0 do begin
	    x := x * 10.0;
	    e := e - 1
	end
    end;
    x := x + 0.5e-15;
    if s < 0 then
	__writechar(f, '-')
    else
	__writechar(f, ' ');

    writeOneDigit(x); __writechar(f, '.');
    if w1 = 0 then w1 := 23;
    for n := 1 to w1 - 8 do
	writeOneDigit(x);
    __writechar(f, 'E'); 
    if e >= 0 then begin
	__writechar(f, '+');
	_writeInt(f, e, -3)
    end
    else
	_writeInt(f, e, -4)
end;

end.
