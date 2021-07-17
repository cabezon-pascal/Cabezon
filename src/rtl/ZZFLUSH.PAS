unit SYSTEM;
interface

procedure _zzflush;
procedure _flushBuffer(var f : text);

implementation

procedure _flushBuffer; external;

procedure _zzflush;
begin
    _flushBuffer(output)
end;

end.
