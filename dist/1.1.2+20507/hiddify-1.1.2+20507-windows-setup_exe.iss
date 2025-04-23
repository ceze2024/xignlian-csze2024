[Setup]
AppId=6L903538-42B1-4596-G479-BJ779F21A65D
AppVersion=1.1.2+20507
AppName=星链
AppPublisher=星链
AppPublisherURL=https://github.com/hiddify/hiddify-next
AppSupportURL=https://github.com/hiddify/hiddify-next
AppUpdatesURL=https://github.com/hiddify/hiddify-next
DefaultDirName={autopf64}\Hiddify
DisableProgramGroupPage=yes
OutputDir=.
OutputBaseFilename=hiddify-setup
Compression=lzma
SolidCompression=yes
SetupIconFile=D:\a\xignlian-csze2024\xignlian-csze2024\windows\runner\resources\app_icon.ico
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
CloseApplications=force

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce
Name: "launchAtStartup"; Description: "{cm:AutoStartProgram,星链}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\星链"; Filename: "{app}\Hiddify.exe"
Name: "{autodesktop}\星链"; Filename: "{app}\Hiddify.exe"; Tasks: desktopicon
Name: "{userstartup}\星链"; Filename: "{app}\Hiddify.exe"; WorkingDir: "{app}"; Tasks: launchAtStartup

[Run]
Filename: "{app}\Hiddify.exe"; Description: "{cm:LaunchProgram,星链}"; Flags: runascurrentuser nowait postinstall skipifsilent

[Code]
function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Exec('taskkill', '/F /IM Hiddify.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec('net', 'stop "HiddifyTunnelService"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec('sc.exe', 'delete "HiddifyTunnelService"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := True;
end; 