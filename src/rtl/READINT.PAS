unit system;
interface
uses deffcb, system1;

function _readint(var f : FCB) : integer;
procedure _skipwhite(var f : FCB);

implementation

procedure _skipwhite(var f : FCB); external;
function _getc1(var f : FCB) : char; external;
procedure _ungetc(var f : FCB; ch : char); external;

function _readint(var f : FCB) : integer;
label 99;
var
    exitLoop : boolean;
    c : char;
    n, d, s : integer;
begin
    n := 0; s := 1;
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
	    n := n * 10 + d;
	    c := _getc1(f)
	end
	else
	    exitLoop := true
    until exitLoop;
    _ungetc(f, c);
    _readint := n * s;
99:
end;

end.
