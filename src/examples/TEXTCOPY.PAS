(* file = textcopy.pas
 *
 * テキスト型のサンプルプログラムです。テキストファイルをコピーします。
 * コピー後のファイルサイズが１バイト小さくなることがあります。これは
 * ＥＯＦマークの＾Ｚ（１Ａ）を除去しているためですので、実使用上は
 * 問題はありません。
 *)
program ftest;
var
    p, q : text;
    buf : string[128];
    fname, oname : string[64];
begin
    write('Enter input  file name : ');
    readln(fname);
    assign(p, fname);
    write('Enter output file name : ');
    readln(oname);
    assign(q, oname);
    reset(p);
    rewrite(q);
    while not eof(p) do begin
        readln(p, buf);
        writeln(q, buf)
    end;
    close(p);
    close(q);
end.
