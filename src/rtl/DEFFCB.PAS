unit deffcb;
interface
const
    dummy	   = 0;
    textBufferSize = 512;
    fnameSize      = 65;
    fileClosed		  = $3C56;	(* マジックナンバ *)
    fileOpenedForRead	  = $3C57;
    fileOpenedForWrite	  = $3C58;
    fileOpenedForReadWrite = $3C59;
type
    fnameType = string[fnameSize];
    FCB = record
	       mode : integer;
	       handle : integer;
	       rest   : integer;
	       cptr   : integer;
	       bufsize : integer;
	       fname   : fnameType;
	       istty   : boolean;
	       ioBuffer : array[1..textBufferSize] of char
	   end;

implementation
end.
