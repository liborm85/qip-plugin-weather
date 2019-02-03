object frmColors: TfrmColors
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Colors'
  ClientHeight = 294
  ClientWidth = 230
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pnlButtons: TPanel
    Left = 0
    Top = 253
    Width = 230
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnApply: TBitBtn
      Left = 61
      Top = 8
      Width = 97
      Height = 25
      Caption = 'Apply'
      DoubleBuffered = True
      ParentDoubleBuffered = False
      TabOrder = 0
      OnClick = btnApplyClick
    end
  end
  object lstColors: TListBox
    Left = 0
    Top = 0
    Width = 230
    Height = 253
    Style = lbOwnerDrawFixed
    Align = alClient
    ItemHeight = 32
    TabOrder = 0
    OnDblClick = lstColorsDblClick
    OnDrawItem = lstColorsDrawItem
    ExplicitLeft = 112
    ExplicitTop = -6
    ExplicitHeight = 255
  end
  object ColorDialog1: TColorDialog
    Left = 8
    Top = 8
  end
end