# Changelog

All notable changes to the **Windows Clock Alarm Auto-Shutoff Utility** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **Append-Only Policy:**
> This file operates strictly in an **append-only** model. When new sprints or patches are completed, append the new version entry at the top under the `# Changelog` heading. Never overwrite, truncate, or alter historical version entries. Unlike `ROADMAP.md` (which represents live sprint state), `changelog.md` serves as a permanent, immutable ledger across the lifecycle of the software.

---

## [1.6.0] - 2026-10-05

### Added
- **Universal 1-Click Installer (`Setup.bat` / `Setup.ps1`):**
  - Added interactive and silent installation targeting `%LOCALAPPDATA%\AlarmAutoDismiss` without requiring administrative UAC elevation.
  - Added Portable / In-Place setup mode to run directly from the extracted directory without copying files.
  - Integrated automatic Desktop and Start Menu shortcut generation (`Alarm Auto-Shutoff Settings.lnk`) with native Clock icons (`shell32.dll,238`).
  - Added automatic user login startup registration in `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`.
  - Added upgrade protection: automatically preserves existing `config.json` customizations during reinstallation.
  - Added immediate detached daemon launching and single-instance mutex verification upon setup completion.
- **Comprehensive 1-Click Uninstaller (`Uninstall.bat` / `Uninstall.ps1`):**
  - Added graceful daemon termination before file removal.
  - Added removal of `HKCU\...\Run` and `StartupApproved\Run` registry entries.
  - Added clean removal of Desktop and Start Menu shortcuts.
  - Added deferred self-cleanup for `%LOCALAPPDATA%\AlarmAutoDismiss` when uninstaller is executed from inside the application directory.
- **Automated Distribution Packager (`package_dist.bat` / `dev/package_dist.ps1`):**
  - Created automated build pipeline that stages pure production runtime scripts into `dist\AlarmAutoDismiss\`.
  - Strictly filters out developer artifacts (`dev/`, `.agents/`, `.git`, `.cs`, `build.bat`, logs, and markdown specs).
  - Built-in guardrail enforcement: validates that `AlarmSettings.ps1` remains strictly under the 24,000-byte cap and enforces the zero-binary mandate.
  - Generates standalone release archive `dist\AlarmAutoDismiss-v1.6.0.zip` (19.9 KB) with SHA-256 integrity verification.
- **Bundled User Guide (`README.txt`):** Plain-text documentation included directly in release packages covering installation, usage, and uninstallation.

### Changed
- Reorganized quick-start guide in `README.md` to highlight 1-click `Setup.bat` as the recommended primary flow.
- Updated project documentation (`PROJECT.md`, `README.md`, `ROADMAP.md`) to reflect the v1.6.0 distribution milestone.

---

## [1.5.1] - 2026-10-05

### Added
- **Automatic Log Rotation:** Truncates `alarm_history.log` to the last 500 lines upon daemon launch if the file size exceeds 512 KB.
- **Dynamic Base Directory Detection in Shortcut Generator:** Patched `dev/create_shortcut.ps1` to detect whether it is invoked from `dev/` or the root directory, ensuring the generated Desktop shortcut always targets `AlarmSettings.bat`.

### Fixed
- **XML Injection Vulnerability in Toast Construction:** Wrapped `$title` and `$body` in `[System.Security.SecurityElement]::Escape()` inside `Send-SilentMissedToast` to prevent malformed XML payload crashes.
- **Broad Process Hunting in Daemon Stopper:** Restricted `AlarmAutoDismiss.ps1 -Action stop` filter to `CommandLine -notlike "*-Action*"` to prevent terminating concurrent test alarm sessions or status queries.
- **GUI Preset Button Closure Variable Capture:** Added `.GetNewClosure()` to alarm and timer preset loops in `AlarmSettings.ps1`, fixing an issue where all preset buttons captured the final loop variable.
- **Single-Instance Mutex Leak Prevention:** Wrapped post-mutex daemon initialization in an enclosing `try/finally` block with guarded `ReleaseMutex()` and `Close()` calls.
- **Polling Loop CPU Overhead:** Replaced periodic `Get-Process` WMI invocations with `[System.Diagnostics.Process]::GetCurrentProcess().WorkingSet64` behind a 60-second time gate.
- **Batched Garbage Collection:** Consolidated manual dismissal memory cleanup so `GC::Collect()` and `TrimWorkingSet()` execute at most once per poll cycle.
- **Config Setting Retention:** Updated `Save-ConfigSettings` in `AlarmSettings.ps1` to preserve custom `checkIntervalSeconds` and `loggingEnabled` values during GUI saves.
- **AUMID Format Alignment:** Aligned test toast notifier identity in `AlarmSettings.ps1` with the daemon package format (`Microsoft.WindowsAlarms_8wekyb3d8bbwe`).
- **Fail-Safe Idle Calculation:** Configured `GetIdleTimeSeconds()` exception handler to return `0` (fails safe by treating the user as active).
- **WPF Clean Teardown:** Added explicit `$pollTimer.Stop()` inside `Window.Add_Closing`.

---

## [1.5.0] - 2026-10-05

### Added
- **Native `SystemEvents` Power & Session Watchdog:**
  - Integrated native .NET `Microsoft.Win32.SystemEvents.PowerModeChanged` and `SessionSwitch` event listeners into `AlarmAutoDismiss.ps1`.
  - Provides zero-privilege lifecycle detection: immediately wakes on resume from Modern Standby / Sleep and workstation unlock to re-evaluate ringing alarms.
  - Eliminates reliance on Windows Task Scheduler (`schtasks.exe` returns `Access is denied (0x80070005)` in unprivileged standard user mode on Windows 11 Build 26100).
- **Wake-Up Memory Compaction:** Re-compacts working set memory and clears active notification skew immediately upon system resume and unlock.
- **Interactive CLI Auto-Healing:** Upgraded `status.bat` using native `choice /C YN` to detect stopped daemon state and provide an interactive 1-click background relaunch.
- **Clean Event Delegate Teardown:** Implemented explicit `remove_PowerModeChanged` and `remove_SessionSwitch` in daemon `finally` block to prevent COM/event memory leaks.

---

## [1.4.0] - 2026-10-05

### Added
- **Silent Missed-Alarm Retention (`Send-SilentMissedToast`):**
  - Automatically posts a quiet, non-looping reminder toast to Windows Action Center (`Missed Clock Alarm` or `Missed Countdown Timer`) when an alarm reaches its timeout limit.
  - Maintains situational awareness for users returning to their PC without keeping loud audio looping.
- **GUI Control Panel Notification Toggle:** Added `ChkNotify` ("Show silent reminder in Notification Center when auto-silenced") checkbox to `AlarmSettings.ps1`.
- **Dynamic Configuration Key:** Added `"notifyOnDismiss": true` to `config.json` with dynamic daemon reloading.

### Changed
- Concluded WASAPI audio session probing: Live testing confirmed Windows Push Notifications renders alarm audio via OS System Sounds (`PID: 0`) rather than `Time.exe`. Determined that dismissing the toast via WinRT `RemoveNotification()` is the cleanest way to silence audio without muting global system sounds.

---

## [1.3.0] - 2026-10-05

### Added
- **Smart Idle Gating (`GetLastInputInfo`):**
  - Integrated Win32 `user32.dll` `GetLastInputInfo` P/Invoke in `ProcessEcoMode::GetIdleTimeSeconds()`.
  - Defers auto-shutoff if active typing or mouse movement occurred within 30 seconds of the shutoff deadline, preventing unwanted dismissals while working.
  - Added throttled logging to prevent log spam while gating is active.
  - Added bypass for synthetic test alarms so interactive testing remains instantaneous.
- **Timer vs. Alarm Differentiation:**
  - Evaluates `ToastGeneric` text payloads for `(?i)\btimer\b` to distinguish short-duration countdown timers from morning wake-up alarms.
  - Added independent configuration keys: `timeoutSeconds` (default 300s) and `timerTimeoutSeconds` (default 60s).
- **Control Panel Preset & Slider Expansion:** Added dedicated preset buttons and custom sliders for countdown timers in `AlarmSettings.ps1`, alongside a Smart Idle Gating toggle.

---

## [1.2.0] - 2026-10-05

### Added
- **Windows 11 EcoQoS (Efficiency Mode):**
  - Injected `PROCESS_POWER_THROTTLING_EXECUTION_SPEED` and `PROCESS_POWER_THROTTLING_IGNORE_TIMER_RESOLUTION` via `kernel32.dll` `SetProcessInformation` P/Invoke.
  - Schedules background daemon polling exclusively onto CPU efficiency cores.
- **Working Set Memory Compaction:**
  - Added unmanaged `SetProcessWorkingSetSize(-1, -1)` compaction after JIT loading and periodic 10-minute intervals.
  - Reduced active working set memory footprint from ~100 MB down to **~5.5 MB – 16 MB RAM**.
- **Native Windows 11 DWM Mica Surface Injection:**
  - Injected `DWMWA_SYSTEMBACKDROP_TYPE = 38` (Mica) and `DWMWA_USE_IMMERSIVE_DARK_MODE = 20` via `dwmapi.dll` P/Invoke on `Window.SourceInitialized`.
  - Enabled authentic Windows 11 Fluent dark glass aesthetics in WPF XAML with zero external dependencies.
- **CLI Standardized Flags:** Standardized all batch execution wrappers to use `-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden`.

---

## [1.1.0] - 2026-10-05

### Added
- **Smart App Control (SAC) Hardening:**
  - Migrated execution from unsigned C# binaries (`AlarmAutoDismiss.exe`) to Microsoft-signed Windows PowerShell (`powershell.exe`).
  - Completely resolved Windows 11 Device Guard Code Integrity Event 3076/3077 warnings under SAC enforcement mode.
- **Interactive Batch Wrappers:** Created `install_startup.bat`, `uninstall_startup.bat`, `status.bat`, and `test_alarm.bat`.
- **Dual-Engine Test Audio:** Combined WinRT toast notification with native .NET `System.Media.SoundPlayer` using `C:\Windows\Media\Alarm01.wav` to guarantee audible test ringtones across speakers on Windows 11 Build 26100.

---

## [1.0.0] - 2026-10-05

### Added
- **Initial Core Daemon Engine (`AlarmAutoDismiss.ps1`):**
  - Headless background monitoring using native WinRT `Windows.UI.Notifications.Management.UserNotificationListener`.
  - App isolation: strictly filters notifications for package identity `Microsoft.WindowsAlarms_8wekyb3d8bbwe`.
  - Clock-skew-immune duration calculation using `(DateTimeOffset.Now - n.CreationTime)`.
  - Automatic audio cutoff and banner removal via `RemoveNotification(id)`.
  - Clean state reset when an alarm or timer is snoozed or dismissed manually by the user.
  - Named Mutex single-instance protection (`Local\AlarmAutoDismiss_PS1_SingleInstance`).
  - Dynamic JSON configuration reloading from `config.json` without requiring daemon restart.
- **On-Demand WinUI 11 Control Panel (`AlarmSettings.ps1` / `AlarmSettings.bat`):**
  - WPF XAML interface launched on-demand via Microsoft-signed `powershell.exe`.
  - Service status monitoring (Running / Stopped), start/stop/restart controls, timeout presets, custom slider, and startup toggle.
  - Maintained strictly under 24,000 bytes for lightweight execution.
