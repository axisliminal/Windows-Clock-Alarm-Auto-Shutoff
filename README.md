# Windows Clock Alarm Auto-Shutoff

[![Windows 11 / 10](https://img.shields.io/badge/Platform-Windows%2011%20%7C%2010-0078D4?logo=windows&logoColor=white)](https://microsoft.com/windows)
[![Zero Dependencies](https://img.shields.io/badge/Dependencies-Zero%20External-success.svg)](https://github.com/axisliminal/Windows-Clock-Alarm-Auto-Shutoff)
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

---

## License

This project is licensed under the [MIT License](LICENSE).
