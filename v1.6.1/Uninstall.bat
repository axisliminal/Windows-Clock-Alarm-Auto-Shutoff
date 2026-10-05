@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"
set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
title Alarm Auto-Shutoff - Uninstaller

if /i "%~1"=="/silent" goto :silent
if /i "%~1"=="-silent" goto :silent
if /i "%~1"=="/s" goto :silent

echo ========================================================
echo   Windows Clock Alarm Auto-Shutoff - Uninstall
echo ========================================================
echo.
echo This will stop the background service, remove auto-start,
echo delete Desktop & Start Menu shortcuts, and clean up files.
echo.
choice /C YN /M "Are you sure you want to completely uninstall Alarm Auto-Shutoff?"
if errorlevel 2 goto :cancel
if errorlevel 1 goto :proceed

:proceed
echo.
"%PS_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Uninstall.ps1"
set "CURRDIR=%~dp0"
set "TARGETAPP=%LOCALAPPDATA%\AlarmAutoDismiss\"
if /i "%CURRDIR%"=="%TARGETAPP%" (
    echo.
    echo Uninstallation complete. Terminal will exit to release directory lock...
    timeout /t 2 /nobreak >nul
    exit
)
goto :done

:silent
"%PS_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Uninstall.ps1" -Silent
goto :end

:cancel
echo.
echo Uninstallation cancelled. No changes were made.
goto :done

:done
echo.
pause

:end
endlocal
