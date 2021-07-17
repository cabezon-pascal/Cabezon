program chash(input, output);
const
    IDSIZE = 31;
    MAXDATA = 100;
type
    alpha = string[IDSIZE];
    tlType = record
                empty : boolean;
                b, f  : integer;
                adr   : integer
             end;
    lxtype = record
                str : alpha;
                L   : integer;
                h, t : char
             end;
var
    lx : array[0..MAXDATA] of lxtype;
    tl : array[0..MAXDATA] of tlType;
    nData, minv, maxv : integer;
    at : array [char] of integer;
    ax : array [char] of integer;
    mark : integer;
    r, y  : integer;

function max(a, b : integer) : integer;
var
    m : integer;
begin
    m := a;
    if b > m then m := b;
    max := m
end;

function min(a, b : integer) : integer;
var
    m : integer;
begin
    m := a;
    if b < m then m := b;
    min := m
end;

function max3(a, b, c : integer) : integer;
var
    m : integer;
begin
    m := a;
    if b > m then m := b;
    if c > m then m := c;
    max3 := m
end;

procedure inc(var n : integer);
begin
    n := n + 1;
end;

function getData : integer;
var
    infile : text;
    line : alpha;
    i : integer;
begin
    assign(infile, 'reserved.dat');
    reset(infile);
    i := 0;
    while not eof(infile) do begin
        readln(infile, line);
        i := i + 1;
        with lx[i] do begin
            str := line;
            L := line.length;
            h := line[1];
            t := line[L]
        end
    end;
    getData := i;
end;

procedure sort2(n : integer);
var
    min  : lxtype;
    ch : char;
    i, j, minI, minK : integer;

   function key(s : lxtype) : integer;
    var
        a, b, k : integer;
    begin
        with s do begin
            a := ax[h];
            b := ax[t];
            if (a = 1) or (b = 1) then
                k := a + b + 100 - L
            else
                k := (a + b) * 100 + 1000 - L;
        end;
        key := k
    end;

    function keyx(s : lxtype) : integer;
    var
        a, b, k : integer;
    begin
        with s do begin
            k := 100 - L
        end;
        keyx := k
    end;

begin
    for ch := chr(0) to chr(255) do
        ax[ch] := 0;
    for i := 1 to n do
        with lx[i] do begin
            inc(ax[h]);
            inc(ax[t])
        end;

    for i := 1 to n - 1 do begin
        min := lx[i]; minI := i; minK := key(min);
        for j := i + 1 to n do
            if key(lx[j]) > minK then begin
                min := lx[j];
                mini := j;
                minK := key(lx[j])
            end;
        lx[minI] := lx[i];
        lx[i] := min
    end
end;

procedure sort3(n : integer);
var
    min  : lxtype;
    ch : char;
    i, j, minI, minK : integer;

function key(s : lxtype) : integer;
var
    a, b, k : integer;
begin
    with s do key := at[h] + at[t] + L
end;

begin
    for i := 1 to n - 1 do begin
        min := lx[i]; minI := i; minK := key(min);
        for j := i + 1 to n do
            if key(lx[j]) < minK then begin
                min := lx[j];
                mini := j;
                minK := key(lx[j])
            end;
        lx[minI] := lx[i];
        lx[i] := min
    end
end;

function searchMin(n : integer) : integer;
var
    i, m, te : integer;
begin
    m := lx[1].L;
    for i := 2 to n do begin
        te := lx[i].L;
        if te < m then m := te
    end;
    searchMin := m
end;

procedure dumpData(n : integer);
var
    k : integer;
begin
    writeln('str':15, 'at[h]':5, 'at[t]':5, 'L':5, 'at[h] + at[t] + L' : 5);
    for k := 1 to n do with lx[k] do
        writeln(k:5, str:15, at[h]:5, at[t]:5, L:5, at[h] + at[t] + L : 5);
end;

procedure dumpHash;
var
    k : char;
begin
    for k := chr(0) to chr(255) do begin
        write(at[k]:3, ',');
        if ord(k) mod 16 = 15 then writeln
    end
end;

procedure list(n : integer);
var
    k : integer;
    c : char;
    ofl : text;
begin
    assign(ofl, 'cblex1.pas');
    rewrite(ofl);
    writeln(ofl, 'unit cblex1;');
    writeln(ofl, 'interface');
    writeln(ofl, 'uses cbcom;'); writeln(ofl);

    writeln(ofl, 'const');
    writeln(ofl, '    HashMax = ', maxv, ';');

    writeln(ofl, 'var');
    writeln(ofl, '    word : array[0..HashMax] of alpha;');
    writeln(ofl, '    wsym : array[0..HashMax] of symbol;');
    writeln(ofl, '    HashTable : array[''0''..''_''] of 0..', maxv + 1, ';');
    writeln(ofl);

    writeln(ofl, 'procedure initSym1;'); writeln;
    writeln(ofl);
    writeln(ofl, 'implementation');
    writeln(ofl);

    writeln(ofl, 'procedure initSym1;');
    writeln(ofl, 'var');
    writeln(ofl, '    k : integer;');
    writeln(ofl, '    c : char;');
    writeln(ofl, 'begin');
    writeln(ofl, '    for c := ''0'' to ''_'' do');
    writeln(ofl, '	HashTable[c] := ', maxv + 1, ';');
    writeln(ofl, '    for k := 0 to HashMax do begin');
    writeln(ofl, '	word[k] := '' '';');
    writeln(ofl, '	wsym[k] := ident');
    writeln(ofl, '    end;');
    writeln(ofl);
    for k := 1 to n do with lx[k] do
        writeln(ofl, '    word[', at[h] + at[t] + L:2, '] := ''', str, ''';');
    writeln(ofl);
    for k := 1 to n do with lx[k] do
        writeln(ofl, '    wsym[', at[h] + at[t] + L:2, '] := ', str, 'sym;');
    k := 0;
    writeln(ofl);

    k := 0;
    for c := '0' to 'z' do begin
	if at[c] <> maxv + 1 then begin
	    write(ofl, '    HashTable[''', c, '''] := ', at[c]:3, ';');
	    k := k + 1;
	    if k = 3 then begin
		writeln(ofl);
		k := 0
	    end
	end
    end;
    if k <> 0 then writeln(ofl);
    writeln(ofl, 'end; { initSym1 }');
    writeln(ofl);
    writeln(ofl, 'end.');
    close(ofl)
end;

procedure init1(minv, maxv : integer);
var
    i : integer;
begin
    for i := minv to maxv do
        with tl[i] do begin
            empty := true;
            f := i + 1;
            b := i - 1;
            adr := -1;
        end;
    tl[0].f := minv;
    tl[0].b := maxv;
    tl[minv].b := 0;
    tl[maxv].f := 0
end;

procedure init2;
var
    ch : char;
begin
    for ch := chr(0) to chr(255) do begin
        at[ch] := mark;
        ax[ch] := -1
    end
end;

procedure delete(p, q : integer);
begin
    with tl[p] do begin
        empty   := false;
        tl[b].f := f;
        tl[f].b := b;
        adr     := q
    end
end;

procedure undelete(p : integer);
begin
    with tl[p] do begin
        empty := true;
        tl[f].b := p;
        tl[b].f := p;
        adr := -1
    end
end;

function try(i, q : integer) : integer;
label 1, 2, 3;
var
    p, j, k, r : integer;
begin
    try := q;
    if i > nData then begin
        sort3(nData);
        writeln;
{	dumpData(nData);	}
{	dumpHash;		}
        list(nData);
	writeln(chr(7), 'finished');
        halt(0) { exit }
    end;
    with lx[i] do begin
        if (at[h] = mark) and (at[t] = mark) then begin
            ax[h] := q;
            for j := 0 to maxv do begin
                at[h] := j;
                r := try(i, q + 1);
                if r < q then begin
                    try := r;
                    goto 1
                end;
            end;
         1: at[h] := mark;
        end
        else if at[h] = mark then begin
            p := tl[0].f;
            ax[h] := q;
            while p <> 0 do begin
                j := p - L - at[t];
                if j >= 0 then begin
                    at[h] := j;
                    delete(p, q);
                    r := try(i + 1, q + 1);
                    undelete(p);
                    if r < q then begin
                       try := r;
                       goto 2
                    end;
                end;
                p := tl[p].f
            end;
         2: at[h] := mark
        end
        else if at[t] = mark then begin
            p := tl[0].f;
            ax[t] := q;
            while p <> 0 do begin
                j := p - L - at[h];
                if j >= 0 then begin
                    at[t] := j;
                    delete(p, q);
                    r := try(i + 1, q + 1);
                    undelete(p);
                    if r < q then begin
                        try := r;
                        goto 3
                    end;
                end;
                p := tl[p].f
            end;
         3: at[t] := mark
        end
        else begin
            p := at[h] + at[t] + L;
            if p > maxv then begin
                try := max(ax[h], ax[t]) { max }
            end
            else if (p <= maxv) and (tl[p].empty) then begin
                delete(p, q);
                r := try(i + 1, q + 1);
                undelete(p);
                if r >= q then begin
                    try := max(ax[h], ax[t]) { max }
                end
                else if r < q then try := r
            end
            else begin
                r := max(ax[h], ax[t]);
                if tl[p].adr = r then
                    r := min(ax[h], ax[t])
                else
                    r := max3(tl[p].adr, ax[h], ax[t]);
                try := r
            end
        end
    end
end;

begin
    y := 0;
    write('Set y : '); readln(y);

    nData := getData;
    sort2(nData);
    minv := searchMin(nData);
    maxv := minv + nData - 1 + Y;
    writeln('minv = ', minv, '  maxv = ', maxv);
    mark := maxv + 1;
    init1(minv, maxv);
    init2;
    dumpData(nData); {}
    r := try(1, 1);
end.
