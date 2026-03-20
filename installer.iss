; Internet QuickKit Installer
; Compile with Inno Setup 6.1+ (https://jrsoftware.org/isinfo.php)
;
; Downloads and silently installs selected tools.
; Does NOT use PowerShell or CMD — only Inno Setup built-in download
; and direct exe calls.

#define MyAppName    "Internet QuickKit"
#define MyAppVersion "1.0"

[Setup]
AppId={{A8F3D2E1-94B7-4C06-B5A1-3E7F60D8C912}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher=Internet QuickKit
DefaultDirName={localappdata}\InternetQuickKit
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputBaseFilename=InternetQuickKitInstaller
Compression=lzma
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

[Dirs]
Name: "{app}\crane";  Components: crane
Name: "{app}\xmouse"; Components: xmouse

[UninstallDelete]
Type: filesandordirs; Name: "{app}\crane"
Type: filesandordirs; Name: "{app}\xmouse"

[Code]
const
  GitURL    = 'https://github.com/git-for-windows/git/releases/download/v2.53.0.windows.2/Git-2.53.0.2-64-bit.exe';
  CraneURL  = 'https://github.com/google/go-containerregistry/releases/download/v0.21.3/go-containerregistry_Windows_x86_64.tar.gz';
  XMouseURL = 'https://www.highrez.co.uk/scripts/download.asp?package=XMousePortable';

var
  DownloadPage: TDownloadWizardPage;

function OnDownloadProgress(const Url, FileName: string; const Progress, ProgressMax: Int64): Boolean;
begin
  if ProgressMax <> 0 then
    Log(Format('  %d of %d bytes', [Progress, ProgressMax]));
  Result := True;
end;

procedure InitializeWizard;
begin
  DownloadPage := CreateDownloadPage(
    SetupMessage(msgWizardPreparing),
    SetupMessage(msgPreparingDesc),
    @OnDownloadProgress);
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if CurPageID <> wpReady then
    Exit;

  DownloadPage.Clear;

  if WizardIsComponentSelected('git') then
    DownloadPage.Add(GitURL, 'GitSetup.exe', '');
  if WizardIsComponentSelected('crane') then
    DownloadPage.Add(CraneURL, 'crane.tar.gz', '');
  if WizardIsComponentSelected('xmouse') then
    DownloadPage.Add(XMouseURL, 'XMousePortable.zip', '');

  DownloadPage.Show;
  try
    try
      DownloadPage.Download;
      Result := True;
    except
      if DownloadPage.AbortedByUser then
        Log('Download aborted by user.')
      else
        SuppressibleMsgBox(AddPeriod(GetExceptionMessage), mbCriticalError, MB_OK, IDOK);
      Result := False;
    end;
  finally
    DownloadPage.Hide;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  Tmp, App, TarExe: string;
  Code: Integer;
begin
  if CurStep <> ssPostInstall then
    Exit;

  Tmp := ExpandConstant('{tmp}');
  App := ExpandConstant('{app}');
  TarExe := ExpandConstant('{sys}\tar.exe');

  { ---- Git for Windows ---- }
  if WizardIsComponentSelected('git') then
  begin
    Log('Installing Git...');
    Exec(Tmp + '\GitSetup.exe', '/VERYSILENT /NORESTART /NOCANCEL /SP- /CURRENTUSER', Tmp, SW_HIDE, ewWaitUntilTerminated, Code);
    Log(Format('Git installer exit code: %d', [Code]));
    DeleteFile(Tmp + '\GitSetup.exe');
  end;

  { ---- Crane ---- }
  if WizardIsComponentSelected('crane') then
  begin
    Log('Extracting Crane...');
    Exec(TarExe, Format('-xzf "%s\crane.tar.gz" -C "%s\crane"', [Tmp, App]), Tmp, SW_HIDE, ewWaitUntilTerminated, Code);
    Log(Format('Crane tar exit code: %d', [Code]));
    DeleteFile(Tmp + '\crane.tar.gz');
  end;

  { ---- XMouse Button Control ---- }
  if WizardIsComponentSelected('xmouse') then
  begin
    Log('Extracting XMouse...');
    Exec(TarExe, Format('-xf "%s\XMousePortable.zip" -C "%s\xmouse"', [Tmp, App]), Tmp, SW_HIDE, ewWaitUntilTerminated, Code);
    if Code <> 0 then
    begin
      { Fallback: not a zip, just copy the file as-is }
      ForceDirectories(App + '\xmouse');
      CopyFile(Tmp + '\XMousePortable.zip', App + '\xmouse\XMouseButtonControl.exe', False);
    end;
    Log(Format('XMouse exit code: %d', [Code]));
    DeleteFile(Tmp + '\XMousePortable.zip');
  end;
end;
