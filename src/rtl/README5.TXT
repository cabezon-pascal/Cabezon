１．カベソン（Cabezon）とは？
　カベソンは自己記述可能なPascalコンパイラです。
　カベソン・コンパイラは１パスのコンパイラで、Pascalのソースを読み込んで
MASMのアセンブリソースを出力することにより、8086のネイティブ・コードを生
成します。
　このアーカイブには、ライブラリ構築のためのソースファイルが入っています。
　カベソンに関する要望質問等は、ockeghem まで連絡下さいますようお願い致し
ます。


２．このアーカイブに含まれるファイル

  README5.TXT    このファイル
  _LIBSOU.ZIP    ライブラリ・ソース詰め合せ

【_LIBSOU.ZIP の内容】
  C.ASM          スタートアップルーチン
  I8087W1.ASM    ８０８７用ワーク１
  I8087W2.ASM    ８０８７用ワーク２
  ITOR.ASM       整数→実数の変換ルーチン
  LN.ASM         自然対数
  LOG10.ASM      常用対数
  LOWIO.PAS      アセンブリ記述の関数手続きのinterface仕様
  READCHAR.ASM   バッファリングありのキー入力ルーチン
  READINT.PAS    整数の読み込みルーチン
  READRL.PAS     実数の読み込みルーチン
  READST.PAS     文字列の読み込みルーチン
  ROUND.ASM      四捨五入をともなう実数→整数変換ルーチン
  SKIPWH.PAS     空白文字をスキップする
  SQRT.ASM       平方根を求める
  STRCMP.PAS     文字列の比較
  SYSTEM.PAS     アセンブリ記述の関数手続きのinterface仕様
  TRUNC.ASM      切捨てによる実数→整数変換ルーチン
  UNGETC.ASM     入力した文字を戻す手続き
  WRITECH.ASM    １文字の出力（バッファリングあり）
  WRITECHR.PAS   １文字の出力（Pascalの仕様に準拠）
  WRITEINT.PAS   整数の出力
  WRITELN.PAS    改行
  WRITERL.PAS    実数の出力
  WRITEST.PAS    文字列の出力
  ZZFLUSH.ASM    出力バッファの掃き出し


３．著作権・免責など
　このプログラムはフリーソフトです。転載は自由ですが、事後で結構ですので、
転載の旨の連絡をメールして下さい。
　また、勝手ながら、このプログラムを使用したことによる結果等については、
作者は責任を負いかねますので、使用者の責任において利用して下さい。
　とくに現在のバージョンにはバグが多く含まれているかもしれないことをお断
りしておきます

徳丸浩／ockeghem
	htokumar@jun.email.ne.jp
	QGB01521@niftyserve.or.jp
	hiroshi_tokumaru@msn.com

