@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"
set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
title Alarm Auto-Shutoff - Setup

if /i "%~1"=="/silent" goto :silent
if /i "%~1"=="-silent" goto :silent
if /i "%~1"=="/portable" goto :portable
if /i "%~1"=="-portable" goto :portable

echo ========================================================
echo   Windows Clock Alarm Auto-Shutoff - Setup
echo ========================================================
echo.
echo Choose your preferred setup option:
echo.
echo   [1] Standard Installation (Recommended)
echo       Installs to: %%LOCALAPPDATA%%\AlarmAutoDismiss
echo       Creates Desktop and Start Menu shortcuts, enables
echo       auto-start on Windows login, and starts the service.
echo.
echo   [2] Portable / In-Place Setup
echo       Runs directly from this folder without copying files.
echo       Creates Desktop shortcut and sets auto-start.
echo.
echo   [3] Cancel
echo.
echo ========================================================
choice /C 123 /N /M "Select an option [1, 2, or 3]: "
if errorlevel 3 goto :cancel
if errorlevel 2 goto :portable
if errorlevel 1 goto :standard

:standard
echo.
echo Installing Alarm Auto-Shutoff...
"%PS_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$src='%~dp0'.TrimEnd('\'); $dst=Join-Path $env:LOCALAPPDATA 'AlarmAutoDismiss'; if(-not(Test-Path $dst)){New-Item -ItemType Directory -Path $dst -Force|Out-Null}; Get-CimInstance Win32_Process|Where-Object{$_.CommandLine -like '*AlarmAutoDismiss.ps1*'}|ForEach-Object{Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue}; Copy-Item -Path (Join-Path $src '*') -Destination $dst -Recurse -Force; $wsh=New-Object -ComObject WScript.Shell; $dPath=[Environment]::GetFolderPath('Desktop'); $pPath=[Environment]::GetFolderPath('Programs'); foreach($dir in @($dPath,$pPath)){$sc=$wsh.CreateShortcut((Join-Path $dir 'Alarm Auto-Shutoff Settings.lnk')); $sc.TargetPath=Join-Path $dst 'AlarmSettings.bat'; $sc.WorkingDirectory=$dst; $sc.Description='Alarm Auto-Shutoff Control Panel'; $sc.IconLocation='shell32.dll,238'; $sc.Save()}; $dScript=Join-Path $dst 'src\AlarmAutoDismiss.ps1'; if(-not(Test-Path $dScript)){$dScript=Join-Path $dst 'AlarmAutoDismiss.ps1'}; $runCmd='\"' + $env:SystemRoot + '\System32\WindowsPowerShell\v1.0\powershell.exe\" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File \"' + $dScript + '\"'; Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'AlarmAutoDismiss' -Value $runCmd -Type String -Force; Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run' -Name 'AlarmAutoDismiss' -Force -ErrorAction SilentlyContinue; Start-Process -FilePath ($env:SystemRoot + '\System32\WindowsPowerShell\v1.0\powershell.exe') -ArgumentList ('-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File \"' + $dScript + '\"'); Write-Host 'Installation successful!' -ForegroundColor Green"
echo.
echo Starting Control Panel...
start "" "%~dp0AlarmSettings.bat"
goto :done

:portable
echo.
echo Configuring Portable Setup...
"%PS_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$dst='%~dp0'.TrimEnd('\'); Get-CimInstance Win32_Process|Where-Object{$_.CommandLine -like '*AlarmAutoDismiss.ps1*'}|ForEach-Object{Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue}; $wsh=New-Object -ComObject WScript.Shell; $dPath=[Environment]::GetFolderPath('Desktop'); $sc=$wsh.CreateShortcut((Join-Path $dPath 'Alarm Auto-Shutoff Settings.lnk')); $sc.TargetPath=Join-Path $dst 'AlarmSettings.bat'; $sc.WorkingDirectory=$dst; $sc.Description='Alarm Auto-Shutoff Control Panel'; $sc.IconLocation='shell32.dll,238'; $sc.Save(); $dScript=Join-Path $dst 'src\AlarmAutoDismiss.ps1'; if(-not(Test-Path $dScript)){$dScript=Join-Path $dst 'AlarmAutoDismiss.ps1'}; $runCmd='\"' + $env:SystemRoot + '\System32\WindowsPowerShell\v1.0\powershell.exe\" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File \"' + $dScript + '\"'; Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'AlarmAutoDismiss' -Value $runCmd -Type String -Force; Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run' -Name 'AlarmAutoDismiss' -Force -ErrorAction SilentlyContinue; Start-Process -FilePath ($env:SystemRoot + '\System32\WindowsPowerShell\v1.0\powershell.exe') -ArgumentList ('-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File \"' + $dScript + '\"'); Write-Host 'Portable setup configured!' -ForegroundColor Green"
echo.
echo Starting Control Panel...
start "" "%~dp0AlarmSettings.bat"
goto :done

:silent
"%PS_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$src='%~dp0'.TrimEnd('\'); $dst=Join-Path $env:LOCALAPPDATA 'AlarmAutoDismiss'; if(-not(Test-Path $dst)){New-Item -ItemType Directory -Path $dst -Force|Out-Null}; Get-CimInstance Win32_Process|Where-Object{$_.CommandLine -like '*AlarmAutoDismiss.ps1*'}|ForEach-Object{Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue}; Copy-Item -Path (Join-Path $src '*') -Destination $dst -Recurse -Force; $dScript=Join-Path $dst 'src\AlarmAutoDismiss.ps1'; if(-not(Test-Path $dScript)){$dScript=Join-Path $dst 'AlarmAutoDismiss.ps1'}; $runCmd='\"' + $env:SystemRoot + '\System32\WindowsPowerShell\v1.0\powershell.exe\" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File \"' + $dScript + '\"'; Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'AlarmAutoDismiss' -Value $runCmd -Type String -Force; Start-Process -FilePath ($env:SystemRoot + '\System32\WindowsPowerShell\v1.0\powershell.exe') -ArgumentList ('-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File \"' + $dScript + '\"')"
goto :end

:cancel
echo.
echo Setup cancelled. No changes made.
goto :done

:done
echo.
pause

:end
endlocal
