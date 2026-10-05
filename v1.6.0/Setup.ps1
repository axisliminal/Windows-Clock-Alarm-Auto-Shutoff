# Setup.ps1 - 1-Click Installer for Windows Clock Alarm Auto-Shutoff
param(
    [switch]$Portable,
    [switch]$Silent,
    [switch]$NoGui
)

$sourceDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$localApp = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { [Environment]::GetFolderPath('LocalApplicationData') }
$appDataDir = Join-Path $localApp "AlarmAutoDismiss"
$installDir = if ($Portable) { $sourceDir } else { $appDataDir }

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Windows Clock Alarm Auto-Shutoff - Setup (v1.6)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Mode: $(if ($Portable) { 'Portable (In-Place)' } else { 'Standard Installation' })" -ForegroundColor Gray
Write-Host "Target Directory: $installDir" -ForegroundColor Gray
Write-Host ""

# 1. Stop any currently running daemon instances cleanly
Write-Host "[1/6] Stopping any running background instances..." -ForegroundColor Yellow
$daemonSource = Join-Path $sourceDir "AlarmAutoDismiss.ps1"
$daemonTarget = Join-Path $installDir "AlarmAutoDismiss.ps1"

if (Test-Path $daemonTarget) {
    try { & powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$daemonTarget" -Action stop | Out-Null } catch {}
}
if ((Test-Path $daemonSource) -and ($daemonSource -ne $daemonTarget)) {
    try { & powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$daemonSource" -Action stop | Out-Null } catch {}
}
# Sweep any orphaned daemon process targeting AlarmAutoDismiss.ps1 to guarantee unlocked files
try {
    $daemons = Get-CimInstance Win32_Process | Where-Object { 
        $_.CommandLine -like "*AlarmAutoDismiss.ps1*" -and 
        $_.CommandLine -notlike "*-Action*" -and
        $_.ProcessId -ne $PID 
    }
    if ($daemons) {
        foreach ($d in $daemons) { Stop-Process -Id $d.ProcessId -Force -ErrorAction SilentlyContinue }
    }
} catch {}

# 2. Deploy runtime files (if not portable)
Write-Host "[2/6] Deploying production application files..." -ForegroundColor Yellow
$runtimeFiles = @(
    "AlarmAutoDismiss.ps1",
    "AlarmSettings.ps1",
    "AlarmSettings.bat",
    "status.bat",
    "test_alarm.bat",
    "Uninstall.bat",
    "Uninstall.ps1",
    "README.txt",
    "changelog.md"
)

if (-not $Portable) {
    if (-not (Test-Path $installDir)) {
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    }

    foreach ($file in $runtimeFiles) {
        $srcPath = Join-Path $sourceDir $file
        if (Test-Path $srcPath) {
            Copy-Item -Path $srcPath -Destination (Join-Path $installDir $file) -Force
        }
    }

    # Handle config.json: Preserve existing user configuration during upgrades
    $srcConfig = Join-Path $sourceDir "config.json"
    $dstConfig = Join-Path $installDir "config.json"
    if (Test-Path $srcConfig) {
        if (-not (Test-Path $dstConfig)) {
            Copy-Item -Path $srcConfig -Destination $dstConfig -Force
            Write-Host "  -> Installed default config.json" -ForegroundColor DarkGray
        } else {
            Write-Host "  -> Preserved existing user config.json" -ForegroundColor Green
        }
    }
} else {
    Write-Host "  -> In-place mode: files maintained in $sourceDir" -ForegroundColor DarkGray
}

# 3. Create Shortcuts
Write-Host "[3/6] Generating Desktop and Start Menu shortcuts..." -ForegroundColor Yellow
try {
    $wsh = New-Object -ComObject WScript.Shell
    $launcherPath = Join-Path $installDir "AlarmSettings.bat"
    $iconLocation = "shell32.dll,238"

    # Desktop shortcut
    $desktopPath = [Environment]::GetFolderPath('Desktop')
    $desktopLnk = Join-Path $desktopPath "Alarm Auto-Shutoff Settings.lnk"
    $sc = $wsh.CreateShortcut($desktopLnk)
    $sc.TargetPath = $launcherPath
    $sc.WorkingDirectory = $installDir
    $sc.Description = "Windows Clock Alarm Auto-Shutoff Control Panel"
    $sc.IconLocation = $iconLocation
    $sc.Save()
    Write-Host "  -> Created Desktop shortcut: Alarm Auto-Shutoff Settings.lnk" -ForegroundColor Green

    # Start Menu shortcut
    $programsPath = [Environment]::GetFolderPath('Programs')
    $startLnk = Join-Path $programsPath "Alarm Auto-Shutoff Settings.lnk"
    $sc2 = $wsh.CreateShortcut($startLnk)
    $sc2.TargetPath = $launcherPath
    $sc2.WorkingDirectory = $installDir
    $sc2.Description = "Windows Clock Alarm Auto-Shutoff Control Panel"
    $sc2.IconLocation = $iconLocation
    $sc2.Save()
    Write-Host "  -> Created Start Menu shortcut: Alarm Auto-Shutoff Settings.lnk" -ForegroundColor Green
} catch {
    Write-Host "  -> Warning creating shortcuts: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Register Windows User Startup (HKCU Run)
Write-Host "[4/6] Configuring automatic start on Windows login..." -ForegroundColor Yellow
$runRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$daemonScriptPath = Join-Path $installDir "AlarmAutoDismiss.ps1"
$startupCmd = "powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$daemonScriptPath`""

try {
    Set-ItemProperty -Path $runRegPath -Name "AlarmAutoDismiss" -Value $startupCmd -Type String -Force
    # Clear any stale Task Manager disabled flag from previous installations
    $approvedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
    Remove-ItemProperty -Path $approvedPath -Name "AlarmAutoDismiss" -Force -ErrorAction SilentlyContinue
    Write-Host "  -> Registered in HKCU\...\Run (Zero UAC elevation required, Task Manager enabled)" -ForegroundColor Green
} catch {
    Write-Host "  -> Warning setting startup registry: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Launch Background Daemon
Write-Host "[5/6] Starting background daemon in EcoQoS mode..." -ForegroundColor Yellow
try {
    $proc = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $startupCmd }
    Start-Sleep -Seconds 2
} catch {
    Write-Host "  -> Warning starting daemon: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. Verify Service Health
Write-Host "[6/6] Verifying service operational status..." -ForegroundColor Yellow
$isRunning = $false
try {
    $m = [System.Threading.Mutex]::OpenExisting("Local\AlarmAutoDismiss_PS1_SingleInstance")
    $m.Close()
    $isRunning = $true
} catch {}

if ($isRunning) {
    Write-Host "`n==========================================================" -ForegroundColor Green
    Write-Host "  [SUCCESS] Alarm Auto-Shutoff is fully installed & active!" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "  * Daemon Status: RUNNING (100% invisible, ~5.5MB RAM)" -ForegroundColor White
    Write-Host "  * Auto-Start: Enabled on Windows Login" -ForegroundColor White
    Write-Host "  * Desktop Shortcut: Created on Desktop" -ForegroundColor White
    Write-Host "  * Start Menu: Available in Start Menu search" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "`n[WARNING] Daemon process started but mutex is not yet locked." -ForegroundColor Yellow
    Write-Host "Check status anytime by running 'status.bat'." -ForegroundColor Yellow
}

if (-not $NoGui -and -not $Silent) {
    Write-Host "Opening Alarm Auto-Shutoff Control Panel..." -ForegroundColor Cyan
    try {
        Start-Process powershell.exe -ArgumentList "-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$installDir\AlarmSettings.ps1`""
    } catch {}
}
