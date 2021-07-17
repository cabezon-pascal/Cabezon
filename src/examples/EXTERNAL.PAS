(* file = external.pas
 *
 * 外部手続き・関数のサンプルプログラムです。
 * 
 * A>CAB EXTERNAL ADD.ASM      でコンパイルできます
 *)
program external;
var
    x, y, z : integer;

function add(a, b : integer) : integer; external;

begin
    x := 3;
    y := 5;
    z := add(x, y);
    writeln('z = ', z)
end.
