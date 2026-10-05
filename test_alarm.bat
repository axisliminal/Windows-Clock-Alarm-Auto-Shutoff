@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"
set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "DAEMON=%~dp0src\AlarmAutoDismiss.ps1"
if not exist "%DAEMON%" set "DAEMON=%~dp0AlarmAutoDismiss.ps1"

echo ========================================================
echo  AlarmAutoDismiss - Test Alarm (10-Second Auto-Shutoff)
echo ========================================================
echo This will play a sample alarm sound with a test toast.
echo It should automatically shut off after 10 seconds.
echo.

"%PS_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%DAEMON%" -Action test -TestSeconds 10

echo.
pause
endlocal
