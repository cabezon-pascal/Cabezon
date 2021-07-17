(* file = cbdump.pas
 *
 * ÉJÉxÉ\ÉìÉRÉìÉpÉCÉâÅ@ÅFÅ@ï\ÇÃÉ_ÉìÉv
 *
 *
 * Copyright (C) 1990  Ockeghem
 *)
unit cbdump;

interface
uses cbCom;

procedure dumpSymbols;
procedure dumpEvalTree(p : refEvalTree);
procedure dumpType(p : refStructure);
procedure dumpOneIdent(p : refIdentifier);

implementation

uses cbError, cbtable, cballoc;

procedure printTree(p : refIdentifier);
begin
	if p <> nil then begin
		PrintTree(p^.llink);
		write('-->');
		dumpOneIdent(p);
		PrintTree(p^.rlink);
	end
end; { PrintTree }

procedure printVariant(tg : refTagField; n : integer);
var
	p : refVariant;
begin
	if tg <> nil then begin
		write(' ':n);
		dumpType(tg^.tagFieldType);
		writeln;
		p := tg^.firstVariant;
		while p <> nil do begin
			with p^ do begin
				writeln(' ':n, value:6, '->', size);
				printVariant(subVariant, n + 4)
			end;
			p := p^.next
		end
	end
end;

procedure dumpType(p : refStructure);
begin
	if p = nil then
		write('nil-type')
	else if p = intPtr then
		write('integer')
	else if p = realPtr then
		write('real')
	else if p = bytePtr then
		write('byte')
	else if p = charPtr then
		write('char')
	else if p = stringPtr then
		write('string')
	else if p = boolPtr then
		write('boolean')
	else if p = controlPtr then
		write('control')
	else if p = textPtr then
		write('text')
	else begin
		write('(');
		with p^ do begin
			if isHuge then
				write('huge ');
			case form of
				scalars: begin
						write('scalar ..', tailOfEnumration^.values.intValue)
					end;
				subranges: begin
						write('subrange ');
						dumpType(rangeType);
						write(' ', minValueOfSubrange, '..', 
								maxValueOfSubrange)
					end;
				pointers: begin
						write('^ ');
						if elementTypeOfpointer^.form = records then
							write('record')
						else
							dumpType(elementTypeOfPointer)
					end;
				powers: begin
						write('[');
						dumpType(elementTypeOfSet);
						write(']')
					end;
				arrays: begin
						write('array ');
						dumpType(indexType);
						write(' ');
						dumpType(arrayElementType);
					end;
				strings, stringConsts: begin
						write(formName[form], ' ', stringSize, ' ');
						dumpType(stringElementType);
					end;
				files: begin
						write('file ');
						dumpType(fileType);
					end;
				records: begin
						writeln('record');
						printTree(firstField);
						printVariant(mainVariant, 4)
					end;
				otherwise
					begin
						writeln('form = ', ord(form), ')');
						sysError('dumpType')
					end;
			end; { case }
			write(' ', p^.size, ' ', p^.alignmentUnit, ')')
		end { with }
	end { if }
end; { dumpType }

procedure dumpConst(q : constant);
begin
	if q.strgValuePtr = nil then
		write(' ', q.intValue)
	else
		write(' ', q.strgValuePtr^)
end; { dumpConst }

procedure dumpOneIdent(p : refIdentifier);
begin
	with p^ do begin
		write(name^, chr(9), level:4, ord(idDeclareClass):4, '  ', 
				IdClassName[klass], ' ');
		dumpType(idType);
		case klass of
			labels: writeln(' ', ord(state));
			constants: begin
					dumpConst(p^.values);
					writeln
				end;
			vars: writeln(' ', IdKindName[variableKind], ' ', variableAddress);
			fields: writeln(' ', fieldAddress);
			procedures, functions, programs, units: begin
					write(' ', IdKindName[variableKind]);
					if procOrFuncKind = standard then
						writeln('  key = ', ord(key))
					else begin
						writeln('  forward = ', forwardDec);
						p := paramp;
						while p <> nil do begin
							write('==[', name^, ']==>');
							dumpOneIdent(p);
							p := p^.next
						end;
						writeln
					end;
				end;
			types: writeln;
			otherwise
				sysError('dumpOneIdent');
		end
	end;
end; { dumpOneIdent }

procedure dumpSymbols;
var
	i : integer;
	p : refIdentifier;

	procedure symDump1;
	var
		i : integer;
		p : refIdentifier;
	begin
		writeln('====================== symbol dump ===================');
		for i := 0 to HashSizeMinus1 do begin
			p := hashTable2[i];
			if p <> nil then begin
				write('h :', i:4);
				while p <> nil do begin
					with p^ do
						write(chr(9), name^, '[', level, ']');
					p := p^.hashNext
				end;
				writeln
			end
		end
	end; { symDump1 }

begin
	write('currentRoutine = ');
	dumpOneIdent(currentRoutine);
	writeln('currentLevel   = ', currentLevel);

	writeln('Å|Å|Å|Å|Å|Å|Å|Å|Å|Å| symbol dump Å|Å|Å|Å|Å|Å|Å|Å|Å|Å|Å|Å|');

	for i := 0 to HashSizeMinus1 do begin
		p := hashTable2[i];
		if p <> nil then begin
			while p <> nil do begin
				if p^.level > 0 then
					dumpOneIdent(p);
				p := p^.hashNext
			end;
		end
	end;
	writeln('^^^^^^^^^^^^^^^^^^^^ symbol dump ^^^^^^^^^^^^^^^^^^^^^^^^^')
end; { dumpSymbols }

procedure _evalTreeDump(p : refEvalTree);
var
	a : refArgsLink;
begin
	with p^ do
		case nodeType of
			opVariable: begin
					write(var1^.name^);
					if hugeIndex <> nil then begin
						write('{');
						_evalTreeDump(hugeIndex);
						write('}')
					end;
					if varIndex <> nil then begin
						write('[');
						_evalTreeDump(varIndex);
						write(']')
					end;
					if constIndex <> 0 then
						write('[', constIndex, ']');
				end;
			opConstant: begin
					if const1 = nil then
						write(' nil')
					else
						dumpConst(const1^)
				end;
			opProcedure, opFunction: begin
					write('(');
					write(func^.name^);
					a := args;
					while a <> nil do begin
						write(' ');
						_evalTreeDump(a^.exp);
						a := a^.next
					end;
					write(size);
					write(')')
				end;
			opIndirect: begin
					write('(^ ');
					_evalTreeDump(ref1);
					if hugeIndex <> nil then begin
						write(' +{');
						_evalTreeDump(hugeIndex);
						write('}')
					end;
					if varIndex <> nil then begin
						write(' +[');
						_evalTreeDump(varIndex);
						write(']')
					end;
					if constIndex <> 0 then
						write('.', constIndex);
					write(')')
				end;
			operator: begin
					write('(');
					write(opesName[op], ' ');
					if operand1 <> nil then begin
						_evalTreeDump(operand1);
						write(' ');
					end;
					if operand2 <> nil then
						_evalTreeDump(operand2);
					dumpType(evalType);
					write(')')
				end;
			opRangeCheck: begin
					write('*rangecheck*  from : ', minValue, ' to : ', 
							maxValue, ' = (');
					_evalTreeDump(expr);
					write(')')
				end;
			otherwise
				begin
					writeln('ord(nodeType) = ', ord(nodeType));
					sysError('_evalTreeDump')
				end
		end; { case }
end; { _evalTreeDump }

procedure dumpEvalTree(p : refEvalTree);
begin
	if p <> nil then
		_evalTreeDump(p);
	writeln
end; { dumpEvalTree }

end.
