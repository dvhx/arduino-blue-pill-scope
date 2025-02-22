program arduinoscope;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, lazcontrols, tachartlazaruspkg, main_f, calibration_f, config_p,
  lerp_p, api5_p, calibration_time_f
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMain, Main);
  Application.CreateForm(TCalibration, Calibration);
  Application.CreateForm(TCalibrationTime, CalibrationTime);
  Application.Run;
end.

