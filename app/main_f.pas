unit main_f;

// Main form with chart and main menu

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Menus,
  ComCtrls, ExtCtrls, TAGraph, TASeries, TATypes, TAChartUtils, Process, IniFiles, DateUtils,
  calibration_f, config_p, lerp_p, api5_p, Math, calibration_time_f, TAChartAxisUtils;

type

  { TMain }

  TMain = class(TForm)
    Chart1: TChart;
    MainMenu1: TMainMenu;
    Memo1: TMemo;
    mnuDataShowValues1: TMenuItem;
    mnuDataContinuousMode1: TMenuItem;
    mnuCalibrationTime1: TMenuItem;
    mnuDataDebug1: TMenuItem;
    mnuSampling2: TMenuItem;
    mnuSampling3: TMenuItem;
    mnuSampling4: TMenuItem;
    mnuSampling5: TMenuItem;
    mnuSampling6: TMenuItem;
    mnuSampling7: TMenuItem;
    mnuSampling8: TMenuItem;
    mnuSampling1: TMenuItem;
    mnuXAxis1: TMenuItem;
    mnuDataRefresh1: TMenuItem;
    mnuData1: TMenuItem;
    mnuYAxisAutomatic1: TMenuItem;
    mnuYAxisSetMax1: TMenuItem;
    mnuYAxisSetMin1: TMenuItem;
    mnuYAxis1: TMenuItem;
    mnuRange1: TMenuItem;
    mnuRange2: TMenuItem;
    mnuRange3: TMenuItem;
    mnuRange4: TMenuItem;
    mnuRanges1: TMenuItem;
    mnuCalibrationRange1: TMenuItem;
    mnuCalibrationRange2: TMenuItem;
    mnuCalibrationRange3: TMenuItem;
    mnuCalibrationRange4: TMenuItem;
    mnuCalibration1: TMenuItem;
    mnuPort1: TMenuItem;
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;
    Timer1: TTimer;
    procedure Chart1AfterPaint(ASender: TChart);
    procedure Chart1AxisList1GetMarkText(Sender: TObject; var AText: String; AMark: Double);
    procedure Chart1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Chart1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer
      );
    procedure Chart1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure mnuCalibrationTime1Click(Sender: TObject);
    procedure mnuDataContinuousMode1Click(Sender: TObject);
    procedure mnuDataShowValues1Click(Sender: TObject);
    procedure mnuCalibration1Click(Sender: TObject);
    procedure mnuDataDebug1Click(Sender: TObject);
    procedure mnuDataRefresh1Click(Sender: TObject);
    procedure mnuPort1Click(Sender: TObject);
    procedure mnuRange1Click(Sender: TObject);
    procedure mnuSampling1Click(Sender: TObject);
    procedure mnuYAxisAutomatic1Click(Sender: TObject);
    procedure mnuYAxisSetMax1Click(Sender: TObject);
    procedure mnuYAxisSetMin1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    Series: TLineSeries;
    t0: TDateTime;
    RefreshInProgress: boolean;

    procedure FindUsbPorts;
    procedure mnuPortItemClick(Sender: TObject);
    procedure SetSpeed(aFile: string; aSpeed: integer);
    procedure UpdateCaption(aMessage: string = '');
    procedure UpdateSeries(aData: TRealList);
    procedure DebugRealList(aData: TRealList);
    procedure DebugWordList(aData: TWordList);
  public

  end;

var
  Main: TMain;

implementation

{$R *.lfm}

{ TMain }

procedure TMain.FormCreate(Sender: TObject);
begin
  // Initialize form
  // Create main series
  Series := TLineSeries.Create(Chart1);
  Series.SeriesColor := clRed;
  Chart1.AddSeries(Series);
  mnuYAxisAutomatic1.Checked := Config.YAxisAutomatic;
  Chart1.Extent.YMin := Config.YAxisMin;
  Chart1.Extent.YMax := Config.YAxisMax;
  Chart1.Extent.UseYMin := not Config.YAxisAutomatic;
  Chart1.Extent.UseYMax := not Config.YAxisAutomatic;
  mnuSampling1.Checked := Config.Sampling = 1;
  mnuSampling2.Checked := Config.Sampling = 2;
  mnuSampling3.Checked := Config.Sampling = 3;
  mnuSampling4.Checked := Config.Sampling = 4;
  mnuSampling5.Checked := Config.Sampling = 5;
  mnuSampling6.Checked := Config.Sampling = 6;
  mnuSampling7.Checked := Config.Sampling = 7;
  mnuSampling8.Checked := Config.Sampling = 8;
  // ports
  FindUsbPorts;
  if Config.PortName <> '' then
  begin
    SetSpeed(Config.PortName, Config.PortSpeed);
    mnuDataRefresh1.Click;
  end;
  Timer1.Interval := Config.ReadInteger('MAIN', 'ContinuousInterval', 1000);
  mnuDataContinuousMode1.Checked := Config.ReadBool('MAIN', 'ContinuousEnabled', false);
  Timer1.Enabled := mnuDataContinuousMode1.Checked;
  mnuDataShowValues1.Checked := Config.ReadBool('MAIN', 'DataShowValues', false);
  Memo1.Visible := mnuDataShowValues1.Checked;
  // restore window position
  Left := Config.ReadInteger('MAIN', 'WindowLeft', Left);
  Top := Config.ReadInteger('MAIN', 'WindowTop', Top);
  Width := Config.ReadInteger('MAIN', 'WindowWidth', Width);
  Height := Config.ReadInteger('MAIN', 'WindowHeight', Height);
end;

procedure TMain.FormDestroy(Sender: TObject);
begin
  // Remember window position
  Config.WriteInteger('MAIN', 'WindowLeft', Left);
  Config.WriteInteger('MAIN', 'WindowTop', Top);
  Config.WriteInteger('MAIN', 'WindowWidth', Width);
  Config.WriteInteger('MAIN', 'WindowHeight', Height);
end;

procedure TMain.Chart1AxisList1GetMarkText(Sender: TObject; var AText: String; AMark: Double);
// Show x-zero as "0ms" instead of "0.00"
begin
  aText := format('%1.2f', [aMark]);
  if aText = '0.00' then
    aText := '0ms';
end;

var MeasureStart : TDoublePoint;
    Measuring : boolean = false;
    LastCursorMouse : TPoint;
    LastCursorReal: TDoublePoint;

procedure TMain.Chart1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  // Start measuring time/voltage while holding shift and left mouse button
  if ssLeft in Shift then
  begin
    Measuring := true;
    MeasureStart := Chart1.ImageToGraph(point(x,y));
  end;
end;

procedure TMain.Chart1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var p: TDoublePoint;
    sx, sy: string;
begin
  // Show cursor values in statusbar and near cursor
  if (not Chart1.ScalingValid) or ((x = 0) and (y = 0)) then
    exit;
  p := Chart1.ImageToGraph(Point(x,y));
  LastCursorMouse := point(x,y);
  LastCursorReal := p;
  sx := Format('%1.3f', [p.x]) + 'ms';
  sy := Format('%1.3f', [p.y]) + 'V';
  StatusBar1.Panels[2].Text := sx;
  StatusBar1.Panels[4].Text := sy;
  Chart1.Repaint;
  if not ((ssLeft in Shift) or (ssRight in Shift) or (ssMiddle in Shift)) then
  begin
    Chart1.Canvas.Font.Color := clBlack;
    Chart1.Canvas.TextOut(LastCursorMouse.x + 10, LastCursorMouse.y - 10, sx + ' ' + sy);
  end;
end;

procedure TMain.Chart1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var MeasureEnd : TDoublePoint;
    t1, t2: double;
    v1, v2: double;
begin
  // End measuring time and voltage (using shift and left mouse button) and show delta
  if Measuring then
  begin
    Measuring := false;
    MeasureEnd := Chart1.ImageToGraph(point(x,y));
    t1 := min(MeasureStart.x, MeasureEnd.x);
    t2 := max(MeasureStart.x, MeasureEnd.x);
    v1 := min(MeasureStart.y, MeasureEnd.y);
    v2 := max(MeasureStart.y, MeasureEnd.y);
    ShowMessage(
    'Voltage: ' + format('%1.3fV ... %1.3fV (delta %1.3fV)', [v1, v2, v2-v1]) + LineEnding +
    'Time: ' + format('%1.6fms ... %1.6fms (delta %1.6fms)', [t1, t2, t2-t1]) + LineEnding +
    'Frequency: ' + format('%1.3f Hz', [1000/(t2-t1)])
    );
  end;
end;

procedure TMain.Chart1AfterPaint(ASender: TChart);
var sx, sy: string;
begin
  // This prevents label from disappearing
  if (LastCursorMouse.x = 0) and (LastCursorMouse.y = 0) then
    exit;
  sx := Format('%1.3f', [LastCursorReal.x]) + 'ms';
  sy := Format('%1.3f', [LastCursorReal.y]) + 'V';
  Chart1.Canvas.Font.Color := clBlack;
  Chart1.Canvas.TextOut(LastCursorMouse.x + 10, LastCursorMouse.y - 10, sx + ' ' + sy);
end;

procedure TMain.mnuCalibrationTime1Click(Sender: TObject);
begin
  // Calibrate time
  CalibrationTime.ShowModal;
end;

procedure TMain.mnuDataContinuousMode1Click(Sender: TObject);
begin
  // start/stop continuous mode
  Timer1.Enabled := mnuDataContinuousMode1.Checked;
  Config.WriteBool('MAIN', 'ContinuousChecked', mnuDataContinuousMode1.Checked);
  Config.Save;
end;

procedure TMain.mnuDataShowValues1Click(Sender: TObject);
begin
  // Show/hide values
  Memo1.Visible := mnuDataShowValues1.Checked;
  Config.WriteBool('MAIN', 'DataShowValues', mnuDataShowValues1.Checked);
  Config.Save;
end;

procedure TMain.mnuCalibration1Click(Sender: TObject);
begin
  // Show calibration form for given range
  Calibration.Range := TMenuItem(Sender).Tag;
  Calibration.ShowModal;
end;

procedure TMain.mnuDataDebug1Click(Sender: TObject);
begin
  // Get debug info via "j" command
  Memo1.Lines.Text := '...';
  Application.ProcessMessages;
  Memo1.Lines.Text := Api5Ascii('j', 500, 32000);
end;

procedure TMain.mnuDataRefresh1Click(Sender: TObject);
var r: TRealList;
    w : TWordList;
    i : integer;
begin
  // refresh data
  RefreshInProgress := true;
  // read binary buffer
  w := Api5Send('s' + IntToStr(Config.Sampling) + 'c' + IntToStr(Config.Range) + 'B', 100, 500);
  r := Api5Voltages(Config.Range, w);
  // Add points to series
  UpdateSeries(r);
  // Add to memo
  if Memo1.Visible then
  begin
    Memo1.Lines.BeginUpdate;
    Memo1.Lines.Clear;
    for i := 0 to r.Count-1 do
      Memo1.Lines.Add(FloatToStr(r[i]));
    Memo1.Lines.EndUpdate;
  end;
  w.Free;
  r.Free;
  RefreshInProgress := false;
end;

procedure TMain.mnuPort1Click(Sender: TObject);
begin
  // Refresh port menu
  FindUsbPorts;
end;

procedure TMain.mnuRange1Click(Sender: TObject);
begin
  // Change range
  Config.Range := TMenuItem(Sender).Tag;
  Config.Save;
  TMenuItem(Sender).Checked := true;
  Api5Send('C' + IntToStr(Config.Range), 10, 1).Free;
  UpdateCaption;
  mnuRanges1.Caption:= '&Range #' + IntToStr(Config.Range);
  mnuDataRefresh1.Click;
end;

procedure TMain.mnuSampling1Click(Sender: TObject);
var mi : TMenuItem;
begin
  // Change sampling rate
  mi := TMenuItem(Sender);
  mi.Checked := true;
  Config.Sampling := mi.Tag;
  Config.Save;
  Api5Send('S' + IntToStr(mi.Tag), 10, 1).Free;
  mnuDataRefresh1.Click;
end;

procedure TMain.mnuYAxisAutomatic1Click(Sender: TObject);
begin
  // Make y-axis auromatic/manual
  Config.YAxisAutomatic := mnuYAxisAutomatic1.Checked;
  Config.Save;
  Chart1.Extent.YMin := Config.YAxisMin;
  Chart1.Extent.YMax := Config.YAxisMax;
  Chart1.Extent.UseYMin := not Config.YAxisAutomatic;
  Chart1.Extent.UseYMax := not Config.YAxisAutomatic;
end;

procedure TMain.mnuYAxisSetMax1Click(Sender: TObject);
var s : string;
begin
  // Ask user for y-axis max value
  s := FloatToStr(Config.YAxisMax);
  if InputQuery('Y-Axis max', 'Volts', s) then
  begin
    Config.YAxisMax := StrToFloatDef(s, Config.YAxisMax);
    Config.Save;
    Chart1.Extent.YMax := Config.YAxisMax;
  end;
end;

procedure TMain.mnuYAxisSetMin1Click(Sender: TObject);
var s : string;
begin
  // Ask user for y-axis min value
  s := FloatToStr(Config.YAxisMin);
  if InputQuery('Y-Axis min', 'Volts', s) then
  begin
    Config.YAxisMin := StrToFloatDef(s, Config.YAxisMin);
    Config.Save;
    Chart1.Extent.YMin := Config.YAxisMin;
  end;
end;

procedure TMain.FindUsbPorts;
var sr: TSearchRec;
    mi: TMenuItem;
    found: boolean = false;
begin
  // Populate port menu with serial ports
  mnuPort1.Clear;
  if FindFirst('/dev/ttyUSB*', faAnyFile, sr) = 0 then
  repeat
    mi := TMenuItem.Create(mnuPort1);
    mi.Caption := sr.Name;
    mi.Hint := sr.Name;
    mi.Checked := sr.Name = Config.PortName;
    if mi.Checked then
      found := true;
    mi.OnClick := @mnuPortItemClick;
    mnuPort1.Add(mi);
  until FindNext(sr) <> 0;
  FindClose(sr);
  // only enable controls if port is found
  mnuCalibration1.Enabled := found;
  if not found then
    UpdateCaption('port ' + Config.PortName + ' not found!')
  else begin
    // stty
    SetSpeed(Config.PortName, Config.PortSpeed);
    // restore previous range
    case Config.Range of
      1: mnuRange1.Click;
      2: mnuRange2.Click;
      3: mnuRange3.Click;
      4: mnuRange4.Click;
    end;
  end;
end;

procedure TMain.mnuPortItemClick(Sender: TObject);
var mi: TMenuItem;
begin
  // Click on port item will choose it
  mi := TMenuItem(Sender);
  mi.Checked := true;
  Config.PortName := mi.Hint;
  UpdateCaption;
  Config.Save;
end;

procedure TMain.SetSpeed(aFile: string; aSpeed: integer);
begin
  // Setup tty and speed
  with TProcess.Create(nil) do
  try
    CommandLine := 'stty -F /dev/' + aFile + ' ispeed 115200 ospeed 115200 min 0 -icrnl -ixon -isig -opost -isig -icanon -iexten -echo -echoe -echok';
    Execute;
    if ExitCode <> 0 then
      MessageDlg('Failed to set port speed, stty exit code #' + IntToStr(ExitCode) + LineEnding + 'Command: ' + CommandLine, mtError, [mbOk], 0)
    else
      UpdateCaption('STTY OK');
  finally
    Free;
  end;
end;

procedure TMain.UpdateCaption(aMessage: string = '');
begin
  // Update caption
  Caption := 'ArduinoScope - ' + Config.PortName + '@' + IntToStr(Config.PortSpeed) + ', Range ' + IntToStr(Config.Range) + ' ' + aMessage;
end;

procedure TMain.UpdateSeries(aData: TRealList);
var i: integer;
    dt: real;
begin
  // Add data into chart series
  dt := Config.TimeStep;
  Series.BeginUpdate;
  Series.Clear;
  for i := 0 to aData.Count-1 do
    Series.AddXY(i * dt * 1000, aData[i]);
  Series.EndUpdate;
end;

procedure TMain.DebugRealList(aData: TRealList);
var i: integer;
begin
  // Add data into chart series
  Memo1.Lines.BeginUpdate;
  Memo1.Lines.Clear;
  for i := 0 to aData.Count-1 do
    Memo1.Lines.Add(IntToStr(i) + ': ' + FloatToStr(aData[i]));
  Memo1.Lines.EndUpdate;
end;

procedure TMain.DebugWordList(aData: TWordList);
var i: integer;
begin
  // Add data into chart series
  Memo1.Lines.BeginUpdate;
  Memo1.Lines.Clear;
  for i := 0 to aData.Count-1 do
    Memo1.Lines.Add(IntToStr(i) + ': ' + IntToStr(aData[i]));
  Memo1.Lines.EndUpdate;
end;

procedure TMain.Timer1Timer(Sender: TObject);
begin
  // In continuous mode keep refreshing
  if mnuDataContinuousMode1.Checked then
    if not Api5Busy then
      if not RefreshInProgress then
        if not Calibration.Visible then
          if not CalibrationTime.Visible then
          begin
            mnuDataRefresh1Click(Sender);
            Application.ProcessMessages;
          end;
end;

end.

