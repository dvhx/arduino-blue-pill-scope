unit lerp_p;

// Convert ADC codes to voltages using calibration curves stored in config file

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Types, config_p;

type
  TDefVoltage = array[1..5] of real;

const
  DEF_VOLTAGE : array[1..4] of TDefVoltage = (
    (13,7,0,-7,-13),
    (5,4,3,1.5,0),
    (1,0.5,0,-0.5,-1),
    (0.1,0.05,0,-0.05,-0.1)
  );
const
  DEF_CODE : array[1..4] of TDefVoltage = (
    (2990,2359,1616,862,210),
    (3016,2444,1868,1066,153),
    (3500,2500,1500,1000,500),
    (3500,2500,1500,1000,500)
  );
const
  DEF_FREQUENCY : array[1..8] of real = (10000,2000,2000,2000,2000,2000,2000,300);
const
  DEF_SAMPLES : array[1..8] of real = (85,300,231,146,112,89,72,158);

type
  TVector2 = record
    x, y: real;
  end;

function lerp(value, x1, y1, x2, y2: real): real;
function lerpRange(aRange: integer; aCode: real) : real;
procedure lerpRangeClearCache;

implementation

function lerp(value, x1, y1, x2, y2: real): real; inline;
begin
  // Linear interpolation
  result := y1 + (y2 - y1) * (value - x1) / (x2 - x1);
end;

var cache_voltage_1, cache_code_1: real;
    cache_voltage_2, cache_code_2: real;
    cache_voltage_3, cache_code_3: real;
    cache_voltage_4, cache_code_4: real;
    cache_voltage_5, cache_code_5: real;
    cache_range : integer = -1;

function lerpRange(aRange: integer; aCode: real) : real;
var key : string;
begin
  // Interpolate code to voltage using calibration of given range
  if cache_range <> aRange then
  begin
    key := 'RANGE' + IntToStr(aRange);
    cache_range := aRange;
    cache_code_1 := Config.ReadFloat(key, 'Code1', DEF_CODE[aRange][0]);
    cache_code_2 := Config.ReadFloat(key, 'Code2', DEF_CODE[aRange][1]);
    cache_code_3 := Config.ReadFloat(key, 'Code3', DEF_CODE[aRange][2]);
    cache_code_4 := Config.ReadFloat(key, 'Code4', DEF_CODE[aRange][3]);
    cache_code_5 := Config.ReadFloat(key, 'Code5', DEF_CODE[aRange][4]);
    cache_voltage_1 := Config.ReadFloat(key, 'Voltage1', DEF_VOLTAGE[aRange][0]);
    cache_voltage_2 := Config.ReadFloat(key, 'Voltage2', DEF_VOLTAGE[aRange][1]);
    cache_voltage_3 := Config.ReadFloat(key, 'Voltage3', DEF_VOLTAGE[aRange][2]);
    cache_voltage_4 := Config.ReadFloat(key, 'Voltage4', DEF_VOLTAGE[aRange][3]);
    cache_voltage_5 := Config.ReadFloat(key, 'Voltage5', DEF_VOLTAGE[aRange][4]);
  end;
  if aCode > cache_code_2 then
  begin
    result := lerp(aCode, cache_code_2, cache_voltage_2, cache_code_1, cache_voltage_1);
    exit;
  end;
  if aCode > cache_code_3 then
  begin
    result := lerp(aCode, cache_code_3, cache_voltage_3, cache_code_2, cache_voltage_2);
    exit;
  end;
  if aCode > cache_code_4 then
  begin
    result := lerp(aCode, cache_code_4, cache_voltage_4, cache_code_3, cache_voltage_3);
    exit;
  end;
  result := lerp(aCode, cache_code_5, cache_voltage_5, cache_code_4, cache_voltage_4);
end;

procedure lerpRangeClearCache;
begin
  // Invalidate cache (e.g. after calibration)
  cache_range := -1;
end;

end.

