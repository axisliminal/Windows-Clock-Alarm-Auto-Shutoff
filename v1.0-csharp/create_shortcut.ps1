$wsh = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath('Desktop')
$baseDir = if (Test-Path (Join-Path $PSScriptRoot 'AlarmSettings.bat')) { $PSScriptRoot } else { Split-Path -Parent $PSScriptRoot }
$target = Join-Path $baseDir 'AlarmSettings.bat'
$lnkPath = Join-Path $desktop 'Alarm Auto-Shutoff Settings.lnk'
$shortcut = $wsh.CreateShortcut($lnkPath)
$shortcut.TargetPath = $target
$shortcut.WorkingDirectory = $baseDir
$shortcut.Description = 'Windows Clock Alarm Auto-Shutoff Control Panel'
$shortcut.IconLocation = 'shell32.dll,238'
$shortcut.Save()
Write-Host "[SUCCESS] Shortcut created on Desktop: Alarm Auto-Shutoff Settings.lnk"
