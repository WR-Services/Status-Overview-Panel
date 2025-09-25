#!/usr/bin/env pwsh
# Script to update version numbers across the project

param(
    [Parameter(Mandatory = $true)]
    [string]$NewVersion,
    
    [Parameter(Mandatory = $false)]
    [string]$ReleaseType = "dev-release",
    
    [Parameter(Mandatory = $false)]
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
$oldVersion = $packageJson.version
$packageJson.version = $NewVersion
$packageJson | ConvertTo-Json -Depth 100 | Set-Content -Path "package.json"
Write-Host "  Changed from v$oldVersion to v$NewVersion" -ForegroundColor Gray

# 2. Update plugin.json
Write-Host "Updating src/plugin.json..." -ForegroundColor Yellow
$pluginJson = Get-Content -Path "src/plugin.json" -Raw | ConvertFrom-Json
$oldPluginVersion = $pluginJson.info.version
$pluginJson.info.version = $NewVersion
$pluginJson | ConvertTo-Json -Depth 100 | Set-Content -Path "src/plugin.json"
Write-Host "  Changed from v$oldPluginVersion to v$NewVersion" -ForegroundColor Gray

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
}
else {
    # Insert new version at the top of the changelog
    $updatedChangelog = $newVersionEntry + "`n" + ($changelog -replace "# Changelog\r?\n", "")
    $updatedChangelog | Set-Content -Path "CHANGELOG.md"
}

Write-Host "Version update complete!" -ForegroundColor Green
Write-Host "Don't forget to update the CHANGELOG.md with actual changes." -ForegroundColor Yellow

# Verify all files have been updated correctly
Write-Host "`nVerifying version updates:" -ForegroundColor Cyan
$packageJsonCheck = Get-Content -Path "package.json" -Raw | ConvertFrom-Json
$pluginJsonCheck = Get-Content -Path "src/plugin.json" -Raw | ConvertFrom-Json

Write-Host "package.json: $($packageJsonCheck.version)" -ForegroundColor $(if ($packageJsonCheck.version -eq $NewVersion) { "Green" } else { "Red" })
Write-Host "plugin.json: $($pluginJsonCheck.info.version)" -ForegroundColor $(if ($pluginJsonCheck.info.version -eq $NewVersion) { "Green" } else { "Red" })

if ($packageJsonCheck.version -ne $NewVersion -or $pluginJsonCheck.info.version -ne $NewVersion) {
    Write-Host "`n⚠️ WARNING: Not all version numbers were updated correctly!" -ForegroundColor Red
    Write-Host "Run the script again or check the files manually." -ForegroundColor Red
}
else {
    Write-Host "`n✅ All version numbers updated successfully to v$NewVersion" -ForegroundColor Green
    Write-Host "Run .\clean-build.ps1 followed by .\package-plugin.ps1 to create a package with the new version." -ForegroundColor Cyan
}