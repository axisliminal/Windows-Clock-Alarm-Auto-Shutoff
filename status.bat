@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"
set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "DAEMON=%~dp0src\AlarmAutoDismiss.ps1"
if not exist "%DAEMON%" set "DAEMON=%~dp0AlarmAutoDismiss.ps1"

"%PS_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%DAEMON%" -Action status
if %ERRORLEVEL% NEQ 0 (
    echo.
    "%SystemRoot%\System32\choice.exe" /C YN /M "Daemon is STOPPED. Start it now?"
    if errorlevel 2 goto :done
    if errorlevel 1 (
        echo.
        echo Starting Alarm Auto-Shutoff daemon in background...
        start "" "%PS_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "%DAEMON%"
        "%PS_EXE%" -NoProfile -Command "Start-Sleep -Seconds 2"
        "%PS_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%DAEMON%" -Action status
    )
)
:done
echo.
pause
endlocal
