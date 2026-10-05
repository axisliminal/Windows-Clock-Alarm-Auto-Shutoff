---
title: Architectural Constraints and Platform Boundaries
description: Enforces zero-dependency native Windows toolchain, user-space execution, and resource limits.
trigger: always_on
---

# Architectural Constraints

## 1. Zero-Dependency Mandate
- Rely exclusively on tools already installed on standard Windows 10/11:
  - Runtime: Microsoft-signed `powershell.exe` (Windows PowerShell 5.1)
  - Compiler: `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe`
  - WinRT System Metadata: `C:\Windows\System32\WinMetadata\`
  - Core .NET Assemblies: `mscorlib.dll`, `System.dll`, `System.Windows.Forms.dll`, `System.Drawing.dll`, `System.Runtime.dll`, `System.Runtime.WindowsRuntime.dll`, `PresentationFramework.dll`
- Never require or assume external package managers, Python runtimes, Node.js, or external installer packages.

## 2. Privilege Isolation
- Run in standard user privilege mode.
- Do not require Administrator privileges (`UAC` elevation).
- The Windows Notification platform API (`UserNotificationListener`) operates in user space and has verified `Allowed` status.
- Windows Task Scheduler (`schtasks.exe /Create` and `Register-ScheduledTask`) requires administrative elevation on Windows 11 Build 26100 and fails with `Access is denied (0x80070005)`. To preserve standard user isolation, autostart is managed via `HKCU\...\Run` and power/session lifecycle triggers are handled via native `Microsoft.Win32.SystemEvents`.

## 3. Resource & Footprint Targets
- Idle CPU usage must remain near 0%.
- Enable Windows 11 EcoQoS (Efficiency Mode) using `PROCESS_POWER_THROTTLING_EXECUTION_SPEED` and `IGNORE_TIMER_RESOLUTION`.
- Active working set RAM footprint should remain between 5.5MB and 20MB, achieved via steady-state and post-wake working set compaction (`SetProcessWorkingSetSize(-1, -1)`).
- Background polling loops must sleep between checks (recommended interval: 2 seconds).
