#ifndef AppVersion
  #define AppVersion "2.2.0"
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

[CustomMessages]
BackendGroup=Backend:
AutoStartBackend=Start the backend automatically when I sign in to Windows (recommended)
italian.AutoStartBackend=Avvia automaticamente il backend all'accesso a Windows (consigliato)

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "autostartbackend"; Description: "{cm:AutoStartBackend}"; GroupDescription: "{cm:BackendGroup}"

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

[Registry]
; Start the backend at sign-in, in the user's own desktop session (hotkeys, volume
; and brightness do not work from a Windows service). --background = no console
; window. Users can switch it off from Task Manager > Startup apps.
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "ConsoleDeckProBackend"; ValueData: """{app}\console_deck_pro.exe"" --background"; Flags: uninsdeletevalue; Tasks: autostartbackend
; Re-installing with the option unticked removes a previous registration.
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: none; ValueName: "ConsoleDeckProBackend"; Flags: deletevalue; Tasks: not autostartbackend
; Leftover of the removed "Start with Windows" toggle (v2.0.0), which started the UI at sign-in.
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: none; ValueName: "ConsoleDeckPro"; Flags: deletevalue

[Icons]
Name: "{autoprograms}\Console Deck PRO"; Filename: "{app}\console_deck_ui.exe"
Name: "{autodesktop}\Console Deck PRO"; Filename: "{app}\console_deck_ui.exe"; Tasks: desktopicon

[Run]
; Remove the manual Task Scheduler workaround from the v2.1.0 README, if present,
; so the backend is not started twice (once with a visible console).
Filename: "{sys}\schtasks.exe"; Parameters: "/Delete /TN ""Console Deck PRO Backend"" /F"; Flags: runhidden; Tasks: autostartbackend
; Start the backend right away, hidden, as the user who launched the installer
; (not as the elevated administrator account).
Filename: "{app}\console_deck_pro.exe"; Parameters: "--background"; Flags: nowait runasoriginaluser
Filename: "{app}\console_deck_ui.exe"; Description: "{cm:LaunchProgram,Console Deck PRO}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{sys}\taskkill.exe"; Parameters: "/F /IM console_deck_pro.exe"; Flags: runhidden; RunOnceId: "StopBackend"

[Code]
// The backend runs hidden in the background: stop it before its exe is replaced,
// otherwise the file is locked and the update fails.
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ResultCode: Integer;
begin
  Exec(ExpandConstant('{sys}\taskkill.exe'), '/F /IM console_deck_pro.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(500);
  Result := '';
end;
