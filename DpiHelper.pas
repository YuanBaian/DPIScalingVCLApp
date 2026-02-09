unit DpiHelper;

{$A4}

interface

uses
  System.SysUtils,
  Winapi.Windows;

const
  DpiVals: array[0..11] of Cardinal = (100, 125, 150, 175, 200, 225, 250, 300, 350, 400, 450, 500);

  QDC_ONLY_ACTIVE_PATHS = $00000002;

  DISPLAYCONFIG_DEVICE_INFO_GET_TARGET_NAME = 2;
  DISPLAYCONFIG_DEVICE_INFO_GET_DPI_SCALE = -3;
  DISPLAYCONFIG_DEVICE_INFO_SET_DPI_SCALE = -4;
  DISPLAYCONFIG_DEVICE_INFO_GET_MONITOR_BRIGHTNESS_INFO = -7;
  DISPLAYCONFIG_DEVICE_INFO_GET_MONITOR_INTERNAL_INFO = DISPLAYCONFIG_DEVICE_INFO_GET_MONITOR_BRIGHTNESS_INFO;
  DISPLAYCONFIG_DEVICE_INFO_GET_MONITOR_UNIQUE_NAME = DISPLAYCONFIG_DEVICE_INFO_GET_MONITOR_INTERNAL_INFO;

  DISPLAYCONFIG_OUTPUT_TECHNOLOGY_INTERNAL = $80000000;

type
  TPointL = record
    X: Longint;
    Y: Longint;
  end;

  DISPLAYCONFIG_RATIONAL = record
    Numerator: UINT32;
    Denominator: UINT32;
  end;

  DISPLAYCONFIG_2DREGION = record
    cx: UINT32;
    cy: UINT32;
  end;

  DISPLAYCONFIG_PATH_SOURCE_INFO = record
    AdapterId: LUID;
    Id: UINT32;
    ModeInfoIdx: UINT32;
    StatusFlags: UINT32;
  end;

  DISPLAYCONFIG_PATH_TARGET_INFO = record
    AdapterId: LUID;
    Id: UINT32;
    ModeInfoIdx: UINT32;
    OutputTechnology: UINT32;
    Rotation: UINT32;
    Scaling: UINT32;
    RefreshRate: DISPLAYCONFIG_RATIONAL;
    ScanLineOrdering: UINT32;
    TargetAvailable: BOOL;
    StatusFlags: UINT32;
  end;

  DISPLAYCONFIG_PATH_INFO = record
    SourceInfo: DISPLAYCONFIG_PATH_SOURCE_INFO;
    TargetInfo: DISPLAYCONFIG_PATH_TARGET_INFO;
    Flags: UINT32;
  end;
  PDISPLAYCONFIG_PATH_INFO = ^DISPLAYCONFIG_PATH_INFO;

  DISPLAYCONFIG_VIDEO_SIGNAL_INFO = record
    PixelRate: UInt64;
    HSyncFreq: DISPLAYCONFIG_RATIONAL;
    VSyncFreq: DISPLAYCONFIG_RATIONAL;
    ActiveSize: DISPLAYCONFIG_2DREGION;
    TotalSize: DISPLAYCONFIG_2DREGION;
    VideoStandard: UINT32;
    ScanLineOrdering: UINT32;
  end;

  DISPLAYCONFIG_TARGET_MODE = record
    TargetVideoSignalInfo: DISPLAYCONFIG_VIDEO_SIGNAL_INFO;
  end;

  DISPLAYCONFIG_SOURCE_MODE = record
    Width: UINT32;
    Height: UINT32;
    PixelFormat: UINT32;
    Position: TPointL;
  end;

  DISPLAYCONFIG_MODE_INFO_UNION = record
    case Integer of
      0: (TargetMode: DISPLAYCONFIG_TARGET_MODE);
      1: (SourceMode: DISPLAYCONFIG_SOURCE_MODE);
  end;

  DISPLAYCONFIG_MODE_INFO = record
    InfoType: UINT32;
    Id: UINT32;
    AdapterId: LUID;
    Mode: DISPLAYCONFIG_MODE_INFO_UNION;
  end;
  PDISPLAYCONFIG_MODE_INFO = ^DISPLAYCONFIG_MODE_INFO;

  TDisplayConfigDeviceInfoHeaderEx = record
    Type_: Integer;
    Size: UINT32;
    AdapterId: LUID;
    Id: UINT32;
  end;

  TDisplayConfigSourceDpiScaleGet = record
    Header: TDisplayConfigDeviceInfoHeaderEx;
    MinScaleRel: Integer;
    CurScaleRel: Integer;
    MaxScaleRel: Integer;
  end;

  TDisplayConfigSourceDpiScaleSet = record
    Header: TDisplayConfigDeviceInfoHeaderEx;
    ScaleRel: Integer;
  end;

  TDisplayConfigTargetDeviceName = record
    Header: TDisplayConfigDeviceInfoHeaderEx;
    Flags: DWORD;
    OutputTechnology: DWORD;
    EdidManufactureId: Word;
    EdidProductCodeId: Word;
    ConnectorInstance: DWORD;
    MonitorFriendlyDeviceName: array[0..63] of WideChar;
    MonitorDevicePath: array[0..127] of WideChar;
  end;

  TDisplayConfigBrightnessNitRange = record
    MinMillinits: Cardinal;
    MaxMillinits: Cardinal;
    StepSizeMillinits: Cardinal;
  end;

  TDisplayConfigBrightnessCaps = record
    LegacyLevels: array[0..100] of Byte;
    LegacyLevelCount: Cardinal;
    NitRanges: array[0..15] of TDisplayConfigBrightnessNitRange;
    NormalRangeCount: Cardinal;
    TotalRangeCount: Cardinal;
    PreferredMaximumBrightness: Cardinal;
    Flags: Cardinal;
  end;

  TDisplayConfigGetMonitorInternalInfo = record
    Header: TDisplayConfigDeviceInfoHeaderEx;
    MonitorUniqueName: array[0..259] of WideChar;
    RedPrimary: array[0..1] of Cardinal;
    GreenPrimary: array[0..1] of Cardinal;
    BluePrimary: array[0..1] of Cardinal;
    WhitePoint: array[0..1] of Cardinal;
    MinLuminance: Cardinal;
    MaxLuminance: Cardinal;
    MaxFullFrameLuminance: Cardinal;
    ColorspaceSupport: Integer;
    Flags: Integer;
    BrightnessCaps: TDisplayConfigBrightnessCaps;
    UsageSubClass: Cardinal;
    DisplayTech: Cardinal;
    NativeWidth: Cardinal;
    NativeHeight: Cardinal;
    PhysicalWidthInMm: Cardinal;
    PhysicalHeightInMm: Cardinal;
    DockedOrientation: Cardinal;
    DisplayHdrCertifications: Cardinal;
  end;

  TDPIScalingInfo = record
    Minimum: Cardinal;
    Maximum: Cardinal;
    Current: Cardinal;
    Recommended: Cardinal;
    InitDone: Boolean;
  end;

  TDpiHelper = class
  public
    class function GetPathsAndModes(out Paths: TArray<DISPLAYCONFIG_PATH_INFO>;
      out Modes: TArray<DISPLAYCONFIG_MODE_INFO>; Flags: UINT32 = QDC_ONLY_ACTIVE_PATHS): Boolean; static;
    class function GetDisplayUniqueName(AdapterId: LUID; TargetId: UINT32): string; static;
    class function GetDPIScalingInfo(AdapterId: LUID; SourceId: UINT32): TDPIScalingInfo; static;
    class function SetDPIScaling(AdapterId: LUID; SourceId: UINT32; DpiPercentToSet: UINT32): Boolean; static;
  end;

function DisplayConfigGetDeviceInfoRaw(RequestPacket: Pointer): Longint; stdcall;
function DisplayConfigSetDeviceInfoRaw(RequestPacket: Pointer): Longint; stdcall;
function GetDisplayConfigBufferSizes(Flags: UINT32; out NumPaths: UINT32; out NumModes: UINT32): Longint; stdcall;
function QueryDisplayConfig(Flags: UINT32; var NumPaths: UINT32; Paths: PDISPLAYCONFIG_PATH_INFO;
  var NumModes: UINT32; Modes: PDISPLAYCONFIG_MODE_INFO; CurrentTopologyId: Pointer): Longint; stdcall;

implementation

function DisplayConfigGetDeviceInfoRaw(RequestPacket: Pointer): Longint; stdcall; external 'user32.dll' name 'DisplayConfigGetDeviceInfo';
function DisplayConfigSetDeviceInfoRaw(RequestPacket: Pointer): Longint; stdcall; external 'user32.dll' name 'DisplayConfigSetDeviceInfo';
function GetDisplayConfigBufferSizes(Flags: UINT32; out NumPaths: UINT32; out NumModes: UINT32): Longint; stdcall; external 'user32.dll' name 'GetDisplayConfigBufferSizes';
function QueryDisplayConfig(Flags: UINT32; var NumPaths: UINT32; Paths: PDISPLAYCONFIG_PATH_INFO;
  var NumModes: UINT32; Modes: PDISPLAYCONFIG_MODE_INFO; CurrentTopologyId: Pointer): Longint; stdcall; external 'user32.dll' name 'QueryDisplayConfig';

class function TDpiHelper.GetPathsAndModes(out Paths: TArray<DISPLAYCONFIG_PATH_INFO>;
  out Modes: TArray<DISPLAYCONFIG_MODE_INFO>; Flags: UINT32): Boolean;
var
  NumPaths: UINT32;
  NumModes: UINT32;
  Status: Longint;
  PathsPtr: PDISPLAYCONFIG_PATH_INFO;
  ModesPtr: PDISPLAYCONFIG_MODE_INFO;
begin
  SetLength(Paths, 0);
  SetLength(Modes, 0);

  NumPaths := 0;
  NumModes := 0;
  Status := GetDisplayConfigBufferSizes(Flags, NumPaths, NumModes);
  if Status <> ERROR_SUCCESS then
    Exit(False);

  if (NumPaths = 0) and (NumModes = 0) then
    Exit(True);

  SetLength(Paths, NumPaths);
  SetLength(Modes, NumModes);
  if NumPaths > 0 then
    PathsPtr := @Paths[0]
  else
    PathsPtr := nil;
  if NumModes > 0 then
    ModesPtr := @Modes[0]
  else
    ModesPtr := nil;

  Status := QueryDisplayConfig(Flags, NumPaths, PathsPtr, NumModes, ModesPtr, nil);
  if Status <> ERROR_SUCCESS then
    Exit(False);

  SetLength(Paths, NumPaths);
  SetLength(Modes, NumModes);
  Result := True;
end;

class function TDpiHelper.GetDisplayUniqueName(AdapterId: LUID; TargetId: UINT32): string;
var
  Info: TDisplayConfigGetMonitorInternalInfo;
  Res: Longint;
begin
  FillChar(Info, SizeOf(Info), 0);
  Info.Header.AdapterId := AdapterId;
  Info.Header.Id := TargetId;
  Info.Header.Size := SizeOf(Info);
  Info.Header.Type_ := DISPLAYCONFIG_DEVICE_INFO_GET_MONITOR_UNIQUE_NAME;

  Res := DisplayConfigGetDeviceInfoRaw(@Info);
  if Res = ERROR_SUCCESS then
    Result := string(PWideChar(@Info.MonitorUniqueName[0]))
  else
    Result := '';
end;

class function TDpiHelper.GetDPIScalingInfo(AdapterId: LUID; SourceId: UINT32): TDPIScalingInfo;
var
  RequestPacket: TDisplayConfigSourceDpiScaleGet;
  Res: Longint;
  MinAbs: Integer;
  MaxIndex: Integer;
  CurrentIndex: Integer;
begin
  Result.Minimum := 100;
  Result.Maximum := 100;
  Result.Current := 100;
  Result.Recommended := 100;
  Result.InitDone := False;

  FillChar(RequestPacket, SizeOf(RequestPacket), 0);
  RequestPacket.Header.Type_ := DISPLAYCONFIG_DEVICE_INFO_GET_DPI_SCALE;
  RequestPacket.Header.Size := SizeOf(RequestPacket);
  RequestPacket.Header.AdapterId := AdapterId;
  RequestPacket.Header.Id := SourceId;

  Res := DisplayConfigGetDeviceInfoRaw(@RequestPacket);
  if Res <> ERROR_SUCCESS then
    Exit;

  if RequestPacket.CurScaleRel < RequestPacket.MinScaleRel then
    RequestPacket.CurScaleRel := RequestPacket.MinScaleRel
  else if RequestPacket.CurScaleRel > RequestPacket.MaxScaleRel then
    RequestPacket.CurScaleRel := RequestPacket.MaxScaleRel;

  MinAbs := Abs(RequestPacket.MinScaleRel);
  MaxIndex := MinAbs + RequestPacket.MaxScaleRel;
  if MaxIndex < 0 then
    Exit;

  if (MaxIndex + 1) <= Length(DpiVals) then
  begin
    CurrentIndex := MinAbs + RequestPacket.CurScaleRel;
    if (CurrentIndex >= 0) and (CurrentIndex < Length(DpiVals)) then
    begin
      Result.Current := DpiVals[CurrentIndex];
      Result.Recommended := DpiVals[MinAbs];
      Result.Maximum := DpiVals[MaxIndex];
      Result.InitDone := True;
    end;
  end;
end;

class function TDpiHelper.SetDPIScaling(AdapterId: LUID; SourceId: UINT32;
  DpiPercentToSet: UINT32): Boolean;
var
  DpiInfo: TDPIScalingInfo;
  IdxSet: Integer;
  IdxRec: Integer;
  I: Integer;
  DpiRelativeVal: Integer;
  SetPacket: TDisplayConfigSourceDpiScaleSet;
  Res: Longint;
begin
  Result := False;
  DpiInfo := GetDPIScalingInfo(AdapterId, SourceId);

  if DpiPercentToSet = DpiInfo.Current then
    Exit(True);

  if DpiPercentToSet < DpiInfo.Minimum then
    DpiPercentToSet := DpiInfo.Minimum
  else if DpiPercentToSet > DpiInfo.Maximum then
    DpiPercentToSet := DpiInfo.Maximum;

  IdxSet := -1;
  IdxRec := -1;
  for I := Low(DpiVals) to High(DpiVals) do
  begin
    if DpiVals[I] = DpiPercentToSet then
      IdxSet := I;
    if DpiVals[I] = DpiInfo.Recommended then
      IdxRec := I;
  end;

  if (IdxSet = -1) or (IdxRec = -1) then
    Exit(False);

  DpiRelativeVal := IdxSet - IdxRec;

  FillChar(SetPacket, SizeOf(SetPacket), 0);
  SetPacket.Header.AdapterId := AdapterId;
  SetPacket.Header.Id := SourceId;
  SetPacket.Header.Size := SizeOf(SetPacket);
  SetPacket.Header.Type_ := DISPLAYCONFIG_DEVICE_INFO_SET_DPI_SCALE;
  SetPacket.ScaleRel := DpiRelativeVal;

  Res := DisplayConfigSetDeviceInfoRaw(@SetPacket);
  Result := (Res = ERROR_SUCCESS);
end;

end.
