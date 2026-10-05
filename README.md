# Windows Clock Alarm Auto-Shutoff

[![Windows 11 / 10](https://img.shields.io/badge/Platform-Windows%2011%20%7C%2010-0078D4?logo=windows&logoColor=white)](https://microsoft.com/windows)
[![Zero Dependencies](https://img.shields.io/badge/Dependencies-Zero%20External-success.svg)](https://github.com/axisliminal/Windows-Clock-Alarm-Auto-Shutoff)
[![Smart App Control](https://img.shields.io/badge/Security-Smart%20App%20Control%20Compliant-brightgreen.svg)](SECURITY.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> A lightweight Windows utility that automatically turns off ringing Windows Clock alarms and timers after a set duration.

---

## Why This Exists

The default Windows Clock app does not automatically stop alarms. When an alarm or timer goes off, it plays loud looping audio and stays on screen indefinitely until someone manually clicks Dismiss.

If you step away from your computer, take a phone call, or leave the room, the alarm will ring endlessly.

**This utility solves that problem:** It runs silently in the background, detects ringing Clock alerts, and automatically turns them off once your chosen timeout is reached.

---

## Quick Start

1. **Download or clone** this repository.
2. Double-click **`Setup.bat`**.
3. Choose your installation mode:
   - **`[1] Standard Installation`**: Installs to `%LOCALAPPDATA%\AlarmAutoDismiss`, adds Desktop and Start Menu shortcuts, sets auto-start on Windows login, and starts the service.
   - **`[2] Portable / In-Place`**: Runs directly from the folder without copying files.

That's it! Your alarms will now automatically silence after the configured duration (default: 5 minutes for alarms, 1 minute for countdown timers).

---

## Control Panel

Open the **Alarm Auto-Shutoff Settings** shortcut on your Desktop or run **`AlarmSettings.bat`** to customize your preferences:

- **Wake-Up Alarms Timeout:** Quick presets (**1m**, **2m**, **3m**, **5m**, **10m**) or a custom slider (30s – 20m).
- **Countdown Timers Timeout:** Quick presets (**30s**, **1m**, **2m**, **5m**) or a custom slider (15s – 5m).
- **Smart Idle Gating (Optional):** Pauses shutoff while you are actively typing or using your mouse, so an active workflow isn't interrupted.
- **Missed Alarm Notification:** Leaves a quiet reminder in Windows Notification Center after an alarm is automatically silenced.
- **Test Alarm (10s):** Plays a sample alarm ringtone with a live countdown to verify that audio and toast shut off automatically.
- **Service Controls:** Check live status (Running / Stopped) and Start, Stop, or Restart with one click.

Closing the Control Panel leaves zero background windows or tray icons; the background service continues monitoring silently.

---

## Configuration (`config.json`)

Settings can be changed via the Control Panel or edited directly in `config.json` (dynamically reloaded without restarting):

```json
{
  "timeoutSeconds": 300,
  "timerTimeoutSeconds": 60,
  "smartIdleGating": false,
  "notifyOnDismiss": true,
  "checkIntervalSeconds": 2,
  "loggingEnabled": true
}
```

- `timeoutSeconds`: Duration (in seconds) before a wake-up alarm is silenced (default: `300`).
- `timerTimeoutSeconds`: Duration (in seconds) before a countdown timer is silenced (default: `60`).
- `smartIdleGating`: When `true`, defers shutoff while keyboard/mouse input is active, up to a 60-second grace ceiling (default: `false`).
- `notifyOnDismiss`: When `true`, posts a silent Action Center reminder after auto-shutoff (default: `true`).
- `checkIntervalSeconds`: Background polling frequency in seconds (default: `2`).
- `loggingEnabled`: Enables event logging to `alarm_history.log` (default: `true`).

*(Note: Auto-start on Windows login is managed via the Control Panel toggle or `Setup.bat`, storing its state directly in `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`).*

---

## Repository Structure

```text
├── Setup.bat          # 1-Click Installer (Standard or Portable)
├── Uninstall.bat      # 1-Click Uninstaller
├── AlarmSettings.bat  # Settings & Control Panel Launcher
├── status.bat         # Live Service Status Checker & Auto-Healer
├── test_alarm.bat     # 10-Second Test Alarm with Audio Cutoff
├── config.json        # User Configuration File
├── README.md          # User Guide & Documentation
├── LICENSE            # MIT License
├── SECURITY.md        # Security Policy & Model
└── src/               # Background Engine Scripts
    ├── AlarmAutoDismiss.ps1
    └── AlarmSettings.ps1
```

---

## Utility Scripts

- **`AlarmSettings.bat`**: Opens the graphical Control Panel.
- **`status.bat`**: Checks if the background monitor is running and lets you restart it if stopped.
- **`test_alarm.bat`**: Runs a quick 10-second test alarm with real audio to test auto-shutoff.
- **`Uninstall.bat`**: Completely stops the service, removes shortcuts, and cleans up files.

---

## System Requirements

- **Operating System:** Windows 11 or Windows 10
- **Privileges:** Standard user (No Administrator / UAC elevation required)
- **Dependencies:** None (uses built-in Windows components)
- **Security:** 100% Smart App Control (SAC) compliant

---

## License

This project is licensed under the [MIT License](LICENSE).
