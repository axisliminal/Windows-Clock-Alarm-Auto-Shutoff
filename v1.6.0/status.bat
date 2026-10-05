@echo off
setlocal
powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0AlarmAutoDismiss.ps1" -Action status
if %ERRORLEVEL% NEQ 0 (
    echo.
    choice /C YN /M "Daemon is STOPPED. Start it now?"
    if errorlevel 2 goto :done
    if errorlevel 1 (
        echo.
        echo Starting Alarm Auto-Shutoff daemon in background...
        start "" powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0AlarmAutoDismiss.ps1"
        timeout /t 2 /nobreak >nul
        powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0AlarmAutoDismiss.ps1" -Action status
    )
)
:done
echo.
pause
endlocal
