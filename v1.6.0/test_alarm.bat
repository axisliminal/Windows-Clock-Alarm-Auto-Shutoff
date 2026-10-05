@echo off
setlocal
echo ========================================================
echo  AlarmAutoDismiss - Test Alarm (10-Second Auto-Shutoff)
echo ========================================================
echo This will play a sample alarm sound with a test toast.
echo It should automatically shut off after 10 seconds.
echo.

powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0AlarmAutoDismiss.ps1" -Action test -TestSeconds 10

echo.
pause
endlocal
