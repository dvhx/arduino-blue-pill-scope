unit api5_p;

{
Binary api to communicate with scope, scope is sending back array of words (uint16_t)

Command Explanation
SX      Switch sampling rate, X=1..8, receives value that switched to
sX      Switch sampling rate, X=1..8, receives nothing
CX      Switch channel (range) to X, X=1..4, receives ADC channel switched to
cX      Switch channel (range) to X, X=1..4, receives nothing
B       Request for binary data, receives binary buffer (currently 500 uint16_t)
P       Measure period (decision level is at 50% between max and min voltage), sends back 1 uint16_t with number of samples in period
a       Measure average code in entire block, receives uint16_t with 10*average code e.g. 20480 for average code 2048
A       Measure average code in 30 blocks, receives uint16_t with 10*average code  e.g. 20480 for average code 2048
j       Print some debuging info in ascii format

Typical use:

s1c2B   - Switch to fastest sampling rate 1 (1.5cycles/sample, 862kHz)
        - Switch to channel 2 (pin PA7)
        - Measure one block and send it back in binary form (2*500 bytes)
}

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Dialogs, DateUtils, fgl, config_p, lerp_p;

type
  TWordList = specialize TFPGList<Word>;   // "Word" is uint16_t
  TRealList = specialize TFPGList<Real>;

// low leverl calls
function Api5Send(aCommand: string; aDelayMS: integer; aWordCount: integer) : TWordList; // send command, receive words back
function Api5Voltages(aRange: integer; aWordList: TWordList) : TRealList;                // convert words to voltages
function Api5Ascii(aCommand: string; aDelayMS: integer; aMaxLength: word) : string;      // send command, receive response as string

// higher level calls
function Api5Avg : real;               // measure average word from 30 blocks
function Api5AvgFast: real;            // measure average word from 1 block
procedure Api5Range(aRange : integer); // switch range
function Api5Period : real;            // measure period (unit is number of samples)
function Api5ReadString : string;      // read string from device

var Api5Busy : boolean = false;        // true during any command

implementation

function Api5Ascii(aCommand: string; aDelayMS: integer; aMaxLength: word) : string;
var r: longint;
    i: longint;
    buffer: TByteArray;
    f: file of char;
begin
  // Send command and receive response as ascii string
  Api5Busy := true;
  AssignFile(f, '/dev/' + Config.PortName);
  // open port
  {$I-}
  Reset(f);
  {$I+}
  if IOResult <> 0 then
  begin
    Api5Busy := false;
    exit;
  end;
  Rewrite(f);
  // write command
  for i := 1 to length(aCommand) do
    write(f, aCommand[i]);
  // wait
  sleep(aDelayMS);
  // read response in one block
  r := 0;
  BlockRead(f, buffer, aMaxLength, r);
  result := '';
  SetLength(result, r);
  for i := 0 to r do
    result[i + 1] := chr(buffer[i]);
  // close file
  CloseFile(f);
  Api5Busy := false;
end;

function Api5Send(aCommand: string; aDelayMS: integer; aWordCount: integer) : TWordList;
// Send aCommand, wait aDelayMs milliseconds, then read response in one block
var f: file of byte;
    r, i: longint;
    buffer : array[0..32768] of byte;
    //buffer: TByteArray; this was causing some issues, if I used this then BlockRead could not read #13 in data!
    w: word;
begin
  if (2 * aWordCount > 32768) then
    exit;
  Api5Busy := true;
  //  SetLength(buffer, aWordCount * 2);
  result := TWordList.Create;
  // open port
  AssignFile(f, '/dev/' + Config.PortName);
  {$I-}
  Reset(f);
  {$I+}
  if IOResult <> 0 then
  begin
    Api5Busy := true;
    exit;
  end;
  // read possible pending garbage
  BlockRead(f, buffer, 1000, r);
  // open file for writing
  Rewrite(f);
  // write command
  for i := 1 to length(aCommand) do
    Write(f, byte(aCommand[i]));
  // wait
  sleep(aDelayMS);
  // read response in one block
  if (aWordCount > 0) then
  begin
    BlockRead(f, buffer, 2 * aWordCount, r);
    if r <> 2 * aWordCount then
    begin
      //SetLength(buffer, 0);
      Api5Busy := false;
      exit;
    end;
    // convert data to voltages
    i := 0;
    while i < r do
    begin
      w := buffer[i] * 256;
      inc(i);
      w := w + buffer[i];
      inc(i);
      result.add(w);
    end;
  end;
  // close file
  CloseFile(f);
  //SetLength(buffer, 0);
  Api5Busy := false;
end;

function Api5Voltages(aRange: integer; aWordList: TWordList) : TRealList;
// Convert ADC codes to voltages
var i : integer;
begin
  result := TRealList.Create;
  for i := 0 to aWordList.Count - 1 do
    result.Add(lerpRange(aRange, aWordList[i]));
end;

procedure Api5Range(aRange : integer);
begin
  // Switch range
  Api5Send('C' + IntToStr(aRange), 15, 1).Free;
end;

function Api5Period: real;
var w : TWordList;
begin
  // Measure period of a square wave signal (for frequency calibration)
  result := 0;
  w := Api5Send('P', 10, 1);
  if w.Count > 0 then
    result := w[0];
  w.Free;
end;

function Api5ReadString: string;
var f: file of char;
    buf: array[0..500] of char;
    r, i: longint;
begin
  // Read any remaining data as string
  Api5Busy := true;
  result := '';
  AssignFile(f, '/dev/' + Config.PortName);
  {$I-}
  Reset(f);
  {$I+}
  if IOResult <> 0 then
  begin
    Api5Busy := false;
    exit;
  end;
  repeat
    BlockRead(f, buf, 500, r);
    for i := 0 to r do
      result := result + buf[i];
  until r <> 500;
  CloseFile(f);
  Api5Busy := false;
end;

function Api5Avg: real;
// Call "A" avg command that returns average of 30 blocks
var w : TWordList;
begin
  result := 0;
  w := Api5Send('A', 250, 1);
  if w.Count > 0 then
    result := w[0] / 10;
  w.Free;
end;

function Api5AvgFast: real;
// Call "a" avg command that returns average of single block
var w : TWordList;
begin
  result := 0;
  w := Api5Send('a', 20, 1);
  if w.Count > 0 then
    result := w[0] / 10;
  w.Free;
end;

end.

