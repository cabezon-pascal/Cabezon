unit system;
interface
type
    alpha = string[128];

function _strcmp(var a, b : alpha) : integer;

implementation

function min(i, j : integer) : integer;
begin
    if i < j then
	min := i
    else
	min := j
end;

function _strcmp(var a, b : alpha) : integer;
var
    i, n : integer;
    Exit : boolean;
begin
    n := min(a.length, b.length);
    i := 1;
    Exit := false;
    while (i <= n) and not Exit do begin
	if a[i] <> b[i] then
	    Exit := true
	else
	    i := i + 1
    end;
    if Exit then
	_strcmp := ord(b[i]) - ord(a[i])
    else
	_strcmp := b.length - a.length
end;

end.
