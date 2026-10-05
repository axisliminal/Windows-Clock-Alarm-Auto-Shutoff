# Project Execution Roadmap & Live Status

**Current Status:** PRODUCTION READY, STREAMLINED & GITHUB-SYNCHRONIZED (v1.6.1 ROOT RELEASE)  
**Active Sprint:** Sprint 17 Complete (Ready for GitHub Remote Push)  
**Last Updated:** 2026-10-05  
**Live Blocker:** None (Ready to commit and push to GitHub remote)  

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
- [x] **Duplicate Staging Removal:** Purged loose files in root and unversioned staging folders, eliminating duplicate filenames across the repository.
- [x] **Release Packaging Parity:** Packaged standalone ZIP archives within each release folder.
- [x] **Archived Prototype Preservation:** Consolidated early C# prototype into `v1.0-csharp/`.

### [x] Sprint 16: GitHub Publishing Preparation, Pre-Flight Sanitization & Security Hardening
- [x] **Git Toolchain & WinGet Verification:** Installed official `Git.MinGit` (v2.56.0) via `winget`, registered in Windows Package Manager database for `winget upgrade` support.
- [x] **Pre-Flight Repository Sanitization:** Created root `.gitignore`, `LICENSE` (MIT), and `SECURITY.md`.
- [x] **Codebase Security Hardening (v1.6.1):** Native WinRT XML DOM toast formatting (THREAT-07), caller-SID DACL mutex security (THREAT-09), EcoQoS struct alignment & tick rollover handling (THREAT-08), atomic config commits via `File.Replace()` (THREAT-10), and normalized working directories/System32 paths (THREAT-05/06).
- [x] **Git Author Identity Configuration & Initial Commit:** Configured `axisliminal <amananmahajan@gmail.com>` and generated commit `1c9afc8`.

### [x] Sprint 17: Repository Streamlining, Dual-Track Separation & Public Release Sanitization
- [x] **Local Backup Consolidation:** Relocated historical snapshots (`v1.0-csharp/`, `v1.6.0/`) and raw research audit files into `_local_backups/` on the local machine.
- [x] **Git Ignore Hardening:** Hardened `.gitignore` to strictly exclude `_local_backups/`, `backups/`, `development/`, and maintenance helper `push_to_github.bat`.
- [x] **Development Track Isolation (`development/`):** Established active development workspace with complete working copies of scripts, `dev/package_dist.ps1`, and testing assets.
- [x] **Dual-Track Release Synchronization Skill:** Created Antigravity skill [`.agents/skills/github-sync/SKILL.md`](.agents/skills/github-sync/SKILL.md) enforcing strict development isolation and explicit user approval before promoting changes to the GitHub track.
- [x] **Root Flattening:** Promoted hardened v1.6.1 production payload directly to repository root (`AlarmAutoDismiss.ps1`, `AlarmSettings.ps1`, `AlarmSettings.bat`, `config.json`, `Setup.bat`, `Setup.ps1`, `Uninstall.bat`, `Uninstall.ps1`, `status.bat`, `test_alarm.bat`, `README.txt`, `AlarmAutoDismiss-v1.6.1.zip`, `SHA256SUMS`). Redundant `v1.6.1/` directory deleted.
- [x] **Public README.md Audit & Sanitization:** Overwrote root `README.md` with clean, public open-source documentation. Stripped internal sprint tags, private paths, internal memory references, and old version trees; added shields.io badges, feature table, quick start, configuration reference, and security principles.
- [x] **Guardrail & Constraint Verification:** Confirmed root `AlarmSettings.ps1` remains strictly under 24KB limit (23,979 bytes).

---

## System Operational Summary
- **GitHub Production Release (Root):** Complete, flattened, standalone, zero-dependency v1.6.1 release files.
- **Active Development Workspace (`development/`):** Full isolated working environment for all future iterative development (git-ignored).
- **Local Backup Archives (`_local_backups/`):** Historical versions (`v1.0-csharp`, `v1.6.0`) and deep research documents stored locally (git-ignored).
- **Installed Package:** `%LOCALAPPDATA%\AlarmAutoDismiss` (Active, PID running, hardened).
- **Control Panel Access:** Available on Desktop and Start Menu ("Alarm Auto-Shutoff Settings").
- **Smart App Control:** 100% compliant with zero unsigned binaries.
- **Git State:** Staged and ready for clean commit on branch `main`.

---

## Immediate Next Steps
1. Execute `git add -A` and commit the streamlined structure: `refactor: streamline repository structure for v1.6.1 public release`.
2. Push to GitHub remote `origin main` using `push_to_github.bat` or git CLI.
3. Apply Google SEO & GitHub "About" metadata (description, topics, search keywords) to GitHub repository settings.
