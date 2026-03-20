; Internet QuickKit Installer
; Compile with Inno Setup 6+ (https://jrsoftware.org/isinfo.php)
;
; Downloads and silently installs selected tools.
; Uses urlmon.dll for downloads — no PowerShell, no CMD.

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
  XMouseURL = 'https://dvps.highrez.co.uk/downloads/XMouseButtonControl%202.20.5%20Portable.zip';

function URLDownloadToFile(pCaller: Integer; szURL, szFileName: string; Reserved: Integer; StatusCB: Integer): Integer;
  external 'URLDownloadToFileW@urlmon.dll stdcall';

function DeleteUrlCacheEntry(lpszUrlName: string): Boolean;
  external 'DeleteUrlCacheEntryW@wininet.dll stdcall';

var
  ProgressPage: TOutputProgressWizardPage;

function DoDownload(const URL, Dest, DisplayName: string): Boolean;
var
  Res: Integer;
begin
  DeleteUrlCacheEntry(URL);
  Log(Format('Downloading %s from %s', [DisplayName, URL]));
  Res := URLDownloadToFile(0, URL, Dest, 0, 0);
  Result := (Res = 0);
  if Result then
    Log(Format('Downloaded %s OK', [DisplayName]))
  else
    Log(Format('Download FAILED for %s, HRESULT=%d', [DisplayName, Res]));
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  Tmp, App: string;
  Done, Total, Code: Integer;
begin
  if CurStep <> ssPostInstall then
    Exit;

  Tmp := ExpandConstant('{tmp}');
  App := ExpandConstant('{app}');
  Done  := 0;
  Total := 0;

  if WizardIsComponentSelected('git')    then Total := Total + 2;
  if WizardIsComponentSelected('crane')  then Total := Total + 2;
  if WizardIsComponentSelected('xmouse') then Total := Total + 2;
  if Total = 0 then Exit;

  ProgressPage := CreateOutputProgressPage(
    'Installing Tools',
    'Downloading and installing selected components...');
  ProgressPage.Show;
  try

    { ---- Git for Windows ---- }
    if WizardIsComponentSelected('git') then
    begin
      ProgressPage.SetText('Downloading Git for Windows...', 'This may take a few minutes');
      ProgressPage.SetProgress(Done, Total);

      if DoDownload(GitURL, Tmp + '\GitSetup.exe', 'Git') then
      begin
        Done := Done + 1;
        ProgressPage.SetText('Installing Git for Windows (silent)...', '');
        ProgressPage.SetProgress(Done, Total);
        Exec(Tmp + '\GitSetup.exe', '/VERYSILENT /NORESTART /NOCANCEL /SP- /CURRENTUSER', Tmp, SW_HIDE, ewWaitUntilTerminated, Code);
        DeleteFile(Tmp + '\GitSetup.exe');
      end
      else
        MsgBox('Failed to download Git for Windows. Skipping.', mbError, MB_OK);

      Done := Done + 1;
    end;

    { ---- Crane ---- }
    if WizardIsComponentSelected('crane') then
    begin
      ProgressPage.SetText('Downloading Crane...', 'This may take a minute');
      ProgressPage.SetProgress(Done, Total);

      if DoDownload(CraneURL, Tmp + '\crane.tar.gz', 'Crane') then
      begin
        Done := Done + 1;
        ProgressPage.SetText('Extracting Crane...', App + '\crane');
        ProgressPage.SetProgress(Done, Total);
        Exec(ExpandConstant('{sys}\tar.exe'), Format('-xzf "%s\crane.tar.gz" -C "%s\crane"', [Tmp, App]), Tmp, SW_HIDE, ewWaitUntilTerminated, Code);
        DeleteFile(Tmp + '\crane.tar.gz');
      end
      else
        MsgBox('Failed to download Crane. Skipping.', mbError, MB_OK);

      Done := Done + 1;
    end;

    { ---- XMouse Button Control ---- }
    if WizardIsComponentSelected('xmouse') then
    begin
      ProgressPage.SetText('Downloading XMouse Button Control...', 'This may take a minute');
      ProgressPage.SetProgress(Done, Total);

      if DoDownload(XMouseURL, Tmp + '\XMousePortable.zip', 'XMouse') then
      begin
        Done := Done + 1;
        ProgressPage.SetText('Extracting XMouse Button Control...', App + '\xmouse');
        ProgressPage.SetProgress(Done, Total);
        Exec(ExpandConstant('{sys}\tar.exe'), Format('-xf "%s\XMousePortable.zip" -C "%s\xmouse"', [Tmp, App]), Tmp, SW_HIDE, ewWaitUntilTerminated, Code);
        if Code <> 0 then
        begin
          ForceDirectories(App + '\xmouse');
          CopyFile(Tmp + '\XMousePortable.zip', App + '\xmouse\XMouseButtonControl.exe', False);
        end;
        DeleteFile(Tmp + '\XMousePortable.zip');
      end
      else
        MsgBox('Failed to download XMouse Button Control. Skipping.', mbError, MB_OK);

      Done := Done + 1;
    end;

    ProgressPage.SetText('Done!', '');
    ProgressPage.SetProgress(Total, Total);

  finally
    ProgressPage.Hide;
  end;
end;
