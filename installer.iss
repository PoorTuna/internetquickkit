; Internet QuickKit Installer
; Compile with Inno Setup 6+ (https://jrsoftware.org/isinfo.php)
;
; Downloads and silently installs selected tools:
;   - Git for Windows (per-user, silent)
;   - Crane (Google Container Registry CLI, extracted)
;   - XMouse Button Control (Portable, extracted)

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
  ProgressPage: TOutputProgressWizardPage;

function RunHidden(const Exe, Params: string): Integer;
var
  Code: Integer;
begin
  if Exec(Exe, Params, '', SW_HIDE, ewWaitUntilTerminated, Code) then
    Result := Code
  else
    Result := -1;
  Log(Format('Exec [%d]: %s %s', [Result, Exe, Params]));
end;

function Download(const URL, DestPath: string): Boolean;
begin
  Result := RunHidden('curl.exe',
    Format('-L --silent --fail -o "%s" "%s"', [DestPath, URL])) = 0;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  Tmp, App: string;
  Done, Total: Integer;
begin
  if CurStep <> ssPostInstall then
    Exit;

  Tmp := ExpandConstant('{tmp}');
  App := ExpandConstant('{app}');
  Done  := 0;
  Total := 0;

  if IsComponentSelected('git')    then Total := Total + 2;
  if IsComponentSelected('crane')  then Total := Total + 2;
  if IsComponentSelected('xmouse') then Total := Total + 2;
  if Total = 0 then Exit;

  ProgressPage := CreateOutputProgressPage(
    'Installing Tools',
    'Downloading and installing selected components...');
  ProgressPage.Show;
  try

    { ================================================================ }
    {  Git for Windows                                                  }
    { ================================================================ }
    if IsComponentSelected('git') then
    begin
      ProgressPage.SetText('Downloading Git for Windows...', GitURL);
      ProgressPage.SetProgress(Done, Total);

      if Download(GitURL, Tmp + '\GitSetup.exe') then
      begin
        ProgressPage.SetText('Installing Git for Windows (silent)...', '');
        ProgressPage.SetProgress(Done + 1, Total);
        RunHidden(Tmp + '\GitSetup.exe',
          '/VERYSILENT /NORESTART /NOCANCEL /SP- /CURRENTUSER');
        DeleteFile(Tmp + '\GitSetup.exe');
      end
      else
        MsgBox('Failed to download Git for Windows. Skipping.',
          mbError, MB_OK);

      Done := Done + 2;
    end;

    { ================================================================ }
    {  Crane                                                            }
    { ================================================================ }
    if IsComponentSelected('crane') then
    begin
      ProgressPage.SetText('Downloading Crane...', CraneURL);
      ProgressPage.SetProgress(Done, Total);

      if Download(CraneURL, Tmp + '\crane.tar.gz') then
      begin
        ProgressPage.SetText('Extracting Crane...', App + '\crane');
        ProgressPage.SetProgress(Done + 1, Total);
        RunHidden('tar.exe',
          Format('-xzf "%s\crane.tar.gz" -C "%s\crane"', [Tmp, App]));
        DeleteFile(Tmp + '\crane.tar.gz');
      end
      else
        MsgBox('Failed to download Crane. Skipping.',
          mbError, MB_OK);

      Done := Done + 2;
    end;

    { ================================================================ }
    {  XMouse Button Control                                            }
    { ================================================================ }
    if IsComponentSelected('xmouse') then
    begin
      ProgressPage.SetText('Downloading XMouse Button Control...', XMouseURL);
      ProgressPage.SetProgress(Done, Total);

      if Download(XMouseURL, Tmp + '\XMousePortable.zip') then
      begin
        ProgressPage.SetText('Extracting XMouse Button Control...', App + '\xmouse');
        ProgressPage.SetProgress(Done + 1, Total);

        if RunHidden('powershell.exe', Format('-NoProfile -Command "Expand-Archive -Path ''%s\XMousePortable.zip'' -DestinationPath ''%s\xmouse'' -Force"', [Tmp, App])) <> 0 then
        begin
          { Fallback: file may be a standalone exe rather than a zip }
          ForceDirectories(App + '\xmouse');
          FileCopy(Tmp + '\XMousePortable.zip',
            App + '\xmouse\XMouseButtonControl.exe', False);
        end;

        DeleteFile(Tmp + '\XMousePortable.zip');
      end
      else
        MsgBox('Failed to download XMouse Button Control. Skipping.',
          mbError, MB_OK);

      Done := Done + 2;
    end;

    ProgressPage.SetText('Done!', '');
    ProgressPage.SetProgress(Total, Total);

  finally
    ProgressPage.Hide;
  end;
end;
