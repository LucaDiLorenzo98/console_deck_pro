[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{C0N50L3-D3CK-PR0-U1}}
AppName=Console Deck PRO
AppVersion=1.0.0
;AppVerName=Console Deck PRO
AppPublisher=Luca Di Lorenzo
DefaultDirName={autopf}\Console Deck PRO
DisableProgramGroupPage=yes
; Remove the following line to run in administrative install mode (install for all users.)
PrivilegesRequired=lowest
OutputBaseFilename=ConsoleDeckPro_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
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

[Icons]
Name: "{autoprograms}\Console Deck PRO"; Filename: "{app}\console_deck_ui.exe"
Name: "{autodesktop}\Console Deck PRO"; Filename: "{app}\console_deck_ui.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\console_deck_ui.exe"; Description: "{cm:LaunchProgram,Console Deck PRO}"; Flags: nowait postinstall skipifsilent
