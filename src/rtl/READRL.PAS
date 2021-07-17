{ unit readrl; }
unit system;
interface
uses system1;

function _readreal(var f : FCB) : real;
function _readint(var f : FCB) : integer;
procedure _skipwhite(var f : FCB);

implementation
const
    real10 = 10.0;

function _readint(var f : FCB) : integer; external;
procedure _skipwhite(var f : FCB); external;
function _getc1(var f : FCB) : char; external;
procedure _ungetc(var f : FCB; ch : char); external;

function _readreal(var f : FCB) : real;
label 99;
var
    exitLoop : boolean;
    c : char;
    d, e, s : integer;
    x : real;
begin
    x := 0.0; s := 1; e := 0;
    _skipwhite(f);
    c := _getc1(f);
    if c = '-' then begin
	s := -1;
	c := _getc1(f)
    end
    else if c = '+' then
	c := _getc1(f);
    if (c < '0') or (c > '9') then begin
	_ioresult_1 := 106;
	goto 99
    end;
    exitLoop := false;
    repeat
	d := ord(c) - ord('0');
	if (d >= 0) and (d <= 9) then begin
	    x := x * real10 + d;
	    c := _getc1(f)
	end
	else
	    exitLoop := true
    until exitLoop;
    if c = '.' then begin
	c := _getc1(f);
	exitLoop := false;
	repeat
	    d := ord(c) - ord('0');
	    if (d >= 0) and (d <= 9) then begin
		x := x * real10 + d;
		c := _getc1(f);
		e := e - 1
	    end
	    else
		exitLoop := true
	until exitLoop
    end;
    if (c = 'e') or (c = 'E') then
	e := e + _readint(f)
    else
	_ungetc(f, c);
    while e > 0 do begin
	x := x * real10;
	e := e - 1
    end;
    while e < 0 do begin
	x := x / real10;
	e := e + 1
    end;
    if s > 0 then
	_readreal := x
    else
	_readreal := -x;
 99:
end;

end.
