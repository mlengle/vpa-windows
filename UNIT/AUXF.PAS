Unit	AuxF;		(* Auxiliary Functions And Definitions *)
{$V-}


Interface

type	int	= integer;
	long	= longint;
	CharArr	= array [1..MaxInt] of char;
	ByteArr	= array [1..MaxInt] of byte;
	IntArr	= array [1..MaxInt] of int;
	LongArr	= array [1..MaxInt div 2] of long;

const	Yes	= True;
	No	= False;
	On	= True;
	Off	= False;

function  IIF (b:boolean; a1,a2:int) : int;
function  IIFL(b:boolean; a1,a2:long) : long;
function  Within (a,a1,a2:int) : boolean;
function  Sign (a:int) : int;
function  Min (a,b:int) : int;
function  Max (a,b:int) : int;
function  MinL (a,b:long) : long;
function  MaxL (a,b:long) : long;
function  Diff (var arg1,arg2; count:word) : boolean;
procedure Delay (ms:word);
procedure Sound (hz:word);
procedure NoSound;
function  Timer : long;
function  MsTimer : longword;  { milisegundos, da la vuelta cada 49 dias: comparar restando }
function  MaxAvail : long;   { heap: no existe en FPC/Linux; ver implementacion }
function  MemAvail : long;
(* procedure RealModeInt (n:byte;_ds,_es,_ax,_cx,_dx,_bx,_bp,_si,_di:word); *)

Implementation

uses SysUtils;  { Sleep, GetTickCount64 }



function IIF (b:boolean; a1,a2:int) : int;
  begin if b then IIF:=a1 else IIF:=a2; end;

function IIFL(b:boolean; a1,a2:long) : long;
  begin if b then IIFL:=a1 else IIFL:=a2; end;

function Within (a,a1,a2:int) : boolean;
  { Semantica EXACTA del asm original: True si (a>=a1) y (a<>a2) }
  begin Within := (a >= a1) and (a <> a2); end;

function Sign (a:int) : int;
  begin if a<0 then Sign:=-1 else if a>0 then Sign:=1 else Sign:=0; end;

function Min (a,b:int) : int;
  begin if a<=b then Min:=a else Min:=b; end;

function Max (a,b:int) : int;
  begin if a>=b then Max:=a else Max:=b; end;

function MinL (a,b:long) : long;
  begin if a<b then MinL:=a else MinL:=b; end;

function MaxL (a,b:long) : long;
  begin if a>b then MaxL:=a else MaxL:=b; end;

function Diff (var arg1,arg2; count:word) : boolean;
  { True si los 'count' bytes difieren }
  begin Diff := CompareByte(arg1, arg2, count) <> 0; end;

procedure Delay (ms:word);
  begin Sleep(ms); end;

procedure Sound (hz:word);
  begin { TODO: altavoz PC no portable a Linux userspace; no-op por ahora } end;

procedure NoSound;
  begin { TODO: ver Sound } end;

function Timer : long;
  { ticks ~18.2 Hz como la cuenta de la BIOS (1 tick ~ 55 ms) }
  begin Timer := long(GetTickCount64 div 55); end;

{$IFDEF WINDOWS}
{ timeGetTime y no GetTickCount64: esta avanza a saltos de 15,6 ms aunque se
  haya pedido timeBeginPeriod(1), y el limite de 35 ms del scroll se
  convertia en 47-62 ms (medido con una traza). timeGetTime si va a 1 ms. }
function timeGetTime : longword; stdcall; external 'winmm.dll' name 'timeGetTime';
function MsTimer : longword;
  begin MsTimer := timeGetTime; end;
{$ELSE}
function MsTimer : longword;
  begin MsTimer := longword(GetTickCount64); end;
{$ENDIF}

{ MaxAvail/MemAvail eran funciones de heap de Turbo Pascal (memoria libre del
  montón DOS). FPC/Linux no las provee: en Linux la memoria es amplia y dinamica,
  asi que devolvemos un valor grande para que las comprobaciones del tipo
  "¿hay memoria suficiente?" del codigo original pasen siempre. }
function MaxAvail : long;
  begin MaxAvail := $7FFFFFFF; end;

function MemAvail : long;
  begin MemAvail := $7FFFFFFF; end;

{$IFDEF WINDOWS}
{ VPA-Windows: el reloj de Windows avanza por omision cada 15,6 ms, y con el
  Sleep(5) de Delay/CpuNap, el Sleep(1) del bucle de teclado y el Sleep(10)
  del hilo que copia la imagen a la ventana se convertian todos en ~16 ms:
  las animaciones del combate (Delay(5), Delay(13)) iban 1,2-3 veces mas
  lentas y el refresco de la ventana se quedaba en ~60 Hz. Solo iba bien si
  otro programa (un navegador) habia subido la resolucion por su cuenta.
  Se pide 1 ms para todo el proceso, plugin incluido, mientras VPA corre. }
function timeBeginPeriod (uPeriod:longword) : longword; stdcall; external 'winmm.dll' name 'timeBeginPeriod';

{ (Windows lo deshace solo al terminar el proceso: no hace falta timeEndPeriod.) }
{$ENDIF}

begin
{$IFDEF WINDOWS}
  timeBeginPeriod(1);
{$ENDIF}
End.
