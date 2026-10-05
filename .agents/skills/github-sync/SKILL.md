---
name: github-sync
description: Manages the dual-track development and GitHub release synchronization lifecycle for Windows Clock Alarm Auto-Shutoff. Enforces strict isolation so ongoing work occurs exclusively in development/ and is never promoted to the root GitHub release track without explicit user command.
---

# GitHub Release Synchronization & Dual-Track Workflow

## 1. Core Operating Directive

> **STRICT ISOLATION MANDATE:**
> - All ongoing development, bug fixes, refactoring, feature additions, scratch scripts, and testing **MUST occur strictly inside `development/`**.
> - **NEVER** modify or copy files into the repository root (the GitHub release track) during normal coding turns.
> - The root GitHub release files are **strictly read-only** until the user explicitly requests:
>   - *"Sync to GitHub"*
>   - *"Publish changes to GitHub"*
>   - *"Update the GitHub release"*

---

## 2. Dual-Track Architecture

```
Alarm shutting off/
│
├── development/                 # Active Development Track (Git-Ignored)
│   ├── AlarmAutoDismiss.ps1     # Working daemon script
│   ├── AlarmSettings.ps1        # Working WinUI 11 settings GUI
│   ├── AlarmSettings.bat        # Working launcher
│   ├── config.json              # Working configuration
│   ├── Setup.bat / Setup.ps1    # Working installer
│   ├── Uninstall.bat / .ps1     # Working uninstaller
│   ├── status.bat / test_alarm.bat
│   ├── README.txt               # Bundled user guide
│   └── dev/                     # Build tools (package_dist.ps1, assets)
│
├── [Project Root]               # GitHub Production Track (Public Remote)
│   ├── AlarmAutoDismiss.ps1     # Production daemon
│   ├── AlarmSettings.ps1        # Production GUI (<24KB)
│   ├── AlarmSettings.bat        # Production launcher
│   ├── config.json              # Production configuration
│   ├── Setup.bat / Setup.ps1    # Production installer
│   ├── Uninstall.bat / .ps1     # Production uninstaller
│   ├── status.bat / test_alarm.bat
│   ├── README.txt               # Production user guide
│   ├── README.md                # Public open-source manual (audited)
│   ├── LICENSE                  # MIT License
│   ├── SECURITY.md              # Vulnerability policy
│   ├── changelog.md             # Immutable ledger
│   ├── AlarmAutoDismiss-*.zip   # Production release archive
│   ├── SHA256SUMS               # Canonical cryptographic manifest
│   └── push_to_github.bat       # Remote publication helper
│
└── _local_backups/              # Local Backups (Git-Ignored)
    ├── v1.0-csharp/             # Prototype archive
    ├── v1.6.0/                  # Previous snapshot
    └── research_notes/          # Internal architecture & audit texts
```

---

## 3. Pre-Promotion Verification Checklist

Before copying any files from `development/` to root, execute this verification sequence:

1. **Size Budget Enforcement:**
   - Measure `development/AlarmSettings.ps1`.
   - Must remain **strictly under 24,000 bytes** (24KB limit).
2. **Zero-Binary Mandate:**
   - Ensure zero `.exe`, `.dll`, or third-party binaries exist in the distribution payload.
3. **JSON Syntax Integrity:**
   - Validate `development/config.json` via `Get-Content ... | ConvertFrom-Json` to ensure valid formatting and required keys.
4. **Execution Safety & Audio Cutoff:**
   - Run `AlarmAutoDismiss.ps1 -Action test -TestSeconds 5` to confirm 5-second audio cutoff and toast dismissal.
5. **Release Packaging & Manifest:**
   - Execute `development/dev/package_dist.ps1` to generate `AlarmAutoDismiss-v<Version>.zip` and calculate canonical `SHA256SUMS`.

---

## 4. Promotion & GitHub Publication Protocol

When the user gives explicit approval to publish:

1. **Promote Production Files:**
   Copy the verified files from `development/` to project root:
   - `AlarmAutoDismiss.ps1`
   - `AlarmSettings.ps1`
   - `AlarmSettings.bat`
   - `config.json`
   - `Setup.bat`
   - `Setup.ps1`
   - `Uninstall.bat`
   - `Uninstall.ps1`
   - `status.bat`
   - `test_alarm.bat`
   - `README.txt`
   - `AlarmAutoDismiss-v<Version>.zip`
   - `SHA256SUMS`

2. **Update Ledgers:**
   - Update `changelog.md` with new version entry under `# Changelog`.
   - Update `PROJECT.md` decisions log if architectural changes occurred.
   - Overwrite `ROADMAP.md` reflecting the live sprint state.

3. **Stage & Commit:**
   ```powershell
   git add -A
   git commit -m "feat(release): update production release v<Version>"
   ```

4. **Push to GitHub Remote:**
   - Execute `push_to_github.bat` or run:
     ```powershell
     git push origin main
     ```
