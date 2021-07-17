(* file = prlist.pas
 *
 * リスト処理のサンプル
 *
 * 作成：オケゲム／松田晋
 *
 * 使用法：
 *　　プロンプト”＞”の後に文字列を入力して行く。
 *　　空行を入力すると、それまで入力して行った文字列を
 *　　正順に表示する
 *)
 
program printList;
type
    alpha = string[32];
    refNode = ^node;
    node  = record
                name : alpha;
                next : refNode
            end;
var
    root : refNode;

function getName(var nm : alpha) : boolean;
begin
    write('>'); readln(nm);
    getName := nm <> ''
end;

procedure makeList;
var
    p : refNode; nm : alpha;
begin
    while getName(nm) do begin
        new(p);
        p^.name := nm;
        p^.next := root;
        root := p
    end
end;

procedure print(p : refNode);
begin
    if p <> nil then begin
        print(p^.next);
        writeln(p^.name);
	dispose(p)
    end
end;

begin
    root := nil;
    makeList;
    print(root)
end.
