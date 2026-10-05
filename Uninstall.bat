@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"
set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
title Alarm Auto-Shutoff - Uninstall

if /i "%~1"=="/silent" goto :proceed
if /i "%~1"=="-silent" goto :proceed

echo ========================================================
echo   Windows Clock Alarm Auto-Shutoff - Uninstall
echo ========================================================
echo.
echo This will stop the background service, remove auto-start,
echo delete Desktop & Start Menu shortcuts, and clean up files.
echo.
"%SystemRoot%\System32\choice.exe" /C YN /M "Are you sure you want to completely uninstall Alarm Auto-Shutoff?"
if errorlevel 2 goto :cancel
if errorlevel 1 goto :proceed

:proceed
echo.
echo Uninstalling...
"%PS_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$currSession=[System.Diagnostics.Process]::GetCurrentProcess().SessionId; Get-CimInstance Win32_Process|Where-Object{$_.Name -match '^powershell\.exe$' -and $_.SessionId -eq $currSession -and $_.CommandLine -like '*AlarmAutoDismiss.ps1*' -and $_.CommandLine -notlike '*-Action*' -and $_.ProcessId -ne $PID}|ForEach-Object{Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue}; Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'AlarmAutoDismiss' -Force -ErrorAction SilentlyContinue; Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run' -Name 'AlarmAutoDismiss' -Force -ErrorAction SilentlyContinue; foreach($dir in @([Environment]::GetFolderPath('Desktop'),[Environment]::GetFolderPath('Programs'))){$lnk=Join-Path $dir 'Alarm Auto-Shutoff Settings.lnk'; if(Test-Path $lnk){Remove-Item $lnk -Force -ErrorAction SilentlyContinue}}; Write-Host 'Service stopped, auto-start and shortcuts removed.' -ForegroundColor Green"

set "CURRDIR=%~dp0"
set "TARGETAPP=%LOCALAPPDATA%\AlarmAutoDismiss\"
if /i "%CURRDIR%"=="%TARGETAPP%" (
    echo Cleaning up installation files...
    "%PS_EXE%" -NoProfile -Command "Start-Sleep -Seconds 2"
    start "" "%SystemRoot%\System32\cmd.exe" /c rd /s /q "%LOCALAPPDATA%\AlarmAutoDismiss"
    exit
)
goto :done

:cancel
echo.
echo Uninstallation cancelled. No changes made.
goto :done

:done
echo.
pause

endlocal
