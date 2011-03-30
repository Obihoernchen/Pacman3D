unit SplashScreen;
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,
  pngimage,
  ExtCtrls;

type
  TSplashScreen2 = class(TForm)
    Image1: TImage;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private-Deklarationen }
    FInitializationDone: Boolean;
    procedure SetInitializationDone(const Value: Boolean);
    procedure FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
  public
    { Public-Deklarationen }
     property InitializationDone: Boolean read FInitializationDone write SetInitializationDone;
  end;
var
  SplashScreen2: TSplashScreen2;

implementation

{$R *.dfm}

procedure TSplashScreen2.SetInitializationDone(const Value: Boolean);
begin
  FInitializationDone := Value;
  Close;
end;

procedure TSplashScreen2.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;       // Ressourcen wieder freigeben
  Splashscreen2 := nil;
end;

procedure TSplashScreen2.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  CanClose := FInitializationDone;  // Kann erst geschlossen werden wenn Initialisierung abgeschlossen wurde
end;

end.
