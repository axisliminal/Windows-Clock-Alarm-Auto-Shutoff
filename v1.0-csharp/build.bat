@echo off
setlocal
echo ========================================================
echo  Building AlarmAutoDismiss (Zero-Dependency C# Build)
echo ========================================================

set CSC="C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"

if not exist %CSC% (
    echo ERROR: .NET Framework compiler csc.exe not found at %CSC%
    pause
    exit /b 1
)

echo Compiling AlarmAutoDismiss.cs targeting winexe (headless)...

%CSC% /target:winexe /optimize+ /nologo ^
  /r:System.dll ^
  /r:C:\Windows\Microsoft.NET\Framework64\v4.0.30319\System.Runtime.dll ^
  /r:C:\Windows\System32\WinMetadata\Windows.Foundation.winmd ^
  /r:C:\Windows\System32\WinMetadata\Windows.UI.winmd ^
  /r:C:\Windows\System32\WinMetadata\Windows.Data.winmd ^
  /r:C:\Windows\System32\WinMetadata\Windows.ApplicationModel.winmd ^
  /out:"%~dp0AlarmAutoDismiss.exe" "%~dp0AlarmAutoDismiss.cs"

if %ERRORLEVEL% equ 0 (
    echo.
    echo [SUCCESS] Build succeeded! Created AlarmAutoDismiss.exe
    echo Binary: %~dp0AlarmAutoDismiss.exe
) else (
    echo.
    echo [FAILED] Compilation failed with error code %ERRORLEVEL%.
    pause
    exit /b %ERRORLEVEL%
)

endlocal
