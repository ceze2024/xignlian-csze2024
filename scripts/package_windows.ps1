# Create output directories
New-Item -ItemType Directory -Force -Name "dist\tmp" | Out-Null
New-Item -ItemType Directory -Force -Name "out" | Out-Null
New-Item -ItemType Directory -Force -Name "dist\1.1.2+20507" | Out-Null

# Copy setup files from flutter_distributor outputs or directly from build
if (Test-Path "dist\*\*.exe") {
    Get-ChildItem -Recurse -File -Path "dist" -Filter "*.exe" | Copy-Item -Destination "out\starlink-Windows-Setup-x64.exe" -ErrorAction SilentlyContinue
} else {
    # Check if we're in a GitHub Actions environment
    $isGitHubActions = $env:GITHUB_ACTIONS -eq "true"
    Write-Host "Is GitHub Actions: $isGitHubActions"
    
    # If no exe found from distributor, create inno setup file and call innosetup directly
    if (Test-Path "C:\Program Files (x86)\Inno Setup 6\ISCC.exe") {
        # Create a simplified .iss file for CI environment to avoid language issues
        if ($isGitHubActions) {
            $issContent = @"
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
"@
            Set-Content -Path "dist\1.1.2+20507\direct.iss" -Value $issContent
            Write-Host "Created simplified direct.iss file for GitHub Actions environment"
            
            # Compile the direct ISS file
            & "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" "dist\1.1.2+20507\direct.iss"
            if (Test-Path "dist\1.1.2+20507\hiddify-setup.exe") {
                Copy-Item "dist\1.1.2+20507\hiddify-setup.exe" -Destination "out\starlink-Windows-Setup-x64.exe"
                Write-Host "Successfully created installer using direct.iss"
            } else {
                Write-Host "Failed to create installer using direct.iss"
            }
        } else {
            # Use the standard approach for local builds
            & "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" "dist\1.1.2+20507\hiddify-1.1.2+20507-windows-setup_exe.iss"
            if (Test-Path "dist\1.1.2+20507\hiddify-setup.exe") {
                Copy-Item "dist\1.1.2+20507\hiddify-setup.exe" -Destination "out\starlink-Windows-Setup-x64.exe"
            }
        }
    } else {
        Write-Host "Inno Setup not found at C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
    }
}

# Copy MSIX if available
Get-ChildItem -Recurse -File -Path "dist" -Filter "*.msix" | Copy-Item -Destination "out\starlink-Windows-Setup-x64.msix" -ErrorAction SilentlyContinue

# Create portable version
xcopy "build\windows\x64\runner\Release" "dist\tmp\starlink" /E/H/C/I/Y
xcopy ".github\help\mac-windows\*.url" "dist\tmp\starlink" /E/H/C/I/Y
Compress-Archive -Force -Path "dist\tmp\starlink" -DestinationPath "out\starlink-Windows-Portable-x64.zip" -ErrorAction SilentlyContinue

# Cleanup
Remove-Item -Path "$HOME\.pub-cache\git\cache\flutter_circle_flags*" -Force -Recurse -ErrorAction SilentlyContinue

Write-Host "Done"