unit config_p;

// Configuration ini file in ~/.config/arduinoscope.ini

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, IniFiles;

type
  TConfig = class(TIniFile)
    Range: integer;          // Currently used range, 1=PA0, 2=PA7, 3=?, 4=?
    Sampling: integer;       // Curretly used sampling rate 1..8
    PortName: string;        // Port name after /dev/ for example "ttyUSB0"
    PortSpeed: integer;      // Port speed, e.g. 115200
    YAxisAutomatic: boolean; // If true y-axis min/max will be automatic
    YAxisMin: real;          // If y-axis is not automatic, this value will be used for minimum
    YAxisMax: real;          // If y-axis is not automatic, this value will be used for maximum
    constructor Create(const AFileName: string; AOptions: TIniFileoptions=[]); overload; override;
    procedure Save;
    function TimeStep: real;
  end;

var
  Config: TConfig;

implementation

constructor TConfig.Create(const AFileName: string; AOptions: TIniFileoptions);
begin
  // Load basic settings
  inherited Create(AFileName, AOptions);
  Range := ReadInteger('MAIN', 'Range', 1);
  Sampling := ReadInteger('MAIN', 'Sampling', 1);
  PortName := ReadString('PORT', 'Name', 'ttyUSB0');
  PortSpeed := ReadInteger('PORT', 'Speed', 115200);
  YAxisAutomatic := ReadBool('YAxis', 'Automatic', true);
  YAxisMin := ReadFloat('YAxis', 'Min', -13);
  YAxisMax := ReadFloat('YAxis', 'Max', 13);
end;

procedure TConfig.Save;
begin
  // Save everything at once
  WriteInteger('MAIN', 'Range', Range);
  WriteInteger('MAIN', 'Sampling', Sampling);
  WriteString('PORT', 'Name', PortName);
  WriteInteger('PORT', 'Speed', PortSpeed);
  WriteBool('YAxis', 'Automatic', YAxisAutomatic);
  WriteFloat('YAxis', 'Min', YAxisMin);
  WriteFloat('YAxis', 'Max', YAxisMax);
  UpdateFile;
end;

function TConfig.TimeStep: real;
var f, s: real;
begin
  // Calculate current time step
  f := ReadFloat('TIME', 'Frequency' + IntToStr(Sampling), 10000);
  s := ReadFloat('TIME', 'Samples' + IntToStr(Sampling), 85);
  result := 1/(f*s);
end;

initialization

  Config := TConfig.Create(IncludeTrailingPathDelimiter(GetEnvironmentVariable('HOME')) + '.config' + PathDelim + 'arduinoscope.ini')

finalization

  Config.Free;

end.

