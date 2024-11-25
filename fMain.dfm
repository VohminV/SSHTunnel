object f_Main: Tf_Main
  Left = 0
  Top = 0
  AutoSize = True
  Caption = 'SSHTunnel'
  ClientHeight = 265
  ClientWidth = 675
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 8
    Top = 0
    Width = 361
    Height = 105
    Caption = ' '#1055#1086#1083#1100#1079#1086#1074#1072#1090#1077#1083#1100' '
    TabOrder = 0
    object Label1: TLabel
      Left = 23
      Top = 32
      Width = 34
      Height = 13
      Caption = #1051#1086#1075#1080#1085':'
    end
    object Label2: TLabel
      Left = 16
      Top = 59
      Width = 41
      Height = 13
      Caption = #1055#1072#1088#1086#1083#1100':'
    end
    object EditLogin: TEdit
      Left = 63
      Top = 29
      Width = 228
      Height = 21
      TabOrder = 0
    end
    object EditPassword: TEdit
      Left = 63
      Top = 56
      Width = 228
      Height = 21
      TabOrder = 1
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 232
    Width = 675
    Height = 33
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object bStart: TButton
      Left = 510
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Start'
      TabOrder = 0
      OnClick = bStartClick
    end
    object bStop: TButton
      Left = 591
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Stop'
      TabOrder = 1
      OnClick = bStopClick
    end
  end
  object GroupBox2: TGroupBox
    Left = 8
    Top = 111
    Width = 361
    Height = 105
    Caption = ' '#1057#1077#1088#1074#1077#1088' '
    TabOrder = 2
    object Label3: TLabel
      Left = 23
      Top = 32
      Width = 57
      Height = 13
      Caption = #1040#1076#1088#1077#1089' SSH:'
    end
    object Label4: TLabel
      Left = 51
      Top = 59
      Width = 29
      Height = 13
      Caption = #1055#1086#1088#1090':'
    end
    object EditAdres: TEdit
      Left = 87
      Top = 29
      Width = 228
      Height = 21
      TabOrder = 0
    end
    object EditPort: TEdit
      Left = 87
      Top = 56
      Width = 108
      Height = 21
      TabOrder = 1
    end
  end
  object GroupBox3: TGroupBox
    Left = 375
    Top = 0
    Width = 298
    Height = 105
    Caption = ' '#1055#1077#1088#1077#1085#1072#1087#1088#1072#1074#1083#1077#1085#1080#1077' '#1087#1086#1088#1090#1086#1074
    TabOrder = 3
    object Label5: TLabel
      Left = 23
      Top = 32
      Width = 88
      Height = 13
      Caption = #1051#1086#1082#1072#1083#1100#1085#1099#1081' '#1087#1086#1088#1090':'
    end
    object Label6: TLabel
      Left = 23
      Top = 59
      Width = 89
      Height = 13
      Caption = #1059#1076#1072#1083#1077#1085#1085#1099#1081' '#1087#1086#1088#1090':'
    end
    object EditLocalPort: TEdit
      Left = 117
      Top = 29
      Width = 174
      Height = 21
      TabOrder = 0
    end
    object EditRemotePort: TEdit
      Left = 117
      Top = 56
      Width = 174
      Height = 21
      TabOrder = 1
    end
  end
  object TrayIcon: TTrayIcon
    PopupMenu = PopupMenu
    OnClick = TrayIconClick
    Left = 480
    Top = 176
  end
  object PopupMenu: TPopupMenu
    Left = 408
    Top = 192
    object Open: TMenuItem
      Caption = #1054#1090#1082#1088#1099#1090#1100
      OnClick = OpenClick
    end
    object Exit: TMenuItem
      Caption = #1047#1072#1082#1088#1099#1090#1100
      OnClick = ExitClick
    end
  end
  object Timer: TTimer
    OnTimer = TimerTimer
    Left = 312
    Top = 104
  end
end
