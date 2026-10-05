================================================================================
  Windows Clock Alarm Auto-Shutoff - Prototype v1.0 (C# / .NET 4.8)
================================================================================

OVERVIEW
--------------------------------------------------------------------------------
This folder contains the original v1.0 compiled prototype implemented in C# 5.0
targeting .NET Framework 4.8 with native WinRT COM interop.

ARCHITECTURAL NOTES & RETIREMENT RATIONALE
--------------------------------------------------------------------------------
1. Why C# was initially chosen:
   - Compiled to native win32 winexe executable with zero console window.
   - Interfaced with Windows.UI.Notifications.Management.UserNotificationListener
     using ManualResetEvent WinRT synchronization.

2. Why C# was superseded in v1.1+:
   - Windows 11 Smart App Control (SAC) / Device Guard enforcement mode
     (VerifiedAndReputablePolicyState: 1) blocks unsigned binaries with Code
     Integrity Event 3076/3077 warnings.
   - To achieve 100% SAC compliance with zero UAC elevation and zero security
     warnings, the architecture was migrated to Microsoft-signed powershell.exe
     with hidden window style.

FILES IN THIS DIRECTORY
--------------------------------------------------------------------------------
* AlarmAutoDismiss.cs        : Native C# 5.0 WinRT COM notification monitor.
* build.bat                  : Builds the C# source using native .NET 4.8 csc.exe.
* create_shortcut.ps1        : WScript shell Desktop shortcut generator.
* create_desktop_shortcut.bat: Wrapper for desktop shortcut creation.
* install_startup.bat        : Legacy registry HKCU\...\Run startup registration.
* uninstall_startup.bat      : Legacy registry startup removal script.
================================================================================
