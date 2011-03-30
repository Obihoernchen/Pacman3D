unit Einstellungen;

interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Controls, Forms,
  Dialogs, StdCtrls, dglOpenGL, ComCtrls, BASS;

type
  TEinstellungenForm = class(TForm)
    Edit1: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    ComboBox1: TComboBox;
    Label3: TLabel;
    Edit2: TEdit;
    CheckBox1: TCheckBox;
    TrackBar1: TTrackBar;
    Label5: TLabel;
    procedure Edit1Change(Sender: TObject);
    procedure Edit1KeyPress(Sender: TObject; var Key: Char);
    procedure FormCreate(Sender: TObject);
    procedure ComboBox1Select(Sender: TObject);
    procedure Edit2KeyPress(Sender: TObject; var Key: Char);
    procedure CheckBox1Click(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  EinstellungenForm: TEinstellungenForm;
  Mausempf: single;

implementation

uses Main;

{$R *.dfm}

procedure TEinstellungenForm.CheckBox1Click(Sender: TObject); // Schatten
begin
  if Checkbox1.checked = true then
    glEnable(GL_FOG)
  else
    glDisable(GL_FOG);
end;

procedure TEinstellungenForm.ComboBox1Select(Sender: TObject); // Grafikqualität
begin
  Main.quali := ComboBox1.ItemIndex + 1;
  Main.Form1.createlistEnviroment;    // Displaylisten neu erstellen
  Main.Form1.createlistBlock;
end;

procedure TEinstellungenForm.Edit1Change(Sender: TObject); // Mausempfindlichkeit setzen
begin
  if Edit1.Text <> '' then
    Mausempf := strtofloat(Edit1.Text) / 50;
end;

procedure TEinstellungenForm.Edit1KeyPress(Sender: TObject; var Key: Char);
begin
  if not CharInSet(Key,['0' .. '9', #8, #46]) then // Nur Zahlen erlauben
    Key := #0;
end;

procedure TEinstellungenForm.Edit2KeyPress(Sender: TObject; var Key: Char);
begin
  if not CharInSet(Key,['0' .. '9', #8, #46]) then // Nur Zahlen erlauben
    Key := #0;
end;

procedure TEinstellungenForm.FormCreate(Sender: TObject);
begin
  Mausempf := strtofloat(Edit1.Text) / 50; // Mausempfindlichkeit festlegen
  ComboBox1.ItemIndex := 1;
end;

procedure TEinstellungenForm.TrackBar1Change(Sender: TObject);  // Lautstärke ändern
begin
  BASS_ChannelSetAttribute(backgroundSound, BASS_ATTRIB_VOL, EinstellungenForm.TrackBar1.Position / 100);
  BASS_ChannelSetAttribute(pilleSound, BASS_ATTRIB_VOL, EinstellungenForm.TrackBar1.Position / 100);
  BASS_ChannelSetAttribute(ghostSound, BASS_ATTRIB_VOL, EinstellungenForm.TrackBar1.Position / 100);
  BASS_ChannelSetAttribute(gunSound, BASS_ATTRIB_VOL, EinstellungenForm.TrackBar1.Position / 100);
end;

end.
