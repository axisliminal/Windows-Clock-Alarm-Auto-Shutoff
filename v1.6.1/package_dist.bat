@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"
set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
title Alarm Auto-Shutoff - Build Release Package

echo ========================================================
echo   Alarm Auto-Shutoff - Packaging Release v1.6.1
echo ========================================================
echo.

"%PS_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0dev\package_dist.ps1"

echo.
pause
endlocal
