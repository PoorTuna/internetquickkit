; Internet QuickKit Installer
; Compile with Inno Setup 6+ (https://jrsoftware.org/isinfo.php)
;
; All files are bundled inside the installer — no internet needed.

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
Source: "bundle\GitSetup.exe";      DestDir: "{tmp}"; Components: git;    Flags: ignoreversion deleteafterinstall
Source: "bundle\crane.tar.gz";      DestDir: "{tmp}"; Components: crane;  Flags: ignoreversion deleteafterinstall
Source: "bundle\XMousePortable.zip"; DestDir: "{tmp}"; Components: xmouse; Flags: ignoreversion deleteafterinstall

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
  Tmp, App: string;
  Code: Integer;
begin
  if CurStep <> ssPostInstall then
    Exit;

  Tmp := ExpandConstant('{tmp}');
  App := ExpandConstant('{app}');

  { ---- Git for Windows ---- }
  if WizardIsComponentSelected('git') then
  begin
    Log('Installing Git...');
    Exec(Tmp + '\GitSetup.exe', Format('/VERYSILENT /NORESTART /NOCANCEL /SP- /CURRENTUSER /DIR="%s\Git"', [App]), Tmp, SW_HIDE, ewWaitUntilTerminated, Code);
    Log(Format('Git exit code: %d', [Code]));
  end;

  { ---- Crane ---- }
  if WizardIsComponentSelected('crane') then
  begin
    Log('Extracting Crane...');
    Exec(ExpandConstant('{sys}\tar.exe'), Format('-xzf "%s\crane.tar.gz" -C "%s\crane"', [Tmp, App]), Tmp, SW_HIDE, ewWaitUntilTerminated, Code);
    Log(Format('Crane tar exit code: %d', [Code]));
  end;

  { ---- XMouse Button Control ---- }
  if WizardIsComponentSelected('xmouse') then
  begin
    Log('Extracting XMouse...');
    Exec(ExpandConstant('{sys}\tar.exe'), Format('-xf "%s\XMousePortable.zip" -C "%s\xmouse"', [Tmp, App]), Tmp, SW_HIDE, ewWaitUntilTerminated, Code);
    if Code <> 0 then
    begin
      ForceDirectories(App + '\xmouse');
      CopyFile(Tmp + '\XMousePortable.zip', App + '\xmouse\XMouseButtonControl.exe', False);
    end;
    Log(Format('XMouse exit code: %d', [Code]));
  end;
end;
