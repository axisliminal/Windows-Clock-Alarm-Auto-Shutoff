# Security Policy

## Supported Versions

Only the latest release receives active security patches. We recommend all users keep their local installation up-to-date.

| Version | Supported          |
| ------- | ------------------ |
| 1.6.x   | :white_check_mark: |
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

---

## Enterprise WDAC & Code-Signing Guidance

In enterprise environments enforcing **Windows Defender Application Control (WDAC)** or **Smart App Control Enforced Mode (`2`)**, unsigned PowerShell scripts automatically drop to **ConstrainedLanguage Mode (CLM)**. In CLM, dynamic code generation (`System.Reflection.Emit`) and certain WinRT interop types are restricted by Windows kernel Code Integrity policy.

To deploy in enterprise CLM/WDAC environments with FullLanguage capabilities:
1. Obtain an Authenticode Code-Signing Certificate from your enterprise Public Key Infrastructure (PKI) or Internal Root CA.
2. Sign all PowerShell scripts in `src/` prior to rollout:
   ```powershell
   $cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Select-Object -First 1
   Set-AuthenticodeSignature -FilePath "src\AlarmAutoDismiss.ps1" -Certificate $cert -TimestampServer "http://timestamp.digicert.com"
   Set-AuthenticodeSignature -FilePath "src\AlarmSettings.ps1" -Certificate $cert -TimestampServer "http://timestamp.digicert.com"
   ```
3. Deploy the enterprise root CA certificate to target machines' `Trusted Root Certification Authorities` and `Trusted Publishers` stores via Group Policy (GPO) or Microsoft Intune.

