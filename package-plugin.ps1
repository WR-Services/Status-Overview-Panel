#!/usr/bin/env pwsh
# Plugin packaging script for Status Overview Panel
# Based on https://grafana.com/developers/plugin-tools/publish-a-plugin/package-a-plugin

# Configuration variables
$pluginName = "wrservices-statusoverview-panel"
$pluginVersion = "0.0.7"
$outputFolder = "package"

Write-Host "Starting packaging process for $pluginName v$pluginVersion..." -ForegroundColor Cyan

# Step 1: Ensure we have a clean build
Write-Host "Building plugin in production mode..." -ForegroundColor Yellow
npm run build

if (-Not $?) {
    Write-Host "Build failed. Aborting packaging process." -ForegroundColor Red
    exit 1
}

# Step 2: Create output directory if it doesn't exist
if (Test-Path $outputFolder) {
    Write-Host "Cleaning existing package directory..." -ForegroundColor Yellow
    Remove-Item -Path "$outputFolder\*" -Recurse -Force
} else {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

# Step 3: Create a clean plugin directory in the output folder
$pluginPackageDir = "$outputFolder\$pluginName"
New-Item -ItemType Directory -Path $pluginPackageDir | Out-Null

# Step 4: Copy required files from dist to package directory
Write-Host "Copying plugin files to package directory..." -ForegroundColor Yellow

# Copy all files from dist
Copy-Item -Path "dist\*" -Destination $pluginPackageDir -Recurse

# Step 5: Remove any development files that shouldn't be in the package
$filesToRemove = @(
    "$pluginPackageDir\.git*",
    "$pluginPackageDir\.eslintrc",
    "$pluginPackageDir\.prettierrc",
    "$pluginPackageDir\node_modules",
    "$pluginPackageDir\src",
    "$pluginPackageDir\coverage",
    "$pluginPackageDir\cypress",
    "$pluginPackageDir\.vscode"
)

foreach ($file in $filesToRemove) {
    if (Test-Path $file) {
        Remove-Item -Path $file -Recurse -Force
        Write-Host "Removed: $file" -ForegroundColor Gray
    }
}

# Step 6: Create ZIP archive
Write-Host "Creating ZIP archive..." -ForegroundColor Yellow
$zipFilePath = "$outputFolder\$pluginName-$pluginVersion.zip"

# Remove existing zip if it exists
if (Test-Path $zipFilePath) {
    Remove-Item -Path $zipFilePath -Force
}

# Create the ZIP archive
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($pluginPackageDir, $zipFilePath)

# Step 7: Calculate SHA1 and MD5 checksums (Grafana only supports MD5 and SHA1)
Write-Host "Calculating checksums..." -ForegroundColor Yellow
$sha1 = Get-FileHash -Path $zipFilePath -Algorithm SHA1
$md5 = Get-FileHash -Path $zipFilePath -Algorithm MD5

# Write checksums to files
$sha1.Hash | Out-File -FilePath "$outputFolder\$pluginName-$pluginVersion.zip.sha1" -NoNewline
$md5.Hash | Out-File -FilePath "$outputFolder\$pluginName-$pluginVersion.zip.md5" -NoNewline

# Step 8: Verify package
Write-Host "Verifying package..." -ForegroundColor Yellow
if (Test-Path $zipFilePath) {
    $sizeInMB = [Math]::Round((Get-Item $zipFilePath).Length / 1MB, 2)
    Write-Host "Package successfully created:" -ForegroundColor Green
    Write-Host "  - Location: $zipFilePath" -ForegroundColor Green
    Write-Host "  - Size: $sizeInMB MB" -ForegroundColor Green
    Write-Host "  - MD5: $($md5.Hash)" -ForegroundColor Green
    Write-Host "  - SHA1: $($sha1.Hash)" -ForegroundColor Green
    
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Test the packaged plugin in a clean Grafana environment" -ForegroundColor Cyan
    Write-Host "2. Submit the plugin to Grafana Plugin Catalog: https://grafana.com/grafana/plugins/submit/" -ForegroundColor Cyan
    Write-Host "3. For signing information, visit: https://grafana.com/docs/grafana/latest/developers/plugins/sign-a-plugin/" -ForegroundColor Cyan
} else {
    Write-Host "Failed to create package." -ForegroundColor Red
}