# Create output directories
New-Item -ItemType Directory -Force -Name "dist\tmp" | Out-Null
New-Item -ItemType Directory -Force -Name "out" | Out-Null
New-Item -ItemType Directory -Force -Name "dist\1.1.2+20507" | Out-Null

# Copy setup files from flutter_distributor outputs or directly from build
if (Test-Path "dist\*\*.exe") {
    Get-ChildItem -Recurse -File -Path "dist" -Filter "*.exe" | Copy-Item -Destination "out\starlink-Windows-Setup-x64.exe" -ErrorAction SilentlyContinue
} else {
    # If no exe found from distributor, create inno setup file and call innosetup directly
    if (Test-Path "C:\Program Files (x86)\Inno Setup 6\ISCC.exe") {
        & "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" "dist\1.1.2+20507\hiddify-1.1.2+20507-windows-setup_exe.iss"
        if (Test-Path "dist\1.1.2+20507\hiddify-setup.exe") {
            Copy-Item "dist\1.1.2+20507\hiddify-setup.exe" -Destination "out\starlink-Windows-Setup-x64.exe"
        }
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