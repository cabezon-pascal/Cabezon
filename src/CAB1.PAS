(* file = cab1.pas
 *
 * cab1.exe : カベソンコンパイラ
 *
 * ラストアップデート　'90/08/16  オケゲム／松田晋
 *
 * Copyright (C) 1990, 91 Ockeghem
 *)

program cab1;
uses cbinit, cbmodule, cbflush;

(* －－－－－－－－－－－－－－　関数定義　－－－－－－－－－－－－－ *)

(*  目的：コンパイラのメインプログラム
 *
 *  戻り値：正常終了（エラー０）の場合は０を返す。
 *)
begin
	Init;
	programOrUnit;
	Flush;
	halt(0)
end.
