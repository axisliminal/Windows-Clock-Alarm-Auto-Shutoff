param(
    [string]$Action = "daemon",
    [int]$TestSeconds = 10
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logPath = Join-Path $scriptDir "alarm_history.log"
$configPath = Join-Path $scriptDir "config.json"
$stopSignalPath = Join-Path $scriptDir ".stop_signal"
$targetPackage = "Microsoft.WindowsAlarms_8wekyb3d8bbwe"
$testTag = "AlarmAutoDismiss-Test"

# Helper for silent logging
$loggingEnabled = $true
function Write-Log([string]$message) {
    if (-not $loggingEnabled) { return }
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$timestamp] $message"
    try {
        Add-Content -Path $logPath -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {}
}

# Load config
$timeoutSeconds = 300
$timerTimeoutSeconds = 60
$smartIdleGating = $false
$notifyOnDismiss = $true
$checkIntervalSeconds = 2
if (Test-Path $configPath) {
    try {
        $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
        if ($cfg.timeoutSeconds -gt 0) { $timeoutSeconds = $cfg.timeoutSeconds }
        if ($cfg.timerTimeoutSeconds -gt 0) { $timerTimeoutSeconds = $cfg.timerTimeoutSeconds }
        if ($null -ne $cfg.smartIdleGating) { $smartIdleGating = [bool]$cfg.smartIdleGating }
        if ($null -ne $cfg.notifyOnDismiss) { $notifyOnDismiss = [bool]$cfg.notifyOnDismiss }
        if ($cfg.checkIntervalSeconds -gt 0) { $checkIntervalSeconds = $cfg.checkIntervalSeconds }
        if ($null -ne $cfg.loggingEnabled) { $loggingEnabled = [bool]$cfg.loggingEnabled }
    } catch {
        Write-Log "WARNING: Failed to parse config.json, using defaults: $($_.Exception.Message)"
    }
}

function Send-SilentMissedToast([string]$title, [string]$body) {
    try {
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
        $doc = [Windows.Data.Xml.Dom.XmlDocument]::new()
        $toast = $doc.CreateElement("toast")
        $null = $doc.AppendChild($toast)

        $audio = $doc.CreateElement("audio")
        $audio.SetAttribute("silent", "true")
        $null = $toast.AppendChild($audio)

        $visual = $doc.CreateElement("visual")
        $null = $toast.AppendChild($visual)

        $binding = $doc.CreateElement("binding")
        $binding.SetAttribute("template", "ToastGeneric")
        $null = $visual.AppendChild($binding)

        $t1 = $doc.CreateElement("text")
        $t1.SetAttribute("id", "1")
        $null = $t1.AppendChild($doc.CreateTextNode($title))
        $null = $binding.AppendChild($t1)

        $t2 = $doc.CreateElement("text")
        $t2.SetAttribute("id", "2")
        $null = $t2.AppendChild($doc.CreateTextNode($body))
        $null = $binding.AppendChild($t2)

        $t = [Windows.UI.Notifications.ToastNotification]::new($doc)
        $notif = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($targetPackage)
        $notif.Show($t)
    } catch {}
}

# --- Action: -stop ---
if ($Action -match "^[-/]?stop$") {
    Write-Host "Sending stop signal to AlarmAutoDismiss..."
    Set-Content -Path $stopSignalPath -Value "STOP" -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    # Also terminate any running powershell daemon process targeting this script
    $daemons = Get-CimInstance Win32_Process | Where-Object { 
        $_.CommandLine -like "*AlarmAutoDismiss.ps1*" -and 
        $_.CommandLine -notlike "*-Action*" -and
        $_.ProcessId -ne $PID 
    }
    if ($daemons) {
        foreach ($d in $daemons) {
            Stop-Process -Id $d.ProcessId -Force -ErrorAction SilentlyContinue
        }
        Write-Host "AlarmAutoDismiss stopped successfully."
    } else {
        Write-Host "AlarmAutoDismiss was not running."
    }
    Remove-Item $stopSignalPath -Force -ErrorAction SilentlyContinue
    exit 0
}

# --- Action: -status ---
if ($Action -match "^[-/]?status$") {
    try {
        $m = [System.Threading.Mutex]::OpenExisting("Local\AlarmAutoDismiss_PS1_SingleInstance")
        $m.Close()
        Write-Host "AlarmAutoDismiss Status: RUNNING (Active)"
        exit 0
    } catch {
        Write-Host "AlarmAutoDismiss Status: STOPPED (Not running)"
        exit 1
    }
}

# --- Action: -test ---
if ($Action -match "^[-/]?test$") {
    Write-Host "=================================================="
    Write-Host "  AlarmAutoDismiss - Test Verification"
    Write-Host "  Target Duration: $TestSeconds seconds"
    Write-Host "=================================================="

    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
    [Windows.UI.Notifications.Management.UserNotificationListener, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $asTaskGeneric = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { 
        $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' 
    } | Select-Object -First 1

    $xml = @"
<toast scenario="alarm">
    <visual>
        <binding template="ToastGeneric">
            <text>${testTag}: Active</text>
            <text>Testing auto-shutoff. Audio will stop in $TestSeconds seconds.</text>
        </binding>
    </visual>
    <audio src="ms-winsoundevent:Notification.Looping.Alarm" loop="true"/>
    <actions>
        <action content="Dismiss" arguments="dismiss" activationType="background"/>
    </actions>
</toast>
"@

    $doc = [Windows.Data.Xml.Dom.XmlDocument]::new()
    $doc.LoadXml($xml)
    $toast = [Windows.UI.Notifications.ToastNotification]::new($doc)
    $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($targetPackage)

    Write-Host "[1/3] Playing alarm toast with looping audio..."
    $notifier.Show($toast)

    $alarmWav = "C:\Windows\Media\Alarm01.wav"
    $soundPlayer = $null
    if (Test-Path $alarmWav) {
        try {
            $soundPlayer = [System.Media.SoundPlayer]::new($alarmWav)
            $soundPlayer.PlayLooping()
        } catch {}
    }

    Write-Host "[2/3] Waiting $TestSeconds seconds..."
    Start-Sleep -Seconds $TestSeconds

    if ($soundPlayer) {
        try { $soundPlayer.Stop() } catch {}
    }

    Write-Host "[3/3] Dismissing alarm notification and halting audio..."
    $listener = [Windows.UI.Notifications.Management.UserNotificationListener]::Current
    $op = $listener.GetNotificationsAsync([Windows.UI.Notifications.NotificationKinds]::Toast)
    $task = $asTaskGeneric.MakeGenericMethod([System.Collections.Generic.IReadOnlyList[Windows.UI.Notifications.UserNotification]]).Invoke($null, @($op))
    $task.Wait()
    $notifs = $task.Result

    $dismissed = $false
    foreach ($n in $notifs) {
        $isTest = $false
        try {
            if ($n.Notification -and $n.Notification.Visual) {
                $b = $n.Notification.Visual.GetBinding("ToastGeneric")
                if ($b) {
                    foreach ($t in $b.GetTextElements()) {
                        if ($t.Text -and $t.Text.Contains($testTag)) { $isTest = $true; break }
                    }
                }
            }
        } catch {}

        if ($isTest) {
            $listener.RemoveNotification($n.Id)
            Write-Host "  -> Dismissed notification ID: $($n.Id)"
            $dismissed = $true
        }
    }

    if ($dismissed) {
        Write-Host "`n[SUCCESS] Test completed! Alarm audio cut off immediately and toast was removed."
    } else {
        Write-Host "`n[INFO] Notification was already dismissed (likely handled by the background daemon)."
    }
    exit 0
}

# --- Action: Default Daemon ---
# Ensure single-instance with caller-SID DACL to prevent squatting
$mutexCreated = $false
$mutex = $null
try {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
    $mutexSec = New-Object System.Security.AccessControl.MutexSecurity
    $accessRule = New-Object System.Security.AccessControl.MutexAccessRule(
        $currentUser,
        [System.Security.AccessControl.MutexRights]::FullControl,
        [System.Security.AccessControl.AccessControlType]::Allow
    )
    $mutexSec.AddAccessRule($accessRule)
    $mutex = New-Object System.Threading.Mutex($true, "Local\AlarmAutoDismiss_PS1_SingleInstance", [ref]$mutexCreated, $mutexSec)
} catch [System.UnauthorizedAccessException] {
    Write-Log "SECURITY ALERT: Mutex exists with an incompatible DACL. Possible squatting attack."
    exit 1
} catch {
    # Fallback to standard constructor if MutexSecurity is restricted in current context
    try {
        $mutex = New-Object System.Threading.Mutex($true, "Local\AlarmAutoDismiss_PS1_SingleInstance", [ref]$mutexCreated)
    } catch {}
}

if (-not $mutexCreated) {
    if ($mutex) { $mutex.Close() }
    Write-Log "Another daemon instance is already running. Exiting silently."
    exit 0
}

try {
    # Rotate log if larger than 512 KB
    if (Test-Path $logPath) {
        try {
            if ((Get-Item $logPath).Length -gt 512KB) {
                $tailLines = Get-Content -Path $logPath -Tail 500 -Encoding UTF8 -ErrorAction SilentlyContinue
                Set-Content -Path $logPath -Value $tailLines -Encoding UTF8 -ErrorAction SilentlyContinue
            }
        } catch {}
    }

# Define EcoQoS and memory compaction helper if not already loaded
if (-not ([System.Management.Automation.PSTypeName]'ProcessEcoMode').Type) {
    try {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class ProcessEcoMode
{
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetCurrentProcess();

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetProcessInformation(
        IntPtr hProcess,
        int ProcessInformationClass,
        ref PROCESS_POWER_THROTTLING_STATE ProcessInformation,
        uint ProcessInformationSize
    );

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetProcessWorkingSetSize(IntPtr hProcess, IntPtr dwMinimumWorkingSetSize, IntPtr dwMaximumWorkingSetSize);

    public const int ProcessPowerThrottling = 4;
    public const uint PROCESS_POWER_THROTTLING_CURRENT_VERSION = 1;
    public const uint PROCESS_POWER_THROTTLING_EXECUTION_SPEED = 0x1;
    public const uint PROCESS_POWER_THROTTLING_IGNORE_TIMER_RESOLUTION = 0x4;

    [StructLayout(LayoutKind.Sequential, Pack = 4)]
    public struct PROCESS_POWER_THROTTLING_STATE
    {
        public uint Version;
        public uint ControlMask;
        public uint StateMask;
    }

    public static bool EnableEcoQoS()
    {
        try {
            PROCESS_POWER_THROTTLING_STATE state = new PROCESS_POWER_THROTTLING_STATE();
            state.Version = PROCESS_POWER_THROTTLING_CURRENT_VERSION;
            state.ControlMask = PROCESS_POWER_THROTTLING_EXECUTION_SPEED | PROCESS_POWER_THROTTLING_IGNORE_TIMER_RESOLUTION;
            state.StateMask = PROCESS_POWER_THROTTLING_EXECUTION_SPEED | PROCESS_POWER_THROTTLING_IGNORE_TIMER_RESOLUTION;

            return SetProcessInformation(
                GetCurrentProcess(),
                ProcessPowerThrottling,
                ref state,
                (uint)Marshal.SizeOf(typeof(PROCESS_POWER_THROTTLING_STATE))
            );
        } catch {
            return false;
        }
    }

    public static void TrimWorkingSet()
    {
        try {
            SetProcessWorkingSetSize(GetCurrentProcess(), (IntPtr)(-1), (IntPtr)(-1));
        } catch { }
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct LASTINPUTINFO
    {
        public uint cbSize;
        public uint dwTime;
    }

    [DllImport("user32.dll")]
    public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

    public static uint GetIdleTimeSeconds()
    {
        try {
            LASTINPUTINFO lii = new LASTINPUTINFO();
            lii.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
            if (GetLastInputInfo(ref lii))
            {
                uint currentTick = (uint)Environment.TickCount;
                uint diff = (currentTick >= lii.dwTime) ? (currentTick - lii.dwTime) : (uint.MaxValue - lii.dwTime + currentTick);
                return diff / 1000;
            }
        } catch { }
        return 0;
    }
}
'@
    } catch {}
}

# Opt into Windows 11 EcoQoS (Efficiency Mode)
$ecoSuccess = $false
try {
    $ecoSuccess = [ProcessEcoMode]::EnableEcoQoS()
} catch {}

Remove-Item $stopSignalPath -Force -ErrorAction SilentlyContinue

Write-Log "=== PowerShell Daemon started (PID: $PID, AlarmTimeout: ${timeoutSeconds}s, TimerTimeout: ${timerTimeoutSeconds}s, SmartIdle: $smartIdleGating, Interval: ${checkIntervalSeconds}s, EcoQoS: $ecoSuccess) ==="

# Initialize WinRT UserNotificationListener
try {
    [Windows.UI.Notifications.Management.UserNotificationListener, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $asTaskGeneric = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { 
        $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' 
    } | Select-Object -First 1

    $listener = [Windows.UI.Notifications.Management.UserNotificationListener]::Current
    $status = $listener.GetAccessStatus()
    if ($status -ne [Windows.UI.Notifications.Management.UserNotificationListenerAccessStatus]::Allowed) {
        Write-Log "WARNING: UserNotificationListener status: $status"
    }
} catch {
    Write-Log "ERROR initializing UserNotificationListener: $($_.Exception.Message)"
    return
}

# Initial memory compaction pass after WinRT assemblies loaded
try {
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [ProcessEcoMode]::TrimWorkingSet()
    $initMb = [math]::Round((Get-Process -Id $PID).WorkingSet64 / 1MB, 2)
    Write-Log "Initial memory compaction applied. Active working set: ${initMb} MB."
} catch {}

# Register Native Watchdog event handlers (Sleep/Resume and Lock/Unlock)
$powerModeHandler = $null
$sessionSwitchHandler = $null
try {
    $powerModeHandler = [Microsoft.Win32.PowerModeChangedEventHandler]{
        param($sender, $e)
        if ($e.Mode -eq [Microsoft.Win32.PowerModes]::Resume) {
            Write-Log "WATCHDOG: System resumed from sleep/standby. Re-evaluating alarms."
            try {
                [System.GC]::Collect()
                [System.GC]::WaitForPendingFinalizers()
                [ProcessEcoMode]::TrimWorkingSet()
            } catch {}
        }
    }
    [Microsoft.Win32.SystemEvents]::add_PowerModeChanged($powerModeHandler)

    $sessionSwitchHandler = [Microsoft.Win32.SessionSwitchEventHandler]{
        param($sender, $e)
        if ($e.Reason -eq [Microsoft.Win32.SessionSwitchReason]::SessionUnlock) {
            Write-Log "WATCHDOG: Workstation unlocked. Active alarms synchronized."
            try {
                [System.GC]::Collect()
                [System.GC]::WaitForPendingFinalizers()
                [ProcessEcoMode]::TrimWorkingSet()
            } catch {}
        } elseif ($e.Reason -eq [Microsoft.Win32.SessionSwitchReason]::SessionLock) {
            Write-Log "WATCHDOG: Workstation locked. Background alarm monitoring active."
        }
    }
    [Microsoft.Win32.SystemEvents]::add_SessionSwitch($sessionSwitchHandler)
    Write-Log "Self-healing watchdog event handlers registered (PowerMode & SessionSwitch)."
} catch {
    Write-Log "WARNING: Could not register SystemEvents watchdog: $($_.Exception.Message)"
}

$firstSeenMap = @{}
$lastIdleLog = @{}
$lastMemoryTrim = [DateTime]::UtcNow
$steadyTrimDone = $false

$lastConfigModified = [DateTime]::MinValue
if (Test-Path $configPath) {
    try { $lastConfigModified = (Get-Item $configPath).LastWriteTimeUtc } catch {}
}

while ($true) {
    # Check for stop signal
    if (Test-Path $stopSignalPath) {
        Write-Log "Stop signal detected. Exiting daemon."
        break
    }

    # Dynamic configuration reload
    if (Test-Path $configPath) {
        try {
            $currModified = (Get-Item $configPath).LastWriteTimeUtc
            if ($currModified -ne $lastConfigModified) {
                $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
                if ($cfg.timeoutSeconds -gt 0 -and $cfg.timeoutSeconds -ne $timeoutSeconds) {
                    $timeoutSeconds = $cfg.timeoutSeconds
                    Write-Log "Settings reloaded from config.json: Alarm timeout set to ${timeoutSeconds}s."
                }
                if ($cfg.timerTimeoutSeconds -gt 0 -and $cfg.timerTimeoutSeconds -ne $timerTimeoutSeconds) {
                    $timerTimeoutSeconds = $cfg.timerTimeoutSeconds
                    Write-Log "Settings reloaded from config.json: Timer timeout set to ${timerTimeoutSeconds}s."
                }
                if ($null -ne $cfg.smartIdleGating -and $cfg.smartIdleGating -ne $smartIdleGating) {
                    $smartIdleGating = [bool]$cfg.smartIdleGating
                    Write-Log "Settings reloaded from config.json: Smart Idle Gating set to ${smartIdleGating}."
                }
                if ($null -ne $cfg.notifyOnDismiss -and $cfg.notifyOnDismiss -ne $notifyOnDismiss) {
                    $notifyOnDismiss = [bool]$cfg.notifyOnDismiss
                    Write-Log "Settings reloaded from config.json: Notify On Dismiss set to ${notifyOnDismiss}."
                }
                if ($null -ne $cfg.loggingEnabled -and $cfg.loggingEnabled -ne $loggingEnabled) {
                    $loggingEnabled = [bool]$cfg.loggingEnabled
                    Write-Log "Settings reloaded from config.json: Logging Enabled set to ${loggingEnabled}."
                }
                if ($cfg.checkIntervalSeconds -gt 0) {
                    $checkIntervalSeconds = $cfg.checkIntervalSeconds
                }
                # Concurrency hardening: only advance timestamp marker after successful parse
                $lastConfigModified = $currModified
            }
        } catch {}
    }

    try {
        # Query active toast notifications
        $op = $listener.GetNotificationsAsync([Windows.UI.Notifications.NotificationKinds]::Toast)
        $task = $asTaskGeneric.MakeGenericMethod([System.Collections.Generic.IReadOnlyList[Windows.UI.Notifications.UserNotification]]).Invoke($null, @($op))
        $null = $task.Wait(4000)
        $notifs = $task.Result

        $currentIds = [System.Collections.Generic.HashSet[uint32]]::new()

        if ($notifs) {
            foreach ($n in $notifs) {
                if (-not $n) { continue }
                $id = $n.Id
                [void]$currentIds.Add($id)

                    # Strict Filter: Only Windows Clock alarms/timers or synthetic test toasts
                    $isClockAlarm = $false
                    $isTestToast = $false

                    try {
                        if ($n.AppInfo) {
                            $pfn = $n.AppInfo.PackageFamilyName
                            $aumid = $n.AppInfo.AppUserModelId
                            if ($pfn -eq $targetPackage -or ($aumid -and $aumid -like "*WindowsAlarms*")) {
                                $isClockAlarm = $true
                            }
                        }
                    } catch {}

                    # Inspect binding for test tag and timer discrimination
                    $isTimer = $false
                    try {
                        if ($n.Notification -and $n.Notification.Visual) {
                            $b = $n.Notification.Visual.GetBinding("ToastGeneric")
                            if ($b) {
                                foreach ($t in $b.GetTextElements()) {
                                    if ($t.Text) {
                                        if ($t.Text.Contains($testTag)) { $isTestToast = $true }
                                        if ($t.Text -match "(?i)\btimer\b") { $isTimer = $true }
                                    }
                                }
                            }
                        }
                    } catch {}

                    # Strictly ignore all unrelated notifications
                    if (-not $isClockAlarm -and -not $isTestToast) {
                        continue
                    }

                    $typeStr = if ($isTestToast) { "Test Alarm" } elseif ($isTimer) { "Clock Timer" } else { "Clock Alarm" }
                    $effectiveThreshold = if ($isTestToast) { 10 } elseif ($isTimer) { $timerTimeoutSeconds } else { $timeoutSeconds }

                    # Track ringing duration
                    $now = Get-Date
                    if (-not $firstSeenMap.ContainsKey($id)) {
                        $firstSeenMap[$id] = $now
                        Write-Log "ACTIVE: Ringing $typeStr detected (ID: $id). Starting auto-shutoff countdown (${effectiveThreshold}s threshold)."
                    }

                    $localElapsed = ($now - $firstSeenMap[$id]).TotalSeconds
                    $creationElapsed = 0
                    try {
                        $creationElapsed = ($now - $n.CreationTime.DateTime).TotalSeconds
                    } catch {}

                    # Clock-skew and step defense: enforce non-negative elapsed duration
                    $elapsed = [Math]::Max(0.0, [Math]::Max($localElapsed, $creationElapsed))

                    if ($elapsed -ge $effectiveThreshold) {
                        # Smart Idle Gating check: delay shutoff if user actively used keyboard/mouse within last 30s
                        if ($smartIdleGating -and -not $isTestToast) {
                            $idleSec = [ProcessEcoMode]::GetIdleTimeSeconds()
                            if ($idleSec -lt 30) {
                                # Hard ceiling: allow maximum 60s grace period beyond threshold
                                $maxGraceCeiling = $effectiveThreshold + 60
                                if ($elapsed -lt $maxGraceCeiling) {
                                    if (-not $lastIdleLog.ContainsKey($id) -or ($now - $lastIdleLog[$id]).TotalSeconds -ge 30) {
                                        $lastIdleLog[$id] = $now
                                        Write-Log "IDLE-GATE: Active user presence detected (${idleSec}s idle < 30s threshold). Deferring auto-dismiss for $typeStr (ID: $id) while user is active (max grace: ${maxGraceCeiling}s)."
                                    }
                                    continue
                                } else {
                                    Write-Log "IDLE-GATE: Maximum deferral ceiling reached (${elapsed}s >= ${maxGraceCeiling}s). Overriding idle gate to auto-dismiss $typeStr (ID: $id)."
                                }
                            }
                        }

                        Write-Log "TIMEOUT: $typeStr (ID: $id) reached [${elapsed}s >= ${effectiveThreshold}s]. AUTO-DISMISSING NOW..."
                        try {
                            $listener.RemoveNotification($id)
                            Write-Log "SUCCESS: Notification ID $id dismissed. Looping audio terminated."
                        } catch {
                            Write-Log "ERROR dismissing notification ID ${id}: $($_.Exception.Message)"
                        }

                        if ($notifyOnDismiss -and -not $isTestToast) {
                            $mTitle = if ($isTimer) { "Missed Countdown Timer" } else { "Missed Clock Alarm" }
                            $mBody = if ($isTimer) {
                                "Countdown timer completed and was silenced after ${timerTimeoutSeconds}s."
                            } else {
                                $mins = [math]::Round($timeoutSeconds / 60, 1)
                                "Clock alarm rang and was automatically silenced after ${mins} minutes."
                            }
                            Send-SilentMissedToast $mTitle $mBody
                            Write-Log "NOTIFY: Silent reminder posted to Notification Center ($mTitle)."
                        }

                        $firstSeenMap.Remove($id)
                        $lastIdleLog.Remove($id)
                        try {
                            [System.GC]::Collect()
                            [System.GC]::WaitForPendingFinalizers()
                            [ProcessEcoMode]::TrimWorkingSet()
                        } catch {}
                    }
                }
            }

            # Clean up tracking for user-dismissed alarms
            $trackedKeys = @($firstSeenMap.Keys)
            $resetAny = $false
            foreach ($trackedId in $trackedKeys) {
                if (-not $currentIds.Contains($trackedId)) {
                    Write-Log "RESET: Notification ID $trackedId was manually dismissed/snoozed by user. Resetting countdown."
                    $firstSeenMap.Remove($trackedId)
                    $lastIdleLog.Remove($trackedId)
                    $resetAny = $true
                }
            }
            if ($resetAny) {
                try {
                    [System.GC]::Collect()
                    [System.GC]::WaitForPendingFinalizers()
                    [ProcessEcoMode]::TrimWorkingSet()
                } catch {}
            }
        } catch {
            Write-Log "Warning in poll loop: $($_.Exception.Message)"
        }

        # Steady-state memory compaction (after first full iteration loads all WinRT JIT code)
        if (-not $steadyTrimDone) {
            $steadyTrimDone = $true
            try {
                [System.GC]::Collect()
                [System.GC]::WaitForPendingFinalizers()
                [ProcessEcoMode]::TrimWorkingSet()
                $curMb = [math]::Round((Get-Process -Id $PID).WorkingSet64 / 1MB, 2)
                Write-Log "Steady-state memory compaction applied. Active working set: ${curMb} MB."
            } catch {}
        }

        # Periodic memory compaction (every 10 minutes, or when idle working set exceeds 25MB)
        $timeSinceTrim = [DateTime]::UtcNow - $lastMemoryTrim
        $needTrim = ($timeSinceTrim.TotalMinutes -ge 10) -or ($firstSeenMap.Count -eq 0 -and $timeSinceTrim.TotalSeconds -ge 60 -and [System.Diagnostics.Process]::GetCurrentProcess().WorkingSet64 -gt 25MB)
        if ($needTrim) {
            $lastMemoryTrim = [DateTime]::UtcNow
            try {
                [System.GC]::Collect()
                [System.GC]::WaitForPendingFinalizers()
                [ProcessEcoMode]::TrimWorkingSet()
            } catch {}
        }

        Start-Sleep -Seconds $checkIntervalSeconds
    }
} finally {
    Write-Log "=== PowerShell Daemon stopped gracefully ==="
    try {
        if ($powerModeHandler) {
            [Microsoft.Win32.SystemEvents]::remove_PowerModeChanged($powerModeHandler)
        }
        if ($sessionSwitchHandler) {
            [Microsoft.Win32.SystemEvents]::remove_SessionSwitch($sessionSwitchHandler)
        }
    } catch {}
    Remove-Item $stopSignalPath -Force -ErrorAction SilentlyContinue
    if ($mutex) {
        try { $mutex.ReleaseMutex() } catch {}
        $mutex.Close()
    }
}
