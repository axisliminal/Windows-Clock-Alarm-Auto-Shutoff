# Security Policy

## Supported Versions

Only the latest release receives active security patches. We recommend all users keep their local installation up-to-date.

| Version | Supported          |
| ------- | ------------------ |
| 1.6.1   | :white_check_mark: |
| < 1.6.0 | :x:                |

---

## Security Model & Guarantees

This utility is designed with a defense-in-depth security architecture:
1. **Zero Administrator Elevation:** All scripts and tools run strictly within the standard user space. The installer and background service never request or require administrative privileges (`UAC`).
2. **Strict Application Isolation:** The background notification listener (`UserNotificationListener`) queries exclusively for notifications belonging to the official Windows Clock app (`Microsoft.WindowsAlarms_8wekyb3d8bbwe`). All other system notifications are bypassed without inspection.
3. **Smart App Control (SAC) Compliance:** Execution is hosted within Microsoft-signed `powershell.exe`, avoiding untrusted unsigned binaries.
4. **Input Sanitization:** XML construction for silent missed-alarm toasts utilizes native WinRT XML DOM (`Windows.Data.Xml.Dom.XmlDocument`) with text nodes to completely prevent XML injection.

---

## Reporting a Vulnerability

If you discover a security vulnerability or security bug in this repository, please **do not open a public issue**. Public issues disclose potential attack vectors before a fix is available.

### Reporting Channels
- **GitHub Private Vulnerability Reporting (Recommended):** If available on this repository, please submit your advisory via the **Security** tab -> **Report a vulnerability**.
- **Alternative Contact:** Open a GitHub discussion or contact the maintainer directly through your GitHub profile contact info.

### What to Include
When reporting a vulnerability, please include:
1. A clear description of the potential vulnerability and its impact.
2. Steps to reproduce or proof-of-concept (PoC) code.
3. The specific script affected (e.g., `src/AlarmAutoDismiss.ps1`).
4. Any proposed remediations or patches.

### Response Timeline
- **Initial Acknowledgment:** Within 48 hours of receipt.
- **Assessment & Triage:** Within 5 business days.
- **Fix & Advisory Release:** Coordinated disclosure once a patch is tested and verified.
