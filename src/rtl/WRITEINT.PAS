unit SYSTEM;

interface
uses deffcb;
type
    string6 = string[6];

procedure _writeInt(var f : FCB; n, w : integer);
procedure str(n : integer; var s : string6);
procedure _putSpace(var f : FCB; n : integer);
procedure _putNChar(var f : FCB; c : char; n : integer);

implementation

procedure _putSpace(var f : FCB; n : integer); external;
procedure _putNChar(var f : FCB; c : char; n : integer); external;
procedure __writechar(var f : FCB; ch : char); external;

procedure str(n : integer; var s : string6);
var
    i, p, sgn : integer;
    buf  : array[0..6] of char;
begin
    p := 0;
    sgn := -1;
    if n >= 0 then begin
	n := -n;
	sgn := 1
    end;
    repeat
	buf[p] := chr(ord('0') - n mod 10);
	p := p + 1;
	n := n div 10
    until n = 0;
    if sgn < 0 then begin
	buf[p] := '-';
	p := p + 1
    end;
    for i := 1 to p do
	s[i] := buf[p - i];
    s.length := p
end;

procedure _writeInt(var f : FCB; n, w : integer);
var
    p : integer;
    st : string6;
begin
    if w >= 0 then begin
	str(n, st);
	_putspace(f, w - st.length)
    end else if n < 0 then begin
	str(-n, st);
	__writeChar(f, '-');
	_putNChar(f, '0', -w - st.length - 1)
    end else begin
	str(n, st);
	_putNChar(f, '0', -w - st.length)
    end;
    for p := 1 to st.length do
	__writeChar(f, st[p]);
end; { _writeInt }

end.
