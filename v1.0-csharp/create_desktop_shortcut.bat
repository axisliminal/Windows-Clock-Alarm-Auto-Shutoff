@echo off
setlocal
echo Creating Desktop shortcut for Alarm Auto-Shutoff Control Panel...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0create_shortcut.ps1"
echo.
pause
endlocal
