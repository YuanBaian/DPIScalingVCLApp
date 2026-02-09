object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'DPIScalingVCLApp'
  ClientHeight = 232
  ClientWidth = 366
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Shell Dlg'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object LabelSelectDisplay: TLabel
    Left = 18
    Top = 18
    Width = 67
    Height = 13
    Caption = 'Select Display'
  end
  object LabelDisplayUniqueName: TLabel
    Left = 18
    Top = 38
    Width = 102
    Height = 13
    Caption = 'Display Unique Name'
  end
  object LabelCurrentDpi: TLabel
    Left = 18
    Top = 61
    Width = 55
    Height = 13
    Caption = 'Current DPI'
  end
  object LabelRecommendedDpi: TLabel
    Left = 18
    Top = 82
    Width = 93
    Height = 13
    Caption = 'Recommended DPI'
  end
  object LabelSelectDpi: TLabel
    Left = 18
    Top = 105
    Width = 80
    Height = 13
    Caption = 'Select DPI to set'
  end
  object LabelLog: TLabel
    Left = 20
    Top = 169
    Width = 21
    Height = 13
    Caption = 'Log:'
  end
  object ComboDisplay: TComboBox
    Left = 120
    Top = 14
    Width = 223
    Height = 21
    Sorted = True
    TabOrder = 0
    OnChange = ComboDisplayChange
  end
  object EditDisplayUniqueName: TEdit
    Left = 120
    Top = 35
    Width = 224
    Height = 21
    CharCase = ecUpperCase
    ReadOnly = True
    TabOrder = 1
  end
  object EditCurrentDpi: TEdit
    Left = 120
    Top = 58
    Width = 224
    Height = 21
    ReadOnly = True
    TabOrder = 2
  end
  object EditRecommendedDpi: TEdit
    Left = 119
    Top = 79
    Width = 226
    Height = 21
    ReadOnly = True
    TabOrder = 3
  end
  object ListDpi: TListBox
    Left = 118
    Top = 105
    Width = 226
    Height = 48
    Sorted = True
    TabOrder = 4
  end
  object ButtonApply: TButton
    Left = 234
    Top = 160
    Width = 50
    Height = 23
    Caption = 'Apply'
    TabOrder = 5
    OnClick = ButtonApplyClick
  end
  object ButtonRefresh: TButton
    Left = 294
    Top = 160
    Width = 50
    Height = 23
    Caption = 'Refresh'
    TabOrder = 6
    OnClick = ButtonRefreshClick
  end
  object MemoLog: TMemo
    Left = 19
    Top = 187
    Width = 343
    Height = 43
    ScrollBars = ssBoth
    TabOrder = 7
    WordWrap = False
  end
end
