(* file = cab.pas
 *
 * cab.exe : Cabezon compiler driver
 *
 * Copyright (C) 1990, 93  Ockeghem
 *)

{$M $1000, 0, 0 }

program cab;
uses Dos;
const
	paramStrSize = 64;
	envStrSize = 255;
	maxObjects = 20;

type
	paramString = string[paramStrSize];
	envString = string[envStrSize];
	asmKindType = (masm, tasm, r86, a86, others);
var
	tasmJmpOpt, tiny, compile, assemble, link : boolean;
	list, map, debug, debugInfo : boolean;
	nObj : integer;
	asmName, linkName, progName : paramString;
	objects : array[1..maxObjects] of paramString;
	asmKind : asmKindType;

function upCaseString(str : string) : string;
var
	i : integer;
begin
	upCaseString := str;
	for i := 1 to length(str) do
		upCaseString[i] := upCase(str[i])
end;

procedure usage;
begin
	writeln('Cabezon Compiler Ver 0.08  ');
	writeln('Copyright (C) 1990, 93  Ockeghem');
	writeln('/j	jump optimization (tasm 2.0 only)');
	writeln('/g	debug information');
	writeln('/s	compile only');
	writeln('/c	compile and assemble only');
	writeln('/l	generate list file');
	writeln('/m	generate map file');
	halt(1)
end; { usage }

procedure setDefault;
begin
	asmName := upCaseString(getenv('ASM'));
	if asmName = '' then
		asmName := 'MASM';

	if asmName = 'MASM' then
		asmKind := masm
	else if asmName = 'TASM' then
		asmKind := tasm
	else if asmName = 'R86' then
		asmKind := r86
	else if asmName = 'A86' then
		asmKind := a86
	else
		asmKind := others;

	linkName := upCaseString(getEnv('LINK'));
	if linkName = '' then
		linkName := 'LINK'
end;

procedure runTimeOption;
var
	i : integer;
	ps : paramString;
begin
	tasmJmpOpt := false;
	tiny := false;
	compile := true;
	assemble := true;
	link := true;
	list := false;
	map := false;
	debug := false;
	debugInfo := false;

	for i := 1 to ParamCount do begin
		ps := ParamStr(i) + '    ';
		if (ps[1] = '-') or (ps[1] = '/') then
			case upCase(ps[2]) of
				'J': tasmJmpOpt := true;
				'D': debug := true;
				'S': begin
						assemble := false;
						link := false
					end;
				'C': link := false;
				'L': list := true;
				'M': map := true;
				'G': begin
						debugInfo := true;
						map := true
					end;
				else
					begin
						writeln('Inappropriate option: ', ps);
						writeln;
						usage
					end
			end { case }
	end; { for }
end; { runTimeOption }

function nextPath(var pathString : envString; var path : paramString) :
		boolean;
var
	p : integer;
begin
	p := pos(';', pathString);
	if p = 0 then begin
		path := pathString;
		pathString := ''
	end else begin
		path := Copy(pathString, 1, p - 1);
		pathString := Copy(pathString, p + 1, 255)
	end;
	if path[length(path)] <> '\' then
		path := path + '\';
	if path = '\' then
		nextPath := false
	else
		nextPath := true
end;

procedure execute(prog, cmdLine : string);
var
	next : boolean;
	path : paramString;
	pathString : envString;
	rCode : word;
begin
	writeln(prog, ' ', cmdLine);
	pathString := GetEnv('PATH');
	path := '';
	repeat
		SwapVectors;
		Exec(path + prog, cmdLine);
		SwapVectors;
		if DosError <> 0 then begin
			SwapVectors;
			Exec(path + prog + '.COM', cmdLine);
			SwapVectors;
		end;
		if DosError <> 0 then begin
			SwapVectors;
			Exec(path + prog + '.EXE', cmdLine);
			SwapVectors;
		end;
		next := nextPath(pathString, path)
	until (DosError = 0) or (next = false);
	if DosError <> 0 then begin
		writeln('Unable execute command : ', prog);
		halt(255)
	end else begin
		rCode := DosExitCode;
		if rCode <> 0 then begin
			writeln;
			writeln('*** Error : return code = ', rCode);
			halt(1)
		end
	end;
	writeln
end;

procedure removeFile(fName : paramString);
var
	f : file;
begin
	writeln('DEL ', fName);
	assign(f, fName);
	erase(f)
end;

function makeAsmName(var filePrime : paramString) : paramString;
var
	work : paramString;
	tmp : envString;
begin
	tmp := getEnv('TMP');
	if (tmp = '') or not assemble then
		tmp := '.\'
	else
		case tmp[length(tmp)] of
			':', '/', '\':;	(* do nothing *)
			else
				tmp := tmp + '\';
		end;
	case asmKind of
		r86: work := tmp + filePrime + '.a86';
		else
			work := tmp + filePrime + '.asm'
	end; { case }
	makeAsmName := work
end; { makeAsmName }

procedure gocab1(ps : paramString);
var
	filePrime, cmdLine, asmFileName : paramString;
	fileExt : string[3];
	n, p : integer;
begin
	p := pos('.', ps);
	if p = 0 then begin
		filePrime := ps;
		fileExt := 'pas'
	end else begin
		filePrime := Copy(ps, 1, p - 1);
		fileExt := Copy(ps, p + 1, 3);
	end;

	p := pos(':', filePrime);
	if p <> 0 then
		filePrime := Copy(filePrime, p + 1, 255);
	fileExt := upCaseString(fileExt);
	if progName = '' then
		progName := filePrime;

	if (fileExt = 'ASM') or (fileExt = 'A86') then begin
		asmFileName := ps;
		n := 2
	end else if fileExt = 'OBJ' then begin
		n := 3;
		nObj := nObj + 1;
		objects[nObj] := filePrime
	end else begin
		asmFileName := makeAsmName(filePrime);
		n := 1
	end;

	if (n = 1) and compile then begin
		cmdLine := '/o' + asmFileName + ' ';
		if tasmJmpOpt then
			cmdLine := cmdLine + '/j ';
		if debug then
			cmdLine := cmdLine + '/d ';
		if debugInfo then
			cmdLine := cmdLine + '/g ';
		if asmKind = r86 then
			cmdLine := cmdLine + '/r ';
		cmdLine := cmdLine + ps;
		execute('cab1', cmdLine)
	end;
	if (n <= 2) and assemble then begin
		case asmKind of
			a86: cmdLine := asmFileName + ' ' + filePrime + '.obj';
			r86: begin
					cmdLine := '-o ' + filePrime + '.obj' + ' ' + asmFileName;
					if list then
						cmdLine := '-p ' + filePrime + '.lst ' + cmdLine
				end;
			else
				begin
					cmdLine := '';
					if tasmJmpOpt then
						cmdLine := '/m ';
					cmdLine := cmdLine + asmFileName;
					if list then
						cmdLine := cmdLine + '/L';
					cmdLine := cmdLine + ';'
				end
		end; { case }
		execute(asmName, cmdLine);
		if n = 1 then
			removeFile(asmFileName);
		nObj := nObj + 1;
		objects[nObj] := filePrime;
	end
end; { gocab1 }

{
function getCompilerDriverFolder : DirStr;
const
	INDEX_TO_EXECUTING_PROGRAM = 0;
var
	compilerDriverFolder : DirStr;
	compilerDriverName : NameStr;
	compilerDriverExtension : ExtStr;
begin
	FSplit(ParamStr(INDEX_TO_EXECUTING_PROGRAM),
		compilerDriverFolder,
		compilerDriverName,
		compilerDriverExtension);
	getCompilerDriverFolder := compilerDriverFolder;
end;
}

{ Produces smaller code than the one above }
function getCompilerDriverFolder : DirStr;
const
	INDEX_TO_EXECUTING_PROGRAM = 0;
	INDEX_TO_FIRST_CHAR = 1;
var
	compilerDriverFqpn : PathStr;
	indexToCurrentChar : Byte;
begin
	compilerDriverFqpn := ParamStr(INDEX_TO_EXECUTING_PROGRAM);
	indexToCurrentChar := Length(compilerDriverFqpn);
	while (indexToCurrentChar > INDEX_TO_FIRST_CHAR) and (compilerDriverFqpn[indexToCurrentChar] <> '\') do
		Dec(indexToCurrentChar);
	getCompilerDriverFolder := Copy(compilerDriverFqpn, INDEX_TO_FIRST_CHAR, indexToCurrentChar);
end;

procedure goLink;
var
	cmdLine : paramString;
	i : integer;
begin
	if linkName = 'LLD' then begin
		cmdLine := objects[1] + '.obj';
		for i := 2 to nObj do
			cmdLine := cmdLine + ' ' + objects[i] + '.obj';
		cmdLine := cmdLine + ' ' + getCompilerDriverFolder + 'CLIB.LIB';
(*
{ Alternative calling convention: }
		cmdLine := cmdLine + ' -L' + getCompilerDriverFolder + ' -lCLIB';
*)
		if debugInfo then
			cmdLine := cmdLine + ' -M -g'
		else if map then
			cmdLine := cmdLine + ' -M'
	end else begin
		cmdLine := objects[1];
		for i := 2 to nObj do
			cmdLine := cmdLine + '+' + objects[i];
		cmdLine := cmdLine + ',,,' + getCompilerDriverFolder + 'CLIB';
		if debugInfo then
			cmdLine := cmdLine + '/m/li;'
		else if map then
			cmdLine := cmdLine + '/m;'
		else
			cmdLine := cmdLine + ';'
	end;
	execute(linkName, cmdLine);
end;

procedure goCabezon;
var
	i, nPrg : integer;
	ps : paramString;
begin
	nPrg := 0;
	for i := 1 to ParamCount do begin
		ps := paramStr(i);
		if (ps[1] <> '-') and (ps[1] <> '/') then begin
			gocab1(ps);
			nPrg := nPrg + 1
		end
	end;
	if nPrg = 0 then
		usage;
	if link then
		goLink
end; { runTimeOption }

begin
	setDefault;
	runTimeOption;
	nObj := 0;
	progName := '';
	goCabezon
end.
