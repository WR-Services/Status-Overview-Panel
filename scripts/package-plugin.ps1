#!/usr/bin/env pwsh
# Plugin packaging script for Status Overview Panel
# Based on https://grafana.com/developers/plugin-tools/publish-a-plugin/package-a-plugin

# Configuration variables
$pluginName = "wrservices-statusoverview-panel"
$outputFolder = "package"

# Read version from package.json
$packageJsonContent = Get-Content -Path "package.json" -Raw | ConvertFrom-Json
$pluginVersion = $packageJsonContent.version

# Verify plugin.json also has the same version
$pluginJsonContent = Get-Content -Path "src/plugin.json" -Raw | ConvertFrom-Json
if ($pluginJsonContent.info.version -ne $pluginVersion) {
    Write-Host "Warning: Version mismatch between package.json ($pluginVersion) and plugin.json ($($pluginJsonContent.info.version))" -ForegroundColor Yellow
    Write-Host "Run update-version.ps1 to synchronize all version numbers" -ForegroundColor Yellow
}

Write-Host "Starting packaging process for $pluginName v$pluginVersion..." -ForegroundColor Cyan

# Step 1: Ensure we have a clean build
Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
if (Test-Path -Path "node_modules\.cache") {
    Remove-Item -Path "node_modules\.cache" -Recurse -Force
}
if (Test-Path -Path "dist") {
    Remove-Item -Path "dist\*" -Recurse -Force
}

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
}
else {
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
    Write-Host "Removing existing zip file: $zipFilePath" -ForegroundColor Gray
    Remove-Item -Path $zipFilePath -Force
}

# Debug directory structure before zipping
Write-Host "DEBUG: Plugin directory structure before zipping:" -ForegroundColor Magenta
if (Test-Path "$outputFolder\$pluginName") {
    Write-Host "Plugin directory exists at: $outputFolder\$pluginName" -ForegroundColor Gray
    $pluginFiles = Get-ChildItem -Path "$outputFolder\$pluginName" -Recurse | Select-Object -First 10
    Write-Host "First 10 files in plugin directory:" -ForegroundColor Gray
    $pluginFiles | ForEach-Object { Write-Host "  $($_.FullName.Replace("$outputFolder\$pluginName\", ""))" -ForegroundColor Gray }
}
else {
    Write-Host "ERROR: Plugin directory not found at: $outputFolder\$pluginName" -ForegroundColor Red
    exit 1
}

# Using a more reliable method to create the ZIP file
Write-Host "Creating properly structured ZIP file using 7-Zip or built-in compression..." -ForegroundColor Yellow

# Check if 7-Zip is available
$use7Zip = $false
if (Test-Path "C:\Program Files\7-Zip\7z.exe") {
    $use7Zip = $true
    Write-Host "Using 7-Zip for better compression..." -ForegroundColor Gray
}

# Current location for later restoration
$currentLocation = Get-Location

if ($use7Zip) {
    # Create zip with 7-Zip (better compression and more reliable)
    Set-Location $outputFolder
    
    # IMPORTANT: We zip the DIRECTORY itself, not its contents, to maintain proper structure
    & "C:\Program Files\7-Zip\7z.exe" a -tzip "$pluginName-$pluginVersion.zip" ".\$pluginName" -r
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: 7-Zip failed to create the archive." -ForegroundColor Red
        Set-Location $currentLocation
        exit 1
    }
    
    Set-Location $currentLocation
}
else {
    # Fallback to .NET built-in compression
    Write-Host "Using .NET built-in compression..." -ForegroundColor Gray
    
    # Create a temporary directory with the right structure
    $tempDir = Join-Path -Path $env:TEMP -ChildPath "grafana-plugin-temp-$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    # Copy plugin files with the right structure
    $tempPluginDir = Join-Path -Path $tempDir -ChildPath $pluginName
    New-Item -ItemType Directory -Path $tempPluginDir -Force | Out-Null
    Copy-Item -Path "$outputFolder\$pluginName\*" -Destination $tempPluginDir -Recurse
    
    # Create the zip file
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $zipFilePath)
    
    # Clean up temp directory
    Remove-Item -Path $tempDir -Recurse -Force
}

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
}
else {
    Write-Host "Failed to create package." -ForegroundColor Red
}