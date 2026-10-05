# Windows Clock Alarm Auto-Shutoff

[![Windows 11 / 10](https://img.shields.io/badge/Platform-Windows%2011%20%7C%2010-0078D4?logo=windows&logoColor=white)](https://microsoft.com/windows)
[![Zero Dependencies](https://img.shields.io/badge/Dependencies-Zero%20External-success.svg)](https://github.com/axisliminal/Windows-Clock-Alarm-Auto-Shutoff)
[![PowerShell 5.1 / .NET 4.8](https://img.shields.io/badge/Runtime-PowerShell%205.1%20%2F%20.NET%204.8-blue.svg)](https://learn.microsoft.com/powershell/)
[![Smart App Control](https://img.shields.io/badge/Security-Smart%20App%20Control%20Compliant-brightgreen.svg)](SECURITY.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> A lightweight, 100% invisible Windows utility with an on-demand Fluent WinUI Control Panel that automatically silences and dismisses ringing Windows Clock alarms and countdown timers after a configurable duration.

---

## The Problem

The native Windows Clock application (`Microsoft.WindowsAlarms`) lacks an automatic shutoff feature. When an alarm or countdown timer fires, it continuously loops loud audio and keeps an on-screen toast banner open indefinitely until someone manually clicks Dismiss or Snooze.

If you step away from your workstation, take a call, leave the room, or sleep through an alarm, your computer rings endlessly.

## The Solution

**Windows Clock Alarm Auto-Shutoff** runs silently in the background, continuously monitoring for active notifications originating exclusively from the Windows Clock app. When an alarm or timer rings past your chosen threshold (e.g., 5 minutes for alarms, 1 minute for countdown timers), it programmatically dismisses the alert—instantly halting the looping audio and clearing the notification.

---

## Key Features

- **100% Headless & Invisible:** Runs completely in the background without persistent console windows, tray icons, or taskbar buttons.
- **On-Demand WinUI Control Panel:** Clean, modern Windows 11 Fluent dark-mode dashboard featuring authentic DWM Mica glass styling. Launch it to configure settings or test your setup, and close it when done—leaving zero UI processes behind.
- **Smart Idle Gating (Optional):** Senses user activity via Win32 `GetLastInputInfo`. If you are actively typing or moving the mouse, shutoff is temporarily paused (up to a safe 60-second grace ceiling) so your active workflow is not disrupted. (Disabled by default for deterministic shutoff).
- **Differentiated Alarm & Timer Thresholds:** Automatically inspects notification payloads to apply independent timeouts for countdown timers (e.g. 60 seconds) versus morning wake-up alarms (e.g. 5 minutes).
- **Silent Missed-Alarm Retention:** When an alarm is auto-silenced, the utility can post an optional quiet, non-looping reminder in Windows Action Center (`Missed Clock Alarm`) so you know what fired while you were away.
- **EcoQoS Efficiency Mode:** Opts into Windows 11 Efficiency Mode (`PROCESS_POWER_THROTTLING_EXECUTION_SPEED`) and performs working set compaction, idling at near 0% CPU and only **~5.5MB–16MB RAM**.
- **Self-Healing Power Watchdog:** Hooks native Windows power and session events (`PowerModeChanged`, `SessionSwitch`) to wake immediately from sleep, Modern Standby, or workstation unlock and re-evaluate ringing alerts.
- **Zero External Dependencies:** Built entirely with native Windows components (WinRT `UserNotificationListener`, native PowerShell 5.1, and .NET Framework 4.8). No Python, Node.js, external binaries, or package managers required.
- **Smart App Control (SAC) Compliant:** Runs inside Microsoft-signed system processes (`powershell.exe`) with zero Device Guard blocks or untrusted executable warnings.
- **Standard User Privilege:** Operates entirely within standard user permissions. Never requires Administrator (`UAC`) elevation.

---

## Quick Start & Installation

### Option 1: 1-Click Automated Setup (Recommended)

1. Download or clone this repository, or grab the latest release archive (`AlarmAutoDismiss-v1.6.1.zip`).
2. Double-click **`Setup.bat`**.
3. Choose your installation mode:
   - **`[1] Standard Installation`**: Deploys cleanly to `%LOCALAPPDATA%\AlarmAutoDismiss`, creates Desktop and Start Menu shortcuts, registers user login auto-start, and immediately launches the background service.
   - **`[2] Portable / In-Place`**: Configures auto-start and shortcuts pointing directly to your current folder without copying files.

### Option 2: Standalone / Manual Run

If you prefer not to install anything:
- **Start the background monitor:** Double-click `Setup.bat` and select portable mode, or run `powershell.exe -WindowStyle Hidden -File .\AlarmAutoDismiss.ps1`.
- **Open Settings:** Double-click **`AlarmSettings.bat`**.
- **Check Status:** Double-click **`status.bat`**.

---

## On-Demand Control Panel

Launch **`AlarmSettings.bat`** (or the **Alarm Auto-Shutoff Settings** shortcut) at any time to manage the utility:

| Feature | Description |
| :--- | :--- |
| **Service Status** | Real-time service health indicator (Running / Stopped) with 1-click Start, Stop, and Restart controls. |
| **Wake-Up Alarms** | Timeout duration for alarms. Quick presets: **1m**, **2m**, **3m**, **5m**, **10m**, or custom slider (30s – 20m). |
| **Countdown Timers** | Timeout duration for timers. Quick presets: **30s**, **1m**, **2m**, **5m**, or custom slider (15s – 5m). |
| **Smart Idle Gating** | When enabled, defers shutoff while keyboard/mouse input is active within 30 seconds (up to a 60s hard grace ceiling). |
| **Missed Alarm Toast** | When enabled, leaves a silent reminder in Windows Action Center after an alarm is automatically silenced. |
| **Auto-Start on Login** | Toggles automatic background launch upon Windows login via `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`. |
| **Test Alarm (10s)** | Plays authentic Windows alarm audio with a live progress bar to test instant audio/toast cutoff. |
| **Activity History** | Real-time scrollable log showing alarm detection timestamps, timeouts, and manual user dismissals. |

> Closing the Control Panel window terminates the UI thread immediately; the background service continues monitoring silently.

---

## Configuration (`config.json`)

Settings are stored in `config.json` and dynamically reloaded by the background daemon every 2 seconds without requiring a restart:

```json
{
  "timeoutSeconds": 300,
  "timerTimeoutSeconds": 60,
  "smartIdleGating": false,
  "idleGraceSeconds": 30,
  "notifyOnDismiss": true,
  "autoStart": true,
  "checkIntervalSeconds": 2
}
```

### Parameter Reference

- `timeoutSeconds` *(integer)*: Maximum ringing duration in seconds for wake-up alarms before auto-dismissal (default: `300`).
- `timerTimeoutSeconds` *(integer)*: Maximum ringing duration in seconds for countdown timers (default: `60`).
- `smartIdleGating` *(boolean)*: If `true`, pauses dismissal while active at the PC; alarms auto-dismiss after a maximum 60s grace ceiling (default: `false`).
- `idleGraceSeconds` *(integer)*: Inactivity threshold in seconds for smart idle gating (default: `30`).
- `notifyOnDismiss` *(boolean)*: If `true`, displays a silent Action Center reminder toast when an alarm is dismissed (default: `true`).
- `autoStart` *(boolean)*: Reflects login startup state in `HKCU\...\Run` (default: `true`).
- `checkIntervalSeconds` *(integer)*: Background polling frequency in seconds (default: `2`).

---

## Utility Scripts

- **`status.bat`**: Inspects background daemon health. If the service is stopped, offers an interactive 1-click restart.
- **`test_alarm.bat`**: Triggers a standalone 10-second test alarm with live audio to verify toast detection and cutoff.
- **`Uninstall.bat`**: 1-click uninstaller that cleanly terminates background processes, removes shortcuts, unregisters startup, and deletes installed files.

---

## Security & Architecture Principles

- **Strict App Isolation:** The background engine strictly filters notifications by package family name (`Microsoft.WindowsAlarms_8wekyb3d8bbwe`). Notifications from Outlook, Teams, web browsers, or system alerts are never inspected, modified, or cleared.
- **Injection-Safe WinRT DOM:** Toast construction utilizes native `Windows.Data.Xml.Dom.XmlDocument` with explicit text node creation, preventing XML injection and formatting errors.
- **Single-Instance Mutex Security:** The daemon enforces single-instance locking with caller-SID DACL security, preventing cross-session mutex squatting.
- **Atomic Configuration Commits:** Settings updates are written to temporary staging and committed via `File.Replace()`, protecting against file truncation or read collisions.
- **Zero Elevated Privileges:** Operates strictly within user-mode permissions. No administrative privileges or UAC elevation required.

For full vulnerability reporting guidelines and threat assessments, review [SECURITY.md](SECURITY.md).

---

## System Requirements

- **Operating System:** Windows 11 (Build 22000+) or Windows 10 (Build 19041+)
- **Runtime:** Built-in Windows PowerShell 5.1 & .NET Framework 4.8 (pre-installed on standard Windows)
- **Privileges:** Standard User (Non-Elevated)
- **Smart App Control:** Compatible in full enforcement mode

---

## License

This project is licensed under the [MIT License](LICENSE).
