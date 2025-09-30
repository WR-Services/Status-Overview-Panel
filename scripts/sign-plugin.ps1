#!/usr/bin/env pwsh
# Script to sign the Grafana plugin using the Grafana Plugin Signing Service

param(
    [Parameter(Mandatory=$true)]
    [string]$ApiKey,
    
    [Parameter(Mandatory=$false)]
    [string]$PluginId = "wrservices-statusoverview-panel",
    
    [Parameter(Mandatory=$false)]
    [string]$PackagePath = "package"
)

# Check if the plugin has been packaged
$zipFile = Get-ChildItem -Path $PackagePath -Filter "$PluginId-*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $zipFile) {
    Write-Host "Error: No plugin package found in $PackagePath directory." -ForegroundColor Red
    Write-Host "Please run package-plugin.ps1 first." -ForegroundColor Red
    exit 1
}

Write-Host "Found plugin package: $($zipFile.Name)" -ForegroundColor Cyan

# Check for MD5 checksum file
$md5File = $zipFile.FullName + ".md5"
if (-not (Test-Path $md5File)) {
    Write-Host "Error: MD5 checksum file not found: $md5File" -ForegroundColor Red
    exit 1
}

$md5 = Get-Content -Path $md5File -Raw

Write-Host "Submitting plugin for signing..." -ForegroundColor Yellow
Write-Host "Plugin ID: $PluginId" -ForegroundColor Yellow
Write-Host "Package: $($zipFile.FullName)" -ForegroundColor Yellow
Write-Host "MD5: $md5" -ForegroundColor Yellow

# Here we would typically call the Grafana Plugin Signing API
# For security reasons, we'll just provide instructions

Write-Host "`nTo sign your plugin:" -ForegroundColor Green
Write-Host "1. Go to https://grafana.com/developers/plugin-tools/publish-a-plugin/sign-a-plugin" -ForegroundColor Green
Write-Host "2. Use your API key: $ApiKey" -ForegroundColor Green
Write-Host "3. Submit your plugin ID: $PluginId" -ForegroundColor Green
Write-Host "4. Upload your ZIP file: $($zipFile.FullName)" -ForegroundColor Green
Write-Host "5. Provide the MD5 checksum: $md5" -ForegroundColor Green

Write-Host "`nAlternatively, use the Grafana CLI:" -ForegroundColor Cyan
Write-Host "grafana-cli --api-key=$ApiKey plugins sign $($zipFile.FullName)" -ForegroundColor Cyan

Write-Host "`nAfter signing, you'll receive a signed version of your plugin that you can distribute." -ForegroundColor Yellow