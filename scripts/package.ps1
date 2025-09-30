#!/usr/bin/env pwsh
# Plugin packaging script for Grafana plugin

param(
    [switch]$SkipBuild,
    [string]$OutputFolder = "package"
)

# Get the root directory
$rootDir = Split-Path -Parent $PSScriptRoot

# Configuration
$pluginName = "wrservices-statusoverview-panel"

# Read version from package.json
$packageJsonContent = Get-Content -Path "$rootDir\package.json" -Raw | ConvertFrom-Json
$pluginVersion = $packageJsonContent.version

# Verify plugin.json also has the same version
$pluginJsonContent = Get-Content -Path "$rootDir\src\plugin.json" -Raw | ConvertFrom-Json
if ($pluginJsonContent.info.version -ne $pluginVersion) {
    Write-Host "Warning: Version mismatch between package.json ($pluginVersion) and plugin.json ($($pluginJsonContent.info.version))" -ForegroundColor Yellow
    Write-Host "Run ./plugin.ps1 update-version to synchronize all version numbers" -ForegroundColor Yellow
}

Write-Host "Starting packaging process for $pluginName v$pluginVersion..." -ForegroundColor Cyan

# Ensure output directory exists
$outputFolderPath = Join-Path -Path $rootDir -ChildPath $OutputFolder
if (-not (Test-Path $outputFolderPath)) {
    New-Item -ItemType Directory -Path $outputFolderPath | Out-Null
}

# Step 1: Build if not skipped
if (-not $SkipBuild) {
    $buildScript = Join-Path -Path $PSScriptRoot -ChildPath "build.ps1"
    Write-Host "Building plugin in production mode..." -ForegroundColor Yellow
    & $buildScript -Production -Clean
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build failed. Aborting packaging process." -ForegroundColor Red
        exit 1
    }
}

# Step 2: Clean package directory
Write-Host "Cleaning package directory..." -ForegroundColor Yellow
if (Test-Path "$outputFolderPath\*") {
    Remove-Item -Path "$outputFolderPath\*" -Recurse -Force
}

# Step 3: Create plugin directory
$pluginPackageDir = Join-Path -Path $outputFolderPath -ChildPath $pluginName
New-Item -ItemType Directory -Path $pluginPackageDir -Force | Out-Null

# Step 4: Copy plugin files
Write-Host "Copying plugin files..." -ForegroundColor Yellow
Copy-Item -Path "$rootDir\dist\*" -Destination $pluginPackageDir -Recurse

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

# Step 6: Debug directory structure
Write-Host "Verifying plugin directory structure..." -ForegroundColor Yellow
if (Test-Path $pluginPackageDir) {
    $fileCount = (Get-ChildItem -Path $pluginPackageDir -Recurse -File).Count
    Write-Host "Plugin directory contains $fileCount files" -ForegroundColor Gray
    
    $requiredFiles = @("plugin.json", "module.js")
    $missingFiles = @()
    
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path "$pluginPackageDir\$file")) {
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        Write-Host "Warning: Missing required files: $($missingFiles -join ', ')" -ForegroundColor Red
    } else {
        Write-Host "All required files are present" -ForegroundColor Green
    }
} else {
    Write-Host "ERROR: Plugin directory not found at: $pluginPackageDir" -ForegroundColor Red
    exit 1
}

# Step 7: Create ZIP archive with proper structure
Write-Host "Creating ZIP archive..." -ForegroundColor Yellow
$zipFilePath = "$outputFolderPath\$pluginName-$pluginVersion.zip"

# Remove existing zip if it exists
if (Test-Path $zipFilePath) {
    Remove-Item -Path $zipFilePath -Force
}

# Save current location
$currentLocation = Get-Location

# Create zip from the parent of the plugin directory to maintain structure
Set-Location $outputFolderPath

# Use 7-Zip if available, otherwise .NET
if (Test-Path "C:\Program Files\7-Zip\7z.exe") {
    Write-Host "Using 7-Zip for compression..." -ForegroundColor Gray
    & "C:\Program Files\7-Zip\7z.exe" a -tzip "$pluginName-$pluginVersion.zip" ".\$pluginName" -r
    
    if ($LASTEXITCODE -ne 0) {
        Set-Location $currentLocation
        Write-Host "Failed to create ZIP archive with 7-Zip." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Using .NET compression..." -ForegroundColor Gray
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($outputFolderPath, "$outputFolderPath\temp.zip")
    
    # Extract to fix structure
    $tempDir = Join-Path -Path $env:TEMP -ChildPath "grafana-plugin-temp-$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$outputFolderPath\temp.zip", $tempDir)
    Remove-Item -Path "$outputFolderPath\temp.zip" -Force
    
    # Recreate with proper structure
    [System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, "$outputFolderPath\$pluginName-$pluginVersion.zip")
    
    # Clean up
    Remove-Item -Path $tempDir -Recurse -Force
}

# Restore original location
Set-Location $currentLocation

# Step 8: Calculate checksums
Write-Host "Calculating checksums..." -ForegroundColor Yellow
$sha1 = Get-FileHash -Path $zipFilePath -Algorithm SHA1
$md5 = Get-FileHash -Path $zipFilePath -Algorithm MD5

$sha1.Hash | Out-File -FilePath "$zipFilePath.sha1" -NoNewline
$md5.Hash | Out-File -FilePath "$zipFilePath.md5" -NoNewline

# Step 9: Final verification
Write-Host "Verifying package..." -ForegroundColor Yellow

if (Test-Path $zipFilePath) {
    $sizeInMB = [Math]::Round((Get-Item $zipFilePath).Length / 1MB, 2)
    Write-Host "✅ Package successfully created:" -ForegroundColor Green
    Write-Host "  - Location: $zipFilePath" -ForegroundColor Green
    Write-Host "  - Size: $sizeInMB MB" -ForegroundColor Green
    Write-Host "  - MD5: $($md5.Hash)" -ForegroundColor Green
    Write-Host "  - SHA1: $($sha1.Hash)" -ForegroundColor Green
    
    # Run the analyze script to verify structure
    $analyzeScript = Join-Path -Path $PSScriptRoot -ChildPath "analyze.ps1"
    Write-Host "`nVerifying package structure:" -ForegroundColor Cyan
    & $analyzeScript -ZipPath $zipFilePath -Brief
    
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Test the package in a clean Grafana environment" -ForegroundColor Cyan
    Write-Host "2. Submit to Grafana Plugin Catalog: https://grafana.com/grafana/plugins/submit/" -ForegroundColor Cyan
} else {
    Write-Host "❌ Failed to create package." -ForegroundColor Red
}