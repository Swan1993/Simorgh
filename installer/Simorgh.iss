; Build with Inno Setup 6 after running scripts/build_windows.ps1.
#define AppName "Simorgh"
#define AppVersion "0.1.0"
#define ReleaseDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{A0D2D2A8-6E8B-4A54-AB4C-5E3A8C0E7B11}
AppName={#AppName}
AppVersion={#AppVersion}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
OutputDir=Output
OutputBaseFilename=Simorgh-{#AppVersion}-Setup
Compression=lzma
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
WizardStyle=modern
PrivilegesRequired=lowest
UninstallDisplayIcon={app}\simorgh.exe

[Files]
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\simorgh.exe"
Name: "{group}\{#AppName}"; Filename: "{app}\simorgh.exe"

[Run]
Filename: "{app}\simorgh.exe"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent
