# Windows Clock Alarm Auto-Shutoff Utility (v1.6.1)

> **A lightweight, 100% invisible Windows 11 utility with an on-demand Fluent WinUI 11 Control Panel that automatically turns off ringing alarms and countdown timers after a configurable duration.**

---

## 1. Overview & Problem Solved

The default Windows Clock app (`Microsoft.WindowsAlarms`) provides no built-in auto-shutoff mechanism. When an alarm or countdown timer triggers, it loops continuous loud audio and displays a banner indefinitely until someone physically dismisses it. If you step away from your desk, leave the room, or sleep through an alarm, it rings endlessly.

**This utility solves that completely:**
- **Invisible Background Monitoring:** Silently detects active ringing alarms and countdown timers originating exclusively from the Windows Clock app.
- **Smart Idle Gating (Optional):** Senses user presence via Win32 `GetLastInputInfo`. When enabled, if you are actively typing or moving your mouse, auto-shutoff is deferred up to a maximum 60s grace ceiling before forcing dismissal. (Disabled by default for 100% predictable shutoff out-of-the-box).
- **Differentiated Alarms & Timers:** Distinguishes short countdown timers (e.g. 1-minute default) from morning wake-up alarms (e.g. 5-minute default) with independent timeout thresholds.
- **Silent Missed-Alarm Retention:** When an alarm is auto-dismissed, looping alarm audio is halted instantly, and an optional quiet reminder is posted to Windows Action Center so you know an alert fired while you were away.
- **Self-Healing Watchdog:** Employs native .NET `Microsoft.Win32.SystemEvents` hooks to immediately wake from Modern Standby / Sleep and synchronize notifications upon workstation unlock—with zero special privileges required.
- **EcoQoS Efficiency Mode:** Opts into Windows 11 EcoQoS (Efficiency Mode) and automatically compacts working set memory down to **~5.5MB–16MB RAM** with near 0% CPU footprint.
- **On-Demand WinUI 11 Control Panel:** Modern Windows 11 dark mode interface featuring native DWM Mica glass backdrops, live status badges, sliders, presets, and a 10s audio cutoff verification tool.
- **1-Click Universal Setup & Distribution:** Clean per-user installer (`Setup.bat`) targeting `%LOCALAPPDATA%\AlarmAutoDismiss` with zero UAC prompts, Start Menu & Desktop shortcuts, and automated packager (`package_dist.bat`).
- **Zero External Dependencies:** Built entirely with native Windows 11 components (WinRT `UserNotificationListener`, native PowerShell 5.1, and WPF). No Python, Node.js, or external runtimes required.
- **Smart App Control (SAC) Compliant:** Runs inside Microsoft-signed system processes (`powershell.exe`) with zero security warnings or Device Guard blocks.

---

## 2. Quick Start Guide

### Option A: 1-Click Setup & Automatic Deployment (Recommended)
1. Navigate to [`v1.6.1/`](v1.6.1/) and double-click [`v1.6.1/Setup.bat`](v1.6.1/Setup.bat).
2. Choose **[1] Standard Installation** (or [2] Portable / In-Place):
   - Deploys cleanly into `%LOCALAPPDATA%\AlarmAutoDismiss` (zero elevation required).
   - Automatically generates **Desktop** and **Start Menu** shortcuts (`Alarm Auto-Shutoff Settings`).
   - Configures automatic launch on Windows user login (`HKCU\...\Run`).
   - Starts the background service immediately in hidden mode and launches the Control Panel.

### Option B: The On-Demand Control Panel
1. Double-click the **Alarm Auto-Shutoff Settings** shortcut on your Desktop or Start Menu, or run [`v1.6.1/AlarmSettings.bat`](v1.6.1/AlarmSettings.bat).
2. The control panel allows you to:
   - **Service Status:** Check live background daemon health (Green = Active, Red = Stopped) and Start, Stop, or Restart with one click.
   - **Wake-Up Alarms Timeout:** Set shutoff limit using quick presets (**1 min**, **2 min**, **3 min**, **5 min**, **10 min**) or the custom slider (30s – 20m).
   - **Countdown Timers Timeout:** Set separate shutoff limit for timers using presets (**30 sec**, **1 min**, **2 min**, **5 min**) or custom slider (15s – 5m).
   - **Smart Idle Gating (Optional):** Check/uncheck to pause auto-shutoff whenever keyboard/mouse activity was detected within 30 seconds (defers shutoff up to a maximum 60-second grace ceiling before forcing dismissal; disabled by default).
   - **Missed Alarm Retention:** Check/uncheck to automatically post a silent reminder in Windows Action Center whenever an alarm or timer is auto-silenced.
   - **Auto-Start on Login:** Toggle automatic execution on Windows user login (`HKCU\...\Run`).
   - **Save Settings:** Saves changes instantly to [`v1.6.1/config.json`](v1.6.1/config.json). The background daemon dynamically reloads settings within 2 seconds without requiring a restart.
   - **Test Alarm (10s):** Plays the authentic Windows alarm ringtone with a live progress bar to verify that audio and toast notifications are silenced automatically.
   - **Activity History Log:** View real-time timestamps of active alarms, timeouts, and manual user dismissals.
3. Close the window with **[X]** when finished. The UI process terminates completely, leaving zero GUI overhead while the background service continues monitoring.

### Option C: Quick Management Scripts
- **Check Service Status & Auto-Heal:** Double-click [`v1.6.1/status.bat`](v1.6.1/status.bat). If stopped, prompts for 1-click relaunch.
- **Run a 10-Second Test Alarm:** Double-click [`v1.6.1/test_alarm.bat`](v1.6.1/test_alarm.bat).
- **Uninstall Completely:** Double-click [`v1.6.1/Uninstall.bat`](v1.6.1/Uninstall.bat) to stop background services, remove shortcuts, unregister startup, and clean up files.
- **Build Release Package:** Double-click [`v1.6.1/package_dist.bat`](v1.6.1/package_dist.bat) to generate a clean distribution ZIP.

---

## 3. Directory & Version Organization

The workspace is cleanly structured into version folders, keeping the root folder dedicated exclusively to master documentation and system memory:

```text
Alarm shutting off/
│
├── v1.6.1/                        # Active Production Release (v1.6.1)
│   ├── Setup.bat                  # 1-Click universal installer (AppData / Portable)
│   ├── Setup.ps1                  # Setup automation script
│   ├── Uninstall.bat              # 1-Click uninstaller and service cleanup
│   ├── Uninstall.ps1              # Uninstallation automation script
│   ├── AlarmSettings.bat          # 1-Click launcher for WinUI 11 Control Panel
│   ├── AlarmSettings.ps1          # WinUI 11 WPF/XAML Dashboard (<24KB)
│   ├── AlarmAutoDismiss.ps1       # Headless background monitoring daemon engine
│   ├── config.json                # User settings (default: smartIdle: false)
│   ├── status.bat                 # Interactive status check & auto-healer
│   ├── test_alarm.bat             # Standalone 10-second CLI alarm test with audio
│   ├── package_dist.bat           # 1-Click distribution packager
│   ├── README.txt                 # Clean user guide bundled in release
│   ├── changelog.md               # Version-pinned release notes
│   ├── AlarmAutoDismiss-v1.6.1.zip# Standalone release archive (26.1 KB)
│   └── dev/                       # Packager build tools and assets
│
├── v1.6.0/                        # Previous Release Snapshot (v1.6.0)
│   ├── Setup.bat / Setup.ps1      # v1.6.0 installer scripts
│   ├── AlarmAutoDismiss.ps1       # v1.6.0 engine (pre-ceiling baseline)
│   ├── AlarmSettings.ps1 / .bat   # v1.6.0 Control Panel
│   ├── config.json                # v1.6.0 configuration snapshot
│   ├── README.txt / changelog.md  # v1.6.0 documentation
│   └── AlarmAutoDismiss-v1.6.0.zip# Standalone release archive (25.5 KB)
│
├── v1.0-csharp/                   # Initial C# Prototype & Legacy Toolchain
│   ├── AlarmAutoDismiss.cs        # Native C# 5.0 WinRT COM notification monitor
│   ├── build.bat                  # Native .NET 4.8 csc.exe compiler script
│   ├── create_shortcut.ps1        # Desktop shortcut generator
│   ├── create_desktop_shortcut.bat# Shortcut creation launcher
│   ├── install_startup.bat        # Legacy v1.1 startup installer
│   ├── uninstall_startup.bat      # Legacy v1.1 startup uninstaller
│   └── README.txt                 # Architectural context & SAC retirement rationale
│
├── [Master Documentation & Memory]
│   ├── README.md                  # Master technical documentation & repository index
│   ├── PROJECT.md                 # Technical architecture specifications & decision log
│   ├── ROADMAP.md                 # Live sprint execution checklist & status
│   ├── changelog.md               # Permanent append-only release ledger
│   ├── GEMINI.md                  # Assistant system instructions & core directives
│   └── Windows Alarm Auto-Shutoff Architecture.txt # Architecture research report
│
└── .agents/                       # Assistant rules and wrap-up protocols
    ├── rules/                     # Architecture, coding, and testing standards
    └── skills/wrap-up/            # Session synchronization skill
```

---

## 4. Key Architectural Features

1. **Self-Healing Watchdog & Lifecycle Resilience (v1.5):**
   - In standard user mode, native .NET `Microsoft.Win32.SystemEvents.PowerModeChanged` and `SessionSwitch` handlers monitor power and workstation state.
   - On wake from Modern Standby or sleep, the daemon wakes immediately, re-evaluates ringing notifications, and re-compacts working set memory.
   - On workstation unlock, pending notifications are processed instantly without latency.
2. **Interactive CLI Auto-Healing (`status.bat`):**
   - Status checks verify single-instance mutex state. If the daemon has stopped, an interactive prompt powered by native `choice` allows immediate 1-click detached restart.
3. **Silent Missed-Alarm Retention (v1.4):**
   - Automatically posts a silent non-looping reminder toast to Windows Action Center (`Missed Clock Alarm`) when an alarm reaches its timeout limit, preserving visual notification history without audio annoyance.
4. **Smart Inactivity / Idle Gating (`GetLastInputInfo` v1.3 / v1.6.1):**
   - Win32 `GetLastInputInfo` monitors user interaction. When enabled in the Control Panel, if typing or mouse movement occurred within 30 seconds of the shutoff deadline, auto-dismissal is deferred up to a hard ceiling of 60 seconds grace. Once the ceiling is reached, the alarm is dismissed regardless of user activity. (Disabled by default).
5. **Countdown Timer vs. Alarm Discrimination (v1.3):**
   - Evaluates notification payloads via WinRT `ToastGeneric` visual bindings to distinguish countdown timers (`(?i)\btimer\b`) from alarms, applying shorter timeouts to timers.
6. **Windows 11 EcoQoS & Working Set Compaction (v1.2):**
   - Injects `PROCESS_POWER_THROTTLING_EXECUTION_SPEED` and `IGNORE_TIMER_RESOLUTION` via `kernel32.dll` P/Invoke to schedule daemon polling onto efficiency cores.
   - Employs steady-state and post-idle working set compaction (`SetProcessWorkingSetSize(-1, -1)`), keeping memory footprint down to **~5.5MB–16MB**.
7. **Native Windows 11 DWM Mica Backdrop (v1.2):**
   - Injects `DWMWA_SYSTEMBACKDROP_TYPE = 38` (Mica) and `DWMWA_USE_IMMERSIVE_DARK_MODE = 20` via `dwmapi.dll` into the WPF XAML window, providing authentic Windows 11 Fluent glass aesthetics with zero external dependencies.
8. **Dual-Engine Test Verification:**
   - Test alarms play the authentic Windows Alarm sound (`C:\Windows\Media\Alarm01.wav`) out loud via native `System.Media.SoundPlayer` while simultaneously posting a WinRT toast notification.
   - At exactly 10 seconds, audio cuts off instantly (< 10ms latency) and the toast is removed via WinRT `RemoveNotification()`.
9. **Safe App Isolation:**
   - The daemon inspects notifications strictly for package identity matching `Microsoft.WindowsAlarms_8wekyb3d8bbwe`. Notifications from Outlook, web browsers, Teams, or system components are completely untouched.
10. **Clock-Skew Immunity:**
    - Calculates ringing duration using `(DateTimeOffset.Now - n.CreationTime)`, ensuring timing accuracy even if your PC enters sleep, hibernation, or Modern Standby while an alarm is ringing.
11. **Dynamic Configuration Reloading:**
    - The daemon monitors [`config.json`](config.json) timestamps every 2 seconds. When settings are modified in the GUI, the daemon reloads them instantly without requiring a service restart.

---

## 5. Technical Requirements

- **Operating System:** Windows 10 (Build 19041+) or Windows 11 (Build 22000, 22621, 26100+).
- **Runtimes:** Built-in PowerShell 5.1 & .NET Framework 4.8 (standard on all Windows installations).
- **Privileges:** Standard user account (no Administrator / UAC elevation needed).
- **Smart App Control:** 100% compatible under active enforcement mode.
