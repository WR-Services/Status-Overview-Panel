#!/usr/bin/env pwsh
# Script to update version numbers across the project

param(
    [Parameter(Mandatory=$true)]
    [string]$NewVersion,
    
    [Parameter(Mandatory=$false)]
    [string]$ReleaseType = "dev-release",
    
    [Parameter(Mandatory=$false)]
    [string]$ReleaseDate = (Get-Date -Format "dd-MM-yyyy")
)

# Validate version format
if ($NewVersion -notmatch '^\d+\.\d+\.\d+$') {
    Write-Host "Error: Version must be in format X.Y.Z" -ForegroundColor Red
    exit 1
}

Write-Host "Updating plugin version to $NewVersion ($ReleaseType) released on $ReleaseDate" -ForegroundColor Cyan

# 1. Update package.json
Write-Host "Updating package.json..." -ForegroundColor Yellow
$packageJson = Get-Content -Path "package.json" -Raw | ConvertFrom-Json
$packageJson.version = $NewVersion
$packageJson | ConvertTo-Json -Depth 100 | Set-Content -Path "package.json"

# 2. Update plugin.json
Write-Host "Updating src/plugin.json..." -ForegroundColor Yellow
$pluginJson = Get-Content -Path "src/plugin.json" -Raw | ConvertFrom-Json
$pluginJson.info.version = $NewVersion
$pluginJson | ConvertTo-Json -Depth 100 | Set-Content -Path "src/plugin.json"

# 3. Update CHANGELOG.md
Write-Host "Updating CHANGELOG.md..." -ForegroundColor Yellow
$changelog = Get-Content -Path "CHANGELOG.md" -Raw
$newVersionEntry = @"
# Changelog

## [v$NewVersion] ($ReleaseType)

Released at $ReleaseDate

### Added

- 

### Fixed

- 

"@

# Check if the version already exists in the changelog
if ($changelog -match "\[v$NewVersion\]") {
    Write-Host "Warning: Version v$NewVersion already exists in CHANGELOG.md" -ForegroundColor Yellow
} else {
    # Insert new version at the top of the changelog
    $updatedChangelog = $newVersionEntry + "`n" + ($changelog -replace "# Changelog\r?\n", "")
    $updatedChangelog | Set-Content -Path "CHANGELOG.md"
}

Write-Host "Version update complete!" -ForegroundColor Green
Write-Host "Don't forget to update the CHANGELOG.md with actual changes." -ForegroundColor Yellow