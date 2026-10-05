# Project Execution Roadmap & Live Status

**Current Status:** PRODUCTION READY & GIT-INITIALIZED (v1.6.1 HARDENED)  
**Active Sprint:** Ready for GitHub Remote Push & Release Publishing  
**Last Updated:** 2026-10-05  
**Live Blocker:** None (Awaiting Remote Repository Creation on GitHub.com)  

---

## Sprint Checklist & Status

### [x] Sprint 0: Requirements Alignment, Architecture & In-Depth Research
- Verified Windows 11 Build 26100+, WinRT `UserNotificationListener` status (`Allowed`), and audio shutoff capability.
- Established project working memory (`GEMINI.md`, `PROJECT.md`, `ROADMAP.md`) and modular rule files (`.agents/rules/`).
- Clarified requirements: Complete dismissal, both Alarms and Timers, 100% headless background daemon, auto-start on login, zero interference.

### [x] Sprint 1: Headless Core Daemon Engine
- Implemented `AlarmAutoDismiss.ps1` background monitor using native WinRT `UserNotificationListener`.
- Single-instance mutex protection (`Local\AlarmAutoDismiss_PS1_SingleInstance`).
- Strict isolation: Only processes `Microsoft.WindowsAlarms_8wekyb3d8bbwe`.
- Clock-skew-immune duration tracking using `(DateTimeOffset.Now - n.CreationTime) >= timeoutSeconds`.
- Clean reset logic when an alarm is dismissed or snoozed manually by the user before timeout.
- Dynamic configuration reloading from `config.json` without requiring daemon restart.

### [x] Sprint 2: Startup Integration & Smart App Control Hardening
- Eliminated unsigned `.exe` and `.vbs` to eliminate Smart App Control (SAC) Code Integrity Event 3076/3077 warnings.
- Standardized execution on Microsoft-signed `powershell.exe -WindowStyle Hidden`.
- Implemented `install_startup.bat`, `uninstall_startup.bat`, `status.bat`, and `test_alarm.bat`.

### [x] Sprint 3: Verification & Quality Assurance
- Automated audio termination test verified (< 500ms).
- Manual dismissal test verified.
- Non-interference test verified.
- SAC validation verified.

### [x] Sprint 4: On-Demand GUI Control Panel
- Created initial `AlarmSettings.ps1`, `AlarmSettings.bat`, and Desktop shortcut (`Alarm Auto-Shutoff Settings.lnk`).
- Live service status badge, presets, slider, and startup toggle.

### [x] Sprint 5: GUI Test Alarm Bugfix, Encoding Fix & WinUI 11 Polish
- Fixed countdown timer scope issue (`[DateTime]::UtcNow` delta timer prevents freezing at 9s).
- Fixed character encoding (removed emoji mojibake).
- Modern Windows 11 Fluent dark mode styling applied to WPF XAML.
- Maintained strict file size limit (under 24,000 bytes).

### [x] Sprint 6: Test Alarm Audio Fix & Project Folder Sorting
- Direct SoundPlayer Alarm Audio Integration (`C:\Windows\Media\Alarm01.wav` in GUI and CLI test).
- Folder structure organization: isolated developer artifacts into `dev/`.
- Cleaned up redundant directories and created `README.md` user manual.

### [x] Sprint 7: Architecture Research & Modernization Analysis
- Formulated and executed exhaustive Gemini Deep Research prompt.
- Findings document received and audited (`Windows Alarm Auto-Shutoff Architecture.txt`).
- Validated SAC compliance rules (PowerShell host remains optimal; unsigned/self-signed native binaries blocked by kernel ci.dll).
- Identified 4 high-value breakthroughs: EcoQoS / working set compaction (<10MB RAM), native DWM Mica WPF rendering, WASAPI audio session decoupling, and user idle gating.

### [x] Sprint 8 (v1.2): Core Efficiency & Native Mica UI Polish
- [x] **EcoQoS Efficiency Mode:** Integrated `ProcessEcoMode` P/Invoke with `PROCESS_POWER_THROTTLING_EXECUTION_SPEED` and `PROCESS_POWER_THROTTLING_IGNORE_TIMER_RESOLUTION` in `AlarmAutoDismiss.ps1` (verified `EcoQoS: True`).
- [x] **Working Set Compaction:** Added steady-state and periodic `SetProcessWorkingSetSize(-1, -1)` compaction in `AlarmAutoDismiss.ps1` (verified active working set memory drops from ~100MB to ~6-16MB).
- [x] **Native Windows 11 Mica Surface:** Integrated `dwmapi.dll` P/Invoke on `Window.SourceInitialized` in `AlarmSettings.ps1` enabling `DWMWA_SYSTEMBACKDROP_TYPE = 38` (Mica) and `DWMWA_USE_IMMERSIVE_DARK_MODE = 20` with `Background="Transparent"` and translucent Fluent card surfaces.
- [x] **Standardized CLI Invocations:** Updated all batch wrappers to use `-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden`.
- [x] **Guardrail Adherence:** Maintained `AlarmSettings.ps1` strictly under 24,000 bytes.

### [x] Sprint 9 (v1.3): Smart Inactivity Detection & Differentiated Timers
- [x] **Timer vs. Alarm Differentiation:** Inspected `ToastGeneric` XML payload to discriminate between countdown timers (`(?i)\btimer\b`) and alarms, supporting dedicated `timerTimeoutSeconds` (default 60s) and `timeoutSeconds` (default 300s).
- [x] **Adaptive Idle Gating:** Integrated `GetLastInputInfo` via `ProcessEcoMode::GetIdleTimeSeconds()`. If active typing or mouse movement occurred within 30 seconds, auto-dismissal is safely paused while the user is actively working, with throttled logging to prevent log noise.
- [x] **Settings GUI Enhancements:** Updated `AlarmSettings.ps1` with separate presets and sliders for alarms and timers, plus a Smart Idle Gating toggle. Maintained strict compliance with the 24,000-byte limit.
- [x] **Dynamic Reloading & Memory Tuning:** Dynamic reload tested and verified for all settings in `config.json`. Working set memory verified at ~16-20MB with EcoQoS active.
- [x] **Test Alarm Verification:** Executed live 10s synthetic test alarm with audio and toast cutoff verified.

### [x] Sprint 10 (v1.4): Phased Audio Control & Missed Alarm Retention
- [x] **Empirical Audio Session Probing:** Verified WASAPI COM interop GUIDs (`IMMDeviceEnumerator`, `IAudioSessionManager2`, `IAudioSessionEnumerator`, `IAudioSessionControl2`, `ISimpleAudioVolume`).
- [x] **Architecture Routing Analysis:** Discovered Windows Push Notification platform routes alarm audio via System Sounds (`PID: 0`) rather than `Time.exe`.
- [x] **Silent Missed-Alarm Toast Notification:** Implemented `Send-SilentMissedToast` upon auto-dismissal in `AlarmAutoDismiss.ps1`. When an alarm or timer is auto-silenced, it posts a quiet non-looping reminder toast to Windows Action Center with zero sound.
- [x] **Control Panel Integration:** Added `ChkNotify` ("Show silent reminder in Notification Center when auto-silenced") toggle in `AlarmSettings.ps1` and dynamic reload in `config.json` (`notifyOnDismiss: true`).
- [x] **Size Constraint Adherence:** Maintained `AlarmSettings.ps1` strictly under 24,000 bytes.
- [x] **Live Verification:** Test verification executed; background daemon active and verified.

### [x] Sprint 11 (v1.5): Self-Healing Watchdog & Power Lifecycle Management
- [x] **Privilege Isolation Analysis:** Confirmed Windows Task Scheduler API returns `Access is denied (0x80070005)` in unprivileged standard user mode on Windows 11 Build 26100 without UAC elevation. Enforced core privilege isolation constraint by avoiding UAC elevation requirements.
- [x] **Native `SystemEvents` Watchdog:** Hooked native .NET `Microsoft.Win32.SystemEvents.PowerModeChanged` and `SessionSwitch` in `AlarmAutoDismiss.ps1` to detect resume from sleep/standby, workstation lock, and workstation unlock without elevated permissions.
- [x] **Wake-Up Memory Compaction:** Re-compacts working set memory and re-evaluates active ringing alarms immediately upon system wake and unlock.
- [x] **Clean Event Sink Teardown:** Implemented graceful unregistration of event delegates in `finally` block to prevent leaks.
- [x] **Interactive CLI Auto-Healing:** Upgraded `status.bat` to detect stopped daemon state and provide an interactive 1-click startup option via native `choice` and background execution.
- [x] **Live Verification:** Validated daemon startup, steady-state memory compaction (~5.5MB), watchdog event registration, and executed 10s synthetic test alarm successfully.

### [x] Sprint 12 (v1.6.0): Clean 1-Click Distribution Package & Audit Patch
- [x] **Universal 1-Click Installer (`Setup.bat` & `Setup.ps1`):** Created per-user installer supporting standard install (`%LOCALAPPDATA%\AlarmAutoDismiss`) and portable in-place mode. Automatically deploys runtime files, generates Desktop and Start Menu shortcuts (`shell32.dll,238`), registers `HKCU\...\Run` startup, starts the daemon invisibly in EcoQoS mode, and verifies single-instance mutex.
- [x] **Comprehensive 1-Click Uninstaller (`Uninstall.bat` & `Uninstall.ps1`):** Gracefully halts the background daemon, removes `HKCU\...\Run` registry entries, cleans up Desktop and Start Menu shortcuts, and handles directory self-deletion without orphan processes.
- [x] **Automated Distribution Packager (`package_dist.bat` & `dev/package_dist.ps1`):** Staged pure production files into `dist/AlarmAutoDismiss/`, excluded developer artifacts, validated size budgets (<24KB), bundled `README.txt`, and generated `dist/AlarmAutoDismiss-v1.6.0.zip` with SHA-256 verification.
- [x] **Post-Sprint Audit Hardening:** Addressed 8 findings (concurrency reload race, self-uninstall locking, startup key suppression, `$KeepConfig` retention, pre-flight JSON validation, clock stepping defense).
- [x] **Permanent Append-Only Ledger:** Generated `changelog.md` detailing full chronological project ledger.

### [x] Sprint 13 (v1.6.1): Empirical Clock Alarm Bugfix & Smart Idle Hard Ceiling
- [x] **Root Cause Resolution for Non-Shutoff Alarm:** Empirical log auditing of user test alarm (`ID: 173521`) revealed that active user input (`0s idle < 30s threshold`) caused unbounded deferral of auto-dismissal beyond 5m25s.
- [x] **60-Second Hard Grace Ceiling:** Implemented `maxGraceCeiling = effectiveThreshold + 60` in `AlarmAutoDismiss.ps1`. Even when Smart Idle Gating is explicitly enabled, alarms and timers forcibly auto-dismiss after at most 60 seconds of grace.
- [x] **Deterministic Out-of-the-Box Shutoff:** Set `smartIdleGating: false` as the default in `config.json`, `AlarmAutoDismiss.ps1`, and `AlarmSettings.ps1`. Alarms shut off strictly at the configured timeout (default 300s) out of the box.
- [x] **Settings GUI Polish & Constraint Verification:** Clarified checkbox text to `"Smart Idle Gating (Defer shutoff up to 60s while active at PC)"` and verified file size (23,786 bytes, strictly under 24KB limit).
- [x] **Documentation & Release Artifacts Synchronized:** Updated `README.txt`, `README.md`, `changelog.md`, and rebuilt distribution package.
- [x] **Live Operational Verification:** Deployed to `%LOCALAPPDATA%\AlarmAutoDismiss`, verified running daemon (PID: 7396, ~8.5MB RAM, EcoQoS enabled), and confirmed synthetic test alarm auto-dismissal (`ID: 173552`).

### [x] Sprint 14: Comprehensive Code & Documentation Reconciliation
- [x] **Documentation Audit:** Audited all project markdown specs, text files, and launcher banners against physical codebase.
- [x] **Version Parity:** Synchronized title version badges and headers to `v1.6.1` across `README.md`, `README.txt`, `Setup.bat`, and `Setup.ps1`.
- [x] **Directory Tree Alignment:** Added `changelog.md` and updated distribution archive reference in `README.md`.
- [x] **Behavioral Documentation Alignment:** Documented Smart Idle Gating optional status (disabled by default) and 60-second hard grace ceiling across `PROJECT.md`, `README.md`, `README.txt`, and `.agents/rules/testing-standards.md`.

### [x] Sprint 15: Top-Level Version Folder Sorting & Repository Organization
- [x] **Version Isolation Structure:** Created dedicated top-level version folders (`v1.6.1/`, `v1.6.0/`, `v1.0-csharp/`).
- [x] **Duplicate Staging Removal:** Purged loose files in root and unversioned staging folders (`dist/AlarmAutoDismiss`), eliminating duplicate filenames across the repository.
- [x] **Release Packaging Parity:** Packaged standalone ZIP archives within each release folder (`v1.6.1/AlarmAutoDismiss-v1.6.1.zip` and `v1.6.0/AlarmAutoDismiss-v1.6.0.zip`).
- [x] **Archived Prototype Preservation:** Consolidated early C# prototype and legacy compiler wrappers into `v1.0-csharp/` with dedicated architectural documentation.
- [x] **Root Directory Purification:** Root folder now dedicated strictly to master repository documentation (`README.md`, `PROJECT.md`, `ROADMAP.md`, `changelog.md`, `GEMINI.md`, and architecture research).
- [x] **Documentation & Navigation Synchronization:** Updated `README.md` Quick Start and directory tree to route through version folders.

### [x] Sprint 16: GitHub Publishing Preparation, Pre-Flight Sanitization & Security Hardening
- [x] **Requirements Alignment & User Preferences:** Public repository visibility confirmed, MIT license selected, automated winget Git CLI installation confirmed.
- [x] **Git Toolchain & WinGet Verification:** Installed official `Git.MinGit` (v2.56.0) via `winget`, registered in Windows Package Manager database for `winget upgrade` support, alias configured in `%LOCALAPPDATA%\Microsoft\WinGet\Links`.
- [x] **Pre-Flight Repository Sanitization:**
  - Created root `.gitignore` (ignoring logs, stop signals, IDE cache, OS files, `.gemini/`).
  - Created root `LICENSE` (MIT License).
  - Created root `SECURITY.md` (vulnerability disclosure policy & security model).
  - Sanitized local absolute username paths across documentation and specs.
- [x] **Deep Research Ingestion & Threat Analysis:**
  - Ingested `Windows Automation Security Audit.txt` and synthesized 10-vector STRIDE threat matrix.
  - Reconciled downstream runtime risks (THREAT-05 to THREAT-10) with existing v1.6.1 codebase.
- [x] **Codebase Security Hardening (v1.6.1):**
  - **WinRT Toast XML DOM (THREAT-07):** Migrated `Send-SilentMissedToast` to native `Windows.Data.Xml.Dom.XmlDocument` with `CreateTextNode()` calls for immunity against XML injection and Unicode parser corruption.
  - **Named Mutex DACL (THREAT-09):** Instantiated single-instance mutex with explicit `MutexSecurity` granting `FullControl` solely to current user SID (`WindowsIdentity.GetCurrent().User`), neutralizing local mutex squatting DoS.
  - **Type-Safe P/Invoke & Rollover Handling (THREAT-08):** Enforced `[StructLayout(LayoutKind.Sequential, Pack = 4)]` on `PROCESS_POWER_THROTTLING_STATE`, corrected `ProcessInformationSize` to `uint`, and handled the 49.7-day tick count rollover in `GetIdleTimeSeconds()`.
  - **Atomic Configuration Writes (THREAT-10):** Updated `Save-ConfigSettings` to write to `config.json.tmp` and commit via `[System.IO.File]::Replace()`, preventing TOCTOU truncation and read races.
  - **Execution Path Normalization & DLL Planting Mitigation (THREAT-05 & THREAT-06):** Normalized working directories (`cd /d "%~dp0"`) and resolved `powershell.exe` via explicit System32 paths across all batch files and `HKCU\...\Run` persistence commands.
  - **Release Verification Manifest:** Automated canonical `SHA256SUMS` generation in release packager (`package_dist.ps1`).
  - **Guardrail Verification:** Verified `AlarmSettings.ps1` file size remains strictly within budget (23,979 / 24,000 bytes).
  - **Live Operational Verification:** Deployed hardened scripts to `%LOCALAPPDATA%\AlarmAutoDismiss`, verified active daemon, and passed 5-second synthetic test alarm audio/toast cutoff.
- [x] **Git Author Identity Configuration & Initial Commit:**
  - Configured Git credentials: `axisliminal <amananmahajan@gmail.com>`.
  - Generated initial root commit `1c9afc8` on branch `main` (51 files committed, working tree clean).

---

## System Operational Summary
- **Installed Package:** `%LOCALAPPDATA%\AlarmAutoDismiss` (Active, PID running, hardened).
- **Active Release Directory:** `v1.6.1/` (Contains complete standalone package, `AlarmAutoDismiss-v1.6.1.zip`, and `SHA256SUMS`).
- **Previous Release Snapshot:** `v1.6.0/` (Contains complete standalone package & `AlarmAutoDismiss-v1.6.0.zip`).
- **Prototype Archive:** `v1.0-csharp/` (Contains original C# sources, build script, and legacy wrappers).
- **Master Documentation:** Root folder contains strictly global project specs (`README.md`, `PROJECT.md`, `ROADMAP.md`, `changelog.md`, `LICENSE`, `SECURITY.md`, `.gitignore`, `Windows Alarm Auto-Shutoff Architecture.txt`, `Windows Automation Security Audit.txt`).
- **Control Panel Access:** Available on Desktop and Start Menu ("Alarm Auto-Shutoff Settings").
- **Smart App Control:** 100% compliant with zero unsigned binaries.
- **Git Version Control:** Branch `main` initialized with root commit `1c9afc8`.
- **Milestone State:** Release v1.6.1 hardened against all audit findings, verified live, and committed to Git.

---

## Immediate Next Step
- Create a new repository on [GitHub.com](https://github.com/new) under the account `axisliminal`, link the remote with `git remote add origin ...`, and push the `main` branch.
