unit calibration_time_f;

// Calibrate all sampling ranges using square wave signal of known frequency

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ActnList, api5_p, config_p, lerp_p, SpinEx, TAGraph, TASeries;

type

  { TCalibrationTime }

  TCalibrationTime = class(TForm)
    Action1: TAction;
    ActionList1: TActionList;
    btnCancel1: TButton;
    btnMeasure1: TButton;
    btnMeasure2: TButton;
    btnMeasure3: TButton;
    btnMeasure4: TButton;
    btnMeasure5: TButton;
    btnMeasure6: TButton;
    btnMeasure7: TButton;
    btnMeasure8: TButton;
    btnSave1: TButton;
    btnRefresh1: TButton;
    Chart1: TChart;
    edtFrequency1: TFloatSpinEditEx;
    edtFrequency2: TFloatSpinEditEx;
    edtFrequency3: TFloatSpinEditEx;
    edtFrequency4: TFloatSpinEditEx;
    edtFrequency5: TFloatSpinEditEx;
    edtFrequency6: TFloatSpinEditEx;
    edtFrequency7: TFloatSpinEditEx;
    edtFrequency8: TFloatSpinEditEx;
    labCode1: TLabel;
    labCode2: TLabel;
    labCode3: TLabel;
    labCode4: TLabel;
    labCode5: TLabel;
    labCode6: TLabel;
    labCode7: TLabel;
    labCode8: TLabel;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label2: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    Label25: TLabel;
    labNote1: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    labVoltage1: TLabel;
    procedure btnCancel1Click(Sender: TObject);
    procedure btnMeasure1Click(Sender: TObject);
    procedure btnMeasure2Click(Sender: TObject);
    procedure btnMeasure3Click(Sender: TObject);
    procedure btnMeasure4Click(Sender: TObject);
    procedure btnMeasure5Click(Sender: TObject);
    procedure btnMeasure6Click(Sender: TObject);
    procedure btnMeasure7Click(Sender: TObject);
    procedure btnMeasure8Click(Sender: TObject);
    procedure btnRefresh1Click(Sender: TObject);
    procedure btnSave1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    Series: TLineSeries;
    procedure Measure(aSamplingRate: integer; aLabel: TLabel);
  public

  end;

var
  CalibrationTime: TCalibrationTime;

implementation

{$R *.lfm}

{ TCalibrationTime }

procedure TCalibrationTime.Measure(aSamplingRate: integer; aLabel: TLabel);
var p : real;
begin
  // Measure period length and display it in label
  // Change sampling rate
  Api5Send('S' + IntToStr(aSamplingRate), 50, 1).Free;
  // Measure period
  p := Api5Period;
  aLabel.Caption := Format('%1.3f', [p]);
  // Refresh chart
  btnRefresh1.Click;
  // Show red label if too few samples for this frequency
  aLabel.Font.Color := clDefault;
  labNote1.Visible := false;
  if p < 0.1 * 500 then
  begin
    aLabel.Font.Color := clRed;
    labNote1.Visible := true;
  end;
end;

procedure TCalibrationTime.btnMeasure1Click(Sender: TObject);
begin
  Measure(1, labCode1);
end;

procedure TCalibrationTime.btnMeasure2Click(Sender: TObject);
begin
  Measure(2, labCode2);
end;

procedure TCalibrationTime.btnMeasure3Click(Sender: TObject);
begin
  Measure(3, labCode3);
end;

procedure TCalibrationTime.btnMeasure4Click(Sender: TObject);
begin
  Measure(4, labCode4);
end;

procedure TCalibrationTime.btnMeasure5Click(Sender: TObject);
begin
  Measure(5, labCode5);
end;

procedure TCalibrationTime.btnMeasure6Click(Sender: TObject);
begin
  Measure(6, labCode6);
end;

procedure TCalibrationTime.btnMeasure7Click(Sender: TObject);
begin
  Measure(7, labCode7);
end;

procedure TCalibrationTime.btnMeasure8Click(Sender: TObject);
begin
  Measure(8, labCode8);
end;

procedure TCalibrationTime.btnRefresh1Click(Sender: TObject);
var w : TWordList;
    r : TRealList;
    i: integer;
begin
  w := Api5Send('B', 100, 500);
  r := Api5Voltages(Config.Range, w);
  Series.Clear;
  for i := 0 to r.Count-1 do
    Series.AddXY(i, r[i]);
  //Chart1.Extent.XMin := 0;
  //Chart1.Extent.XMax := r.Count-1;
  Chart1.Extent.YMin := 0;
  Chart1.Extent.UseYMin := true;
  //Chart1.Extent.YMax := ;
  w.Free;
  r.Free;
end;

procedure TCalibrationTime.btnSave1Click(Sender: TObject);
var c1, c2, c3, c4, c5, c6, c7, c8: real;
begin
  // Save
  c1 := StrToFloat(labCode1.Caption);
  c2 := StrToFloat(labCode2.Caption);
  c3 := StrToFloat(labCode3.Caption);
  c4 := StrToFloat(labCode4.Caption);
  c5 := StrToFloat(labCode5.Caption);
  c6 := StrToFloat(labCode6.Caption);
  c7 := StrToFloat(labCode7.Caption);
  c8 := StrToFloat(labCode8.Caption);
  Config.WriteFloat('TIME', 'Frequency1', edtFrequency1.Value);
  Config.WriteFloat('TIME', 'Frequency2', edtFrequency2.Value);
  Config.WriteFloat('TIME', 'Frequency3', edtFrequency3.Value);
  Config.WriteFloat('TIME', 'Frequency4', edtFrequency4.Value);
  Config.WriteFloat('TIME', 'Frequency5', edtFrequency5.Value);
  Config.WriteFloat('TIME', 'Frequency6', edtFrequency6.Value);
  Config.WriteFloat('TIME', 'Frequency7', edtFrequency7.Value);
  Config.WriteFloat('TIME', 'Frequency8', edtFrequency8.Value);
  Config.WriteFloat('TIME', 'Samples1', c1);
  Config.WriteFloat('TIME', 'Samples2', c2);
  Config.WriteFloat('TIME', 'Samples3', c3);
  Config.WriteFloat('TIME', 'Samples4', c4);
  Config.WriteFloat('TIME', 'Samples5', c5);
  Config.WriteFloat('TIME', 'Samples6', c6);
  Config.WriteFloat('TIME', 'Samples7', c7);
  Config.WriteFloat('TIME', 'Samples8', c8);
  // restore current sampling and close
  Api5Send('S' + IntToStr(Config.Sampling), 50, 1).Free;
  Close;
end;

procedure TCalibrationTime.FormCreate(Sender: TObject);
begin
  // Initialize form
  Series := TLineSeries.Create(Chart1);
  Series.SeriesColor:= clRed;
  Series.AddXY(0, 0);
  Series.AddXY(500, 0);
  Chart1.AddSeries(Series);
  edtFrequency1.Value := Config.ReadFloat('TIME', 'Frequency1', DEF_FREQUENCY[1]);
  edtFrequency2.Value := Config.ReadFloat('TIME', 'Frequency2', DEF_FREQUENCY[2]);
  edtFrequency3.Value := Config.ReadFloat('TIME', 'Frequency3', DEF_FREQUENCY[3]);
  edtFrequency4.Value := Config.ReadFloat('TIME', 'Frequency4', DEF_FREQUENCY[4]);
  edtFrequency5.Value := Config.ReadFloat('TIME', 'Frequency5', DEF_FREQUENCY[5]);
  edtFrequency6.Value := Config.ReadFloat('TIME', 'Frequency6', DEF_FREQUENCY[6]);
  edtFrequency7.Value := Config.ReadFloat('TIME', 'Frequency7', DEF_FREQUENCY[7]);
  edtFrequency8.Value := Config.ReadFloat('TIME', 'Frequency8', DEF_FREQUENCY[8]);
  labCode1.Caption := Config.ReadFloat('TIME', 'Samples1', DEF_SAMPLES[1]).ToString();
  labCode2.Caption := Config.ReadFloat('TIME', 'Samples2', DEF_SAMPLES[2]).ToString();
  labCode3.Caption := Config.ReadFloat('TIME', 'Samples3', DEF_SAMPLES[3]).ToString();
  labCode4.Caption := Config.ReadFloat('TIME', 'Samples4', DEF_SAMPLES[4]).ToString();
  labCode5.Caption := Config.ReadFloat('TIME', 'Samples5', DEF_SAMPLES[5]).ToString();
  labCode6.Caption := Config.ReadFloat('TIME', 'Samples6', DEF_SAMPLES[6]).ToString();
  labCode7.Caption := Config.ReadFloat('TIME', 'Samples7', DEF_SAMPLES[7]).ToString();
  labCode8.Caption := Config.ReadFloat('TIME', 'Samples8', DEF_SAMPLES[8]).ToString();
end;

procedure TCalibrationTime.btnCancel1Click(Sender: TObject);
begin
  // Close without saving
  Api5Send('S' + IntToStr(Config.Sampling), 50, 1).Free;
  Close;
end;

end.

