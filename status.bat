@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"
set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

"%PS_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0AlarmAutoDismiss.ps1" -Action status
if %ERRORLEVEL% NEQ 0 (
    echo.
    choice /C YN /M "Daemon is STOPPED. Start it now?"
    if errorlevel 2 goto :done
    if errorlevel 1 (
        echo.
        echo Starting Alarm Auto-Shutoff daemon in background...
        start "" "%PS_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0AlarmAutoDismiss.ps1"
        timeout /t 2 /nobreak >nul
        "%PS_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0AlarmAutoDismiss.ps1" -Action status
    )
)
:done
echo.
pause
endlocal
