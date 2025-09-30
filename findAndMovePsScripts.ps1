#!/usr/bin/env pwsh
# Script to find and move remaining PS1 scripts to the scripts folder

$rootDir = $PSScriptRoot
$scriptsDir = Join-Path -Path $rootDir -ChildPath "scripts"

# Make sure scripts directory exists
if (-not (Test-Path $scriptsDir)) {
    New-Item -Path $scriptsDir -ItemType Directory -Force | Out-Null
    Write-Host "Created scripts directory" -ForegroundColor Yellow
}

# Get all PS1 files in root directory except plugin.ps1
$psFiles = Get-ChildItem -Path $rootDir -Filter "*.ps1" | Where-Object { $_.Name -ne "plugin.ps1" -and $_.Name -ne "findAndMovePsScripts.ps1" }

if ($psFiles.Count -eq 0) {
    Write-Host "No PS1 files to move." -ForegroundColor Green
    exit 0
}

Write-Host "Found $($psFiles.Count) PS1 files in root directory:" -ForegroundColor Yellow
$psFiles | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }

Write-Host "`nMoving files to scripts directory..." -ForegroundColor Yellow

foreach ($file in $psFiles) {
    $destPath = Join-Path -Path $scriptsDir -ChildPath $file.Name
    
    if (Test-Path $destPath) {
        Write-Host "WARNING: File already exists in scripts directory: $($file.Name)" -ForegroundColor Yellow
        $choice = Read-Host "Replace? (y/n)"
        if ($choice -ne "y") {
            Write-Host "Skipped: $($file.Name)" -ForegroundColor Gray
            continue
        }
    }
    
    Move-Item -Path $file.FullName -Destination $destPath -Force
    Write-Host "Moved: $($file.Name)" -ForegroundColor Green
}

Write-Host "`nAll PS1 files have been moved to the scripts directory." -ForegroundColor Green
Write-Host "You may need to update references to these scripts in your project." -ForegroundColor Yellow