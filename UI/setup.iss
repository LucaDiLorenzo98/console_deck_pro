#ifndef AppVersion
  #define AppVersion "2.1.0"
#endif

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{C0N50L3-D3CK-PR0-U1}}
AppName=Console Deck PRO
AppVersion={#AppVersion}
;AppVerName=Console Deck PRO
AppPublisher=Luca Di Lorenzo
DefaultDirName={autopf}\Console Deck PRO
DisableProgramGroupPage=yes
PrivilegesRequired=admin
OutputBaseFilename=ConsoleDeckPro_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\console_deck_ui.exe
SetupIconFile=windows\runner\resources\app_icon.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; IMPORTANT: Ensure you have run "flutter build windows" before compiling this script
Source: "build\windows\x64\runner\Release\console_deck_ui.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "*.pdb"
; Python backend compiled executable (built by PyInstaller in CI)
Source: "..\dist\console_deck_pro.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\config.example.json"; DestDir: "{app}"; Flags: ignoreversion

[InstallDelete]
; Cleanup old installer layouts no longer used.
Type: filesandordirs; Name: "{app}\backend"
Type: filesandordirs; Name: "{app}\tools"
Type: files; Name: "{app}\console_deck_pro.exe"

[Icons]
Name: "{autoprograms}\Console Deck PRO"; Filename: "{app}\console_deck_ui.exe"
Name: "{autodesktop}\Console Deck PRO"; Filename: "{app}\console_deck_ui.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\console_deck_ui.exe"; Description: "{cm:LaunchProgram,Console Deck PRO}"; Flags: nowait postinstall skipifsilent
