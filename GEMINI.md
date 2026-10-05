# Global Instructions & Project Conventions

> **Core Directive:**
> At the start of every session, read `PROJECT.md` and `ROADMAP.md`. Before finishing any task, update `ROADMAP.md`.

---

## 1. Operating Context & Tech Stack
- **Target OS:** Windows 11 (NT 10.0 / Build 26100+)
- **Primary Toolchain:** Native Windows .NET Framework 4.8 (`csc.exe` C# compiler at `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe`)
- **APIs:** WinRT `Windows.UI.Notifications.Management.UserNotificationListener` & Win32 User32 APIs
- **Zero-Dependency Mandate:** Do not introduce Python, Node.js, external package managers, or third-party binaries. All executables must build cleanly with Windows's built-in toolchain.

---

## 2. Memory & Session Management
- **`PROJECT.md`:** Authoritative source for project scope, architectural decisions, and constraints. Update whenever key design decisions are made.
- **`ROADMAP.md`:** Live execution status and sprint checklist. **Always overwrite** this file when updating status; never append.
- **Session Wrap-Up:** Follow the `wrap-up` skill protocol (`.agents/skills/wrap-up/SKILL.md`) to summarize accomplishments, record decisions, and sync the roadmap before concluding.

---

## 3. Modular Rules Protocol
Detailed coding standards, WinRT interop patterns, and verification protocols are managed modularly in `.agents/rules/`:
- `.agents/rules/architecture-constraints.md`: Zero-dependency, resource limits, and privilege isolation.
- `.agents/rules/coding-standards.md`: C# 5 compatibility, WinRT COM interop, WinForms/WPF conventions.
- `.agents/rules/testing-standards.md`: Synthetic notification tests, audio cutoff verification, and timer testing.

---

## 4. Execution Guardrails
1. **Never write implementation code** without explicit approval of the active sprint plan in `ROADMAP.md`.
2. **Never leave console windows visible:** Background processes must use the `winexe` subsystem or hidden window styles.
3. **Safe notification management:** Only target notifications belonging to the configured application (`Microsoft.WindowsAlarms_8wekyb3d8bbwe` / Clock). Never touch unrelated system notifications.
