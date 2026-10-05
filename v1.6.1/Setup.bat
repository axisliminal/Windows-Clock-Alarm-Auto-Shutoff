@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"
set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
title Alarm Auto-Shutoff - 1-Click Setup

if /i "%~1"=="/silent" goto :silent
if /i "%~1"=="-silent" goto :silent
if /i "%~1"=="/s" goto :silent
if /i "%~1"=="/portable" goto :portable
if /i "%~1"=="-portable" goto :portable
if /i "%~1"=="/p" goto :portable

echo ========================================================
echo   Windows Clock Alarm Auto-Shutoff - Setup (v1.6.1)
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
"%PS_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Setup.ps1"
goto :done

:portable
echo.
"%PS_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Setup.ps1" -Portable
goto :done

:silent
"%PS_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Setup.ps1" -Silent -NoGui
goto :end

:cancel
echo.
echo Setup cancelled. No changes were made.
goto :done

:done
echo.
pause

:end
endlocal
