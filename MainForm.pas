unit MainForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  DpiHelper;

type
  HCRYPTPROV = ULONG_PTR;
  PHCRYPTPROV = ^HCRYPTPROV;
  HCRYPTHASH = ULONG_PTR;
  PHCRYPTHASH = ^HCRYPTHASH;
  HCRYPTKEY = ULONG_PTR;

  TDisplayData = record
    AdapterId: LUID;
    SourceId: Cardinal;
    TargetId: Cardinal;
  end;

  TDisplayDataObj = class(TObject)
  public
    Data: TDisplayData;
  end;

  TMainForm = class(TForm)
    ComboDisplay: TComboBox;
    LabelSelectDisplay: TLabel;
    EditCurrentDpi: TEdit;
    LabelCurrentDpi: TLabel;
    EditRecommendedDpi: TEdit;
    LabelRecommendedDpi: TLabel;
    LabelSelectDpi: TLabel;
    ListDpi: TListBox;
    ButtonApply: TButton;
    MemoLog: TMemo;
    LabelLog: TLabel;
    ButtonRefresh: TButton;
    EditDisplayUniqueName: TEdit;
    LabelDisplayUniqueName: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ComboDisplayChange(Sender: TObject);
    procedure ButtonRefreshClick(Sender: TObject);
    procedure ButtonApplyClick(Sender: TObject);
  private
    procedure Log(const Msg: string);
    procedure ClearDisplayList;
    function FillDisplayInfo(const Data: TDisplayData): Boolean;
    function RefreshDisplays: Boolean;
    function GetDisplayUniqueString(const AdapterId: LUID; TargetId: Cardinal): string;
    function GetHashTextAscii(const S: string): string;
  public
  end;

var
  MainFormInstance: TMainForm;

const
  PROV_RSA_AES = 24;
  CRYPT_VERIFYCONTEXT = $F0000000;
  CALG_MD5 = $00008003;
  HP_HASHVAL = $0002;
  HP_HASHSIZE = $0004;

function CryptAcquireContextW(phProv: PHCRYPTPROV; pszContainer: PWideChar; pszProvider: PWideChar;
  dwProvType: DWORD; dwFlags: DWORD): BOOL; stdcall; external 'advapi32.dll' name 'CryptAcquireContextW';
function CryptReleaseContext(hProv: HCRYPTPROV; dwFlags: DWORD): BOOL; stdcall; external 'advapi32.dll' name 'CryptReleaseContext';
function CryptCreateHash(hProv: HCRYPTPROV; Algid: DWORD; hKey: HCRYPTKEY; dwFlags: DWORD; phHash: PHCRYPTHASH): BOOL; stdcall; external 'advapi32.dll' name 'CryptCreateHash';
function CryptDestroyHash(hHash: HCRYPTHASH): BOOL; stdcall; external 'advapi32.dll' name 'CryptDestroyHash';
function CryptHashData(hHash: HCRYPTHASH; pbData: PBYTE; dwDataLen: DWORD; dwFlags: DWORD): BOOL; stdcall; external 'advapi32.dll' name 'CryptHashData';
function CryptGetHashParam(hHash: HCRYPTHASH; dwParam: DWORD; pbData: PBYTE; var pdwDataLen: DWORD; dwFlags: DWORD): BOOL; stdcall; external 'advapi32.dll' name 'CryptGetHashParam';

implementation

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RefreshDisplays;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  ClearDisplayList;
end;

procedure TMainForm.Log(const Msg: string);
begin
  MemoLog.Lines.BeginUpdate;
  try
    MemoLog.Lines.Add(Msg);
    MemoLog.SelStart := Length(MemoLog.Text);
    MemoLog.Perform(EM_SCROLLCARET, 0, 0);
  finally
    MemoLog.Lines.EndUpdate;
  end;
end;

procedure TMainForm.ClearDisplayList;
var
  I: Integer;
begin
  for I := 0 to ComboDisplay.Items.Count - 1 do
    ComboDisplay.Items.Objects[I].Free;
  ComboDisplay.Items.Clear;
end;

function TMainForm.GetHashTextAscii(const S: string): string;
var
  DataBytes: TBytes;
  HashBytes: TBytes;
  HashSize: DWORD;
  HashSizeLen: DWORD;
  HProv: HCRYPTPROV;
  HHash: HCRYPTHASH;
  I: Integer;
begin
  Result := '';
  HProv := 0;
  HHash := 0;
  DataBytes := TEncoding.ASCII.GetBytes(S);

  if not CryptAcquireContextW(@HProv, nil, nil, PROV_RSA_AES, CRYPT_VERIFYCONTEXT) then
    Exit;
  try
    if not CryptCreateHash(HProv, CALG_MD5, 0, 0, @HHash) then
      Exit;
    try
      if Length(DataBytes) > 0 then
      begin
        if not CryptHashData(HHash, @DataBytes[0], Length(DataBytes), 0) then
          Exit;
      end
      else
      begin
        if not CryptHashData(HHash, nil, 0, 0) then
          Exit;
      end;

      HashSize := 0;
      HashSizeLen := SizeOf(HashSize);
      if not CryptGetHashParam(HHash, HP_HASHSIZE, @HashSize, HashSizeLen, 0) then
        Exit;

      SetLength(HashBytes, HashSize);
      if (HashSize > 0) then
      begin
        if not CryptGetHashParam(HHash, HP_HASHVAL, @HashBytes[0], HashSize, 0) then
          Exit;
      end;

      for I := 0 to Length(HashBytes) - 1 do
        Result := Result + IntToHex(HashBytes[I], 2);
    finally
      CryptDestroyHash(HHash);
    end;
  finally
    CryptReleaseContext(HProv, 0);
  end;
end;

function TMainForm.GetDisplayUniqueString(const AdapterId: LUID; TargetId: Cardinal): string;
var
  UniqueName: string;
  Hash: string;
begin
  UniqueName := TDpiHelper.GetDisplayUniqueName(AdapterId, TargetId);
  if UniqueName = '' then
    Exit('');

  Hash := GetHashTextAscii(UniqueName);
  if Length(Hash) = 32 then
    Result := UniqueName + '^' + Hash
  else
    Result := UniqueName;

  Result := UpperCase(Result);
end;

function TMainForm.FillDisplayInfo(const Data: TDisplayData): Boolean;
var
  DpiInfo: TDPIScalingInfo;
  UniqueString: string;
  ValueStr: string;
  CurrentIndex: Integer;
  DpiValue: Cardinal;
begin
  Result := False;
  DpiInfo := TDpiHelper.GetDPIScalingInfo(Data.AdapterId, Data.SourceId);

  if Data.TargetId <> 0 then
  begin
    UniqueString := GetDisplayUniqueString(Data.AdapterId, Data.TargetId);
    EditDisplayUniqueName.Text := UniqueString;
  end
  else
  begin
    EditDisplayUniqueName.Text := '';
    Log('Debug! Not fetching display unique name as target ID is 0');
  end;

  EditCurrentDpi.Text := IntToStr(DpiInfo.Current);
  EditRecommendedDpi.Text := IntToStr(DpiInfo.Recommended);

  ListDpi.Items.BeginUpdate;
  try
    ListDpi.Items.Clear;
    for DpiValue in DpiVals do
    begin
      if (DpiValue >= DpiInfo.Minimum) and (DpiValue <= DpiInfo.Maximum) then
        ListDpi.Items.Add(IntToStr(DpiValue));
    end;
  finally
    ListDpi.Items.EndUpdate;
  end;

  ValueStr := IntToStr(DpiInfo.Current);
  CurrentIndex := ListDpi.Items.IndexOf(ValueStr);
  if CurrentIndex < 0 then
  begin
    Log('Error! Could not find currently set DPI');
    Exit(False);
  end;

  ListDpi.ItemIndex := CurrentIndex;
  Result := True;
end;

function TMainForm.RefreshDisplays: Boolean;
var
  Paths: TArray<DISPLAYCONFIG_PATH_INFO>;
  Modes: TArray<DISPLAYCONFIG_MODE_INFO>;
  Flags: UINT32;
  Path: DISPLAYCONFIG_PATH_INFO;
  DeviceName: TDisplayConfigTargetDeviceName;
  Res: Longint;
  Index: Integer;
  NameString: string;
  DataObj: TDisplayDataObj;
  FriendlyName: string;
begin
  ClearDisplayList;

  Flags := QDC_ONLY_ACTIVE_PATHS;
  if not TDpiHelper.GetPathsAndModes(Paths, Modes, Flags) then
    Log('DpiHelper::GetPathsAndModes() failed')
  else
    Log('DpiHelper::GetPathsAndModes() successful');

  Index := 0;
  for Path in Paths do
  begin
    FillChar(DeviceName, SizeOf(DeviceName), 0);
    DeviceName.Header.Size := SizeOf(DeviceName);
    DeviceName.Header.Type_ := DISPLAYCONFIG_DEVICE_INFO_GET_TARGET_NAME;
    DeviceName.Header.AdapterId := Path.targetInfo.adapterId;
    DeviceName.Header.Id := Path.targetInfo.id;

    Res := DisplayConfigGetDeviceInfoRaw(@DeviceName);
    if Res <> ERROR_SUCCESS then
    begin
      Log('DisplayConfigGetDeviceInfo() failed');
      Continue;
    end;

    FriendlyName := string(PWideChar(@DeviceName.MonitorFriendlyDeviceName[0]));
    Log('display name obtained: ' + FriendlyName);
    NameString := Format('%d. %s', [Index, FriendlyName]);
    if DeviceName.OutputTechnology = DISPLAYCONFIG_OUTPUT_TECHNOLOGY_INTERNAL then
      NameString := NameString + ' (internal display)';

    DataObj := TDisplayDataObj.Create;
    DataObj.Data.AdapterId := Path.targetInfo.adapterId;
    DataObj.Data.SourceId := Path.sourceInfo.id;
    DataObj.Data.TargetId := Path.targetInfo.id;

    ComboDisplay.Items.AddObject(NameString, DataObj);
    Inc(Index);
  end;

  if ComboDisplay.Items.Count = 0 then
  begin
    Log('no displays found!!');
  end
  else
  begin
    ComboDisplay.ItemIndex := 0;
    FillDisplayInfo(TDisplayDataObj(ComboDisplay.Items.Objects[0]).Data);
  end;

  Result := True;
end;

procedure TMainForm.ComboDisplayChange(Sender: TObject);
var
  Obj: TDisplayDataObj;
  Index: Integer;
begin
  Index := ComboDisplay.ItemIndex;
  if Index < 0 then
    Exit;

  Obj := TDisplayDataObj(ComboDisplay.Items.Objects[Index]);
  if Obj = nil then
  begin
    Log('m_displayDataCache cache hit failed');
    Exit;
  end;

  FillDisplayInfo(Obj.Data);
end;

procedure TMainForm.ButtonRefreshClick(Sender: TObject);
begin
  RefreshDisplays;
end;

procedure TMainForm.ButtonApplyClick(Sender: TObject);
var
  CurrSel: Integer;
  DpiToSet: Integer;
  CurrentDpiVal: Integer;
  Obj: TDisplayDataObj;
begin
  CurrSel := ListDpi.ItemIndex;
  if CurrSel < 0 then
    Exit;

  DpiToSet := StrToIntDef(ListDpi.Items[CurrSel], 0);
  CurrentDpiVal := StrToIntDef(EditCurrentDpi.Text, 0);

  if DpiToSet = CurrentDpiVal then
  begin
    Log('Trying to set DPI which is already set. Nothing to do');
    Exit;
  end;

  CurrSel := ComboDisplay.ItemIndex;
  if CurrSel < 0 then
  begin
    Log('Cache miss');
    Exit;
  end;

  Obj := TDisplayDataObj(ComboDisplay.Items.Objects[CurrSel]);
  if Obj = nil then
  begin
    Log('Cache miss');
    Exit;
  end;

  if not TDpiHelper.SetDPIScaling(Obj.Data.AdapterId, Obj.Data.SourceId, DpiToSet) then
  begin
    Log('DpiHelper::SetDPIScaling() failed');
    Exit;
  end;

  RefreshDisplays;
end;

end.
