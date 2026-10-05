# package_dist.ps1 - Automated Distribution Packager for Alarm Auto-Shutoff
param(
    [string]$Version = "1.6.1"
)

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$projectRoot = if (Test-Path (Join-Path $scriptDir "AlarmAutoDismiss.ps1")) { $scriptDir } else { Split-Path -Parent $scriptDir }
$distRoot = Join-Path $projectRoot "dist"
$distFolder = Join-Path $distRoot "AlarmAutoDismiss"
$zipFile = Join-Path $distRoot "AlarmAutoDismiss-v$Version.zip"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Alarm Auto-Shutoff - Distribution Packager (v$Version)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Source Root: $projectRoot" -ForegroundColor Gray
Write-Host "Output Dist: $distFolder" -ForegroundColor Gray
Write-Host "Output ZIP:  $zipFile" -ForegroundColor Gray
Write-Host ""

# 1. Clean previous build artifacts
Write-Host "[1/5] Cleaning previous distribution artifacts..." -ForegroundColor Yellow
if (Test-Path $distRoot) {
    Remove-Item -Path $distRoot -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $distFolder -Force | Out-Null

# 2. Files to package
$packageFiles = @(
    "AlarmAutoDismiss.ps1",
    "AlarmSettings.ps1",
    "AlarmSettings.bat",
    "config.json",
    "Setup.bat",
    "Setup.ps1",
    "Uninstall.bat",
    "Uninstall.ps1",
    "status.bat",
    "test_alarm.bat",
    "README.txt",
    "changelog.md"
)

Write-Host "[2/5] Copying release files to staging directory..." -ForegroundColor Yellow
foreach ($file in $packageFiles) {
    $src = Join-Path $projectRoot $file
    if (-not (Test-Path $src)) {
        Write-Host "ERROR: Missing required release file: $file" -ForegroundColor Red
        exit 1
    }

    # Pre-flight JSON validation for config.json
    if ($file -eq "config.json") {
        try {
            $parsed = Get-Content $src -Raw | ConvertFrom-Json
            if ($null -eq $parsed.timeoutSeconds -or $null -eq $parsed.timerTimeoutSeconds) {
                Write-Host "ERROR: config.json missing required timeout keys!" -ForegroundColor Red
                exit 1
            }
        } catch {
            Write-Host "ERROR: Invalid JSON in config.json: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    }

    Copy-Item -Path $src -Destination (Join-Path $distFolder $file) -Force
    $size = (Get-Item $src).Length
    Write-Host "  -> Bundled: $file ($size bytes)" -ForegroundColor DarkGray
}

# 3. Guardrail and Constraint Validation
Write-Host "[3/5] Validating architectural guardrails..." -ForegroundColor Yellow
$guiPath = Join-Path $distFolder "AlarmSettings.ps1"
$guiSize = (Get-Item $guiPath).Length
if ($guiSize -ge 24000) {
    Write-Host "ERROR: AlarmSettings.ps1 size ($guiSize bytes) exceeds the 24,000-byte budget!" -ForegroundColor Red
    exit 1
}
Write-Host "  [PASS] AlarmSettings.ps1 size constraint: $guiSize / 24,000 bytes ($([math]::Round((24000 - $guiSize))) bytes headroom)" -ForegroundColor Green

# Verify zero third-party binaries or developer residue
$allDistFiles = Get-ChildItem -Path $distFolder -Recurse
$disallowedExts = @(".exe", ".dll", ".cs", ".log", ".tmp", ".pdb")
foreach ($f in $allDistFiles) {
    if ($disallowedExts -contains $f.Extension.ToLower()) {
        Write-Host "ERROR: Disallowed file extension found in dist: $($f.Name)" -ForegroundColor Red
        exit 1
    }
}
Write-Host "  [PASS] Zero-binary mandate verified (no .exe, .dll, or developer artifacts in package)" -ForegroundColor Green

# 4. Generate standalone ZIP archive
Write-Host "[4/5] Generating compressed release archive..." -ForegroundColor Yellow
try {
    Compress-Archive -Path "$distFolder\*" -DestinationPath $zipFile -Force
    $zipSize = (Get-Item $zipFile).Length
    Write-Host "  [PASS] Release archive created: $(Split-Path -Leaf $zipFile) ($([math]::Round($zipSize / 1KB, 1)) KB)" -ForegroundColor Green
} catch {
    Write-Host "ERROR compressing archive: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 5. Summary and SHA-256 Hash
Write-Host "[5/5] Generating release verification manifest..." -ForegroundColor Yellow
$zipHash = (Get-FileHash -Path $zipFile -Algorithm SHA256).Hash.ToLower()

# Copy archive and manifest to project root and clean staging
$finalZip = Join-Path $projectRoot "AlarmAutoDismiss-v$Version.zip"
Copy-Item -Path $zipFile -Destination $finalZip -Force

$manifestPath = Join-Path $projectRoot "SHA256SUMS"
"$zipHash  AlarmAutoDismiss-v$Version.zip" | Out-File -FilePath $manifestPath -Encoding ascii

Remove-Item -Path $distRoot -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  [SUCCESS] Distribution Package v$Version Ready!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Archive Path:   $finalZip" -ForegroundColor White
Write-Host "Archive SHA256: $zipHash" -ForegroundColor Cyan
Write-Host "Manifest File:  $manifestPath" -ForegroundColor White
Write-Host "Package Files:  $($packageFiles.Count) files" -ForegroundColor White
Write-Host ""
