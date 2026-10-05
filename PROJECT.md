# Project: Windows Clock Alarm Auto-Shutoff

## 1. Project Scope & Objectives
- **Problem Statement:** The Windows Clock app (`Microsoft.WindowsAlarms`) provides no built-in mechanism to automatically turn off or stop alarms after a set duration. When an alarm or timer triggers, it loops audio and remains on-screen until manually dismissed. If the user is away from the PC, the alarm rings indefinitely.
- **Primary Goal:** Implement a reliable, lightweight, **100% invisible background utility** that detects ringing alarms and countdown timers originating exclusively from the Windows Clock app and automatically dismisses them completely after 5 minutes (or user-configured duration).
- **Core Intelligence & Safety:**
  - **Smart Idle Gating (Optional):** Senses user activity via Win32 `GetLastInputInfo`. When enabled, if the user has typed or moved the mouse within 30 seconds of the shutoff deadline, auto-shutoff is deferred up to a maximum 60-second grace ceiling before forcing dismissal. (Disabled by default to guarantee deterministic shutoff out-of-the-box).
  - **Timer vs. Alarm Discrimination:** Inspects `ToastGeneric` payloads to discriminate countdown timers (`(?i)\btimer\b`, 60s default) from wake-up alarms (300s default).
  - **Silent Missed-Alarm Retention:** Replaces dismissed looping alarms with a quiet reminder toast in Windows Action Center (`Missed Clock Alarm`), maintaining situational awareness without audible looping.
  - **Self-Healing Watchdog:** Employs native `Microsoft.Win32.SystemEvents` hooks (`PowerModeChanged` and `SessionSwitch`) to wake on Modern Standby / Sleep resume and unlock, re-evaluating alarms and trimming memory.
- **GUI Control Panel:** Provides an **on-demand graphical user interface** (`AlarmSettings.bat` / Desktop shortcut) to:
  - Check live background service status (Running / Stopped).
  - Start, Stop, or Restart the background daemon.
  - Adjust auto-shutoff timeout duration for alarms (presets: 1m, 2m, 3m, 5m, 10m + custom slider) and timers (presets: 30s, 1m, 2m, 5m + custom slider).
  - Toggle Smart Idle Gating and Silent Action Center Reminders with live dynamic reloading.
  - Test 10s audio cutoff live with a progress bar.
  - Toggle auto-start on Windows login (`HKCU\...\Run`).
  - View real-time activity history logs.
  - When closed, the GUI leaves zero processes running; the daemon remains silent in the background.

---

## 2. Target Environment & Library Versions
| Component | Specification |
| :--- | :--- |
| **Operating System** | Windows 11 Home Single Language (Build 26100+) |
| **Security Subsystem** | Smart App Control (SAC) / Device Guard active (`VerifiedAndReputablePolicyState: 1`) |
| **Execution Host** | Native Microsoft-signed PowerShell runtime (`powershell.exe -WindowStyle Hidden`) |
| **GUI Framework** | Native Windows Presentation Foundation (WPF / XAML) styled to Windows 11 WinUI aesthetic with DWM Mica |
| **APIs** | WinRT `Windows.UI.Notifications.Management.UserNotificationListener` & Win32 User32 APIs |
| **Target Binaries/Scripts**| Version-organized: `v1.6.1/` (Active release), `v1.6.0/` (Previous snapshot), `v1.0-csharp/` (Prototype archive), Root (Master documentation) |

---

## 3. Core Architectural Constraints
1. **Zero External Dependencies:** Built solely with tools and libraries pre-installed on standard Windows 10/11 installations.
2. **Standard User Privilege:** Runs strictly in user space without requiring Administrator elevation (`UAC` prompts). Windows Task Scheduler is avoided because `schtasks.exe /Create` requires elevation on Windows 11 Build 26100.
3. **Smart App Control (SAC) Compliance:**
   - Both the background daemon and the on-demand GUI are executed via Microsoft's signed `powershell.exe`.
   - Never triggers Device Guard / SAC blocks or warnings.
4. **On-Demand GUI Isolation:**
   - The GUI runs only when explicitly launched by the user.
   - Closing the GUI terminates the UI process completely while the background daemon continues operating silently.
5. **Strict Notification Isolation:**
   - Only processes notifications matching `Microsoft.WindowsAlarms_8wekyb3d8bbwe`.
   - All notifications from other apps are bypassed immediately without inspection or modification.
6. **Dynamic Configuration Reloading:**
   - The daemon checks `config.json` timestamp every 2 seconds. When settings are modified in the GUI, the daemon reloads them instantly without requiring a service restart.
7. **Efficiency & Footprint Targets:**
   - Process opts into Windows 11 EcoQoS (Efficiency Mode) pinning execution to efficiency cores.
   - Working set compaction (`SetProcessWorkingSetSize(-1, -1)`) maintains idle footprint between ~5.5MB and 16MB RAM with near 0% CPU usage.

---

## 4. Key Architectural Decisions Log

| Date | Decision | Rationale | Alternatives Considered |
| :--- | :--- | :--- | :--- |
| **2026-10-05** | Native WPF XAML with WinUI 11 styling over Web or WinUI 3 | The GUI is NOT web elements (HTML/Electron). It uses native WPF (Windows Presentation Foundation) XAML. WinUI 3 (Windows App SDK) requires external NuGet packages, .NET 8 SDK, MSIX packages, and produces unsigned binaries that Smart App Control blocks. WPF is pre-installed on Windows, loads instantly, has zero dependencies, runs within Microsoft-signed `powershell.exe` without SAC blocks, and can be styled with identical Windows 11 WinUI aesthetics. | Web elements/Electron (heavy RAM overhead, external runtimes); WinUI 3 / App SDK (requires external SDKs & blocked by SAC); WinForms (dated visuals). |
| **2026-10-05** | On-Demand PowerShell WPF (XAML) GUI Dashboard | Modern Windows 11 dark mode styling, zero external dependencies, and 100% compliant with Smart App Control because it runs in Microsoft-signed `powershell.exe`. Closes cleanly without background residue. | WinForms (less modern); C# WinExe GUI (blocked by SAC); System tray icon (rejected per user preference for 100% invisible background). |
| **2026-10-05** | Dynamic `config.json` file-watcher in daemon | Allows changes made in the GUI (e.g. changing timeout to 3m) to take effect instantly in the active background service without dropping active trackers or requiring manual restart. | Polling restart; IPC pipe commands. |
| **2026-10-05** | Native `powershell.exe` execution over unsigned `.exe` | Windows 11 Smart App Control (SAC) is active in enforcement mode (`VerifiedAndReputablePolicyState: 1`), which blocks unsigned compiled binaries with Device Guard policy errors. Running via Microsoft-signed `powershell.exe` is trusted by SAC and executes with zero security popups. | Unsigned C# `.exe` (blocked by SAC); Self-signed certificates (require manual root CA trust). |
| **2026-10-05** | Use WinRT `UserNotificationListener` for alarm detection and dismissal | Official Windows API for notification management. Calling `RemoveNotification(id)` immediately terminates both the toast banner and the looping alarm audio without needing UI automation or audio stream muting. Works across lock screen. | UI Automation; WASAPI Audio Muting. |
| **2026-10-05** | Polling loop over WinRT `NotificationChanged` event | The `NotificationChanged` event on `UserNotificationListener` throws `COMException (0x80070490)` in unpackaged Win32/desktop apps. Synchronous polling of `GetNotificationsAsync` every 2s is 100% stable, uses 0% CPU, and never misses events. | Event-driven notification subscription. |
| **2026-10-05** | Track duration using `n.CreationTime` | Calculating `(DateTimeOffset.Now - n.CreationTime)` prevents timing skew if the computer sleeps, hibernates, or wakes while an alarm is ringing. | Stopwatch or in-memory tick counter. |
| **2026-10-05** | Dual-Engine Audio Playback for Test Alarms | In Windows 11 Build 26100, WPN blocks toast audio streams from unpackaged apps lacking UWP identity. Combining WinRT toast with native .NET `System.Media.SoundPlayer` using `C:\Windows\Media\Alarm01.wav` guarantees audible sound across speakers while still testing WinRT toast detection and dismissal. | Toast-only audio (blocked by WPN); MediaFoundation/WASAPI (complex COM setup). |
| **2026-10-05** | EcoQoS Efficiency Mode & Working Set Compaction (v1.2) | Windows 11 EcoQoS pins daemon execution to E-cores and enables timer coalescing. Combined with unmanaged `SetProcessWorkingSetSize(-1, -1)` compaction after JIT loading and periodic intervals, working set memory drops from ~100MB to ~6MB. | Untuned standard PowerShell process (~100MB RAM); aggressive process restarts. |
| **2026-10-05** | Native Windows 11 DWM Mica Material Injection in WPF (v1.2) | Injected `DWMWA_SYSTEMBACKDROP_TYPE = 38` (Mica) and `DWMWA_USE_IMMERSIVE_DARK_MODE = 20` via `dwmapi.dll` P/Invoke on `SourceInitialized` with `Background="Transparent"` and translucent cards. Produces authentic Windows 11 Fluent mica glass visuals with zero dependencies. | Custom WPF styling shaders; solid dark color backgrounds; WinUI 3 dependencies. |
| **2026-10-05** | Smart Inactivity Gating via Win32 `GetLastInputInfo` (v1.3) | Alarms are only auto-dismissed when the user is idle. If keyboard or mouse activity occurred within the last 30 seconds (`GetIdleTimeSeconds() < 30`), auto-shutoff is deferred while the user is actively working. Bypassed for synthetic test alarms. | Global keyboard/mouse hooks (intrusive, requires elevated privileges); raw input listener. |
| **2026-10-05** | Notification Payload Timer vs. Alarm Discrimination (v1.3) | Inspected `ToastGeneric` text elements for `(?i)\btimer\b` to distinguish short-duration countdown timers (e.g. 60s default) from wake-up alarms (300s default), providing differentiated thresholds in `config.json` and GUI. | Monolithic single timeout for all Clock events; separate app ID heuristics. |
| **2026-10-05** | Silent Missed-Alarm Toast Replacement (v1.4) | Live WASAPI probing revealed Windows Push Notifications renders alarm audio through OS System Sounds (`PID: 0`) rather than `Time.exe`. To fulfill phased alert awareness without muting OS-wide system sounds, auto-shutoff immediately silences looping audio and posts a silent, non-looping reminder toast to Windows Action Center (`Missed Clock Alarm`), preserving visual awareness when the user returns. | Muting Windows System Sounds session via WASAPI (would mute all OS-level alerts and dings, violating isolation). |
| **2026-10-05** | Native `SystemEvents` Power & Session Watchdog (v1.5) | On Windows 11 Build 26100, standard non-elevated user mode returns `Access is denied (0x80070005)` for `schtasks.exe /Create` and `Register-ScheduledTask`, preventing unprivileged Task Scheduler registration. Hooking native .NET `Microsoft.Win32.SystemEvents.PowerModeChanged` and `SessionSwitch` enables immediate wake-on-resume from sleep/Modern Standby and unlock synchronization with zero privileges and zero elevation prompts. Paired with interactive CLI auto-healing in `status.bat`. | UAC-elevated Task Scheduler (violates privilege isolation); polling power APIs (unnecessary CPU overhead). |
| **2026-10-05** | Security & Logic Hardening Audit (v1.5.1) | Resolved XML injection in `Send-SilentMissedToast` via `[System.Security.SecurityElement]::Escape()`, fixed GUI preset button closure variable capture via `.GetNewClosure()`, narrowed `-stop` process targeting to exclude test/status tasks, converted tracking collections to `HashSet[uint32]`, batched GC invocations, eliminated redundant `Get-Process` WMI calls in memory trim polling, and implemented startup log rotation (>512KB). Maintained `AlarmSettings.ps1` strictly under 24KB (23,798 bytes). | Leaving closure variable references (broke preset buttons); killing broad powershell processes (interrupted test sessions). |
| **2026-10-05** | Standalone Distribution Package & 1-Click Setup (v1.6) | Packaged a zero-dependency release bundle containing only production runtime scripts, documentation, and automated installers. `Setup.bat` & `Setup.ps1` provide 1-click deployment to `%LOCALAPPDATA%\AlarmAutoDismiss` (or portable in-place mode) with `HKCU\...\Run` auto-start, Desktop & Start Menu shortcuts, and immediate daemon startup—all requiring zero UAC elevation. Paired with a complete `Uninstall.bat` and automated packager (`package_dist.bat`). | MSI / InnoSetup installers (require third-party compilers/tools, trigger Smart App Control or require elevation); manual file copying. |
| **2026-10-05** | Smart Idle Gating Default Flip & 60-Second Hard Ceiling (v1.6.1) | During a real Windows Clock alarm test, active user interaction (`0s idle < 30s threshold`) caused unbounded deferral of auto-dismissal beyond 5 minutes. Flipped default `smartIdleGating` to `false` so alarms shut off deterministically out-of-the-box. Implemented a 60-second hard grace ceiling (`maxGraceCeiling = effectiveThreshold + 60`) so that even when explicitly enabled, auto-shutoff is strictly enforced after at most 60 seconds of grace. | Leaving idle gating on by default (caused alarm to ring indefinitely while user was active); completely removing idle gating (removes user choice). |
| **2026-10-05** | Top-Level Version Folder Isolation & Root Cleanup | Reorganized workspace into top-level version folders (`v1.6.1/`, `v1.6.0/`, `v1.0-csharp/`) and removed unversioned staging directories (`dist/AlarmAutoDismiss`). Root folder is dedicated strictly to master repository documentation (`README.md`, `PROJECT.md`, `ROADMAP.md`, `changelog.md`). Eliminates identical filename confusion across releases while preserving standalone portability. | Keeping loose scripts in root (caused duplicate filename clutter with distribution builds); single flat archive directory. |
| **2026-10-05** | Comprehensive Security Hardening & Deep Research Reconciliation (v1.6.1) | Implemented native WinRT XML DOM (`Windows.Data.Xml.Dom.XmlDocument`) with `CreateTextNode()` to eliminate XML injection and Unicode parser crashes, added caller-SID DACL `MutexSecurity` to prevent local mutex squatting DoS, enforced `Pack=4` struct alignment and `uint` typing with tick rollover calculation in `ProcessEcoMode`, added atomic configuration replacement via `File.Replace`, normalized batch working directories (`cd /d "%~dp0"`), and enforced absolute System32 paths for `powershell.exe`. | Leaving string XML concatenation; standard mutex without DACL; direct file overwrite without atomic replacement. |



