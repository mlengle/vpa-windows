{ ===========================================================================
  PCSPK.PAS - VPA-Windows: emulacion del altavoz del PC (Sound/NoSound).

  En DOS, Sound(hz) dejaba sonando el altavoz interno con una onda cuadrada
  de hz herzios hasta NoSound, y el visor de combate cambia la frecuencia
  cada pocos milisegundos (rayos, torpedos, explosiones, la musica de los
  "lemmings"). En Windows no hay acceso a ese altavoz, asi que se sintetiza
  la misma onda cuadrada y se envia a la salida de audio por waveOut (winmm):
  un hilo rellena NBUF buferes cortos con la frecuencia que este pedida en
  ese momento. Latencia: NBUF*BUFLEN/RATE, unos 23 ms.

  El dispositivo se abre en el primer Sound, no al arrancar: quien no oye
  nunca un combate con sonido no abre audio. Si no hay salida de audio,
  Sound y NoSound no hacen nada, como antes.

  Modo objfpc local (hilos y API de Windows); lo consume AUXF (-Mtp).
  En Linux la unidad compila vacia.
  =========================================================================== }
unit PCSpk;

{$MODE OBJFPC}{$H-}

interface

procedure SpkSound(Hz: LongInt);
procedure SpkNoSound;
{ True si la salida de audio esta abierta y sonando (para pruebas). }
function SpkActive: Boolean;

implementation

{$IFDEF WINDOWS}
uses Windows, MMSystem;

const
  RATE   = 44100;
  NBUF   = 4;
  BUFLEN = 256;          { muestras por bufer: 5,8 ms }
  AMP    = 5000;         { de 32767: el altavoz del PC no era discreto }

var
  WaveOut : HWAVEOUT;
  Hdr     : array [0..NBUF-1] of TWAVEHDR;
  Buf     : array [0..NBUF-1, 0..BUFLEN-1] of SmallInt;
  DoneEv  : THandle = 0;
  Started : Boolean = False;
  Failed  : Boolean = False;
  Freq    : LongInt = 0;       { la escribe el hilo principal, la lee el de audio }
  Phase   : LongWord = 0;      { acumulador de fase, 32 bits = un periodo }

procedure Fill(i: Integer);
var
  f: LongInt;
  stp: LongWord;
  j: Integer;
begin
  f := Freq;
  if (f <= 0) or (f >= RATE div 2) then
  begin
    FillChar(Buf[i], SizeOf(Buf[i]), 0);
    Exit;
  end;
  stp := LongWord((QWord(f) shl 32) div RATE);
  for j := 0 to BUFLEN - 1 do
  begin
    if Phase < $80000000 then Buf[i, j] := AMP else Buf[i, j] := -AMP;
    Inc(Phase, stp);
  end;
end;

function SpkThread(p: Pointer): PtrInt;
var
  i: Integer;
begin
  Result := 0;
  repeat
    WaitForSingleObject(DoneEv, INFINITE);
    for i := 0 to NBUF - 1 do
      if (Hdr[i].dwFlags and WHDR_DONE) <> 0 then
      begin
        Fill(i);
        Hdr[i].dwFlags := Hdr[i].dwFlags and not WHDR_DONE;
        waveOutWrite(WaveOut, @Hdr[i], SizeOf(TWAVEHDR));
      end;
  until False;
end;

procedure Start;
var
  fmt: TWAVEFORMATEX;
  i: Integer;
begin
  if Started or Failed then Exit;
  Failed := True;   { si algo falla abajo, no se reintenta en cada Sound }
  FillChar(fmt, SizeOf(fmt), 0);
  fmt.wFormatTag      := WAVE_FORMAT_PCM;
  fmt.nChannels       := 1;
  fmt.nSamplesPerSec  := RATE;
  fmt.wBitsPerSample  := 16;
  fmt.nBlockAlign     := 2;
  fmt.nAvgBytesPerSec := RATE * 2;
  DoneEv := CreateEvent(nil, False, False, nil);
  if DoneEv = 0 then Exit;
  if waveOutOpen(@WaveOut, WAVE_MAPPER, @fmt, DWORD_PTR(DoneEv), 0,
                 CALLBACK_EVENT) <> MMSYSERR_NOERROR then Exit;
  for i := 0 to NBUF - 1 do
  begin
    FillChar(Hdr[i], SizeOf(TWAVEHDR), 0);
    Hdr[i].lpData := @Buf[i];
    Hdr[i].dwBufferLength := SizeOf(Buf[i]);
    if waveOutPrepareHeader(WaveOut, @Hdr[i], SizeOf(TWAVEHDR)) <> MMSYSERR_NOERROR then Exit;
  end;
  for i := 0 to NBUF - 1 do
  begin
    Fill(i);
    waveOutWrite(WaveOut, @Hdr[i], SizeOf(TWAVEHDR));
  end;
  if BeginThread(@SpkThread, nil) = 0 then Exit;
  Failed := False;
  Started := True;
end;

procedure SpkSound(Hz: LongInt);
begin
  Freq := Hz;
  if not Started then Start;
end;

procedure SpkNoSound;
begin
  Freq := 0;
end;

function SpkActive: Boolean;
begin
  Result := Started;
end;

{$ELSE}

procedure SpkSound(Hz: LongInt); begin end;
procedure SpkNoSound; begin end;
function SpkActive: Boolean; begin Result := False; end;

{$ENDIF}

end.
