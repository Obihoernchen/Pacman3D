unit Main;
 //########################################
 //#------------- Pacman 3D --------------#
 //#--------------------------------------#
 //#- by Alexander Stoll & Markus Hilger -#
 //#--------------------------------------#
 //#-------------- � 2011 ----------------#
 //#--------------------------------------#
 //########################################
interface
uses
  Windows, SysUtils, Classes, Forms,
  Dialogs, StdCtrls, Menus, ComCtrls,
  Controls, ExtCtrls,
  math,       // Sinus und Cosinus
  Textures,   // Texture loader
  dglOpenGL,  // OpenGL header
  Bass,       // Sound
  ShellApi;   // f�r Hilfe

const
  mapSize = 35;  // Mapgr��e

type

  TVector3f = array [0..2] of real;          // Vektor im 3D-Raum

  TField = array[1..mapSize,1..mapSize] of integer; // 2D Matrix f�r Map

  TRMap = record                       // Record zum Speichern und
    name: string[20];                  // Laden der Maps
    maxx, maxy: integer;               // f�r die Zukunft...
    field: Tfield;
  end;

  TMap = class                         // Map
    name: string;
    maxx, maxy: integer;
    field: Tfield;
    credits: array [1..mapSize,1..mapSize] of boolean;      // Credits
    points: integer;                                        // einzusammelnde C.    
    constructor create;
    procedure load(pfad: string);
    procedure drawcredits(c: TVector3f);
  end;

  TGhost = class                // Geister
    x, y,h, htime: integer; // Position
    dir: char;              // Richtung
    constructor spawn;      
  end;

  TAmmo =class                // Projektil zum Abschie�en der Ghosts
    x,y: real;             // Position
    dir: double;           // Richtung
  end;

  TFogColor = record  // Nebelfarbe
    Red : single;
    Green : single;
    Blue : single;
    Alpha : single;
  end;
  
  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    Optionen1: TMenuItem;
    beenden1: TMenuItem;
    Map1: TMenuItem;
    ffnen1: TMenuItem;
    OpenDialog1: TOpenDialog;
    Einstellungen1: TMenuItem;
    ProgressBar1: TProgressBar;
    Timer1: TTimer;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    About1: TMenuItem;
    Help1: TMenuItem;
    procedure SetupGL;                    // OpenGL Einstellungen vornehmen
    procedure Render;                     // Hauptprozedur zum Rendern der Szene
    procedure InitTextures;               // Ausgabe von Fehlern
    procedure createlistBlock;            // Erstellen Displaylist Bl�cke
    procedure createlistEnviroment;       // Erstellen Displaylist Seitenw�nde + Boden
    procedure LimitFrameRate(atd: double);// Frameratenlimitierung
    procedure CreateSphere(c: TVector3f; r: Single; n: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure beenden1Click(Sender: TObject);
    procedure ffnen1Click(Sender: TObject);
    procedure IdleHandler(Sender: TObject; var Done: boolean);
    procedure Einstellungen1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormClick(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure Help1Click(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
    FrameCount, frames, Frequency, StartCount, EndCount: Int64; // f�r Zeitmessung
    drawtime, timecount: Extended;                              // & FPS
  public
    { Public declarations }
    DC: HDC;              // OpenGL
    RC: HGLRC;            // OpenGL
    Displaylist: glUint;  // Displaylist f�r Boden, W�nde, Bl�cke
  end;

var
  Form1: TForm1;
  a, b, c, x: real;                       // Koordinaten
  texBoden: array [1 .. 4] of glUint;     // Texturen Boden
  texWand: array [1 .. 4] of glUint;      // Texturen Wand
  texCredit: array [1 .. 4] of glUint;    // Texturen Credit
  texPille: array [1 .. 4] of glUint;     // Texturen Pille
  texGhost: array [1 .. 4] of glUint;     // Texturen Ghost
  texProjektil: array [1 .. 4] of glUint; // Texturen Projektil
  ammos: array[1..5] of TAmmo;        // Projektile zum Schie�en
  xpos, xpos2: double;                // Position des
  zpos, zpos2: double;                // Spielers
  ypos: double;                       // in der Map
  rotation: double;                   // Blickrichtung des Spielers in der Map
  map: TMap;                          // Map 
  ghosts: array of TGhost;            // Geister
  bla: Extended = 0;                  // Texturbewegung der Credits
  quali: integer;                     // Qualit�t der Texturen
  backgroundSound, pilleSound, gunSound, ghostSound: HStream; // Sounds
  leben: integer;                    // Leben
  magazin: integer;                  // Anzahl der Sch�sse
  FLastSleep: double = 0;            // Frameratebegrenzung (Zeit des letzten Sleeps)
  FogColor : TFogColor;              // Nebelfarbe
  menust: boolean;                   // Men�steuerung

const
  NearClipping = 1;                  // ab wann man sehen kann
  FarClipping = 500;                 // bis wohin man sehen kann

implementation
{$R *.dfm}
uses Einstellungen, Minimap;

procedure TForm1.FormCreate(Sender: TObject);
begin
  openDialog1.InitialDir := GetCurrentDir + '\maps'; // in \maps wechseln
  Width := Screen.Width;
  Height := Screen.Height;
  Randomize;
  leben := 3;
  ShowCursor(false);    // Cursor verstecken
  if not QueryPerformanceFrequency(Frequency) then  // �berpr�fen ob Hardwaretimer vorhanden ist
    raise Exception.create('Kein Hardware Timer vorhanden');
  QueryPerformanceFrequency(Frequency); // Frequenz des Rechners ermitteln
  Application.OnIdle := IdleHandler;    // IdleHandler initialisieren

  DC := GetDC(Handle);
  if not InitOpenGL then  // Wenn OpenGL nicht initialisiert werden kann close
    Application.Terminate;
  RC := CreateRenderingContext(DC, [opDoubleBuffered], 32, 24, 0, 0, 0, 0);
  ActivateRenderingContext(DC, RC);
  map := TMap.create;
  quali := 2;
  SetupGL;  // OpenGL Einstellungen vornehmen
  Displaylist := glGenLists(2); // 2 Displaylisten erstellen
  createlistEnviroment; // W�nde und Boden Displaylist erstellen

  // Version von Bass.dll �berpr�fen (f�r Sound)
  if (HIWORD(BASS_GetVersion) <> BASSVERSION) then
  begin
    MessageBox(0, 'Falsche BASS.DLL geladen!', nil,
      MB_ICONERROR);
    Halt;
  end;
  // Audio initialisieren - default device, 44100hz, stereo, 16 bits
  BASS_Init(-1, 44100, 0, Application.Handle, nil);

  // Sounddateien den Variablen �bergeben
  backgroundSound := BASS_StreamCreateFile(false, PChar('sounds\background.mp3'), 0, 0,
    BASS_SAMPLE_LOOP {$IFDEF UNICODE} or BASS_UNICODE {$ENDIF});  // im Loop abspielen
  pilleSound := BASS_StreamCreateFile(false, PChar('sounds\pille.mp3'), 0, 0, 0
    {$IFDEF UNICODE} or BASS_UNICODE {$ENDIF});
  gunSound := BASS_StreamCreateFile(false, PChar('sounds\gun.mp3'), 0, 0, 0
    {$IFDEF UNICODE} or BASS_UNICODE {$ENDIF});
  ghostSound := BASS_StreamCreateFile(false, PChar('sounds\ghost.wav'), 0, 0, 0
    {$IFDEF UNICODE} or BASS_UNICODE {$ENDIF});
  BASS_ChannelPlay(backgroundSound, false); // Backgroundmusic abspielen

  // Progressbar Gr��e & Position anpassen
  ProgressBar1.Width := Width div 3;
  ProgressBar1.Height := Height div 37;
  ProgressBar1.Left := 5;
  ProgressBar1.Top := Height - Progressbar1.Height - 25;

  // Fadenkreuz Gr��e & Position anpassen
  Panel3.Left := Width div 2 - 15;
  Panel3.Top := Height div 2;
  Panel4.Left := Width div 2;
  Panel4.Top := Height div 2 - 15;

  glViewport(0, 0, Width, Height);  // Betrachtungsfenster festlegen
  glMatrixMode(GL_PROJECTION);  // Projection Matrix aktivieren
  glLoadIdentity;   // Ersetzt die aktuelle Matrix durch die Identit�tsmatrix
  gluPerspective(90, Width / Height, NearClipping, FarClipping); // Perspektive
  glMatrixMode(GL_MODELVIEW);   // Modelview Matrix aktivieren
  glLoadIdentity;   // Ersetzt die aktuelle Matrix durch die Identit�tsmatrix

  Sleep(3000);          // Splashscreen 3 Sekunden anzeigen
end;

procedure TForm1.SetupGL; // OpenGL Einstellungen vornehmen
begin
  glClearColor(0.0, 0.0, 0.0, 0.0); // default Farbpuffer Farbe
  glEnable(GL_DEPTH_TEST);  // Tiefentest aktivieren
  glEnable(GL_CULL_FACE);   // Backface Culling aktivieren
  glEnable(GL_FOG);         // Neben aktivieren
  // glShadeModel(GL_SMOOTH);  #######################!!! TestEN!!!!!!!!
  FogColor.Red := 0;        // Nebelfarbe
  FogColor.Green := 0;
  FogColor.Blue := 0;
  FogColor.Alpha := 0;
  glFogfv(GL_FOG_COLOR, @FogColor);
  glFogi(GL_FOG_MODE, GL_EXP);  // Nebel exponentiell st�rker werden lassen
  glFogf(GL_FOG_DENSITY, 0.02); // Nebelst�rke
  InitTextures;   // Texturen laden
  ypos := -70;    // Sichth�he
end;

procedure TForm1.InitTextures;  // Texturen laden
begin
  glEnable(GL_TEXTURE_2D);  // Texturen aktivieren
  // Texturfilter
  //glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR); // #### !!!Texturfilter TESTEN!!! Einstellen lassen?
  //glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR); // #### !!!Texturfilter TESTEN!!!
  // Bodentextur
  LoadTexture('textures\boden_low.tga', texBoden[1], false);
  LoadTexture('textures\boden_medium.tga', texBoden[2], false);
  LoadTexture('textures\boden_high.tga', texBoden[3], false);
  LoadTexture('textures\boden_ultra.tga', texBoden[4], false);
  // Wandtextur
  LoadTexture('textures\wand_low.tga', texWand[1], false);
  LoadTexture('textures\wand_medium.tga', texWand[2], false);
  LoadTexture('textures\wand_high.tga', texWand[3], false);
  LoadTexture('textures\wand_ultra.tga', texWand[4], false);
  // Credittextur
  LoadTexture('textures\credit_low.tga', texCredit[1], false);
  LoadTexture('textures\credit_medium.tga', texCredit[2], false);
  LoadTexture('textures\credit_high.tga', texCredit[3], false);
  LoadTexture('textures\credit_ultra.tga', texCredit[4], false);
  // Pillentextur
  LoadTexture('textures\pille_low.tga', texPille[1], false);
  LoadTexture('textures\pille_medium.tga', texPille[2], false);
  LoadTexture('textures\pille_high.tga', texPille[3], false);
  LoadTexture('textures\pille_ultra.tga', texPille[4], false);
  // Geisttextur
  LoadTexture('textures\ghost_low.tga', texGhost[1], false);
  LoadTexture('textures\ghost_medium.tga', texGhost[2], false);
  LoadTexture('textures\ghost_high.tga', texGhost[3], false);
  LoadTexture('textures\ghost_ultra.tga', texGhost[4], false);
  // Projektiltextur
  LoadTexture('textures\projektil_low.tga', texProjektil[1], false);
  LoadTexture('textures\projektil_medium.tga', texProjektil[2], false);
  LoadTexture('textures\projektil_high.tga', texProjektil[3], false);
  LoadTexture('textures\projektil_ultra.tga', texProjektil[4], false);
end;

procedure TForm1.FormClick(Sender: TObject); //Abschuss eines Projektils
begin
if (Timer1.enabled = true) and (menust = false) then   // nur wenn Powerup aktiv
begin                                                  // und nicht Menu
  if (magazin < 4) then                               // maximal 3 Kugeln rendern
    inc(magazin)
  else
    magazin := 1;
  ammos[magazin].x:=round(xpos);
  ammos[magazin].y:=round(zpos);
  ammos[magazin].dir:=rotation;
  BASS_ChannelPlay(gunSound, false);                  // Schie�sound
end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  DeactivateRenderingContext; // Rendercontext deaktivieren
  DestroyRenderingContext(RC); // Rendercontext zerst�ren
  ReleaseDC(Handle, DC);  // wieder freigeben
  BASS_Free();  // Sound freigeben
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState); // damit Tastenkombinationen weiterhin funktionieren
begin
  if Key = VK_ESCAPE then
    begin
      if menust = false then
        begin
          menust:=true;
          ShowCursor(true);
        end
      else
        begin
          menust:=false;
          ShowCursor(false);
        end;
    end;
end;

// ######## [R] #### [E] #### [N] #### [D] #### [E] #### [R] ###################
procedure TForm1.Render;
var
  I, L: integer;
  vec: TVector3f; // Koordinaten im Raum
  N, S, O, W, hdir: boolean;  // Bewegungsrichtungen der Geister
  P: Tpoint;      // Mauskoordinaten
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);  // Tiefenbuffer leeren
  glLoadIdentity;   // Ersetzt die aktuelle Matrix durch die Identit�tsmatrix
  glscalef(0.06, 0.06, 0.06);

  // Bewegung mit Tastatur
  if GetAsyncKeyState($57) <> 0 then // Nach oben (W) Taste gedr�ckt
  begin
    xpos := xpos + sin(degtorad(rotation)) * 2.75;
    zpos := zpos - cos(degtorad(rotation)) * 2.75;
  end;

  if GetAsyncKeyState($53) <> 0 then // Nach unten (S) Taste gedr�ckt
  begin
    xpos := xpos - sin(degtorad(rotation)) * 2.75;
    zpos := zpos + cos(degtorad(rotation)) * 2.75;
  end;

  if GetAsyncKeyState($41) <> 0 then // Nach links (A) Taste gedr�ckt
  begin
    xpos := xpos - cos(degtorad(rotation)) * 2.75;
    zpos := zpos - sin(degtorad(rotation)) * 2.75;
  end;

  if GetAsyncKeyState($44) <> 0 then // Nach rechts (D) Taste gedr�ckt
  begin
    xpos := xpos + cos(degtorad(rotation)) * 2.75;
    zpos := zpos + sin(degtorad(rotation)) * 2.75;
  end;

  // Maussteuerung
  getCursorPos(P);  // Aktuelle Cursorposition
  rotation := rotation + (P.x - Width / 2) * Einstellungen.Mausempf; // Rotation

  // Ghostmovement
  for l := 0 to length(ghosts) - 1 do
  begin
    if (ghosts[l].x mod 50 = 0) and (ghosts[l].x mod 100 <> 0) and (ghosts[l].y mod 50 = 0) and (ghosts[l].y mod 100 <> 0) then
    begin
      s := false;
      n := false;
      o := false;
      w := false;
      // Check ob Block
      if map.field[trunc(ghosts[l].x / 100) + 1, trunc(ghosts[l].y / 100)] = 1 then
        w := false
      else
        w := true;

      if map.field[trunc(ghosts[l].x / 100), trunc(ghosts[l].y / 100) + 1] = 1 then
        s := false
      else
        s := true;

      if map.field[trunc(ghosts[l].x / 100) + 2, trunc(ghosts[l].y / 100) +  1] = 1 then
        n := false
      else
        n := true;

      if map.field[trunc(ghosts[l].x / 100) + 1, trunc(ghosts[l].y / 100) + 2] = 1 then
        o := false
      else
        o := true;
      // Check ob Au�enwand
      case trunc(ghosts[l].x / 100) of
        0: s := false;
        34: n := false;
      end;
      case trunc(ghosts[l].y / 100) of
        0: w := false;
        34: o := false;
      end;

      hdir := false;
      repeat // Um Abwechslung zu generieren
      begin
        i := random(100) + 1;
        case i of
          1 .. 79:  // 79% Geradeaus
            case ghosts[l].dir of
              'n': if n then hdir := true;
              'o': if o then hdir := true;
              's': if s then hdir := true;
              'w': if w then hdir := true;
            end;
          80 .. 86: // 7% entgegengesetzt
            case ghosts[l].dir of
              'n': if s then
                begin
                  ghosts[l].dir := 's';
                  hdir := true;
                end;
              'o': if w then
                begin
                  ghosts[l].dir := 'w';
                  hdir := true;
                end;
              's': if n then
                begin
                  ghosts[l].dir := 'n';
                  hdir := true;
                end;
              'w': if o then
                begin
                  ghosts[l].dir := 'o';
                  hdir := true;
                end;
            end;
          87 .. 93: // 7% rechts
            case ghosts[l].dir of
              'n': if o then
                begin
                  ghosts[l].dir := 'o';
                  hdir := true;
                end;
              'o': if s then
                begin
                  ghosts[l].dir := 's';
                  hdir := true;
                end;
              's': if w then
                begin
                  ghosts[l].dir := 'w';
                  hdir := true;
                end;
              'w': if n then
                begin
                  ghosts[l].dir := 'n';
                  hdir := true;
                end;
            end;
          94 .. 100: // 7% links
            case ghosts[l].dir of
              'n': if w then
                begin
                  ghosts[l].dir := 'w';
                  hdir := true;
                end;
              'o': if n then
                begin
                  ghosts[l].dir := 'n';
                  hdir := true;
                end;
              's': if o then
                begin
                  ghosts[l].dir := 'o';
                  hdir := true;
                end;
              'w': if s then
                begin
                  ghosts[l].dir := 's';
                  hdir := true;
                end;
            end;
        end;
      end;
      until hdir = true;
  end;
    // Geister in Richtung bewegen
    case ghosts[l].dir of
      'n': ghosts[l].x := ghosts[l].x + 2;
      'o': ghosts[l].y := ghosts[l].y + 2;
      's': ghosts[l].x := ghosts[l].x - 2;
      'w': ghosts[l].y := ghosts[l].y - 2;
    end;
    // Geister abgeschossen
    if ghosts[l].htime > 0 then
    begin
      dec(ghosts[l].htime);
      ghosts[l].h := ghosts[l].htime div (strtoint(EinstellungenForm.Edit2.Text) div 20);
    end;
    if (trunc(xpos / 100) = trunc(ghosts[l].x / 100)) and (trunc(zpos / 100) = trunc(ghosts[l].y / 100)) and (ghosts[l].h = 0) then
      begin
        BASS_ChannelPlay(ghostSound, false); // Geistsound
        dec(leben);
        for i := 0 to length(ghosts) - 1 do                  // Respawnprotection
          ghosts[i].htime:= strtoint(EinstellungenForm.Edit2.Text)*5;
        Panel1.Caption := 'Leben: ' + inttostr(leben);
        xpos:=50;  // wieder an
        zpos:=50;  // Ausgangsposition setzen
        xpos2 := xpos;
        zpos2 := zpos;
        if leben = 0 then // Verloren
        begin
          ShowCursor(true);
          menust := true;
         if Application.MessageBox('Zum Laden einer neuen Map "Ja" und zum schlie�en des Programmes "Nein" klicken!',
          'Game Over!', MB_YESNO or MB_DEFBUTTON1) = IDYES then
          begin
            Form1.ffnen1Click(form1.ffnen1);
            Timer1.Enabled := true;
          end
         else
          Application.Terminate;
        end;
      end;
  end;

  // Kollisionskontrolle mit Seitenw�nden
  if xpos > (mapSize * 100 - 34) then
    xpos := mapSize * 100 - 34;
  if xpos < 34 then
    xpos := 34;
  if zpos > (mapSize * 100 - 34) then
    zpos := mapSize * 100 - 34;
  if zpos < 34 then
    zpos := 34;

  // Kollisionskontrolle mit Bl�cken
  for i := 1 to mapSize do
    for L := 1 to mapSize do
      if map.field[i, L] = 1 then
        begin
          // S�dwand
          if (zpos >= (L * 100 - 134)) and (zpos <= (L * 100 + 34)) then
            if (xpos2 <= (i * 100 - 134)) and (xpos >= (i * 100 - 134)) then
              xpos := i * 100 - 135;
          // Nordwand
          if (xpos >= (i * 100 - 134)) and (xpos <= (i * 100 + 34)) then
            if (zpos2 >= (l * 100 + 34)) and (zpos <= (L * 100 + 34)) then
              zpos := l * 100 + 35;
          // Ostwand
          if (zpos >= (L * 100 - 134)) and (zpos <= (L * 100 + 34)) then
            if (xpos2 >= (i * 100 + 34)) and (xpos <= (i * 100 + 34)) then
              xpos := i * 100 + 35;
          // Westwand
          if (xpos >= (i * 100 - 134)) and (xpos <= (i * 100 + 34)) then
            if (zpos2 <= (L * 100 - 134)) and (zpos >= (L * 100 - 134)) then
              zpos := L * 100 - 135;
        end;
  
  // Endg�ltige Bewegung
  glrotatef(rotation, 0, 1, 0); // Die entg�ltige Drehung
  gltranslatef(-xpos, ypos, -zpos); // Die entg�ltige Bewegung

  // Maus wieder in Mitte setzen
  setcursorpos(Width div 2, Height div 2);
  
  // Minimap Spielerposition updaten
  Form2.updateMinimapPlayer(trunc(xpos / 100) + 1, trunc(zpos / 100) + 1);

  // Seitenw�nde + Boden renhdern
  glCallList(Displaylist);

  // Bl�cke rendern
  glCallList(Displaylist + 1);

  // Ghostabschuss
  if Timer1.Enabled = true then            //wenn Pille geschluckt
    begin
        for i := 1 to Length(ammos)-1 do  //F�r alle Projektile
          begin
              //Bewegen der Projektile
              ammos[i].x := ammos[i].x + sin(degtorad(ammos[i].dir)) * 20;
              ammos[i].y := ammos[i].y - cos(degtorad(ammos[i].dir)) * 20;
           for L := 0 to length(ghosts)-1 do //F�r jeden Ghost
            //Projektil auf selbem Feld wie Ghost?
            if (trunc(ammos[i].x/100)=trunc(ghosts[L].x/100))
             and (trunc(ammos[i].y/100)=trunc(ghosts[L].y/100))
             and (ghosts[L].h=0) then
             begin
              //Ghost vorr�bergehend unsch�dlich machen
              ghosts[L].htime:= strtoint(EinstellungenForm.Edit2.Text)*10;
              //Projektil au�erhalb der Map "parken"
              ammos[i].x:=-100;
              ammos[i].y:=-100;
              ammos[i].dir:=200;
             end;
            // Projektil rendern
            glBindTexture(GL_TEXTURE_2D, texProjektil[quali]); //Textur einbinden
            //Vektor festlegen
            vec[0] := ammos[i].x;
            vec[1] := 60;
            vec[2] := ammos[i].y;
            //Sph�re zeichnen
            CreateSphere(vec,3,15);
          end;
    end;

  // Credits  rendern
  if map.credits[trunc(xpos / 100) + 1, trunc(zpos / 100) + 1] then
  //Wenn man sich auf dem selben Feld befindet, wie ein Credit
  begin
    //betroffener Credit wird entfernt
    map.credits[trunc(xpos / 100) + 1, trunc(zpos / 100) + 1] := false;
    map.points := map.points - 1;
    Panel2.Caption := 'Noch ' + inttostr(map.points) + ' Credits';
    if map.points = 0 then  // Gewonnen
      Application.MessageBox('Du hast gewonnen!','Win',MB_ICONINFORMATION);
  end;

  if map.field[trunc(xpos / 100) + 1, trunc(zpos / 100) + 1] = 2 then // Pille eingesammelt
  begin
    map.field[trunc(xpos / 100) + 1, trunc(zpos / 100) + 1] := 0;
    Panel2.Caption := 'Noch ' + inttostr(map.points) + ' Credits';
    //Pille-Modus starten
    ProgressBar1.Position := 1000;
    Timer1.Enabled := true;
    magazin:=0;
    //Projektile erstellen
    for i := 1 to 5 do
      begin
        Ammos[i] := Tammo.Create;
      end;
    BASS_ChannelSetAttribute(backgroundSound, BASS_ATTRIB_VOL, 0.15 * (EinstellungenForm.TrackBar1.Position / 100)); // Lautst�rke der Backgroundmusic verringern
    BASS_ChannelPlay(pilleSound, true);   // Pillensound abspielen
  end;

  //Pillen und Credits zeichnen
  for i := 1 to mapSize do
  begin
    for L := 1 to mapSize do
    begin
      if (map.credits[i, L] = true) and (map.field[i, L] = 0) then
      begin
        glBindTexture(GL_TEXTURE_2D, texCredit[quali]);//Textur einbinden
        vec[0] := i * 100 - 50;
        vec[1] := 50;
        vec[2] := L * 100 - 50;
        map.drawcredits(vec); //Crdits zeichnen mit
                              //entsprechenden Werten
      end;
      if map.field[i, L] = 2 then
      begin
        glBindTexture(GL_TEXTURE_2D, texPille[quali]);
        vec[0] := i * 100 - 50;
        vec[1] := 55;
        vec[2] := L * 100 - 50;
        map.drawcredits(vec); //Crdits zeichnen mit
                              //entsprechenden Werten
      end;
    end;
  end;

  // Ghosts rendern
  for I := 0 to length(ghosts) - 1 do
  begin
    glBindTexture(GL_TEXTURE_2D, texGhost[quali]); //Textur einbinden
    glBegin(GL_QUADS);
    if (ghosts[I].h > 0) then  //wenn Ghost in der Luft,
      glColor3f(0, 1, 0);      //dann gr�n f�rben
    glTexCoord2f(0, 0);
    glVertex3f(ghosts[I].x - 20, 100+ghosts[I].h, ghosts[I].y - 20);
    glTexCoord2f(0, 1);
    glVertex3f(ghosts[I].x - 20, ghosts[I].h, ghosts[I].y - 20);
    glTexCoord2f(1, 1);
    glVertex3f(ghosts[I].x - 20, ghosts[I].h, ghosts[I].y + 20);
    glTexCoord2f(1, 0);
    glVertex3f(ghosts[I].x - 20, 100+ghosts[I].h, ghosts[I].y + 20);

    glTexCoord2f(0, 0);
    glVertex3f(ghosts[I].x - 20, 100+ghosts[I].h, ghosts[I].y + 20);
    glTexCoord2f(0, 1);
    glVertex3f(ghosts[I].x - 20, ghosts[I].h, ghosts[I].y + 20);
    glTexCoord2f(1, 1);
    glVertex3f(ghosts[I].x + 20, ghosts[I].h, ghosts[I].y + 20);
    glTexCoord2f(1, 0);
    glVertex3f(ghosts[I].x + 20, 100+ghosts[I].h, ghosts[I].y + 20);

    glTexCoord2f(0, 0);
    glVertex3f(ghosts[I].x + 20, 100+ghosts[I].h, ghosts[I].y + 20);
    glTexCoord2f(0, 1);
    glVertex3f(ghosts[I].x + 20, ghosts[I].h, ghosts[I].y + 20);
    glTexCoord2f(1, 1);
    glVertex3f(ghosts[I].x + 20, ghosts[I].h, ghosts[I].y - 20);
    glTexCoord2f(1, 0);
    glVertex3f(ghosts[I].x + 20, 100+ghosts[I].h, ghosts[I].y - 20);

    glTexCoord2f(0, 0);
    glVertex3f(ghosts[I].x + 20, 100+ghosts[I].h, ghosts[I].y - 20);
    glTexCoord2f(0, 1);
    glVertex3f(ghosts[I].x + 20, ghosts[I].h, ghosts[I].y - 20);
    glTexCoord2f(1, 1);
    glVertex3f(ghosts[I].x - 20, ghosts[I].h, ghosts[I].y - 20);
    glTexCoord2f(1, 0);
    glVertex3f(ghosts[I].x - 20, 100+ghosts[I].h, ghosts[I].y - 20);
    glColor3f(1, 1, 1);

    glVertex3f(ghosts[I].x - 20, ghosts[I].h, ghosts[I].y - 20);
    glVertex3f(ghosts[I].x + 20, ghosts[I].h, ghosts[I].y - 20);
    glVertex3f(ghosts[I].x + 20, ghosts[I].h, ghosts[I].y + 20);
    glVertex3f(ghosts[I].x - 20, ghosts[I].h, ghosts[I].y + 20);
    glColor3f(1, 1, 1);
    glEnd;
  end;

  SwapBuffers(DC);
  xpos2 := xpos;      //merken der alten
  zpos2 := zpos;      //Spielerposition
  bla := bla + 0.002; // Texturbewegeung der Credits
end;
// ################################## Renderende ###############################

procedure TForm1.CreateSphere(c: TVector3f; r: Single; n: Integer);
//Zeichnen von Sp�hren
const
  TWOPI = PI*2;
  PID2 = PI/2;
var
  i,j: Integer;
  theta1,theta2,theta3: Single;
  e,p:TVector3f;
begin
  if (r < 0) then r := -r;
  if (n < 0) then n := -n;
  if (n < 4) or (r <= 0) then
  begin
    glBegin(GL_POINTS);
      glVertex3f(c[0],c[1],c[2]);
    glEnd;
    exit;
  end;

  for j:=0 to n div 2 do
  begin
    theta1 := j * TWOPI / n - PID2;
    theta2 := (j + 1) * TWOPI / n - PID2;

    glBegin(GL_QUAD_STRIP);
    for i:=0 to n do
    begin
      theta3 := i * TWOPI / n;

      e[0] := cos(theta2) * cos(theta3);
      e[1] := sin(theta2);
      e[2] := cos(theta2) * sin(theta3);
      p[0] := c[0] + r * e[0];
      p[1] := c[1] + r * e[1];
      p[2] := c[2] + r * e[2];

      glNormal3f(e[0],e[1],e[2]);
      glTexCoord2f(i/n,2*(j+1)/n);
      glVertex3f(p[0],p[1],p[2]);

      e[0] := cos(theta1) * cos(theta3);
      e[1] := sin(theta1);
      e[2] := cos(theta1) * sin(theta3);
      p[0] := c[0] + r * e[0];
      p[1] := c[1] + r * e[1];
      p[2] := c[2] + r * e[2];

      glNormal3f(e[0],e[1],e[2]);
      glTexCoord2f(i/n,2*j/n);
      glVertex3f(p[0],p[1],p[2]);
    end;
   glEnd;
  end;
end;

procedure TForm1.LimitFrameRate(atd: double); //FPS-Rate beschr�nken
var
  sleeptime: Double;
begin
  sleeptime := 1000 / strtoint(EinstellungenForm.Edit2.text) - (atd - FLastSleep);
  if sleeptime > 0 then
  begin
    Sleep(trunc(sleeptime));
    FLastSleep := sleeptime;
  end else
    FLastSleep := 0;
end;

procedure TForm1.IdleHandler(Sender: TObject; var Done: boolean); //Leerlauf
begin
  if menust = false then
  begin
    QueryPerformanceCounter(StartCount); // Zeit0
    Render;
    QueryPerformanceCounter(EndCount); // Zeit1
    drawTime := (EndCount - StartCount) / Frequency * 1000 + FLastSleep;
    LimitFrameRate(drawTime);      // Frameratebegrenzung
    TimeCount := TimeCount + drawTime;
    Inc(FrameCount);
    Done := false;
  end;
end;

procedure TForm1.Einstellungen1Click(Sender: TObject); //Option>Einstellungen �ffnen
begin
  EinstellungenForm.Show;
end;

constructor TMap.create;  //Map erstellen
var
  i, j: integer;
begin
  inherited;
  maxx := mapSize;  //variable Gr��e
  maxy := mapSize;  //& Mapname
  name := 'noname'; //f�r sp�ter
  points := mapSize*mapSize; //Anzahl der Credits bei leerer Map
  for i := 1 to mapSize do
  begin
    for j := 1 to mapSize do
    begin
      self.field[i, j] := 0;      //Standartwerte
      self.credits[i, j] := true; //setzen
    end;
  end;

end;

procedure TMap.load(pfad: string); //Map laden
var
  mapfile: file of TRMap; //TRMap, da Klassen nicht gespeichert werden k�nnen
  hmap: TRMap;
  i,j: integer;
  gcount: integer; //Anzahl der Ghosts
begin
  //Volles Leben setzen
  leben := 3;
  Form1.Panel1.Caption := 'Leben: ' + inttostr(leben);
  //Datei �ffnen
  assignfile(mapfile, pfad);
  reset(mapfile);
  read(mapfile, hmap);
  closefile(mapfile);
  //Werte in Objekt self �bertragen
  self.field := hmap.field;
  maxx := mapSize;
  maxy := mapSize;
  xpos := 50;
  zpos := 50;
  xpos2 := xpos;
  zpos2 := zpos;
  points := 0;
  for i := 1 to mapSize do
  begin
    for j := 1 to mapSize do
    begin
      if (self.field[i, j] = 0) then
      begin
        self.credits[i, j] := true;
        Inc(points);
      end
      else
        self.credits[i, j] := false;
    end;
  end;
  //Anzahl der Ghosts aus Creditanzahl berechnen
  gcount := points div 25;
  //Ghosts erstellen
  setlength(ghosts, gcount);
  for i := 0 to length(ghosts) - 1 do
    ghosts[i] := TGhost.spawn;
  for i := 0 to length(ghosts) - 1 do                            // Spawnprotection
    ghosts[i].htime:= strtoint(EinstellungenForm.Edit2.Text)*5;

  Form1.createlistBlock;

  // Minimap erstellen
  lastX := 1;
  lastY := 1;
  Form2.updateMinimap;
  menust := false; // Game wieder starten
  ShowCursor(false);
end;

//Prozedur zum Zeichnen von Credits und Pillen
procedure TMap.drawcredits(c: TVector3f);
begin
    glbegin(GL_TRIANGLE_FAN);
     glTexCoord2f(0.5 + bla,0);
     glVertex3f(c[0], c[1], c[2]);
     glTexCoord2f(0 + bla,1);
     glVertex3f(c[0]-5, c[1]-7, c[2]-5);
     glTexCoord2f(1 + bla,1);
     glVertex3f(c[0]-5, c[1]-7, c[2]+5);
     glTexCoord2f(0 + bla,1);
     glVertex3f(c[0]+5, c[1]-7, c[2]+5);
     glTexCoord2f(1 + bla,1);
     glVertex3f(c[0]+5, c[1]-7, c[2]-5);
     glTexCoord2f(0 + bla,1);
     glVertex3f(c[0]-5, c[1]-7, c[2]-5);
    glEnd;
    glbegin(GL_TRIANGLE_FAN);
     glTexCoord2f(0.5 + bla, 1);
     glVertex3f(c[0], c[1]-14, c[2]);
     glTexCoord2f(0 + bla,0);
     glVertex3f(c[0]-5, c[1]-7, c[2]-5);
     glTexCoord2f(1 + bla,0);
     glVertex3f(c[0]-5, c[1]-7, c[2]+5);
     glTexCoord2f(0 + bla,0);
     glVertex3f(c[0]+5, c[1]-7, c[2]+5);
     glTexCoord2f(1 + bla,0);
     glVertex3f(c[0]+5, c[1]-7, c[2]-5);
     glTexCoord2f(0 + bla,0);
     glVertex3f(c[0]-5, c[1]-7, c[2]-5);
    glEnd;
end;

// Hilfe anzeigen
procedure TForm1.Help1Click(Sender: TObject);
begin
  Shellexecute(Handle,'open', 'c:\windows\notepad.exe','help.txt', nil, SW_SHOWNORMAL);
end;

//About-Informationen anzeigen
procedure TForm1.About1Click(Sender: TObject);
begin
  showmessage('Coded by Alexander Stoll and Markus Hilger' +#13+
              'Music by DoKashiteru > http://ccmixter.org/files/DoKashiteru/19848' +#13+
              'and pornophonique http://www.jamendo.com/en/track/81747' +#13+
              'Licensed under Creative Commons Attribution (3.0)');
end;

//Programm beenden (nicht nur eine Form)
procedure TForm1.beenden1Click(Sender: TObject);
begin
  Application.Terminate;
end;

//Map>�ffnen
procedure TForm1.ffnen1Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
    map.load(OpenDialog1.FileName);
end;

//Timer f�r abgeschossene Ghosts
procedure TForm1.Timer1Timer(Sender: TObject);
begin
if menust = false then
begin
  ProgressBar1.Position := ProgressBar1.Position - 5;
  glClearColor(ProgressBar1.Position / 750, 0.0, 0.0, 0.0);
  FogColor.Red := ProgressBar1.Position / 750;
  glFogfv(GL_FOG_COLOR, @FogColor);
  if ProgressBar1.Position <= 0 then
  begin
    glClearColor(0.0, 0.0, 0.0, 0.0);
    Timer1.Enabled := false;
    Bass_ChannelStop(pilleSound);
    BASS_ChannelSetAttribute(backgroundSound, BASS_ATTRIB_VOL, EinstellungenForm.TrackBar1.Position / 100);
  end;
end;
end;

//Erstellen eines Ghosts
constructor TGhost.spawn;
var
  i, j, hdir: integer;
begin
  self.create;
  Randomize;
  //Startposition zuf�llig generieren, bis keine Wand getroffen wird
  repeat
    i := random(mapSize) + 1;
    j := random(mapSize) + 1;
  until (map.field[i, j] = 0) or (map.field[i, j] = 2);
  self.x := i * 100 - 50;
  self.y := j * 100 - 50;
  //Bewegungsrichtung zuf�llig ermitteln
  hdir := random(4) + 1;
  case hdir of
    1:
      self.dir := 'n';        //Norden
    2:
      self.dir := 'o';        //Osten
    3:
      self.dir := 's';        //S�den
    4:
      self.dir := 'w';        //Westen
  end;
  self.h:=0;
  self.htime:=0;
end;

procedure TForm1.createlistBlock; // Displaylist Bl�cke
var
  i, j: integer;
begin
  glNewList(Displaylist + 1, GL_COMPILE);
  glBindTexture(GL_TEXTURE_2D, texWand[quali]);
  for i := 1 to mapSize do
    for j := 1 to mapSize do
      if map.field[i, j] = 1 then
      begin
        glBegin(GL_QUADS);
        // S�ddwand
        if map.field[i - 1, j] <> 1 then  // Nur rendern, wenn kein Block daneben ist
        begin
          glTexCoord2f(0, 0);
          glVertex3f(i * 100 - 100, 0, j * 100 - 100);
          glTexCoord2f(2, 0);
          glVertex3f(i * 100 - 100, 0, j * 100);
          glTexCoord2f(2, 4);
          glVertex3f(i * 100 - 100, 200, j * 100);
          glTexCoord2f(0, 4);
          glVertex3f(i * 100 - 100, 200, j * 100 - 100);
        end;
        // Ostwand
        if map.field[i, j + 1] <> 1 then
        begin
          glTexCoord2f(0, 0);
          glVertex3f(i * 100 - 100, 0, j * 100);
          glTexCoord2f(2, 0);
          glVertex3f(i * 100, 0, j * 100);
          glTexCoord2f(2, 4);
          glVertex3f(i * 100, 200, j * 100);
          glTexCoord2f(0, 4);
          glVertex3f(i * 100 - 100, 200, j * 100);
        end;
        // Nordwand
        if map.field[i + 1, j] <> 1 then
        begin
          glTexCoord2f(0, 0);
          glVertex3f(i * 100, 0, j * 100);
          glTexCoord2f(2, 0);
          glVertex3f(i * 100, 0, j * 100 - 100);
          glTexCoord2f(2, 4);
          glVertex3f(i * 100, 200, j * 100 - 100);
          glTexCoord2f(0, 4);
          glVertex3f(i * 100, 200, j * 100);
        end;
        // Westwand
        if map.field[i, j - 1] <> 1 then
        begin
          glTexCoord2f(0, 0);
          glVertex3f(i * 100, 0, j * 100 - 100);
          glTexCoord2f(2, 0);
          glVertex3f(i * 100 - 100, 0, j * 100 - 100);
          glTexCoord2f(2, 4);
          glVertex3f(i * 100 - 100, 200, j * 100 - 100);
          glTexCoord2f(0, 4);
          glVertex3f(i * 100, 200, j * 100 - 100);
        end;
        glEnd;
      end;

  glEndList;
end;

procedure TForm1.createlistEnviroment; // Displaylist Au�enw�nde, Boden
begin
  glNewList(Displaylist, GL_COMPILE);

  // W�nde
  glBindTexture(GL_TEXTURE_2D, texWand[quali]);
  glBegin(GL_QUADS);
  glTexCoord2f(mapSize * 2, 4);
  glVertex3f(0, 0, 0);
  glTexCoord2f(mapSize * 2, 0);
  glVertex3f(0, 200, 0);
  glTexCoord2f(0, 0);
  glVertex3f(0, 200, mapSize * 100);
  glTexCoord2f(0, 4);
  glVertex3f(0, 0, mapSize * 100);

  glTexCoord2f(mapSize * 2, 4);
  glVertex3f(mapSize * 100, 0, 0);
  glTexCoord2f(mapSize * 2, 0);
  glVertex3f(mapSize * 100, 200, 0);
  glTexCoord2f(0, 0);
  glVertex3f(0, 200, 0);
  glTexCoord2f(0, 4);
  glVertex3f(0, 0, 0);

  glTexCoord2f(mapSize * 2, 4);
  glVertex3f(mapSize * 100, 0, mapSize * 100);
  glTexCoord2f(mapSize * 2, 0);
  glVertex3f(mapSize * 100, 200, mapSize * 100);
  glTexCoord2f(0, 0);
  glVertex3f(mapSize * 100, 200, 0);
  glTexCoord2f(0, 4);
  glVertex3f(mapSize * 100, 0, 0);

  glTexCoord2f(mapSize * 2, 4);
  glVertex3f(0, 0, mapSize * 100);
  glTexCoord2f(mapSize * 2, 0);
  glVertex3f(0, 200, mapSize * 100);
  glTexCoord2f(0, 0);
  glVertex3f(mapSize * 100, 200, mapSize * 100);
  glTexCoord2f(0, 4);
  glVertex3f(mapSize * 100, 0, mapSize * 100);
  glEnd;

  // Boden
  glBindTexture(GL_TEXTURE_2D, texBoden[quali]);
  glBegin(GL_QUADS);
  glTexCoord2f(750, 750);
  glVertex3f(0, 0, 50000);
  glTexCoord2f(750, 0);
  glVertex3f(50000, 0, 50000);
  glTexCoord2f(0, 0);
  glVertex3f(50000, 0, 0);
  glTexCoord2f(0, 750);
  glVertex3f(0, 0, 0);
  glEnd;

  glEndList;
end;

end.
