unit Minimap;

interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls;

type
  TForm2 = class(TForm)
    procedure updateMinimap; // Erstellen der Minimap
    procedure updateMinimapPlayer(X,Y:integer); // Position des Spielers
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

  TTeil = class(TShape) // Shapes
    private
      X: integer;
      Y: integer;
    public
      constructor create(AOwner: TComponent); override;
  end;

var
  Form2: TForm2;
  Teil: array of TTeil; // Shapes
  lastX: integer; // letzte Position
  lastY: integer;

implementation

{$R *.dfm}
uses Main;

constructor TTeil.Create(AOwner: TComponent); // Shape constructor
begin
  Inherited;
  Shape := stSquare;
  pen.style := psclear;
end;

procedure TForm2.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  canClose := false; // Form kann nicht geschlossen werden
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  // Minimap Größe & Position anpassen
  Width := Form1.Width div 6 + 10; // +10 zur Sicherheit, da gerundet wird
  Height := Width;
  Left := Form1.Width - Form2.Width - 5;
  Top := Form1.Height - Form2.Height - 5;
  updateMinimap;
  Showmessage('Um das Menü zu aktivieren oder weiter zu spielen drücke Escape');
end;

procedure TForm2.FormResize(Sender: TObject); // Erstellen der Shapes
  var
  I,X2,Y2,L,groesse: integer;
begin
  setLength(Teil,mapSize*mapSize);
  X2:=1;
  Y2:=1;
  groesse := Form1.Width div (6*mapSize);
  for I := 0 to Length(Teil)-1 do
    begin
      Teil[I] := TTeil.Create(Form1);
      with Teil[I] do
        begin
          Parent := self;
          Width := groesse;
          Height := groesse;
          Left := X2 * groesse;
          Top := Y2 * groesse;
          X := X2;
          Y := Y2;
        end;
      for L := 1 to Length(Teil)-1 do
        begin
          if I+1 = L*mapSize then // Zeilenumbruch
            begin
              X2:=0;
              inc(Y2);
            end;
        end;
      inc(X2);
    end;
end;

procedure TForm2.updateMinimap;                     // Erstellen der Minimap
var                                                 // anhand der Map
  I: integer;
begin
  for I := 0 to Length(Teil)-1 do
    begin
      Teil[I].Brush.Color := clYellow;
      case Map.Field[Teil[I].X,Teil[I].Y] of
          1: Teil[I].Brush.Color := clNavy;
          2: Teil[I].Brush.Color := clRed;
      end;
  end;
end;

procedure TForm2.updateMinimapPlayer(X,Y:Integer);  // Position des Spielers
var
  I: integer;
begin
  for I := 0 to Length(Teil)-1 do
    begin
      if (Teil[I].X = lastX) and (Teil[I].Y = lastY) and (Teil[I].Color <> clGray) then // letze Position grau färben
          Teil[I].Brush.Color := clGray;
      if (Teil[I].X = X) and (Teil[I].Y = Y) and (Teil[I].Color <> clLime) then   // aktuelle Position grün färben
          Teil[I].Brush.Color := clLime;
    end;
  lastX:=X; // letzte Position speichern
  lastY:=Y;
end;

end.
