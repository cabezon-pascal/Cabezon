unit SYSTEM;
interface

procedure _aainit;

implementation
const
    nullString = '';

procedure _aainit;
begin
    {$i-}
    assign(input, nullString);
    reset(input);
    assign(output, nullString);
    rewrite(output)
end;
end.
