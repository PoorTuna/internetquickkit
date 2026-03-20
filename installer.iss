; Internet QuickKit Installer
; Compile with Inno Setup 6+ (https://jrsoftware.org/isinfo.php)
;
; All files pre-extracted and bundled. No internet, no tar, no cmd,
; no powershell needed at runtime.

#define MyAppName    "Internet QuickKit"
#define MyAppVersion "1.0"

[Setup]
AppId={{A8F3D2E1-94B7-4C06-B5A1-3E7F60D8C912}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher=Internet QuickKit
DefaultDirName={userdesktop}\InternetQuickKit
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputBaseFilename=InternetQuickKitInstaller
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "full";   Description: "Full installation"
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Components]
Name: "git";    Description: "Git for Windows 2.53.0 (current user, silent)";  Types: full
Name: "crane";  Description: "Crane 0.21.3 (Google Container Registry CLI)";   Types: full
Name: "xmouse"; Description: "XMouse Button Control (Portable)";               Types: full

[Files]
; Git installer — extracted to {app}, run post-install, then auto-deleted
Source: "bundle\GitSetup.exe"; DestDir: "{app}"; Components: git; Flags: ignoreversion deleteafterinstall

; Crane — pre-extracted binaries copied directly
Source: "bundle\crane\crane.exe";  DestDir: "{app}\crane"; Components: crane; Flags: ignoreversion
Source: "bundle\crane\gcrane.exe"; DestDir: "{app}\crane"; Components: crane; Flags: ignoreversion
Source: "bundle\crane\krane.exe";  DestDir: "{app}\crane"; Components: crane; Flags: ignoreversion

; XMouse — pre-extracted 64-bit portable
Source: "bundle\xmouse\64bit (x64)\*"; DestDir: "{app}\xmouse"; Components: xmouse; Flags: ignoreversion recursesubdirs
Source: "bundle\xmouse\Readme Portable.txt"; DestDir: "{app}\xmouse"; Components: xmouse; Flags: ignoreversion

[Dirs]
Name: "{app}\Git";    Components: git
Name: "{app}\crane";  Components: crane
Name: "{app}\xmouse"; Components: xmouse

[UninstallDelete]
Type: filesandordirs; Name: "{app}\Git"
Type: filesandordirs; Name: "{app}\crane"
Type: filesandordirs; Name: "{app}\xmouse"

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
var
  App: string;
  Code: Integer;
begin
  if CurStep <> ssPostInstall then
    Exit;

  App := ExpandConstant('{app}');

  { ---- Git for Windows ---- }
  if WizardIsComponentSelected('git') then
  begin
    Log('Installing Git...');
    Exec(App + '\GitSetup.exe', Format('/VERYSILENT /NORESTART /NOCANCEL /SP- /CURRENTUSER /DIR="%s\Git"', [App]), App, SW_HIDE, ewWaitUntilTerminated, Code);
    Log(Format('Git exit code: %d', [Code]));
  end;
end;
