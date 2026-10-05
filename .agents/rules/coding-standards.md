---
title: C# and Win32 Coding Standards
description: Enforces C# 5 syntax compatibility for Framework 4.8 csc.exe, native WinRT async awaiter, safe COM interop, on-demand WPF standards, and SystemEvents watchdog.
trigger: always_on
---

# C# and Win32 Coding Standards

## 1. Compiler Compatibility
- The built-in compiler `csc.exe` in .NET Framework 4.8 supports up to **C# 5.0**.
- **Prohibited modern syntax:**
  - String interpolation `$"Hello {name}"` (Use `string.Format("Hello {0}", name)` instead).
  - Expression-bodied members `=>` (Use standard method bodies `{ return ...; }`).
  - Null-conditional operators `?.` (Use explicit `if (obj != null)` checks).
  - Out variable declarations `out var x` (Declare `int x = 0;` before passing `out x`).
  - Pattern matching `is Type t` (Use `as Type` or `is Type`).
  - Default literal `default` without type (Use `default(T)`).

## 2. Zero-Dependency WinRT Async Pattern
- In standard Windows installations without Visual Studio SDKs, `WindowsRuntimeSystemExtensions.AsTask()` cannot be compiled because the monolithic `Windows.winmd (255.255.255.255)` is absent.
- **Mandatory Pattern:** Use `ManualResetEvent` to synchronize `Windows.Foundation.IAsyncOperation<T>`:
  ```csharp
  public static T AwaitWinRT<T>(IAsyncOperation<T> asyncOp, int timeoutMs = 5000) {
      if (asyncOp.Status == AsyncStatus.Completed) return asyncOp.GetResults();
      var mres = new ManualResetEvent(false);
      asyncOp.Completed = new AsyncOperationCompletedHandler<T>((info, status) => { mres.Set(); });
      if (!mres.WaitOne(timeoutMs)) {
          try { asyncOp.Cancel(); } catch { }
          throw new TimeoutException("WinRT operation timed out");
      }
      return asyncOp.GetResults();
  }
  ```

## 3. Headless Lifecycle & COM Interop
- Use `/target:winexe` or `powershell.exe -WindowStyle Hidden` for complete invisibility without console windows.
- Maintain a single-instance lock using a named `Mutex` (`Local\AlarmAutoDismiss_SingleInstance` or `Local\AlarmAutoDismiss_PS1_SingleInstance`).
- Wrap all notification property inspections in `try-catch` blocks to protect against transient COM errors when the user dismisses an alarm mid-poll.

## 4. On-Demand WPF (XAML) GUI Standards
- Host WPF GUI components within Microsoft-signed `powershell.exe` to comply with Smart App Control (SAC).
- Parse XAML using `[System.Windows.Markup.XamlReader]::Load()`.
- Use standard string concatenation for nested XML snippets inside scriptblocks to avoid multiline here-string indentation issues.
- The GUI must be strictly on-demand: closing the window terminates the UI thread immediately without affecting background daemons.

## 5. Native SystemEvents Watchdog Standards
- Use `[Microsoft.Win32.SystemEvents]::add_PowerModeChanged` and `add_SessionSwitch` for zero-privilege lifecycle detection (Sleep/Resume, Lock/Unlock).
- Always assign scriptblocks to typed delegate variables (`[Microsoft.Win32.PowerModeChangedEventHandler]`, `[Microsoft.Win32.SessionSwitchEventHandler]`) so they can be explicitly unregistered in the `finally` block with `remove_PowerModeChanged` and `remove_SessionSwitch`.
- Re-run working set compaction and alarm synchronization on `PowerModes.Resume` and `SessionSwitchReason.SessionUnlock`.

## 6. CLI Auto-Healing & Process Invocations
- Use `powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "<path>"` for completely headless background executions.
- In interactive batch scripts (e.g. `status.bat`), use native Windows `choice /C YN` to handle yes/no prompts safely without batch variable expansion errors.
