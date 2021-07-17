unit system;
interface
uses system1;

function ioresult : integer;

implementation

function ioresult : integer;
begin
    ioresult := _ioresult_1;
    _ioresult_1 := 0
end;
end.
