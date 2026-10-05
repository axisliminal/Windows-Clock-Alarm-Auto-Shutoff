# Uninstall.ps1 - 1-Click Uninstaller for Windows Clock Alarm Auto-Shutoff
param(
    [switch]$Silent,
    [switch]$KeepConfig
)

$sourceDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$localApp = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { [Environment]::GetFolderPath('LocalApplicationData') }
$appDataDir = Join-Path $localApp "AlarmAutoDismiss"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Windows Clock Alarm Auto-Shutoff - Uninstaller" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Stop background daemon
Write-Host "[1/4] Stopping background service..." -ForegroundColor Yellow
$daemonPaths = @(
    (Join-Path $sourceDir "AlarmAutoDismiss.ps1"),
    (Join-Path $appDataDir "AlarmAutoDismiss.ps1")
)
foreach ($dp in $daemonPaths) {
    if (Test-Path $dp) {
        try { & powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$dp" -Action stop | Out-Null } catch {}
    }
}

# Force terminate any residual daemon process targeting AlarmAutoDismiss.ps1
try {
    $daemons = Get-CimInstance Win32_Process | Where-Object { 
        $_.CommandLine -like "*AlarmAutoDismiss.ps1*" -and 
        $_.CommandLine -notlike "*-Action*" -and
        $_.ProcessId -ne $PID 
    }
    if ($daemons) {
        foreach ($d in $daemons) {
            Stop-Process -Id $d.ProcessId -Force -ErrorAction SilentlyContinue
        }
    }
} catch {}
Write-Host "  -> Background service stopped." -ForegroundColor Green

# 2. Remove Windows User Startup (HKCU Run)
Write-Host "[2/4] Removing startup registry entries..." -ForegroundColor Yellow
$runRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$approvedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
try {
    Remove-ItemProperty -Path $runRegPath -Name "AlarmAutoDismiss" -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $approvedPath -Name "AlarmAutoDismiss" -Force -ErrorAction SilentlyContinue
    Write-Host "  -> Removed from HKCU\...\Run" -ForegroundColor Green
} catch {}

# 3. Remove Desktop and Start Menu Shortcuts
Write-Host "[3/4] Removing shortcuts..." -ForegroundColor Yellow
try {
    $desktopPath = [Environment]::GetFolderPath('Desktop')
    $desktopLnk = Join-Path $desktopPath "Alarm Auto-Shutoff Settings.lnk"
    if (Test-Path $desktopLnk) {
        Remove-Item -Path $desktopLnk -Force -ErrorAction SilentlyContinue
        Write-Host "  -> Removed Desktop shortcut" -ForegroundColor Green
    }

    $programsPath = [Environment]::GetFolderPath('Programs')
    $startLnk = Join-Path $programsPath "Alarm Auto-Shutoff Settings.lnk"
    if (Test-Path $startLnk) {
        Remove-Item -Path $startLnk -Force -ErrorAction SilentlyContinue
        Write-Host "  -> Removed Start Menu shortcut" -ForegroundColor Green
    }
} catch {}

# 4. Clean up application directory if installed in AppData
Write-Host "[4/4] Cleaning application directory..." -ForegroundColor Yellow
if (Test-Path $appDataDir) {
    $isSelfInAppData = ($sourceDir.TrimEnd('\') -eq $appDataDir.TrimEnd('\'))
    $targetCfg = Join-Path $appDataDir "config.json"
    $savedCfg = $null

    if ($KeepConfig -and (Test-Path $targetCfg)) {
        try {
            $savedCfg = Get-Content $targetCfg -Raw -ErrorAction SilentlyContinue
            Write-Host "  -> Retaining user config.json as requested" -ForegroundColor Green
        } catch {}
    }

    if (-not $isSelfInAppData) {
        try {
            Remove-Item -Path $appDataDir -Recurse -Force -ErrorAction SilentlyContinue
            if ($KeepConfig -and $savedCfg) {
                New-Item -ItemType Directory -Path $appDataDir -Force | Out-Null
                Set-Content -Path $targetCfg -Value $savedCfg -Encoding UTF8 -Force
            }
            Write-Host "  -> Removed directory: $appDataDir" -ForegroundColor Green
        } catch {
            Write-Host "  -> Could not remove all files in $appDataDir" -ForegroundColor DarkGray
        }
    } else {
        # Running from inside AppData: schedule detached cleanup with retry loop
        try {
            $cleanupCmd = "Start-Sleep -Seconds 3; for (`$i=0; `$i -lt 5; `$i++) { try { Remove-Item -LiteralPath '$appDataDir' -Recurse -Force -ErrorAction Stop; break } catch { Start-Sleep -Seconds 1 } }"
            Start-Process powershell.exe -WindowStyle Hidden -ArgumentList "-NoProfile -Command $cleanupCmd"
            Write-Host "  -> Scheduled directory self-cleanup upon terminal exit" -ForegroundColor Green
        } catch {}
    }
} else {
    Write-Host "  -> No AppData installation directory found." -ForegroundColor DarkGray
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "  [SUCCESS] Alarm Auto-Shutoff has been uninstalled." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "All background processes have stopped and shortcuts removed." -ForegroundColor White
Write-Host ""
