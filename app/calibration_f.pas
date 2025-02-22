unit calibration_f;

// Voltage calibration form for all ranges

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  SpinEx, TAGraph, TASeries, TATypes, api5_p, config_p, lerp_p;

type

  { TCalibration }

  TCalibration = class(TForm)
    btnMeasure1: TButton;
    btnMeasure2: TButton;
    btnMeasure3: TButton;
    btnMeasure4: TButton;
    btnMeasure5: TButton;
    btnSave1: TButton;
    btnCancel1: TButton;
    Chart1: TChart;
    edtVoltage1: TFloatSpinEditEx;
    edtVoltage2: TFloatSpinEditEx;
    edtVoltage3: TFloatSpinEditEx;
    edtVoltage4: TFloatSpinEditEx;
    edtVoltage5: TFloatSpinEditEx;
    labCode1: TLabel;
    labCode2: TLabel;
    labCode3: TLabel;
    labCode4: TLabel;
    labCode5: TLabel;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    labVoltage1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Timer1: TTimer;
    procedure btnCancel1Click(Sender: TObject);
    procedure MeasureClick(aLabel: TLabel);
    procedure btnMeasure1Click(Sender: TObject);
    procedure btnMeasure2Click(Sender: TObject);
    procedure btnMeasure3Click(Sender: TObject);
    procedure btnMeasure4Click(Sender: TObject);
    procedure btnMeasure5Click(Sender: TObject);
    procedure btnSave1Click(Sender: TObject);
    procedure edtVoltage1Change(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    Key : string;
    procedure UpdateChart;
  public
    Range: integer;
  end;

var
  Calibration: TCalibration;

implementation

uses main_f;

{$R *.lfm}

{ TCalibration }

procedure TCalibration.MeasureClick(aLabel: TLabel);
var r : real;
begin
  // Measure average voltage and update one label
  Timer1.Enabled := false;
  r := Api5Avg;
  aLabel.Caption := Format('%1.3f', [r]);
  UpdateChart;
  lerpRangeClearCache;
  Timer1.Enabled := true;
end;

procedure TCalibration.btnMeasure1Click(Sender: TObject);
begin
  MeasureClick(labCode1);
end;

procedure TCalibration.btnMeasure2Click(Sender: TObject);
begin
  MeasureClick(labCode2);
end;

procedure TCalibration.btnMeasure3Click(Sender: TObject);
begin
  MeasureClick(labCode3);
end;

procedure TCalibration.btnMeasure4Click(Sender: TObject);
begin
  MeasureClick(labCode4);
end;

procedure TCalibration.btnMeasure5Click(Sender: TObject);
begin
  MeasureClick(labCode5);
end;

procedure TCalibration.btnSave1Click(Sender: TObject);
var c1, c2, c3, c4, c5: real;
begin
  // Save
  c1 := StrToFloat(labCode1.Caption);
  c2 := StrToFloat(labCode2.Caption);
  c3 := StrToFloat(labCode3.Caption);
  c4 := StrToFloat(labCode4.Caption);
  c5 := StrToFloat(labCode5.Caption);
  if (c1 < c2) or (c2 < c3) or (c3 < c4) or (c4 < c5) then
    begin
      MessageDlg('Codes must be descending, first voltage is positive and should have large code, and 5th voltage is smalles or negative and should have small code', mtError, [mbOk], 0);
      exit;
    end;
  if (edtVoltage1.Value < edtVoltage2.Value) or (edtVoltage2.Value < edtVoltage3.Value) or (edtVoltage3.Value < edtVoltage4.Value) or (edtVoltage4.Value < edtVoltage5.Value) then
    begin
      MessageDlg('Voltages must be descending, first voltage is positive and should have large code, and 5th voltage is smalles or negative and should have small code', mtError, [mbOk], 0);
      exit;
    end;
  Config.WriteFloat(key, 'Voltage1', edtVoltage1.Value);
  Config.WriteFloat(key, 'Voltage2', edtVoltage2.Value);
  Config.WriteFloat(key, 'Voltage3', edtVoltage3.Value);
  Config.WriteFloat(key, 'Voltage4', edtVoltage4.Value);
  Config.WriteFloat(key, 'Voltage5', edtVoltage5.Value);
  Config.WriteFloat(key, 'Code1', c1);
  Config.WriteFloat(key, 'Code2', c2);
  Config.WriteFloat(key, 'Code3', c3);
  Config.WriteFloat(key, 'Code4', c4);
  Config.WriteFloat(key, 'Code5', c5);
  Close;
end;

procedure TCalibration.edtVoltage1Change(Sender: TObject);
begin
  // Update chart after voltage change
  UpdateChart;
end;

procedure TCalibration.btnCancel1Click(Sender: TObject);
begin
  // Cancel
  Close;
end;

procedure TCalibration.FormShow(Sender: TObject);
begin
  Api5Range(Range);
  Caption := 'Calibration - Range #' + IntToStr(Range) + ' (approx. ' + FloatToStr(DEF_VOLTAGE[Range][5]) + 'V to ' + FloatToStr(DEF_VOLTAGE[Range][1]) + 'V)';
  btnSave1.Caption := 'Save range #' + IntToStr(Range);
  key := 'RANGE' + IntToStr(Range);
  edtVoltage1.Value := Config.ReadFloat(key, 'Voltage1', DEF_VOLTAGE[Range][1]);
  edtVoltage2.Value := Config.ReadFloat(key, 'Voltage2', DEF_VOLTAGE[Range][2]);
  edtVoltage3.Value := Config.ReadFloat(key, 'Voltage3', DEF_VOLTAGE[Range][3]);
  edtVoltage4.Value := Config.ReadFloat(key, 'Voltage4', DEF_VOLTAGE[Range][4]);
  edtVoltage5.Value := Config.ReadFloat(key, 'Voltage5', DEF_VOLTAGE[Range][5]);
  labCode1.Caption := Config.ReadFloat(key, 'Code1', DEF_CODE[Range][1]).ToString;
  labCode2.Caption := Config.ReadFloat(key, 'Code2', DEF_CODE[Range][2]).ToString;
  labCode3.Caption := Config.ReadFloat(key, 'Code3', DEF_CODE[Range][3]).ToString;
  labCode4.Caption := Config.ReadFloat(key, 'Code4', DEF_CODE[Range][4]).ToString;
  labCode5.Caption := Config.ReadFloat(key, 'Code5', DEF_CODE[Range][5]).ToString;
  UpdateChart;
end;

procedure TCalibration.Timer1Timer(Sender: TObject);
var r : real;
    c : char;
begin
  // Show current voltage
  if not Visible then
    exit;
  Timer1.Tag := Timer1.Tag + 1;
  case Timer1.Tag mod 4 of
    0: c := '*';
    1: c := ' ';
    2: c := '*';
    3: c := ' ';
  end;
  r := Api5AvgFast;
  labVoltage1.Caption := Format('%2.3fV (%0.0f)', [lerpRange(Range, r), r]) + c;
end;

procedure TCalibration.UpdateChart;
var s1 : TLineSeries;
    s2 : TLineSeries;
begin
  // Show calibration curve in chart
  Chart1.Series.Clear;
  Chart1.VertAxis.Range.Min := 0;
  Chart1.VertAxis.Range.UseMin := true;
  Chart1.VertAxis.Range.Max := 4096;
  Chart1.VertAxis.Range.UseMax := true;

  // all points
  s1 := TLineSeries.Create(Chart1);
  s1.ShowPoints := true;
  s1.pointer.Style := TSeriesPointerStyle.psCircle;
  s1.pointer.VertSize := 2;
  s1.pointer.HorizSize := 2;
  s1.pointer.Visible := true;
  s1.pointer.Brush.Color := clRed;
  s1.SeriesColor:= clRed;
  s1.AddXY(edtVoltage1.Value, StrToFloatDef(labCode1.Caption, 0));
  s1.AddXY(edtVoltage2.Value, StrToFloatDef(labCode2.Caption, 0));
  s1.AddXY(edtVoltage3.Value, StrToFloatDef(labCode3.Caption, 0));
  s1.AddXY(edtVoltage4.Value, StrToFloatDef(labCode4.Caption, 0));
  s1.AddXY(edtVoltage5.Value, StrToFloatDef(labCode5.Caption, 0));
  Chart1.AddSeries(s1);

  // only first and last point to check linearity
  s2 := TLineSeries.Create(Chart1);
  s2.SeriesColor:= clBlue;
  s2.AddXY(edtVoltage1.Value, StrToFloatDef(labCode1.Caption, 0));
  s2.AddXY(edtVoltage5.Value, StrToFloatDef(labCode5.Caption, 0));
  Chart1.AddSeries(s2);
end;

end.

