program Pacman3D;

uses
  Forms,
  Main in 'Main.pas' {Form1},
  Einstellungen in 'Einstellungen.pas' {Einstellungen},
  SplashScreen in 'SplashScreen.pas' {SplashScreen2},
  Minimap in 'Minimap.pas' {Form2};

{$R *.res}

begin
  SplashScreen2 := TSplashScreen2.Create(Application);
  try
    SplashScreen2.Show;
    SplashScreen2.Refresh;
    Application.Initialize;
    Application.Title := 'Pacman 3D';
    Application.CreateForm(TForm1, Form1);
    Application.CreateForm(TEinstellungenForm, EinstellungenForm);
    Application.CreateForm(TForm2, Form2);
  finally
    SplashScreen2.InitializationDone := True;
  end;
  Application.Run;
end.
