object EinstellungenForm: TEinstellungenForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Einstellungen'
  ClientHeight = 231
  ClientWidth = 298
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 82
    Height = 13
    Caption = 'Mouse sensitivity'
  end
  object Label2: TLabel
    Left = 8
    Top = 43
    Width = 71
    Height = 13
    Caption = 'Graphic quality'
  end
  object Label3: TLabel
    Left = 8
    Top = 80
    Width = 121
    Height = 26
    Caption = 'Max Frames per Second            (Gamespeed)'
    WordWrap = True
  end
  object Label5: TLabel
    Left = 8
    Top = 122
    Width = 34
    Height = 13
    Caption = 'Volume'
  end
  object Edit1: TEdit
    Left = 169
    Top = 5
    Width = 121
    Height = 21
    Alignment = taRightJustify
    TabOrder = 0
    Text = '3'
    OnChange = Edit1Change
    OnKeyPress = Edit1KeyPress
  end
  object ComboBox1: TComboBox
    Left = 169
    Top = 40
    Width = 121
    Height = 21
    Style = csDropDownList
    TabOrder = 1
    OnSelect = ComboBox1Select
    Items.Strings = (
      'Low'
      'Medium'
      'High'
      'Ultra')
  end
  object Edit2: TEdit
    Left = 169
    Top = 77
    Width = 121
    Height = 21
    Alignment = taRightJustify
    BiDiMode = bdLeftToRight
    MaxLength = 4
    ParentBiDiMode = False
    TabOrder = 2
    Text = '100'
    OnKeyPress = Edit2KeyPress
  end
  object CheckBox1: TCheckBox
    Left = 177
    Top = 159
    Width = 97
    Height = 17
    Caption = 'Schatten'
    Checked = True
    State = cbChecked
    TabOrder = 3
    OnClick = CheckBox1Click
  end
  object TrackBar1: TTrackBar
    Left = 169
    Top = 122
    Width = 121
    Height = 23
    Max = 100
    Position = 100
    TabOrder = 4
    TickMarks = tmBoth
    TickStyle = tsNone
    OnChange = TrackBar1Change
  end
end
