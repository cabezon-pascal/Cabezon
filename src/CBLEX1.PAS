unit cblex1;interface
uses cbcom;

const
	HashMax = 55;
var
	word : array[0..HashMax] of alpha;
	wsym : array[0..HashMax] of symbol;
	HashTable : array['0'..'_'] of 0..56;

procedure initSym1;

implementation

procedure initSym1;
var
	k : integer;
	c : char;
begin
	for c := '0' to '_' do
		HashTable[c] := 56;
	for k := 0 to HashMax do begin
		word[k] := ' ';
		wsym[k] := ident
	end;

	word[3] := 'END';
	word[4] := 'ELSE';
	word[5] := 'IF';
	word[6] := 'FILE';
	word[7] := 'HUGE';
	word[8] := 'LEAVE';
	word[9] := 'PACKED';
	word[10] := 'INTERFACE';
	word[11] := 'LABEL';
	word[12] := 'PROCEDURE';
	word[13] := 'IN';
	word[14] := 'CASE';
	word[15] := 'EVERY';
	word[16] := 'NIL';
	word[17] := 'WHILE';
	word[18] := 'BEGIN';
	word[19] := 'WITH';
	word[20] := 'FUNCTION';
	word[21] := 'STEP';
	word[22] := 'UNTIL';
	word[23] := 'FOR';
	word[24] := 'RECORD';
	word[25] := 'IMPLEMENTATION';
	word[26] := 'AND';
	word[27] := 'DIV';
	word[28] := 'MOD';
	word[29] := 'DO';
	word[30] := 'TYPE';
	word[31] := 'OF';
	word[32] := 'USES';
	word[33] := 'DOWNTO';
	word[34] := 'RETURN';
	word[35] := 'PROGRAM';
	word[36] := 'OTHERWISE';
	word[37] := 'STRING';
	word[38] := 'ARRAY';
	word[39] := 'NOT';
	word[40] := 'THEN';
	word[41] := 'CONST';
	word[42] := 'XOR';
	word[43] := 'SET';
	word[44] := 'UNIT';
	word[45] := 'VAR';
	word[47] := 'OR';
	word[48] := 'GOTO';
	word[50] := 'REPEAT';
	word[55] := 'TO';

	wsym[3] := ENDsym;
	wsym[4] := ELSEsym;
	wsym[5] := IFsym;
	wsym[6] := FILEsym;
	wsym[7] := HUGEsym;
	wsym[8] := LEAVEsym;
	wsym[9] := PACKEDsym;
	wsym[10] := INTERFACEsym;
	wsym[11] := LABELsym;
	wsym[12] := PROCEDUREsym;
	wsym[13] := INsym;
	wsym[14] := CASEsym;
	wsym[15] := EVERYsym;
	wsym[16] := NILsym;
	wsym[17] := WHILEsym;
	wsym[18] := BEGINsym;
	wsym[19] := WITHsym;
	wsym[20] := FUNCTIONsym;
	wsym[21] := STEPsym;
	wsym[22] := UNTILsym;
	wsym[23] := FORsym;
	wsym[24] := RECORDsym;
	wsym[25] := IMPLEMENTATIONsym;
	wsym[26] := ANDsym;
	wsym[27] := DIVsym;
	wsym[28] := MODsym;
	wsym[29] := DOsym;
	wsym[30] := TYPEsym;
	wsym[31] := OFsym;
	wsym[32] := USESsym;
	wsym[33] := DOWNTOsym;
	wsym[34] := RETURNsym;
	wsym[35] := PROGRAMsym;
	wsym[36] := OTHERWISEsym;
	wsym[37] := STRINGsym;
	wsym[38] := ARRAYsym;
	wsym[39] := NOTsym;
	wsym[40] := THENsym;
	wsym[41] := CONSTsym;
	wsym[42] := XORsym;
	wsym[43] := SETsym;
	wsym[44] := UNITsym;
	wsym[45] := VARsym;
	wsym[47] := ORsym;
	wsym[48] := GOTOsym;
	wsym[50] := REPEATsym;
	wsym[55] := TOsym;

	HashTable['A'] := 23;
	HashTable['B'] := 3;
	HashTable['C'] := 10;
	HashTable['D'] := 0;
	HashTable['E'] := 0;
	HashTable['F'] := 2;
	HashTable['G'] := 17;
	HashTable['H'] := 3;
	HashTable['I'] := 1;
	HashTable['L'] := 3;
	HashTable['M'] := 25;
	HashTable['N'] := 10;
	HashTable['O'] := 27;
	HashTable['P'] := 3;
	HashTable['R'] := 18;
	HashTable['S'] := 14;
	HashTable['T'] := 26;
	HashTable['U'] := 14;
	HashTable['V'] := 24;
	HashTable['W'] := 12;
	HashTable['X'] := 21;
	HashTable['Y'] := 10;
end; { initSym1 }

end.
