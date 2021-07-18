1. What is Cabezon?
Caveson is a self-describing Pascal compiler. It works in MS-DOS or Windows95 or WindowsNT DOS windows.

The Caveson compiler is a one-pass compiler that reads the Pascal source and outputs the MASM assembly source to generate 8086 native code. Reprinting this version is free. However, it is fine even after the fact, so please send an email to the effect that it will be reprinted. If you have any questions regarding Caveson, please contact ockeghem. This archive contains all the files you need to get started with Caveson.


2. Files contained in this archive

README.TXT      This file
CAB.EXE         Compiler driver
CAB1.EXE        Compiler body
CABEZON.ERR     Error message
CABEZON.INI     Definition collection of built-in functions
CLIB.LIB        Library
EXTERNAL.PAS    Sample of external function / procedure
PRLIST.PAS      Sample program (list processing: example of using new and dispose)
QUEEN.PAS       Sample program (8 queens)
TEXTCOPY.PAS    Sample program (copy of text file)
ADD.ASM         Sample of external function / procedure
HUGESAMP.PAS    Huge array sample program

3. For the time being, to try it

(1) Preparation
Unzip the archive file with LHA or WinZip.
MASM / LINK, TASM / TLINK, R86 / LLD are required for compilation. R86 / LLD is attached to the tasting version of LSI C-86, so you can use it for free.
Make sure that these programs are in the current directory or the directory specified in PATH. Also, be sure to put the two files CABEZON.INI and CABEZON.ERR in the same directory as CAB1.EXE. It can be any directory as long as it is specified in the PATH.

[Important] The three files CAB1.EXE, CABEZON.INI, and CABEZON.ERR should be stored in the same directory.

When using TASM / TLINK as an assembler / linker, set the environment variables as shown below.

C:\>SET ASM=TASM 
C:\>SET LINK=TLINK

  Similarly, when using R86 / LLD,

C:\>SET ASM=R86
C:\>SET LINK=LLD

And so on.

(2) Compile link
Caveson has a compiler driver CAB.EXE. For easy compilation and linking, from the MS-DOS prompt

A>CAB QUEEN

Please type in. The compiler, assembler, and linker should be started automatically, and the program QUEEN.EXE should be created.

(3) Execution
Execution of the sample program is the same as a normal MS-DOS program,

A>QUEEN

Please type in.
It is OK if the 8 queens program is started and 92 solutions are displayed.
If it doesn't work, please contact Ockeghem.
Thank you.


4. Copyright, disclaimer, etc.
The copyright is owned by Hiroshi Tokumaru.
As mentioned earlier, reprinting is free, but please send an email to Ockeghem to the effect that it has been reprinted. In addition, the author is not responsible for the results of using this program, so please use it at your own risk. In particular, please note that the current version may contain many bugs.


5. Acknowledgments
We received encouragement and advice from many people in the development of Caveson. In particular, we received useful advice and warm encouragement from many people, including Chairman nemossan of the Nikkei MIX pascal conference. I would like to take this moment to say thank you. We look forward to your continued support of Caveson.

Hiroshi Tokumaru / ockeghem
	htokumar@jun.email.ne.jp
	QGB01521@niftyserve.or.jp
	hiroshi_tokumaru@msn.com
