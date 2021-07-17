{ unit skipwh; }
unit system;

interface
uses deffcb;

procedure _skipwhite(var f : FCB);

implementation

function _getc1(var f : FCB) : char; external;
procedure _ungetc(var f : FCB; ch : char); external;

procedure _skipwhite(var f : FCB);
var
    c : char;
begin
    repeat
	c := _getc1(f);
    until (c <> ' ') and (c <> chr(9)) and (c <> chr(13)) and (c <> chr(10));
    _ungetc(f, c)
end;

end.
